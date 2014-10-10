use strict;
use warnings;

use URI::Escape;
use Term::ANSIColor qw(:constants);
use Auth;

# формируем функцию для ajax-запроса
my $code_begin = '(sub { my ($dataset, $id1) = @_; %s my $i = 0; for my $data (@$dataset) { my $id = "$id1-".($data->{id} // $i); ';	
my $code_end = ' $i++; } })';
my $code_begin1 = '(sub { my ($data, $id) = @_; %s';
my $code_end1 = ' })';

sub form_code($;$) {
	my ($form, $load) = @_;
	
	#main::msg $form->{id}, $load, $form->{code};
	
	$load = ($form->{noload}? 0: $form->{load} || $load);
	my $begin = ($form->{is_list}? $code_begin: $code_begin1);
	$begin = sprintf $begin, $load? ($form->{is_list}? "\$dataset = form_load() unless defined \$dataset;": "\$data = form_load() unless defined \$data;"): "";
	
	my @code = ["form", $begin, $load];
	for my $code (@{$form->{code}}) {
		if(ref $code eq "HASH") {
			my $s = form_code($code, $code[$#code]->[2]);
			if(defined($s)) {
				my ($name, $type) = ($code->{name}, $code->{is_list});
				$code[$#code]->[1] = join "", $code[$#code]->[1], $s, "->(\$data", (defined($name)? "['$name']": ()), ", \$id", (defined($name)? ".'-$name'": ()), ")";
				$code[$#code]->[2] = 1;
			}
		} else {
			if($code->[0] eq "if") { push @code, $code; }
			elsif($code->[0] eq "fi") {
				my $top = pop @code;
				if($top->[2]) { $top->[1] .= $code->[1]; $code[$#code]->[1] .= $top->[1]; $code[$#code]->[2] = 1; }
			}
			else { $code[$#code]->[1] .= $code->[1] }
		}
	}
	return unless $code[0]->[2];
	join "", $code[0]->[1], ($form->{is_list}? $code_end: $code_end1);
}


# подгружаем экшены в %_action
sub load_htm($) {
	my ($path) = @_;
	local ($_, $`, $');
	
	$path =~ /\baction\/(.*)\.htm$/;
	my $index = $1;
	
	eval {
	
		my $p = $path;
		$p =~ s!\baction/!action_c/!;
		$p .= ".pl";
		
		if(not -e $p or -M $p >= -M $path) {
				
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
			
			$page->{code} = form_code $page->{code};
			
			$eval = join "", "use strict; use warnings; our(%_layout, %_forms, %_pages, %_action_htm, %_STASH); \$_pages{'$index'}{sub} = \$_action_htm{'$index'} = ", $eval, ";\n\n\$_pages{'$index'} = ", Utils::Dump($page), ";\n", @write, "\n\n1;";
			
			Utils::mkpath($p);
			Utils::write($p, $eval);
		}
		require $p;
	};
	if(my $error = $! || $@) { msg RED."load_htm `$path`:".RESET." $error"; $path =~ s/\//_/g; $main::_action_htm{$index} = sub { die raise(501) }; }
}

sub load_action ($$) {
	my ($path, $index) = @_;
	
	return load_htm $path if $path =~ /\.htm$/;
	
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
			my $eval = join("", "use strict; use warnings; our(", join(", ", @our), "); \$main::_action{'$index'} = sub {" , (@local? ("local(", join(", ", @local), "); "): ()), (@my? ("my(", join(", ", @my), "); "): ()), $action, "\n};\n\n1;");
			
			Utils::mkpath($p);
			Utils::write($p, $eval);
		}
		
		require $p;
	};
	
	if(my $error=$! || $@) { msg RED."load_action `$path`:".RESET." $error"; $::_action{$index} = sub { die raise(501) }; }
}


# вспомогательные функции фреймов
sub include_action ($$) {
	my ($data, $frame_id, $default_action) = @_;
	%::_frames = Utils::parse_frames($::param->{_frames_}) unless %::_frames;
	my $action = $::_frames{$frame_id} // $default_action;
	my $act;
	$::_action_htm{$action}->(($act=$::_action{$action}? $act->($data, $action): $data), $action)
}

# пару функций
sub header ($$) {
	my ($k, $v) = @_;
	if($k =~ /^Content-Type$/i) { content($v) }
	else { $::_HEAD{$k} = $v = Utils::uri_escape($v, qr/[^ -\xFF]/); push @::_HEAD, $k.": ".$v; }
}

sub content ($) {
	my $charset = $_[0] =~ /^text\// && $_[0] !~ /;\s*charset=/? "; charset=utf-8": "";
	$::_HEAD[0] = "Content-Type: $_[0]$charset"
}

sub setcookie {
	use HTTP::Date;
	my ($name, $value, $expire, $path, $domain, $secure, $httponly) = @_;
	my $val = join "", $name, "=", $value,
		(defined($expire)? ("; Expires=" , time2str($expire)): ()),
		(defined($path)? "; Path=$path": ()),
		(defined($domain)? "; Domain=$domain": ()),
		($secure? "; Secure": ()),
		($httponly? "; HttpOnly": ());
	header "Set-Cookie", $val;
	push @::_COOKIE, $val;
}

sub redirect ($;$) {
	$::_STATUS = 307;
	header "Location", $_[0];
	"Redirect to <a href='$_[0]'>".Utils::escapeHTML($_[1] // $_[0])."</a>"
}

sub status ($;$) { $::_STATUS = $_[0]; if($_[1]) { header "Error" => $_[1]; $_[1] } else { ($::_STATUS)." ".$::_STATUS{$::_STATUS} } }

sub raise ($;$) { my($error, $message) = @_; bless {error => $error, message => $message || $::_STATUS{$error}, trace => trace() }, "Rubin::Exception" }

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

# рассовывает после регэкспа
sub parse_location {
	my ($id, $ids);
	($::_URL, $::_LOCATION, $::_action, $id, $ids, $::_EXT) = @_;
	our $param = our $_GET = Utils::param($7);
	$param = defined($id)? { %$_GET, id => $id }: $_GET;
	if(defined $ids) {
		my $i = 2;
		$param->{"id" . ($i++)} = $_ for split /_/, substr $ids, 1;
	}
}

# ajax-редирект
sub ajax_redirect {
	parse_location(@{$_[1]});
	our $_POST = {};
	our %_HEAD = ();
	my @COOKIE = @::_COOKIE;
	@::_COOKIE = ();
	my $ret = ritter();
	our $_STATUS = $ret->[0];
	our @_HEAD = @{$ret->[1]};
	@{$_[0]} = @{$ret->[2]};
	header "Set-Cookie", $_ for @COOKIE;
}


# фреймы - механизм лайоутов и таргетов форм
sub action_submit {
	my $result = {};
	my ($id, $url, $act);
	
	content "text/json";
	
	my $add_res = sub {

		die "Нет экшена `$act`" if not exists $main::_action{$act} and not $main::_action_htm{$act};
		
		my $data;
		
		$result->{$act} = {
			act => $act,
			($id ? (id => $id): ()),
			(exists $main::_action{$act}? (data => $data = $main::_action{$act}->()): ()),
			(exists $main::_forms{$act} && exists $main::_info->{$act}? (data => action_view($main::_action, $main::param)): ()),
			(exists $main::_pages{$act}{template}? (template => $main::_pages{$act}{template}): ()),
			(exists $main::_pages{$act}{layout_id}? (layout_id => $main::_pages{$act}{layout_id}): ()),
			(exists $main::_layout{$act}? (layout => $main::_layout{$act}): ())
		};
		
		action_load_forms($data // $main::param, $act) if $main::_pages{$act}{load_forms};
	};

	unless($::param->{_noact_}) {
		$act = $::_action;
		#$act = 'index' if $act eq "/";
		my $layout_id = $::param->{_layout_id_};
		my $layout = [];
		for(; $act; $act = $main::_layout{$act}) {
			last if defined($layout_id) and $main::_pages{$act}{layout_id} eq $layout_id;
			$add_res->();
			unshift @$layout, $act;
		}
		$result->{"\@layout"} = $layout;
		if(defined $layout_id and exists $main::_layout{$act}) {
			$result->{$act=$main::_layout{$act}} = { act => $act, layout_id => $result->{$act}{layout_id} };
			unshift @$layout, $act;
		}
	}

	my $frames = Utils::param($::param->{_frames_}, qr/,/);

	while(($id, $url) = each %$frames) {
		if($url =~ /\?/) { ($act, $::param) = ($`, Utils::param($')) } else { $act = $url; $::param = {} }
		$add_res->();
	}

	$result->{'@stash'} = \%::_STASH;
	$result->{'@url'} = $::_URL;

	return $result;
}


1;