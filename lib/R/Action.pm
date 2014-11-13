package R::Action;
# управляет компилляцией экшенов



# конструктор
sub new {
	my($cls, $app) = @_;
	bless {app => $app}, $cls;
}

# удаляет директорию co скомпиленными темплейтами
sub erase {
	my ($self) = @_;
	Utils::rm($self->{dir_c});
}

# ставит на watch
sub watch {
	my ($self, $watch) = @_;
	my $dir = [dirs($self->{dir})];
	($watch // $self->{app}->watch)->on(qr/\.act$/, $dir, Utils::closure($self, sub {
		my ($self, $path) = @_;
		$self->compile_action($path);
	}))->on(qr/\.htm$/, $dir, Utils::closure($self, sub {
		my ($self, $path) = @_;
		$self->compile_htm($path);
	}))
}

# компилирует нужные и добавляет их в 
sub compile {
	my ($self, $dir, $dir_c) = @_;
	if(@_>1) {
		$self->{dir} = $dir;
		$self->{dir_c} = $dir_c;
	}
	
	unless($self->{dir}) {
		$self->{dir} = 'action';
		$self->{dir_c} = 'action_c';
	}
	
	my $watch = R::Watch->new;
	$self->watch($watch);
	$watch->fire;
	$self
}

sub write {
	my ($self, $file) = @_;
	my $dir = [dirs($self->{dir_c})];
	open my $f, "<", $file or die $!;
	R::Watch->new->on(qr/\.(act|htm)\.pl$/, $dir, sub {
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
	
	$path =~ /\baction\/(.*)\.htm$/;
	my $index = $1;
	
		
	my $tmpl = Utils::read($path);
	my $eval = Utils::TemplateBare($tmpl, my $forms, my $page);
	
	#our %_forms; our %_pages;
	#$_pages{$index} = $page;
	
	my @write;
	
	if(exists $page->{options}) {
		for my $option (@{$page->{options}}) {
			if($option->[0] eq 'layout') { push @write, "\$_layout{'$index'} = '$option->[1]';\n\n"; }
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
		push @write, "\$_forms{'$id'} = ".Utils::Dump($form).";\n\n";
		$_ = "$index-$_" for @{$form->{forms}};
	}
	
	my $code = $page->{code};
	delete $page->{code};
	
	$eval = join "", "my(%_layout, %_forms, %_pages, %_action_htm, %_STASH); \$_action_htm{'$index'} = ", $eval, ";\n\n\$_pages{'$index'} = ", Utils::Dump($page), ";\n\$_pages{'$index'}{code} = ", $code, ";\n", @write, "\n\n1;";
	
	Utils::mkpath($p);
	Utils::write($p, $eval);
}

sub compile_action {
	my ($self, $path) = @_;
	
	$path =~ /([^\/]+)\.htm$/;
	my $index = $1;
	
	eval {
	
		my $p = $path;
		$p =~ s!\baction/!action_c/!;
		$p .= ".pl";
		
		if(not -e $p or -M $p >= -M $path) {
	
			my $action = Utils::read($path);
			my @our = qw/$_COOKIE $_POST $_GET $_HEAD $param $ini %ENV %_STASH $_user_id/;
			my %our = Utils::set(@our);
			my %local = Utils::set(qw/@_ $_ $0 $1 $2 $3 $4 $5 $6 $7 $8 $9 $a $b/);
			my %my = ();
			while($action =~ /\$(\w+)(::\w+)*\s*(\{|\[)|([\%\$\@]\w+)(::\w+)*/g) {
				next if $2 // $5;$my{$4} = 1 if $4;
				$my{($3 eq "{"? "%": "@").$1} = 1 if $1;
			}
			my @my = keys %my;
			my @local = grep { exists $local{$_} } @my;
			@my = grep { not exists $our{$_} and not exists $local{$_} } @my;
			my $eval = join("", "our(", join(", ", @our), "); \$main::_action{'$index'} = sub {" , (@local? ("local(", join(", ", @local), "); "): ()), (@my? ("my(", join(", ", @my), "); "): ()), $action, "\n};\n\n1;");
			
			Utils::mkpath($p);
			Utils::write($p, $eval);
		}
		
		require $p unless $no_require;
	};
	
	if(my $error=$! || $@) { msg RED."load_action `$path`:".RESET." $error"; $::_action{$index} = sub { die raise(501) }; return 1; }
}


1;