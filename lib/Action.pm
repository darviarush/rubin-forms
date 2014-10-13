use strict;
use warnings;

use URI::Escape;
use Term::ANSIColor qw(:constants);
use Auth;

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
			
			my $code = $page->{code};
			delete $page->{code};
			
			$eval = join "", "use strict; use warnings; our(%_layout, %_forms, %_pages, %_action_htm, %_STASH); \$_pages{'$index'}{sub} = \$_action_htm{'$index'} = ", $eval, ";\n\n\$_pages{'$index'} = ", Utils::Dump($page), ";\n\$_pages{'$index'}{code} = ", $code, ";\n", @write, "\n\n1;";
			
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
		
		my $data = exists $main::_action{$act}? $main::_action{$act}->(): {};
		$main::_pages{$act}{code}->($data, $act) if exists $main::_pages{$act}{code};
		
		$result->{$act} = {
			act => $act,
			($id ? (id => $id): ()),
			#(exists $main::_forms{$act} && exists $main::_info->{$act}? (data => action_view($main::_action, $main::param)): ()),
			(defined($data)? (data => $data): ()),
			(exists $main::_pages{$act}{template}? (template => $main::_pages{$act}{template}): ()),
			(exists $main::_pages{$act}{layout_id}? (layout_id => $main::_pages{$act}{layout_id}): ()),
			(exists $main::_layout{$act}? (layout => $main::_layout{$act}): ())
		};
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