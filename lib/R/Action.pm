package R::Action;
# управляет компилляцией экшенов

use R::Watch;

# конструктор
sub new {
	my($cls, $app) = @_;
	bless {app => $app, dir => 'action', dir_c => 'watch/action_c'}, $cls;
}

# удаляет директорию co скомпиленными темплейтами
sub erase {
	my ($self) = @_;
	Utils::rm($self->{dir_c});
}

# ставит на watch
sub watch {
	my ($self, $watch) = @_;
	my $dir = [main::dirs($self->{dir})];
	($watch // $self->{app}->watch)->on(qr/\.act$/, $dir, Utils::closure($self, sub {
		my ($self, $path) = @_;
		$self->compile_action($path);
	}))->on(qr/\.htm$/, $dir, Utils::closure($self, sub { 
		my ($self, $path) = @_;
		$self->compile_htm($path);
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
	$self->watch($watch);
	$watch->fire;
	$self
}

sub write {
	my ($self, $file) = @_;
	$self->{require} = $file // $self->{require};
	my $dir = [main::dirs($self->{dir_c})];
	open my $f, ">", $file or die "Нет файла `$file` для записи: $!";
	print $f "use Helper;\n\n";
	R::Watch->new->on(qr/\.(act|htm)\.pl$/, $dir, sub {
		my ($path) = @_;
		print $f "require '$path';\n";
		#$::_action{$index} = sub { die raise(501) }
	})->fire;
	close $f;
	$self
}

# подгружаем экшены в %_action
sub compile_htm {
	my ($self, $path) = @_;
	local ($_, $`, $');
	
	$path =~ /\b$self->{dir}\/(.*)\.htm$/;
	my $index = $1;
	
		
	my $tmpl = Utils::read($path);
	my $eval = Utils::TemplateBare($tmpl, my $forms, my $page);
	
	#our %_forms; our %_pages;
	#$_pages{$index} = $page;
	
	my @write;
	
	if(exists $page->{options}) {
		for my $option (@{$page->{options}}) {
			if($option->[0] eq 'layout') { push @write, "\$app->action->{layout}{'$index'} = '$option->[1]';\n\n"; }
			else { die "Неизвестная опция `$option->[0]` на странице `$index.htm`" }
		}
	}
	
	if(exists $page->{forms}) {
		$_ = "$index-$_" for @{$page->{forms}};
	}

	while(my ($id, $form) = each %$forms) {
		$form->{name} = $index unless $form->{name};
		$form->{id} = $id = "$index-$id";
		#$form->{query} = form_query $form, $forms;
		push @write, "\$app->action->{form}{'$id'} = ".Utils::Dump($form).";\n\n";
		$_ = "$index-$_" for @{$form->{forms}};
	}
	
	my $code = $page->{code};
	delete $page->{code};
	
	$eval = join "", ($index eq "index"? "\$app->action->{htm}{'/'} = ": ()), "\$app->action->{htm}{'$index'} = sub { $Utils::code_begin_param return join \"\", '", $eval, "'};\n\n\$app->action->{page}{'$index'} = ", Utils::Dump($page), ";\n\$app->action->{page}{'$index'}{code} = ", $code, ";\n", @write, "\n\n1;";
	
	my $p = $path;
	$p =~ s!\b$self->{dir}/!$self->{dir_c}/!;
	$p .= ".pl";
	
	Utils::mkpath($p);
	Utils::write($p, $eval);
	$self;
}

sub compile_action {
	my ($self, $path) = @_;
	
	$path =~ /\b$self->{dir}\/(.*)\.act$/;
	my $index = $1;

	my $action = Utils::read($path);
	my @our = qw/%ENV @INC %INC @ISA/;
	my %our = Utils::set(@our);
	my %local = Utils::set(qw/@_ $_ $0 $1 $2 $3 $4 $5 $6 $7 $8 $9 $a $b/);
	my %my = Utils::set(qw/$app $request $response/);
	while($action =~ /\$(\w+)(::\w+)*\s*(\{|\[)|([\%\$\@]\w+)(::\w+)*/g) {
		next if $2 // $5;$my{$4} = 1 if $4;
		$my{($3 eq "{"? "%": "@").$1} = 1 if $1;
	}
	my @my = keys %my;
	my @local = grep { exists $local{$_} } @my;
	@my = grep { not exists $our{$_} and not exists $local{$_} } @my;
	my $eval = join("", "our(", join(", ", @our), "); ", ($index eq "index"? "\$app->action->{act}{'/'} = ": ()), "\$app->action->{act}{'$index'} = sub {" , (@local? ("local(", join(", ", @local), "); "): ()), (@my? ("my(", join(", ", @my), "); "): ()), "(\$app, \$request, \$response) = \@_; ", $action, "\n};\n\n1;");

	my $p = $path;
	$p =~ s!\b$self->{dir}/!$self->{dir_c}/!;
	$p .= ".pl";
	
	Utils::mkpath($p);
	Utils::write($p, $eval);

	$self
}


1;