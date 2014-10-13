use strict;
use warnings;

use POSIX qw/strftime/;
use Data::Dumper;

use Valid;

our ($dbh, $_info, %_tab_selfcol, %_tab_validator, %_tab_update, %_tab_error, %_tab_valid, %_rules, %_tab_rules, %_alias_tab, $_user_id, $_COOKIE, $_HEAD, %_STASH, $param, %_pages, %_forms);

# возвращает валидаторы или выбрасывает исключение
sub get_validator {
	my ($role, $a, $cols) = @_;
	my $validator = $Valid::{$role}? \&{"Valid::$role"}: undef;
	my $update = $Valid::{"update_$role"}? \&{"Valid::update_$role"}: undef;
	my $error = $Valid::{"error_$role"}? \&{"Valid::error_$role"}: undef;
	die "Не обнаружен валидатор $a = $cols" unless $validator or $update or $error;
	return ($validator, $update, $error);
}

# парсим права
# вида: таблица.роль.права = поля
#	или таблица.роль = права
#	или таблица.selfcol = список полей из подчинённых таблиц, по которым определяется принадлежность к записи таблицы пользователю
# например:
#	user.self.view = name,email
#	user.self = view,edit
#	user.selfcol = user_id,id
# валидация:
#	user.int = id
sub parse_perm {
	my ($do) = @_;
	%_tab_selfcol = ();
	%_tab_validator = ();
	%_tab_update = ();
	%_tab_error = ();
	%_tab_valid = ();
	%_rules = ();
	%_tab_rules = ();
	%_alias_tab = ();

	while(my ($a, $cols) = each %$do) {

		my ($tab, $role, $perm) = split /\./, $a;

		my @cols = $cols eq "*"? keys(%{$_info->{$tab}}): split /,\s*/, $cols;
		
		if(not defined $perm) {
			$_alias_tab{$cols} = $tab if $role eq 'alias';	# для колумнов
			$_tab_selfcol{$tab} = [map {my @x=split /\./; [@x==1? ($tab, @x): @x]} @cols], next if $role eq "selfcol"; # список столбцов в таблице
			# валидаторы
			unless(grep {/^(?:noauth|user|self)$/} $role) {
				my ($validator, $update, $error) = get_validator($role, $a, $cols);
				for my $col (@cols) {
					push @{$_tab_validator{$tab}{$col}}, $validator if $validator;
					push @{$_tab_update{$tab}{$col}}, $update if $update;
					push @{$_tab_error{$tab}{$col}}, $error if $error;
					push @{$_tab_valid{$tab}{$col}}, $role;
				}
				next;
			}
			# права на таблицу
			my @perm = @cols;
			die "Нераспознаны права в $a = $cols" if grep({/^(?:add|rm|edit|view)$/} @perm)!=@perm;
			$_tab_rules{$tab}{$role}{$_} = 1 for @perm;
			next;
		}

		my (@perm, @role) = ();
		die "Нераспознана роль в $a = $cols" if $role !~ /^noauth|user|self$/;
		die "Нераспознаны права в $a = $cols" if $perm !~ /^view|add|edit$/;
		
		$_rules{$tab}{$_}{$role}{$perm} = 1 for @cols;
	}
}


sub get_ini_info {
	return {
		tab_selfcol => {%_tab_selfcol},
		tab_validator => {%_tab_validator},
		tab_update => {%_tab_update},
		tab_error => {%_tab_error},
		tab_valid => {%_tab_valid},
		rules => {%_rules},
		tab_rules => {%_tab_rules},
		alias_tab => {%_alias_tab}
	}
}

# возвращает id пользователя, если он залогинен
sub auth (@) {
	my ($fld) = @_;
	return $_user_id if $_user_id and not $fld;
	my $sess = $_COOKIE->{sess};
	return unless $sess;
	my @res = $dbh->selectrow_array(join("", "SELECT user_id", ($fld? $fld: ()), " FROM sess WHERE id=?"), undef, $sess);
	update("sess", {now=>strftime("%F %T", localtime())}, {id=>$sess}) if $res[0];
	return $fld? @res: $res[0];
}

# проверяет валидацию параметров
sub valids_param (@) {
	my ($v, $action, $tab, $param, $where) = @_;
	my ($valid, $validator) = $_tab_validator{$tab};
	while(my($col, $val) = each %$param) {
		if($validator = $valid->{$col}) { $_->($val, $tab, $col, $action, $where) for @$validator };
	}
}

sub valid_param (@) { valids_param \%_tab_validator, @_ }	# проверяет валидацию параметров
sub update_param (@) { valids_param \%_tab_update, @_ }		# делает апдейт нужных столбцов
sub error_param (@) { valids_param \%_tab_error, @_ }		# выполняется при откате (ещё не реализовано)


# проверяем - можно ли править таблицу
sub check_role (@) {
	my ($action, $tab, $param) = @_;
	#$action = $param->{"id"}? "edit": "add" unless $action;
	my $user_id = auth();
	my $role = $user_id? 'user': 'noauth';
	my $check = sub {
		if($_tab_rules{$tab}{$role}{$action}) {
			if($action ne "rm") {
				for my $col (grep {$_ ne 'id'} keys %$param) {
					$@ = "not support `$action` for role `$role` in column `$tab`.`$col`", return unless $_rules{$tab}{$col}{$role}{$action};
				}
			}
			return 1;
		}
		$@ = "not support `$action` for role `$role` in table `$tab`";
		return 0;
	};
	
	return $tab if $check->();
	
	if($user_id and $_tab_rules{$tab}{'self'}{$action}) {
		$role = 'self';
		my @cols = @{$_tab_selfcol{$tab}};
		my $id;
		my $check_self = sub {
			for my $col (@cols) {
				my ($tab1, $col) = @$col;
				die "not support `$action` for role `$role` in row $tab1.id=$id" unless $id;
				$id = query $tab1, $col, $id;
			}
		};
		
		if($action eq 'add') {	# проверяем, чтобы переданный в параметрах id записи из selfcol принадлежал этому пользователю
			$id = 0+$param->{$cols[0]->[1]};
			@cols = @cols[1..$#cols];
			$check_self->();
			return $tab if $check->();
		} else {	# проверяем, чтобы запись принадлежала пользователю
			$id = 0+$param->{id};
			$check_self->();
			return $tab if $user_id == $id and $check->();
		}
	}
	
	die $@ || "not support `$action` for role `$role` in table `$tab`";
}


# проверяет вложенную структуру и формирует аргументы для sel_join
sub check_role_view {
	
	my ($valid, $tab, $view, @args) = @_;
	
	my @view = FIELDS_NAMES($view);
	
	check_role 'view', $tab, { Utils::set(@view) };
	#valid_param 'view', $tab, $view;
	my $v;
	for my $col (@view) {
		$valid->{$col} = $v if $v = $_tab_valid{$tab}->{$col};
	}

	my @av = ($tab, $view);
	for my $arg (@args) {
		if(ref $arg eq "HASH") { check_role 'view', $tab, $arg; push @av, $arg }
		elsif($arg->[0] =~ /^(?:LEFT_JOIN|INNER_JOIN)$/) { push @av, \&{"main::".$arg->[0]}->(check_role_view($valid->{$arg->[1]} ||= {}, @$arg[1..$#$arg])); }
		elsif($arg->[0] =~ /^(?:GROUP|HAVING|ORDER)$/) { check_role 'view', $tab, $arg->[1]; push @av, \&{"main::".$arg->[0]}->($arg->[1]); }
		elsif($arg->[0] eq 'LIMIT') { push @av, LIMIT($arg->[1], $arg->[2]) }
		else { die "Ошибка в параметре `$arg->[0]`" }
	}
		
	return @av;
}

# загружает данные для форм
sub action_load_forms {
	my ($data, $action) = @_;
	for my $id (@{$_pages{$action}{load_forms}}) {
		next if $_STASH{$id};
		my $form = $_forms{$id};
		my $valid = {};
		my $query = $form->{query};
		my $load = $form->{load};
		my $where = exists $load->{stash}? { id => $_STASH{$load->{stash}} }: exists $load->{var}? { id => Utils::path($data, $load->{var})->[0] }: ();
		my @query = check_role_view $valid, @$query, $where;
		my $response = quick_rows(@query);
		$response = $form->{is_list}? { body => $response }: $response->[0];
		$response->{_valid} = $valid if keys %$valid;
		$_STASH{$id} = $response;
	}
}

# формирует запрос из формата Utils::Template
sub form_query (@) {
	my ($form, $forms) = @_;
	local ($_);
	my @forms = map { $forms->{$_} } @{$form->{forms}};
	my %names = map { $_->{name} => 1 } @forms;
	return [
		$form->{name}, 
		[grep { not $names{$_} } keys %{$form->{fields}}],
		map({ ('LEFT_JOIN', form_query($_)) } @forms),
	];
}


# экшены
# выбирает какая акция нужна. Параметров не использует
sub action_main {
	my ($_action) = @_;
	my $method = $_HEAD->{'Ajax'};
	
	my $p = {};
	my $tab = $_info->{$_action};
	while(my($key, $val) = each %$param) {
		$p->{$key} = $val if exists $tab->{$key};
	}
	
	!$method || $method eq 'load'? action_view($_action, $p):
	$method eq 'save'? action_do($_action, $p):
	$method eq 'erase'? action_erase($_action, $p):
	$method eq 'submit'? do { action_do($_action, $p); action_view($_action, $p) }:
	1;
}

# создаёт запись в таблице
#  $tab - название таблицы
#  $param - хеш с полями
sub action_add($$) {
	my ($tab, $param) = @_;
	check_role 'add', $tab, $param;
	valid_param 'add', $tab, $param;
	my $id = add $tab, $param;
	update_param 'add', $tab, $param, $id;
	{action=>"add", id=>$id}
}

# вносит измениения - update
sub action_edit (@) {
	my ($tab, $param) = @_;
	my($set, $where);
	if($param->{id}) {
		$where = $param->{id};
		delete $param->{id};
		$set = $param;
		check_role 'edit', $tab, $param;
	} else {
		$where = $param->{where};
		$set = $param->{set};
		check_role 'edit', $tab, $set;
		check_role 'edit', $tab, $where;
	}
	valid_param 'edit', $tab, $set;
	my $count = update $tab, $param, $where;
	update_param 'edit', $tab, $param, $where;
	{action=>"edit", count=>$count}
}

# создаёт или изменяет запись в таблице
#  $tab - название таблицы
#  $param - хеш с полями. Если id указан и есть, то запись изменяется
sub action_do ($$) {
	my ($tab, $param) = @_;

	my $action;
	my $id = $param->{"id"}+0;
	
	if($id) {	# изменяем
		action_edit $tab, $param;
	} else {	# добавляем
		action_add $tab, $param;
	}
}

# удаляет запись в таблице
# tab - название таблицы
sub action_rm ($$) {
	my ($tab, $where) = @_;
	check_role 'rm', $tab, $where;
	my $count = erase($tab, $where);
	{action => "rm", count => $count}
}

# просмотр содержимого таблицы по заранее сгенерированным из шаблона запросам
sub action_view ($$) {
	my ($action, $param) = @_;
	my $valid = {};
	my $forms = $_pages{$action}{forms}; # // [$param->{_query}];
	my $response;
	if(@$forms==1) { $response = action_form_view($action, $param) }
	else {
		for my $form (@$forms) {
			my $id = $form->{id};
			$response->{$id} = action_form_view($id, $param->{$id});
		}
	}
	$response
}

# просмотр содержимого таблицы по заранее сгенерированным из шаблона запросу для формы
sub action_form_view ($$) {
	my ($action, $param) = @_;
	my ($response, $valid);
	my @query = check_role_view $valid, @{ $_forms{$action}->{query} }, $param;
	$response = Utils::to_rows(quick_rows(@query));
	$response->{valid} = $valid;
	$response
}

sub action_form_load ($$) {
	my ($action, $data) = @_;
	my ($response, $valid);
	my $form = $_forms{$action};
	my @query = check_role_view $valid, @{ $_forms{$action}->{query} }, $param;
	$response->{body} = quick_rows(@query);
	$response->{valid} = $valid;
	$response
}

sub form_load {
	my ($action, $where) = @_;
	my ($response, $valid);
	my $form = $_forms{$action};
	my $tab = $form->{model} // $form->{name};
	my $view = [keys $form->{fields}];
	my @query = check_role_view $valid, $tab, $view;
	if($form->{is_list}) {
		$response = query_all($tab, $view, $where);
		for my $row (@$response) {
			$row->{_valid} = $valid;
		}
	}
	else {
		$response = query_ref($tab, $view, $where);
		$response->{_valid} = $valid;
	}
	
	$response
}

# удаляет просроченные сессии
sub delete_session {
	my $now = strftime('%F %T', localtime time-3600);
	my $sql = "DELETE FROM sess WHERE `now` < '$now'";
	eval { $dbh->do($sql); };
	dbh_connect() if $@ and not $dbh->ping;
}

1;