
# подгружаем экшены в %_action
sub load_htm($) {
	my ($path) = @_;
	local ($_, $`, $');
	
	eval {
	
		my $p = $path;
		$p =~ s!\baction/!c_action/!;
		$p .= ".pl";
		
		if(not -e $p or -M $p >= -M $path) {
		
			$path =~ /\baction\/(.*)\.htm$/;
			my $index = $1;
				
			my $tmpl = Utils::read($path);
			my $eval = Utils::TemplateStr($tmpl, my $forms, my $page);
			
			#our %_forms; our %_pages;
			#$_pages{$index} = $page;
			
			my @write;
			
			if(exists $page->{options}) {
				for my $option (@{$page->{options}}) {
					if($option->[0] eq 'layout') { push @write, "\$_layout{'$index'} = '$option->[1]';\n\n"; }
					else { die "Неизвестная опция `$option->[0]` на странице `$index.htm`" }
				}
			}
			
			while(my ($id, $form) = each %$forms) {
				$form->{name} = $index unless defined $form->{name};
				$form->{id} = $id = $index.$id;
				$form->{query} = form_query $form;
				push @write, "\$_forms{'$id'} = ".Utils::Dump($form).";\n\n";
			}
			
			
			$eval = join "", "use strict;\nuse warnings;\n\nour(%_layout, %_forms, %_pages, %_action_htm, %_STASH);\n\n\$_pages{'$index'} = ", Utils::Dump($page), ";\n", @write, "\n\n\$_pages{'$index'}{sub} = \$_action_htm{'$index'} = ", $eval, ";\n\n1;";
			
			Utils::mkpath($p);
			Utils::write($p, $eval);
		}
		require $p;
	};
	if(my $error = $! || $@) { msg RED."load_htm `$path`:".RESET." $error"; $path =~ s/\//_/g; $_action_htm{$index} = sub { die raise(501) }; }
}

sub load_action ($$) {
	my ($path, $index) = @_;
	
	return load_htm $path if $path =~ /\.htm$/;
	
	eval {
	
		my $p = $path;
		$p =~ s!\baction/!c_action/!;
		$p .= ".pl";
		
		if(not -e $p or -M $p >= -M $path) {
	
			my $action = Utils::read($path);
			my @keys = qw/$_COOKIE $_POST $_GET $param $ini @_ %ENV %_pages %_forms %_action %_action_htm %_layout %_STASH %_watch/;
			my %keys = Utils::set(@keys);
			my %local = Utils::set(qw/$_ $0 $1 $2 $3 $4 $5 $6 $7 $8 $9 $a $b/);
			my %my = ();
			while($action =~ /\$(\w+)\s*(\{|\[)|([\%\$\@]\w+)/g) {
				$my{$3} = 1 if $3;
				$my{($2 eq "{"? "%": "@").$1} = 1 if $1;
			}
			my @my = keys %my;
			my @local = grep { exists $local{$_} } @my;
			@my = grep { not exists $keys{$_} and not exists $local{$_} } @my;
			my $eval = join("", "use strict;\nuse warnings;\n\nour(", join(", ", @keys), ");\n\n\$_action{'$index'} = sub {" , (@local? ("local(", join(", ", @local), ");\n"): ()), (@my? ("my(", join(", ", @my), ");\n"): ()), $action, "\n};\n\n1;");
			
			Utils::mkpath($p);
			Utils::write($p, $eval);
		}
		
		require $p;
	};
	
	if(my $error=$! || $@) { msg RED."load_action $_[0]:".RESET." $error"; $_action{$index} = sub { die raise(501) }; }
}



# вспомогательные функции фреймов
sub include_action ($$) {
	my ($data, $frame_id, $default_action) = @_;
	%_frames = Utils::parse_frames($param->{_frames_}) unless %_frames;
	my $action = $_frames{$frame_id} // $default_action;
	my $act;
	$_action_htm{$action}->(($act=$_action{$action}? $act->($data, $action): $data), $action)
}

# пару функций
sub header ($$) {
	if($_[0] =~ /^Content-Type$/i) { content($_[1]) }
	else { push @_HEAD, $_[0].": ".$_[1]; }
}

sub content ($) {
	my $charset = $_[0] =~ /^text\// && $_[0] !~ /;\s*charset=/? "; charset=utf-8": "";
	$_HEAD[0] = "Content-Type: $_[0]$charset"
}

sub redirect ($) {
	$_STATUS = 307;
	push @_HEAD, "Location: $_[0]";
	"Redirect to <a href='$_[0]'>$_[0]</a>"
}

sub status ($) { ($_STATUS = $_[0])." ".$_STATUS{$_STATUS} }

sub raise ($;$) { my($error, $message) = @_; bless {error => $error, message => $message, trace => trace() }, "Rubin::Exception" }

sub options ($;$&) {
	local ($_);
	my ($arr, $def, $fn) = @_;
	my ($i, $ret) = 0;
	$fn = $def, $fn = undef if ref $def eq 'CODE';
	if($fn) {
		push @$ret, { text => $fn->($_, $i++), val => $_, ($_ eq $def? (selected => " selected"): ())} for @$arr;
	} else {
		push @$ret, { text => $_, val => $_, ($_ eq $def? (selected => " selected"): ())} for @$arr;
	}
	return $ret;
}

1;