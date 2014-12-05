package R::Auth;
# авторизация запросов


# конструктор
sub new {
	my($cls, $app) = @_;
	my $self = bless {
		app => $app,
		selfcol => {},		# путь по таблицам, чтобы добраться до пользователя
		validator => {},	# ссылки на функции-валидаторы для столбцов таблиц
		update => {},		# валидаторы срабатывающие после запроса
		error => {},		# откат при ошибке (не реализовано) - происходят для предыдущих, когда был сбой на следующем валидаторе
		valid => {},		# имена валидаторов
		rules => {},		# права на столбцы
		tab_rules => {},	# права на таблицы
		alias_tab => {}		# алиасы столбцов-ссылок на таблицы
	}, $cls;
	$self->parse;
	$self
}

sub app { $_[0]->{app} }

# возвращает валидаторы или выбрасывает исключение
# sub get_validator {
	# my ($role, $a, $cols) = @_;
	# my $validator = $Valid::{$role}? \&{"Valid::$role"}: undef;
	# my $update = $Valid::{"update_$role"}? \&{"Valid::update_$role"}: undef;
	# my $error = $Valid::{"error_$role"}? \&{"Valid::error_$role"}: undef;
	# die "Не обнаружен валидатор $a = $cols" unless $validator or $update or $error;
	# return ($validator, $update, $error);
# }

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
sub parse {
	my ($self) = @_;
	my $do = $self->app->ini->{do};
	my $validators = $self->app->valid;
	
	my $selfcol = $self->{selfcol} = {};
	my $validator = $self->{validator} = {};
	my $update = $self->{update} = {};
	my $error = $self->{error} = {};
	my $valid = $self->{valid} = {};
	my $rules = $self->{rules} = {};
	my $tab_rules = $self->{tab_rules} = {};
	my $alias_tab = $self->{alias_tab} = {};
	
	while(my ($a, $cols) = each %$do) {
		my ($tab, $role, $perm) = split /\./, $a;

		my @cols = $cols eq "*"? keys(%{$self->app->connect->info->{$tab}}): split /,\s*/, $cols;
		if(not defined $perm) {
			$alias_tab->{$cols} = $tab if $role eq 'alias';	# для колумнов
			$selfcol->{$tab} = [map {my @x=split /\./; [@x==1? ($tab, @x): @x]} @cols], next if $role eq "selfcol"; # список столбцов в таблице
			# валидаторы
			unless(grep {/^(?:noauth|user|self)$/} $role) {
				#my ($validator, $update, $error) = get_validator($role, $a, $cols);
				for my $col (@cols) {
					#push @{$validator{$tab}{$col}}, $validator if $validator;
					#push @{$update{$tab}{$col}}, $update if $update;
					#push @{$error{$tab}{$col}}, $error if $error;
					die "Нет валидатора `$role`" unless $validators->can($role) or $validators->can("${role}_update");
					push @{$valid->{$tab}{$col}}, $role;
				}
				next;
			}
			# права на таблицу
			my @perm = @cols;
			die "Нераспознаны права в $a = $cols" if grep({/^(?:add|rm|edit|view)$/} @perm)!=@perm;
			$tab_rules->{$tab}{$role}{$_} = 1 for @perm;
			next;
		}

		die "Нераспознана роль в $a = $cols" if $role !~ /^noauth|user|self$/;
		die "Нераспознаны права в $a = $cols" if $perm !~ /^view|add|edit$/;
		
		$rules->{$tab}{$_}{$role}{$perm} = 1 for @cols;
	}
	
	$self
}

# проверяем - можно ли править таблицу
sub check_role {
	my ($self, $action, $tab, $param) = @_;
	#$action = $param->{"id"}? "edit": "add" unless $action;
	my $error;
	my $user_id = $self->app->session->user_id;
	my $role = $user_id? 'user': 'noauth';
	my $check = sub {
		if($self->{tab_rules}{$tab}{$role}{$action}) {
			if($action ne "rm") {
				for my $col (grep {$_ ne 'id'} keys %$param) {
					$error = "not support `$action` for role `$role` in column `$tab`.`$col`", return unless $self->{rules}{$tab}{$col}{$role}{$action};
				}
			}
			return 1;
		}
		#$error = "not support `$action` for role `$role` in table `$tab`";
		return;
	};
	
	return $self if $check->();
	
	if($user_id and $self->{tab_rules}{$tab}{'self'}{$action}) {
		$role = 'self';
		my @cols = @{$self->{tab_selfcol}{$tab}};
		my $id;
		my $check_self = sub {
			for my $col (@cols) {
				my ($tab1, $col) = @$col;
				die "not support `$action` for role `$role` in row $tab1.id=$id" unless $id;
				$id = $self->connect->query($tab1, $col, $id);
			}
		};
		if($action eq 'add') {	# проверяем, чтобы переданный в параметрах id записи из selfcol принадлежал этому пользователю
			$id = 0+$param->{$cols[0]->[1]};
			@cols = @cols[1..$#cols];
			$check_self->();
			return $self if $check->();
		} else {	# проверяем, чтобы запись принадлежала пользователю
			$id = 0+$param->{id};
			$check_self->();
			return $self if $user_id == $id and $check->();
		}
	}
	
	die $error // "not support `$action` for role `$role` in table `$tab`";
}

# проверяет валидацию параметров
sub valid_param {
	my ($self, $validator, $action, $tab, $param) = @_;
	my $valid = $self->{valid}{$tab};
	my $v = $self->{app}->valid;
	for my $col (keys %$param) {
		if(my $role = $valid->{$col}) {
			for my $val ( @$role ) {
				my $x=$val.$validator;
				$v->$x($param->{$col}, $tab, $col, $action) if $v->can($x);
			}
		}
	}
}

# запускает проверку как на роли, так и на валидаторы
sub valid {
	my ($self, $callback, $action, $tab, $param, @args) = @_;
	eval {
		$self->check_role($action, $tab, $param);
		$self->valid_param(undef, $action, $tab, $param);
		$callback->();
		$self->valid_param("_update", $action, $tab, $param);
	};
	$self->valid_param("_error", $action, $tab, $param), die $@ if $@;
	$self
}

# возвращает имена валидаторов для 
sub valid_names {
	my($self, $tab, $view) = @_;
	my $valid = $self->{valid};
	map { $valid->{$_} or () } $self->connect->FIELDS_NAMES($view);
}

# проверяет вложенную структуру
sub check_role_view {
	my ($self, $tab, $view, @args) = @_;
	
	my $tmp;
	my $connect = $self->connect;
	my @S = [@_];
	
	while(@S) {
		($tmp, $tab, $view, @args) = @{pop @S};
		my $param = { Utils::set($connect->FIELDS_NAMES($view)) };
	
		$self->check_role('view', $tab, $param);

		for my $arg (@args) {
			if(ref $arg eq "ARRAY" and $arg->[0] =~ /^(?:LEFT|INNER)$/) {
				push @S, $arg;
			}
			# elsif(ref $arg eq "HASH") { 
				# $self->check_role('view', $tab, $arg);
			# }
			# elsif($arg->[0] =~ /^(?:HAVING)$/) {
				# $self->check_role('view', $tab, $arg->[1]);
			# }
			# elsif($arg->[0] =~ /^(?:GROUP|ORDER|LIMIT)$/) {
			# }
			# else { die "Ошибка в параметре `$arg`" }
		}
	}

	$self
}

# аналоги из connect, только с аутентификацией
sub update { my($self, $tab, $set, $where)=@_; $self->valid(sub{ $self->{app}->connect->update($tab, $set, $where); }, 'edit', $tab, $set); $self }
sub erase { my($self, $tab, $param)=@_; $self->check_role('rm', $tab, {}); $self->{app}->connect->erase($tab, $param); $self }
sub add { my($self, $tab, $param)=@_; $self->valid(sub{ $self->{app}->connect->add($tab, $param) }, 'add', $tab, $param); $self }
sub append { my($self, $tab, $param)=@_; $self->valid(sub { $self->{app}->connect->append($tab, $param) }, 'add', $tab, $param) }
sub replace { my ($self, $tab, $param) = @_; $self->check_role($param->{id}? 'edit': 'add', $tab, $param); $self->{app}->connect->replace($tab, $param); $self }
sub last_count { my($self)=@_; $self->{app}->connect->{last_count} }
sub last_id { my($self)=@_; $self->{app}->connect->last_id }
sub query { my($self, $fields, @any)=@_; $self->check_role_view($tab, $fields); $self->{app}->connect->query($fields, @any) }
sub query_ref { my($self, $fields, @any)=@_; $self->check_role_view($tab, $fields); $self->{app}->connect->query_ref($fields, @any) }
sub query_all { my($self, $fields, @any)=@_; $self->check_role_view($tab, $fields); $self->{app}->connect->query_all($fields, @any) }
sub insert {
	my($self, $tab, $fields, $matrix)=@_;
	$self->check_role('add', $tab, $fields);
	my $i;
	$i = 0, $self->valid_param("validator", 'add', $tab, { map { ($fields->[$i++], $_) } @$_ }) for @$matrix;
	$self->{app}->connect->insert($tab, $fields, $matrix);
	$self
}


sub form_load {
	my ($self, $action, $where) = @_;
	my $response;
	my $form = $self->{app}->action->{forms}{$action};
	my $tab = $form->{model} // $form->{name};
	my $view = [keys %{$form->{fields}}];
	$self->check_role('view', $tab, $view);
	my $valid = [$self->valid_names($tab, $view)];
	if($form->{is_list}) {
		$response = $self->query_all($tab, $view, $where);
		if(@$valid) {
			$_->{_valid} = $valid for @$response;
		}
	}
	else {
		$response = $self->query_ref($tab, $view, $where);
		$response->{_valid} = $valid if @$valid;
	}
	
	$response
}


1;

