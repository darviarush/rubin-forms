package R::Action;
# управляет компилляцией экшенов

use R::Watch;

# конструктор
sub new {
	my($cls, $app, $dir, $dir_c, $ext_act, $ext_htm) = @_;
	bless {
		app => $app,
		app_prop => 'action',
		dir => $dir // 'action',
		dir_c => $dir_c // 'watch/action_c',
		ext_act => $ext_act // qr/\.act$/,
		ext_htm => $ext_htm // qr/\.html$/,
		htm => {},
		act => {},
		validator => {},
	}, $cls;
}

# удаляет директорию co скомпиленными темплейтами
sub erase {
	my ($self) = @_;
	Utils::rm($self->{dir_c});
}

# ставит на watch
sub watch {
	my ($self, $watch, $compile) = @_;
	my $dir = [main::dirs($self->{dir})];
	my $prt = $compile? sub{}: sub{
		my ($self, $module, $path) = @_;
		main::msg(":empty", ":time", " - ", ":red", $module, ":reset", " $path");
		$self->{app}->process->reset;
	};
	
	($watch // $self->{app}->watch)->on($self->{ext_act}, $dir, Utils::closure($self, $prt, sub {
		my ($self, $print, $path) = @_;
		$self->compile_action($path);
		$print->($self, 'action', $path);
	}))->on($self->{ext_htm}, $dir, Utils::closure($self, $prt, sub {
		my ($self, $print, $path) = @_;
		$self->compile_htm($path);
		$print->($self, 'htm', $path);
	}))
}

# компилирует указанные экшены
sub compile {
	my ($self, $dir, $dir_c) = @_;
	if(@_>1) {
		$self->{dir} = $dir;
		$self->{dir_c} = $dir_c;
	}

	my $watch = R::Watch->new;
	$self->watch($watch, 1);
	$watch->fire;
	$self
}


sub write {
	my ($self, $file) = @_;
	$self->{require} = $file // $self->{require};
	my $dir = [main::dirs($self->{dir_c})];
	open my $f, ">", $file or die "Нет файла `$file` для записи: $!";
	print $f "use Helper;\n\n";
	R::Watch->new->on(qr/\.\w+\.pl$/, $dir, sub {
		my ($path) = @_;
		print $f "require '$path';\n";
	})->fire;
	close $f;
	$self
}

# подгружаем экшены в %_action
sub compile_htm {
	my ($self, $path) = @_;
	local ($_, $`, $');
	
	$path =~ /\b$self->{dir}\/(.*)\.(\w+)$/;
	my $index = $1;
	my $ext = $2;
		
	my $tmpl = Utils::read($path);
	my $eval = Utils::TemplateBare($tmpl, my $forms, my $page);
	
	#our %_forms; our %_pages;
	#$_pages{$index} = $page;
	
	my @write;
	
	if(exists $page->{options}) {
		for my $option (@{$page->{options}}) {
			if($option->[0] eq 'layout') { push @write, "\$app->action->{layout}{'$index'} = '$option->[1]';\n\n"; }
			else { die "Неизвестная опция `$option->[0]` на странице `$index.$ext`" }
		}
	}
	
	if(exists $page->{forms}) {
		$_ = "$index-$_" for @{$page->{forms}};
	}

	while(my ($id, $form) = each %$forms) {
		$form->{name} = $index unless $form->{name};
		$form->{id} = $id = "$index-$id";
		if(defined $form->{parent_form}) {
			$form->{parent_form} = "$index-$form->{parent_form}";
		} elsif(exists $form->{parent_form}) {
			$form->{parent_form} = $index;
		}
		
		#$form->{query} = form_query $form, $forms;
		push @write, "\$app->action->{form}{'$id'} = ".Utils::Dump($form).";\n\n";
		$_ = "$index-$_" for @{$form->{forms}};
	}
	
	my $code = $page->{code};
	delete $page->{code};
	
	my $app_prop = $self->{app_prop};
	
	$eval = join "", "\$app->${app_prop}->{htm}{'$index'} = ", $eval, "\n\n\$app->${app_prop}->{page}{'$index'} = ", Utils::Dump($page), ";\n", @write, "\n\n1;";
	#";\n\$app->action->{page}{'$index'}{code} = \$app->action->{ajax_htm}{'$index'} = ", $code,
	
	my $p = $path;
	$p =~ s!\b$self->{dir}/!$self->{dir_c}/!;
	$p .= ".pl";
	
	Utils::mkpath($p);
	Utils::write($p, $eval);
	$self;
}

# компилирует экшены в коде perl
sub compile_action {
	my ($self, $path) = @_;
	
	$path =~ /\b$self->{dir}\/(.*)\.\w+$/;
	my $index = $1;

	# считываем
	my $action = Utils::read($path);
	
	# находим валидаторы
	my %validator = ();
	my $pos = 0;
	$action =~ s/^#[ \t]*([\$\@]([a-z_]\w*))[ \t]+([a-z_]\w*)(?:=(\S+(?: {1,3}\S+)*))?(?:[ \t]+(.*?))?[ \t\r]+$/
		my ($var, $key, $validator, $val, $remark) = ($1, $2, $3, $4, $5);
		
		::msg $pos = length $`;
		
		$validator{$key} = {name => $validator};
		$validator{$key}{val} = $val if defined $val;
		$validator{$key}{remark} = $remark if defined $remark;
		
		$val = defined($val)? ", $val": "";
		$remark = defined($remark)? ", \"$remark\"": "";
		my $ret = "$var = \$app->validator->$validator(\"$key\"$val$remark);";
		::msg $pos += length $ret;
		$ret
	/gme;
	
	if(%validator) {
		::msg $pos;
		pos($action) = $pos;
		$action =~ s/\G/return if \$response->errors;/;
	}
	
	# находим переменные для экранирования через my
	my @our = qw//;
	my %our = Utils::set(@our);
	my %local = Utils::set(qw/$_ $0 $1 $2 $3 $4 $5 $6 $7 $8 $9 $a $b/);
	my %my = Utils::set(qw/$app $request $response/);
	my %no = Utils::set(qw/@_ %ENV @INC %INC @ISA/);
	while($action =~ /\$(\w+)(::\w+)*\s*(\{|\[)|([\%\$\@]\w+)(::\w+)*/g) {
		next if $2 // $5;$my{$4} = 1 if $4;
		$my{($3 eq "{"? "%": "@").$1} = 1 if $1;
	}
	my @my = keys %my;
	my @local = grep { exists $local{$_} } @my;
	@my = grep { not exists $our{$_} and not exists $local{$_} and not exists $no{$_} } @my;
	
	# получаем код
	my $eval = join("", (@our? ("our(", join(", ", @our), "); "): ""), "\$app->action->{act}{'$index'} = sub {" , (@local? ("local(", join(", ", @local), "); "): ()), (@my? ("my(", join(", ", @my), "); "): ()), "(\$app, \$request, \$response) = \@_; ", $action, "\n};\n\n\$app->action->{validator}{'$index'} = ", Utils::Dump(\%validator), ";\n\n1;");

	# записываем во временный файл
	my $p = $path;
	$p =~ s!\b$self->{dir}/!$self->{dir_c}/!;
	$p .= ".pl";
	
	Utils::mkpath($p);
	Utils::write($p, $eval);

	$self
}

# возвращает цепочку лайоутов для экшена
sub layout {
	my ($self, $action) = @_;
	my $lay = $self->{layout_cache}{$action};
	return $lay if defined $lay;
	my $layout = $self->{layout};
	my $layouts = [];
	my $act = $action;
	do { push @$layouts, $act } while $act=$layout->{$act};
	main::msg $layouts;
	$self->{layout_cache}{$action} = $layouts;
}

# загружает данные в шаблоне
sub form_load {
	my ($self, $action, @where) = @_;
	
	my $form_id = $action;
	my $id;
	$id = $1 if $form_id =~ s!-(\d+)!!g;
	
	my $response;
	my $forms = $self->{form};
	my $form = $forms->{$form_id};
	my $name = $form->{name};
	my $model = $form->{model} // $name;
	my @view = keys %{$form->{fields}};
	my $load = $form->{load};
	
	my $get_bean = $load == 2? sub {
		my $bean = $self->{app}{response}{bean}{$form->{parent_form}};
		
		$bean = $bean->Field->{$model}->bean($id) if defined $id;
		
		if(ref $model) {
			$bean = $bean->$_ for @$model;
			$bean
		} else {
			$bean->$model
		}
	}: undef;
	
	main::msg ":inline", ":bold black", '----------------------------', ":red", $action, $form_id, $model, ":green", \@view, ":cyan", \@where;
	
	my $bean;
	
	if($form->{is_list}) {
		$bean = $load == 2? $get_bean->(): $::app->model->$model;
		$bean = $bean->find(@where) if @where;
		@view = ("id", grep { $_ ne "id" } @view);
	}
	else {
		$bean = $load == 2? $get_bean->(): $::app->model->$model(@where);
	}
	
	$self->{app}{response}{bean}{$form_id} = $bean;
	
	$response = $bean->annotate(@view);
	
	$response
}

# объединяет include и ajax_include
sub _include {
	my ($self, $htm, $name, $data, $id, $LAYOUT) = @_;
	die "нет страницы `$name`, для включения в форму `$id`" unless $htm;
	my $app = $self->{app};
	$id =~ s/\d+-//g;
	::msg "include", $name, $id, !!$app->response->{bean}{$id};
	$app->response->{bean}{$name} = $app->response->{bean}{$id};
	$htm->($app, $data, $name, $LAYOUT);
}

# вызывает ajax-инклуд
sub include_ajax {
	my ($self, $name, $data, $id, $LAYOUT) = @_;
	my $htm = $self->{ajax_htm}{$name};
	$self->_include($htm, $name, $data, $id, $LAYOUT);
}

# вставляет в страницу инклуд
sub include {
	my ($self, $name, $data, $id, $LAYOUT) = @_;
	my $htm = $self->{'htm'}{$name};
	$self->_include($htm, $name, $data, $id, $LAYOUT);
}

1;