#> сервер - реализует протокол FastCGI

use strict;
use warnings;


use File::Find;
use File::Basename;
use Time::HiRes qw//;
use JSON;
use Term::ANSIColor qw(:constants);
use POSIX ":sys_wait_h";
use threads ('yield',
	'stack_size' => 64*4096,
	'exit' => 'threads_only',
	'stringify');
use threads::shared;
use Devel::Confess  qw/color/;
use Carp::Trace qw/trace/;
use Watch;
use Auth;
use Helper;
use HttpStatus;
use Rubin;

our (
	$ini, %_action, %_action_htm, $_action, $_id, $_user_id, %_frames, %_forms, %_pages, %_layout,
	%_tab_rules, %_rules, $dbh, $_info,
	$param, $_GET, $_POST, $_COOKIE, $_STATUS, %_STATUS, %_STASH
	);
	
my (
	@_HEAD
	);

my $_site = $ini->{site};
my $_test = $_site->{test};
my $_port = $_site->{port};
my $_watch = $_site->{watch};
my $_lords = $_site->{lords};
my $_req = $ini->{req} // 0;


our $_socket;

sub end_server {
	for my $thr (threads->list()) { $thr->detach();  }
	$_socket->close;
}


# Открываем сокет
# наш скрипт будет слушать порт $ini->{site}{port} (9000)
# длина очереди соединений (backlog)- 5 штук
my $drv = $_site->{drv};
$_socket = $drv =~ /^fcgi$/i? Rubin::FCGI->new($_port): Rubin::HTTP->new($_port);


# подгружаем экшены в %_action
sub load_htm($) {
	my ($path) = @_;
	local ($_, $`, $');
	
	$path =~ /\baction\/(.*)\.htm$/;
	my $index = $1;
		
	my $tmpl = Utils::read($path);
	my $eval = Utils::TemplateStr($tmpl, my $forms, my $page);
	
	our %_forms; our %_pages;
	$_pages{$index} = $page;
	
	if(exists $page->{options}) {
		for my $option (@{$page->{options}}) {
			if($option->[0] eq 'layout') { $_layout{$index} = $option->[1] }
			else { die "Неизвестная опция `$option->[0]` на странице `$index.htm`" }
		}
	}
	while(my ($id, $form) = each %$forms) {
		$form->{name} = $index unless defined $form->{name};
		$form->{id} = $id = $index.$id;
		$form->{query} = form_query $form;
		$_forms{$id} = $form;
	}
	
	my $code = eval $eval;
	if(my $error = $! || $@) { msg "load_htm `$path`: $error"; $path =~ s/\//_/g; $_action_htm{$index} = sub { die raise(501) }; }
	else { $_pages{$index}{sub} = $_action_htm{$index} = $code }
}
sub load_action ($$) {
	return load_htm $_[0] if $_[0] =~ /\.htm$/;
	my $action = Utils::read($_[0]);
	my %keys = Utils::set(qw/$_COOKIE $_POST $_GET $param $ini @_ %ENV %_pages %_forms %_action %_action_htm %_layout %_STASH/);
	my %local = Utils::set(qw/$_ $0 $1 $2 $3 $4 $5 $6 $7 $8 $9 $a $b/);
	my %my = ();
	while($action =~ /\$(\w+)\s*(\{|\[)|([\%\$\@]\w+)/g) {
		$my{$3} = 1 if $3;
		$my{($2 eq "{"? "%": "@").$1} = 1 if $1;
	}
	my @my = keys %my;
	my @local = grep { exists $local{$_} } @my;
	@my = grep { not exists $keys{$_} and not exists $local{$_} } @my;
	my $eval = join("", "sub{ use strict; use warnings; " , (@local? ("\nlocal(", join(", ", @local), ");"): ()), (@my? ("\nmy(", join(", ", @my), ");"): ()), "\n", $action, "\n}");
	my $code = eval $eval;
	my $index = $_[1];
	if(my $error=$! || $@) { msg RED."load_action $_[0]:".RESET." $error"; $_action{$index} = sub { die raise(501) }; Utils::write("$index.pl", $eval) } else { $_action{$index} = $code }
}
for_action \&load_action;	# грузим экшены

# подгружаем таблицы
#msg \%_tab_rules, \%_rules;
for my $a (keys(%_tab_rules), keys(%_rules)) {
	$_action{$a} = \&action_main unless exists $_action{$a};
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

# демонизируемся
if($_site->{daemon}) {
	open STDERR, '>'.dirname($0).'/qq.log' or die $!;
	my $pid = fork;
	die "Не могу выполнить fork\n" if $pid<0;
	exit if $pid;	# это родительский процесс - убиваем его
	die "Не удалось отсоединится от терминала\n" if setsid() == -1;
}

msg "Слушаем ".GREEN.$_port.RESET;

# расщепляем процесс
for(my $i=0; $i<$_lords; $i++) {
	#if(($pid=fork)<0) {die $!} elsif($pid==0) {goto RUN} else { push @_lords, $pid }
	threads->create(*lord) or die $!;
}
$! = undef;

# главный процесс - следит за остальными и выполняет действия по крону
$SIG{INT} = $SIG{TERM} = sub { end_server(); exit; };
for(;;) {
	sleep 1;
	# задачи по крону
	eval {
		delete_session() if time() % 3600 == 0;	# раз в час
		watch() if $_watch;
	};
	msg("Збойнула задача крона: ".($@ || $!)), $@ = $! = undef if $@ || $!;
	
	eval {
		my @joinable = threads->list(threads::joinable);
		for my $thr (@joinable) {		# проверяем наших лордов
			my $tid = $thr->tid();
			my $error = $thr->error();
			#if($tid == $cron) {
			#	print RED."Завершился крон № $tid\n".RESET."$error";
			#	$cron = threads->create(*cron::run)->tid();
			#} else {
				print RED."Завершился лорд № $tid\n".RESET."$error";
				threads->create(*lord);
			#}
		}
		
		#while( $pid = waitpid -1, WNOHANG ) {		# проверяем наших лордов
		#	msg "Сдох ".RED."$pid".RESET;
			#@_lords = grep {$_!=$pid} @_lords;
			#if(($pid=fork)<0) { msg "fork не сработал", $! } elsif($pid==0) {goto RUN} else { push @_lords, $pid }
		#}
	};
	msg("Лорд завершился с ошибкой: ".($@ || $!)), $@ = $! = undef if $@ || $!;
}

# Обработчик запросов
sub lord {
	#$SIG{USR1} = sub { _watch_actions(); };
	#@_lords = ();

	#my $sel = IO::Socket->new($_socket);
	#$sel->add();
	
	#my ($vec, $out) = "";
	#vec($vec, $_socket, 1) = 1;
	#vec($out, $_socket, 1) = 1;
	
	$dbh = undef; # чтобы не закрылась через 
	dbh_connect();	# своё подключение к БД
	$_socket->bind;	# свой request
	
	for(;;) {
		#my $nfound = select $vec, $out, undef, undef;
		#msg CYAN."nfound ".RESET." soc=$_socket vec=$vec ".RED.$nfound.RESET;
		next unless $_socket->accept;
		my $time = Time::HiRes::time();
		@_HEAD = ("Content-Type: text/html; charset=utf-8");
		msg "\n".RED."$_socket->{method}".RESET." $_socket->{location} ".CYAN."tid".RESET.": ".threads->tid().CYAN." from ".RESET.join(", ", threads->list());
		if($_req > 0) { msg MAGENTA.$_.RESET.": ".CYAN.$_socket->head->{$_}.RESET for keys %{$_socket->head} };
		
		%_frames = ();
		my @ret = ();
		($_action, $_id) = $_socket->{location} =~ m!^/(.*?)(-?\d+)?/?$!;

		$_action = 'index' if $_action eq "";
		my $accept = $_socket->{head}{accept};
		eval {
			my ($action);
			unless(($action = $_action{$_action}) or exists $_action_htm{$_action}) {
				$_STATUS = 404;
				@ret = "404 Not Found";
			} else {
				$_STATUS = 200;
				$_GET = $_socket->{get};
				$_POST = $_socket->{post};
				$param = {%$_POST, %$_GET};
				$_COOKIE = $_socket->{cookie};
				$_STASH{_user_id} = $_user_id = auth();
				
				if($action) { @ret = $action->(); } elsif(my $forms = $_pages{$_action}{load_forms}) {
					for my $form (@$forms) {
						msg $form;
					}
					#@ret = action_main $_action
				}
				if($accept !~ /^text\/json\b/i and exists $_action_htm{$_action} and $_STATUS == 200) {
					@ret = $_action_htm{$_action}->($ret[0], $_action);
					for(; my $_layout = $_layout{$_action}; $_action = $_layout) {
						my $arg = ($action = $_action{$_layout})? $action->(): {};
						@ret = $_action_htm{$_layout}->($arg, $_layout, @ret);
					}
				}
			}
			@ret = map { ref($_)? to_json($_): $_ } @ret;
		};
		if(my $error = $@ || $!) {
			$@ = $! = undef;
			if(ref $error) {
				@ret = $error;
			} else {
				if(ref $error eq "Rubin::Exception") { $_STATUS = $error->{error}; $error = $error->{message} . $error->{trace} }
				else { $_STATUS = 500 }
				
				msg "action-error `$_action".(defined($_id)? ".$_id": "")."`: $error\n";
				@_HEAD = "Content-Type: text/plain; charset=utf-8";
				@ret = to_json({error=> $_test ? $error: "Внутренняя ошибка"});
				dbh_connect() unless $dbh and $dbh->ping;
			}
		}
		
		$_socket->send($_STATUS, \@_HEAD, \@ret);
		
		/: /, msg GREEN.$`.RESET.": ".YELLOW.$'.RESET for @_HEAD;
		if($_req > 1) { msg $_ for @ret }
		$time = Time::HiRes::time() - $time;
		msg MAGENTA."sec".RESET." $time";
		
		%_STASH = ();
		@ret = ();
	}
}