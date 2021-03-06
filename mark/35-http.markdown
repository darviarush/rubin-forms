## Http-сервер

### Инициализируемся для тестов

```perl
use lib "lib";
use common::sense;
use R::App qw/$app app/;

$app->man->configure;

my $port = 9015;


```

### Типы серверов

Сервер может использовать tcp и unix-сокеты. Последние удобно использовать через каскадирование с nginx и при создании собственных серверов.

#### Tcp-сервер

```perl

# запускаем сервер в другом процессе
my $process = $app->process->new("tcp-server-example" => '
	$app->man->configure;
	$app->httpServer->new('.$port.')->on("/"=>sub { app->q->echo(261281) })->loop;
')->fg->start->done;

# ждём пока запустится
sleep 1;

$app->http->ua->get("http://localhost:$port")->content # 261281

$process->stop->exists;		## undef




```

### Таймаут

Если выполнение запроса затянулось, то он будет уничтожен.

Таймаут устанавливается в `$app->ini->{site}{alarm}`.

Не устанавливайте его с `$app->ini->{site}{guards}`.

```perl

# my $server = $app->httpServer->new($port)->alarm(1)->on("/"=>sub { sleep 10; app->q->echo("тест не прошёл") });
# my $tcp = $app->process->new("tcp-server-example" => sub { $server->loop })->fg->start->done;

# # ждём пока запустится
# sleep 1;

# $mech->get("http://127.0.0.1:$port")->content;	#~ 504 Gateway Timeout

# $tcp->stop;


```

### Регулярки для локэйшенов

```perl

my $server = $app->httpServer->new($port)->
	on(qr!/mine/! => sub { app->q->echo("mine") })->
	on(qr!^/echo/(?P<str>.*)/(?P<idx>\d+)$! => sub {
		app->q->echo($app->q->ids("str") . " " . $app->q->ids("idx"));
	})->
	on("/rose" => sub { app->q->echo("test") });


$server->GET("/echo/ps/bs-33/1as/10");		# ps/bs-33/1as 10
$server->GET("/x/mine/10");					# mine
$server->GET("/rose");						# test


```

### Группы в локэйшенах

Если в локейшинах есть группы "<...>", то они превращают локейшн в регулярку.

* `int` - целое число с минусом
* `uint` - положительное целое
* `nat` - натуральное
* `float` - плавающее с точкой
* `*` - любой набор символов
* `string` - любой набор символов кроме "/"
* `var` - буквы, цыфры и _
* `word` - буквы, цыфры, _ и -
* `abc` - только буквы

```perl

my $server = $app->httpServer->new($port)->
	on("/<int:a>/<int:b>" => sub { app->q->echo($app->q->ids("a") / $app->q->ids("b")) })
;

$server->GET("/18/3");						# 6

