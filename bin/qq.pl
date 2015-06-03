#== СЕРВЕР
#> сервер - http, fcgi или psgi

use strict;
use warnings;
our $app;

# грузим экшены
unless($app->ini->{restart}) {
	msg(":bold black", "load action...");
	$app->action->compile->write("watch/action.pl");
	$app->mail->action->compile->write("watch/action_mail.pl");
}

# запускаем главный процесс, за которым будет следить и перезапускать этот. Там так же идёт демонизация
$app->process->spy unless $app->ini->{restart};
# тут уже порождённый процесс

require "watch/action.pl";
require "watch/action_mail.pl";

# добавляем роутеры для kitty-cgi
$app->kitty->route($app->action->{act}) if $app->ini->{site}{kitty};

# не даёт некоторым ушлым процессам убивать главный процесс при разрыве соединения. Важно для $app->kitty
$SIG{PIPE} = sub { main::msg ":red", "SIGPIPE -> $$" };

# перечитывает main_do.ini по сигналу
# считывает права на таблицы и их столбцы
$SIG{USR1} = Utils::closure($app, sub {
	my ($app) = @_;
	#msg RED.'signal USR1 thr='.threads->tid().RESET;
	my $ini = Utils::parse_ini("main_do.ini");
	$app->ini->{do} = $ini;
	$app->auth->parse;
});
$SIG{USR1}->();

# Открываем сокет 
# наш скрипт будет слушать порт $ini->{site}{port} (9000)
# длина очереди соединений (backlog)- 5 штук
$app->server;
msg ":empty", ":red", $$, ":reset", " Слушаем ", ":green", $app->ini->{site}{port};

# Обработчик запросов
sub lord {
	my ($self) = @_;
	my $app = $self->{app};
	$app->server->loop;	# инициализируемся в новом треде
}

require POSIX;
my $ppid = POSIX::getppid();
sub graph {	# будет вызываться раз в секунду на главном процессе
	$app->process->close, exit unless kill 0, $ppid;
	#$app->model->session->delete if time % 3600 == 0;	# раз в час - не доделано
}

# порождаем потоки
$app->process->fork(*lord);

# бесконечный цикл с cron
$app->process->loop(*graph);
