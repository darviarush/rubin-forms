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
#use Devel::Confess  qw/color/;
use Carp::Trace qw/trace/;
use Carp 'verbose';
$SIG{ __DIE__ } = \&Carp::confess; #sub { print STDERR RED, $_[0] , GREEN, trace(), RESET;  };
$SIG{ __WARN__ } = sub { print STDERR YELLOW, (ref($_[0])? Dumper($_[0]): $_[0]), CYAN, trace(), RESET; };
use HttpStatus;
use Watch;
use Auth;
use Helper;
use Rubin;
use Actions;

our (
	$ini, %_action, %_action_htm, $_action, $_id, $_user_id, %_frames, %_forms, %_pages, %_layout,
	%_tab_rules, %_rules, $dbh, $_info,
	$param, $_GET, $_POST, $_COOKIE, $_HEAD, $_STATUS, %_STATUS, %_STASH
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
my $drv = $_site->{drv} // "";
$_socket = $drv =~ /^fcgi$/i? Rubin::FCGI->new($_port): Rubin::HTTP->new($_port);

for_action \&load_action;	# грузим экшены

# подгружаем таблицы
#msg \%_tab_rules, \%_rules;
#for my $a (keys(%_tab_rules), keys(%_rules)) {
#	$_action{$a} = \&action_main unless exists $_action{$a};
#}

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
				msg RED."Завершился лорд № $tid\n".RESET.($error // "");
				threads->create(*lord);
			#}
		}
	};
	msg("Лорд завершился с ошибкой: ".($@ || $!)), $@ = $! = undef if $@ || $!;
}

# Обработчик запросов
sub lord {
	$dbh = undef; # чтобы не закрылась через dbh_connect
	dbh_connect();	# своё подключение к БД
	$_socket->bind;	# инициализируемся в новом треде
	$_socket->accept(\&ritter);
}

# Подчинённый обработчик запросов
sub ritter {
	my $time = Time::HiRes::time();
	@_HEAD = ("Content-Type: text/html; charset=utf-8");
	msg "\n".RED."$_socket->{method}".RESET." $_socket->{location} ".CYAN."tid".RESET.": ".threads->tid().CYAN." from ".RESET.join(", ", threads->list());
	if($_req > 0) { msg MAGENTA.$_.RESET.": ".CYAN.$_socket->{head}{$_}.RESET for keys %{$_socket->{head}} };
	
	%_frames = ();
	my @ret = ();
	($_action, $_id) = $_socket->{location} =~ m!^/(.*?)(-?\d+)?/?$!;

	$_action = 'index' if $_action eq "";
	eval {
		my $action = $_action{$_action};
		my $action_htm = $_action_htm{$_action};
		my $info = $_info->{$_action};
		unless(defined $action or defined $action_htm or defined $info) {
			$_STATUS = 404;
			@ret = "404 Not Found";
		} else {
			$_STATUS = 200;
			$_HEAD = $_socket->{head};
			$_COOKIE = $_socket->{cookie};
			$_GET = $_socket->{get};
			$_POST = $_socket->{post};
			$param = {%$_POST, %$_GET};
			$_STASH{_user_id} = $_user_id = auth();
			
			my $ajax = $_HEAD->{Ajax} // "";

			if($action) {
				@ret = $action->();
				if($action_htm and $_STATUS == 200 and not $ajax) { goto HTM; } else { goto FIN; }
			}
			if($info and (not $action_htm or not $ajax =~ /^|submit$/)) { action_main($_action); goto FIN; }
			
			HTM:
			@ret = $_action_htm{$_action}->($ret[0], $_action);
			for(; my $_layout = $_layout{$_action}; $_action = $_layout) {
				my $arg = ($action = $_action{$_layout})? $action->(): {};
				@ret = $_action_htm{$_layout}->($arg, $_layout, @ret);
			}
			FIN:
		}
		@ret = map { ref($_)? to_json($_): $_ } @ret;
	};
	if(my $error = $@ || $!) {
		my $is_io = $!;
		$@ = $! = undef;
		if(ref $error eq "Rubin::Raise") {
			@ret = $error;
		} else {
			if(ref $error eq "Rubin::Exception") { $_STATUS = $error->{error}; $error = $error->{message} . $error->{trace} }
			else { $_STATUS = 500; }
			
			$error = ($is_io? "io: ": "").$error;
			
			my $e = $error;
			$e =~ s!\b((?:called )?at|line|thread)\b!CYAN.$1.RESET!ge;
			msg RED."action-error `$_action".(defined($_id)? ".$_id": "")."`:".RESET." $e\n";
			$error = $_test ? $error: "Внутренняя ошибка";
			
			if($_HEAD->{Accept} =~ /^text\/json\b/) {
				@_HEAD = "Content-Type: text/plain; charset=utf-8";
				@ret = to_json({error=> $error});
			} else {
				@_HEAD = "Content-Type: text/html; charset=utf-8";
				my ($i, $x) = 0;
				$error =~ s!\b((?:called )?at|line|thread)\b!<font color=LightSlateGray>$1</font>!g;
				$error =~ s/^(.*)/$x = $1; ""/e;
				$error =~ s!\n(\s*)!"</div>\n<div class='".($i++ % 2 == 0? 'e-odd': 'e-even')."'>"!ge;
				$error =~ s!^</div>\n!!;
				$error =~ s!<div class='[^']+'>$!!;
				@ret = ("<style><!--
.e-even {background: lavender}
.e-odd {background: AliceBlue}
.e-even, .e-odd { padding: 4pt 4pt 4pt 20pt }
--></style>
$x
", $error);
			}
			dbh_connect() unless $dbh and $dbh->ping;
		}
	}
	
	/: /, msg GREEN.$`.RESET.": ".YELLOW.$'.RESET for @_HEAD;
	if($_req > 1) { msg $_ for @ret }
	$time = Time::HiRes::time() - $time;
	msg MAGENTA."sec".RESET." $time";
	
	%_STASH = ();
	
	return [$_STATUS, \@_HEAD, \@ret];
}