#> сервер - http, fcgi или psgi


use File::Basename;
use Time::HiRes qw//;
use JSON;
use Cwd 'abs_path';
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

use R::Watch;
use HttpStatus;
use MimeType;
use Auth;
use Helper;
use Rubin;
use Action;

our (
	$ini, %_action, %_action_htm, %_frames, %_forms, %_pages, %_layout,
	%_tab_rules, %_rules, $dbh, $_info,
	$param, $_GET, $_POST, $_COOKIE, $_HEAD,
	$_METHOD, $_LOCATION, $_URL, $_action, $_user_id, $_VERSION, $_EXT,
	$_STATUS, %_STATUS, %_STASH,
	@_HEAD, %_MIME, %_HEAD, @_COOKIE
	);

our $_RE_LOCATION = qr!((/([^\s\?]*?)(?:(-?\d+)((?:_-?\d+)*)|(\.\w+))?)(?:\?(\S+))?)!;
	
our $_site = $ini->{site};
our $_test = $_site->{test};
our $_port = $_site->{port};
our $_watch = $_site->{watch};
our $_lords = $_site->{lords};
our $_req = $ini->{req} // $_site->{log} // 0;

our %_HIDDEN_EXT = Utils::set(qw/pl pm act htm/, ($_site->{hidden_ext} or ()));

our $_socket;

# при завершении сервера
sub end_server {
	for my $thr (threads->list()) { $thr->detach();  }
	$_socket->close;
}

# считывает права на таблицы и их столбцы
sub read_perm {
	#msg RED.'signal USR1 thr='.threads->tid().RESET;
	parse_perm( $ini->{do} = Utils::parse_ini("main_do.ini") );
}
read_perm();

# перечитывает main_do.ini по сигналу
$SIG{USR1} = \&read_perm;


# тестирует
sub _test {
	my $test = shift // $0;
	my $res = `perl -c $test`;
	return $? == 0? undef: $res;
}

# перезагружает сервер
sub _reload {
	#print STDERR `nginx -s reload`;
	my $res;
	if($res = _test()) {
		print STDERR RED.$res.RESET;
	} else {
		end_server();
		exec $0, @ARGV;
	}
}

# грузим экшены
msg BOLD . BLACK . "load action..." . RESET;
R::Watch->new->on(qr/\.act$/, [dirs("action")], sub {
	my ($path) = @_;
	load_action $path;
})->on(qr/\.htm$/, [dirs("action")], sub {
	my ($path) = @_;
	load_htm $path;
})->fire();

my $watch;
if($_watch) {
	$watch = R::Watch->new->on(qr/\.act$/, [dirs("action")], sub {
		my ($path) = @_;
		msg strftime("%T", localtime)." - ".RED."action".RESET." $path";
		_reload() unless load_action $path, 1;
	})->on(qr/\.htm$/, [dirs("action")], sub {
		my ($path) = @_;
		msg strftime("%T", localtime)." - ".RED."htm".RESET." $path";
		_reload() if load_htm $path, 1;
	})->on(qr//, ["qq", "main.ini", grep { defined $_ and -e $_ and m!/action/.*\.(?:htm|act)\.pl$! } values %INC], sub {
		my ($path) = @_;
		msg strftime("%T", localtime)." - ".RED."module".RESET." $path";
		_reload();
	});
	
	#run_bin "watch", { ini => $ini, no_loop => 1, watching => $watch };
	my $no_
	require do { dirs "bin/watch.pl" };
}

# демонизируемся
if($_site->{daemon}) {
	my $path = dirname($0).'/rubin.log';
	open STDOUT, '>', $path or die $!;
	open STDERR, '>>', $path or die $!;
	open STDIN, "<", "/dev/null" or die $!;
	my $pid = fork;
	die "Не могу выполнить fork\n" if $pid<0;
	exit if $pid;	# это родительский процесс - убиваем его
	die "Не удалось отсоединится от терминала\n" if setsid() == -1;
}

# Открываем сокет
# наш скрипт будет слушать порт $ini->{site}{port} (9000)
# длина очереди соединений (backlog)- 5 штук
my $drv = $_site->{drv} // "";
$_socket = $drv =~ /^fcgi$/i? Rubin::FCGI->new($_port): $drv =~ /^psgi$/i? Rubin::PSGI->new($_port): Rubin::HTTP->new($_port);

msg "Слушаем ".GREEN.$_port.RESET;

# расщепляем процесс
for(my $i=0; $i<$_lords; $i++) {
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
		$watch->run() if $_watch;
	};
	msg("Збойнула задача крона: ".($@ || $!)), $@ = $! = undef if $@ || $!;
	
	eval {
		my @joinable = threads->list(threads::joinable);
		for my $thr (@joinable) {		# проверяем наших лордов
			my @return = $thr->join();
			my $tid = $thr->tid();
			my $error = $thr->error();
			#if($tid == $cron) {
			#	print RED."Завершился крон № $tid\n".RESET."$error";
			#	$cron = threads->create(*cron::run)->tid();
			#} else {
				msg RED."Завершился лорд № $tid".RESET.($error? "\nС ошибкой: $error": "").(@return? "\nВернул: ": "");
				msg \@return if @return;
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
	$_socket->accept($_site->{ext}? \&tan: \&ritter);
}

# Обработчик с файлами
sub tan {
	if(defined $_EXT) {
		@_HEAD = ("Content-Type: text/html; charset=utf-8");
		$_EXT = lc $_EXT;
		my $res;
		eval {
			my $root;
			return [403, \@_HEAD, [status(403)]] if exists $_HIDDEN_EXT{$_EXT} or ($root=abs_path(".")) ne substr abs_path(".$_LOCATION"), 0, length $root;
			$res = Utils::file2array("./$_LOCATION", $_site->{buf_size} // 1024*1024);
		};
		return [404, \@_HEAD, [status(404)]] if $! // $@;
		content($_MIME{$_EXT} // "text/plain");
		return [200, \@_HEAD, $res];
	}
	
	ritter();
}

# Подчинённый обработчик запросов
sub ritter {
	@_HEAD = "Content-Type: text/html; charset=utf-8";
	
	%_frames = ();
	my @ret = ();

	$_action = 'index' if $_action eq "";
	eval {
		my $action = $_action{$_action};
		my $action_htm = $_action_htm{$_action};
		my $ajax = $_HEAD->{Ajax} // "";
		
		if(defined $action_htm and $ajax eq "reload") {
			$_STATUS = 200;
			$_user_id = $_COOKIE->{sess}? auth(): undef;
			%_STASH = (user_id => $_user_id);
			
			@ret = action_submit($ajax eq "submit");
			my @loc;
			return ajax_redirect(\@ret, \@loc) if $_STATUS == 307 and @loc = $_HEAD{'Location'} =~ /^$_RE_LOCATION$/o;
		}
		elsif(defined $action_htm and $ajax eq "") {
			$_STATUS = 200;
			$_user_id = $_COOKIE->{sess}? auth(): undef;
			%_STASH = (user_id => $_user_id);
						
			@ret = $action? $action->(): $param;
			if($action_htm and $_STATUS == 200) {
				@ret = $_action_htm{$_action}->($ret[0], $_action);
				for(; my $_layout = $_layout{$_action}; $_action = $_layout) {
					my $arg = ($action = $_action{$_layout})? $action->(): {};
					@ret = $_action_htm{$_layout}->($arg, $_layout, @ret);
				}
			}
		} elsif(defined $action) {
			$_STATUS = 200;
			$_user_id = $_COOKIE->{sess}? auth(): undef;
			@ret = $action->();
		} elsif(exists $_info->{$_action}) {
			$_STATUS = 200;
			$_user_id = auth();
			@ret = action_main($_action);
		} else {
			$_STATUS = 404;
			@ret = "404 Not Found";
		}
		@ret = map { ref($_)? to_json($_): $_ } @ret;
	};

	if(my $error = $@ || $!) {
		my $is_io = $!;
		$@ = $! = undef;
		if(ref $error eq "Rubin::Raise") {
			@ret = $error;
		} else {
			if(ref $error eq "Rubin::Exception") { $_STATUS = $error->{error}; $error = join "", $error->{error}, " ", $error->{message}, "\n\n", $error->{trace} }
			else { $_STATUS = 500; }
			
			$error = ($is_io? "io: ": "").$error;
			
			my $e = $error;
			$e =~ s!\b((?:called )?at|line|thread)\b!CYAN.$1.RESET!ge;
			msg RED."action-error `$_action".($param->{id} // "")."`:".RESET." $e\n";
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
	
	%_STASH = ();
	
	return [$_STATUS, \@_HEAD, \@ret];
}


# распечатывают статистику. Используются в драйверах
my %_STAT = ();

sub stat_start {
	$_STAT{time} = Time::HiRes::time();
}

sub stat_begin {
	msg "\n".RED."$_METHOD".RESET." $_URL ".RED."$_VERSION ".CYAN."tid".RESET.": ".threads->tid().CYAN." from ".RESET.join(", ", threads->list());
	if($_req > 0) { msg MAGENTA.$_.RESET.": ".CYAN.$_HEAD->{$_}.RESET for keys %{$_HEAD} };
	if($_req > 1) { msg CYAN.$_.RESET.": ".(!defined($_POST->{$_})? RED."null".RESET: ref $_POST->{$_} eq "JSON::XS::Boolean"? RED.$_POST->{$_}.RESET: ref $_POST->{$_}? Utils::Dump($_POST->{$_}): $_POST->{$_} ) for keys %$_POST };
}

sub stat_end {
	my ($RESPONSE, $head, $out) = @_;
	$RESPONSE =~ s/\s*$//;
	msg $RESPONSE;
	/: /, msg GREEN.$`.RESET.": ".YELLOW.$'.RESET for @$head;
	if($_req > 1) { msg $_ for @$out }
	my $time = Time::HiRes::time() - $_STAT{time};
	msg MAGENTA."sec".RESET." $time";
}