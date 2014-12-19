#> сервер - http, fcgi или psgi

# грузим экшены
msg(":bold black", "load action..."), $app->action->compile->write("watch/action.pl") unless $app->ini->{restart};

# запускаем главный процесс, за которым будет следить и перезапускать этот. Там так же идёт демонизация
$app->process->spy unless $app->ini->{restart};
# тут уже порождённый процесс

require "watch/action.pl";

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

# чтобы создать метод stash
$app->stash({});

# Открываем сокет 
# наш скрипт будет слушать порт $ini->{site}{port} (9000)
# длина очереди соединений (backlog)- 5 штук
$app->server;
msg ":empty", ":red", $$, ":reset", " Слушаем ", ":green", $app->ini->{site}{port};

# порождаем потоки
$app->process->fork(*lord);

# бесконечный цикл с cron
require POSIX;
my $ppid = POSIX::getppid();
$app->process->loop(sub {	# будет вызываться раз в секунду
	$app->process->close, exit unless kill 0, $ppid;
	$app->session->delete if time % 3600 == 0;	# раз в час
});

# Обработчик запросов
sub lord {
	my ($self) = @_;
	my $app = $self->{app};
	$app->server->loop;	# инициализируемся в новом треде
}