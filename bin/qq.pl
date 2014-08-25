#> сервер - реализует протокол FastCGI

use FCGI;
#use CGI;
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
use Carp 'verbose';
$SIG{ __DIE__ } = \&Carp::confess;
use Watch;
use Auth;
use Helper;
use HttpStatus;


sub end_server {
	for my $thr (threads->list()) { $thr->detach();  }
	FCGI::CloseSocket($_socket);
}

$_site = $ini->{site};
$_test = $_site->{test};
$_port = $_site->{port};
$_watch = $_site->{watch};
$_lords = $_site->{lords};


# Открываем сокет
# наш скрипт будет слушать порт $ini->{site}{port} (9000)
# длина очереди соединений (backlog)- 5 штук
$_socket = FCGI::OpenSocket(":$_port", 5);

# подгружаем экшены в %_action
sub load_htm($) {
	my ($path) = @_;
	local ($_, $`, $');
	
	$path =~ /\baction\/(.*)\.htm$/;
	my $index = $1;
		
	$_ = Utils::read($path);
	$_ = Utils::TemplateStr($_, my $forms, my $page);
	
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
	
	my $eval = eval $_;
	if(my $error = $! || $@) { msg "load_htm `$path`: $error"; $path =~ s/\//_/g; msg "`$path.pl`"; Utils::write("$path.pl", $_); } else { $_pages{$index}{sub} = $_action_htm{$index} = $eval }
}
sub load_action ($$) {
	return load_htm $_[0] if $_[0] =~ /\.htm$/;
	my $action = Utils::read($_[0]);
	my %keys = Utils::set(qw/$_COOKIE $_POST $_GET $param $ini @_ %ENV $_pages $_forms $_action/);
	my %local = Utils::set(qw/$_ $0 $1 $2 $3 $4 $5 $6 $7 $8 $9/);
	my %my = ();
	while($action =~ /\$(\w+)\s*->\s*(\{|\[)|([\%\$\@]\w+)/g) {
		$my{$3} = 1 if $3;
		$my{($2 eq "{"? "%": "@").$1} = 1 if $1;
	}
	my @my = keys %my;
	my @local = grep { exists $local{$_} } @my;
	@my = grep { not exists $keys{$_} and not exists $local{$_} } @my;
	
	my $eval = join("", "sub{" , (@local? ("\nlocal(", join(", ", @local), ");"): ()), (@my? ("\nmy(", join(", ", @my), ");"): ()), "\n", $action, "\n}");
	my $code = eval $eval;
	if(my $error=$! || $@) { msg RED."load_action $_[0]:".RESET." $error" } else { $_action{$_[1]} = $code }
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
	our %_frames = Utils::parse_frames($param->{frames}) unless %_frames;
	my $action = $_frames->{$frame_id} // $default_action;
	my $act;
	$_action_htm{$action}->(($act=$_action{$action}? $act->($data, $action): $data), $action)
}

sub layout ($) { $_layout{$_index} = $_[1] }

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
if($_daemon) {
	open STDERR, '>'.dirname($0).'/qq.log' or die $!;
	$pid = fork;
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
	my ($vec, $out) = "";
	vec($vec, $_socket, 1) = 1;
	vec($out, $_socket, 1) = 1;
	
	$dbh = undef;
	dbh_connect();	# своё подключение к БД
	my $_request = FCGI::Request(\*STDIN, \*STDOUT, \*STDOUT, \%ENV, $_socket);	# свой request

	
	for(;;) {
		#my $nfound = select $vec, $out, undef, undef;
		#msg CYAN."nfound ".RESET." soc=$_socket vec=$vec ".RED.$nfound.RESET;
		next if $_request->Accept() < 0;
		my $time = Time::HiRes::time();
		@_HEAD = ("Content-Type: text/html; charset=utf-8");
		msg "\n".RED."$ENV{REQUEST_METHOD}".RESET." $ENV{REQUEST_URI} ".CYAN."tid".RESET.": ".threads->tid().CYAN." from ".RESET.join(", ", threads->list());
		%_frames = ();
		my @ret = ();
		our ($_action, $_id) = $ENV{DOCUMENT_URI} =~ m!^/(.*?)(-?\d+)?/?$!;

		$_action = 'index' if $_action eq "";
		eval {
			my ($action, $form, $htm);
			unless(($action = $_action{$_action}) or ($form = $_forms{$_action}) or exists $_action_htm{$_action} and $ENV{'HTTP_ACCEPT'} !~ /^text\/json\b/i) {
				$_STATUS = 404;
				@ret = "404 Not Found";
			} else {
				$_STATUS = 200;
				our $_GET = Utils::param($ENV{'QUERY_STRING'}, qr/&/);
				#msg \%ENV;
				our $_POST = $ENV{CONTENT_LENGTH}? Utils::param_from_post($ENV{'REQUEST_BODY_FILE'}? do { my $f; open $f, $ENV{'REQUEST_BODY_FILE'} or die "NOT OPEN REQUEST_BODY_FILE=".$ENV{'REQUEST_BODY_FILE'}." $!"; $f }: \*STDIN, $ENV{'CONTENT_TYPE'}, $ENV{'CONTENT_LENGTH'}): {};
				our $_COOKIE = Utils::param($ENV{'COOKIE'}, qr/;\s*/);
				our $param = {%$_POST, %$_GET};
				
				if($action) { @ret = $action->(); } elsif($form) { @ret = action_form_view $_action, $param }
				my $accept = $ENV{'HTTP_ACCEPT'};
				if($accept !~ /^text\/json\b/i and exists $_action_htm{$_action} and $_STATUS == 200) {
					@ret = $_action_htm{$_action}->($ret[0], $_action);
					msg \%_layout, $_action;
					for(; my $_layout = $_layout{$_action} ; $_action = $_layout) {
						msg "$accept $_layout $_action";
						my $arg = ($action = $_action{$_layout})? $action->(): {};
						@ret = $_action_htm{$_layout}->($arg, $_layout, @ret);
					}
				}
			}
			@ret = map { ref($_)? to_json($_): $_ } @ret;
		};
		if($error = $@ || $!) {
			$@ = $! = undef;
			$_STATUS = 500;
			@_HEAD = "Content-Type: text/plain; charset=utf-8";
			msg "action-error `$_action".(defined($_id)? ".$_id": "")."`: $error\n";
			@ret = to_json({error=> $_test ? $error: "Внутренняя ошибка"});
			dbh_connect() unless $dbh and $dbh->ping;
		}
		
		push @_HEAD, "Status: $_STATUS $_STATUS{$_STATUS}\r\n" if $_STATUS;
		print(), print "\r\n" for @_HEAD;
		print "\r\n";
		print for @ret;
		
		/: /, msg GREEN."$`".RESET.": ".YELLOW."$'".RESET for @_HEAD;
		$time = Time::HiRes::time() - $time;
		msg MAGENTA."sec".RESET." $time";
		
		our %_STASH = ();
		@ret = ();
	}
}