#> сервер - http, fcgi или psgi


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


# грузим экшены
msg ":bold black", "load action...";
$app->action->compile->write("watch/action.pl") unless $app->ini->{restart};
$app->stash({});
require "watch/action.pl";

# Открываем сокет
# наш скрипт будет слушать порт $ini->{site}{port} (9000)
# длина очереди соединений (backlog)- 5 штук
$app->server;
msg ":empty", ":red", $$, ":reset", " Слушаем ", ":green", $app->ini->{site}{port};

# демонизируемся
$app->process->daemon if $app->ini->{site}{daemon};

# порождаем потоки
$app->process->fork(*lord);

# перекомпиливать сторонние файлы проекта
$app->hung if $app->ini->{site}{hung};

# перезагружать сервер, если изменился какой-то из модулей проекта
if($app->ini->{site}{watch}) {
	$app->action->watch;
	$app->test->watch;
}

# бесконечный цикл с cron
$app->process->loop(sub {	# будет вызываться раз в секунду
	$app->session->delete if time % 3600 == 0;	# раз в час
	$app->process->watch, $app->watch->run if $app->ini->{site}{watch};
});


# Обработчик запросов
sub lord {
	$app->connect(undef) # чтобы не закрылась через dbh_connect
	->connect;	# своё подключение к БД
	$app->server	# инициализируемся в новом треде
	->accept($app->ini->{site}{ext}? \&R::Server::tan: \&R::Server::ritter);
}