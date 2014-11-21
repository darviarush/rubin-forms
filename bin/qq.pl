#> сервер - http, fcgi или psgi


# при завершении сервера
$app->process->end_server(sub {
	my ($app) = @_;
	$app->process->close;
	$app->server->close;
});

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
$app->action->compile("action", "watch/action_c")->write("watch/action.pl");
require "watch/action.pl";


# Открываем сокет
# наш скрипт будет слушать порт $ini->{site}{port} (9000)
# длина очереди соединений (backlog)- 5 штук
$app->server;
msg ":empty", "Слушаем ", ":green", $app->ini->{site}{port};

# демонизируемся
$app->process->daemon if $app->ini->{site}{daemon};

# расщепляем процесс
$app->process->fork(*lord);

# перезагружать сервер, если изменился какой-то из модулей проекта
if($app->ini->{site}{watch}) {
	$app->action->watch;
	$app->test->watch;
}

# перекомпиливать сторонние файлы проекта
$app->hung if $app->ini->{site}{hung};

# бесконечный цикл с cron
$app->process->loop(sub {	# будет вызываться раз в секунду
	$app->session->delete() if time() % 3600 == 0;	# раз в час
	$app->process->watch, $app->watch->run() if $app->ini->{site}{watch};
});


# Обработчик запросов
sub lord {
	$app->connect(undef) # чтобы не закрылась через dbh_connect
	->connect;	# своё подключение к БД
	$app->server	# инициализируемся в новом треде
	->accept($app->ini->{site}{ext}? \&R::Server::tan: \&R::Server::ritter);
}