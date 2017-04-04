# Сервера

## Инициализируемся для тестов

```perl
use lib "lib";
use common::sense;
use R::App qw/$app app msg1/;

$app->man->conf;

my $port = 9013;



```

## Сервер в отдельном процессе

### tcp-сервер

```perl

my $process = $app->process->new("test-perl-server", '
	$app->processServer->new(port=>'.$port.', test=>1)->on(
		plus => sub { my ($a, $b) = @_; $a+$b },
		minus => sub { my ($a, $b) = @_; $a-$b },
	)->loop;
')->fg->start->done;

```

Пусть запуститься:

```perl

sleep 1;

$process->exists;	# 1

```

Теперь опробуем его.

```perl

my $q1 = $app->processClient->new("localhost", $port);

$q1->put("plus", 7, 6)->res;		# 13
$q1->put("minus", 1, 3)->res;		# -2

$q1->close;

$process->stop->exists;				## undef


```

### HTTP-сервер

```perl

my $process = $app->process->new("test-http-server", '
	# требуется для файла конфигурации
	$app->man->conf;
	$app->httpServer->new(port=>'.$port.', test=>0)->on(
		"/plus" => sub { my $q = $app->q; $q->echo($q->id + $q->id2) },
		"/minus" => sub { my $q = $app->q; $q->echo($q->id - $q->id2) },
	)->loop;
')->fg->start->done;

sleep 1;

$process->exists;	# 1

my $ua = $app->http->ua;
$ua->get("http://127.0.0.1:$port/plus7_6")->content;	# 13
$ua->get("http://127.0.0.1:$port/minus1_3")->content;	# -2

$process->stop->exists;				## undef

```

## Сервер на волокнах

### Волоконный tcp-сервер

Параметр `guards` указывает количество обработчиков на волокнах (fibers) реализованные на `Coro`.

```perl

my $server = $app->processServer->new(port => $port, guards => 3)->on(
	plus => sub { my ($a, $b) = @_; $a+$b },
	sleep => sub { Coro::Timer::sleep(0.1); 123 },
);

$app->coro->async(sub {
	$app->processClient->new("localhost", $port)->put("sleep")->res;	# 123
	
	$server->stop;
});

$app->coro->async(sub {

	my $q1 = $app->processClient->new("localhost", $port)->put("plus", 7, 6);
	my $q2 = $app->processClient->new("localhost", $port)->put("plus", 1, 3);

	$q1->res;		# 13
	$q2->res;		# 4
	
	$q1->put("plus", 8, 6)->res;		# 14
	
});
	
$server->loop;


```

### Волоконный HTTP-сервер

```perl

my $server = $app->httpServer->new(port=>$port, guards=>4, test=>0)->on(
	"/plus" => sub { my $q = $app->q; $q->echo($q->id + $q->id2) },
	"/sleep" => sub { Coro::Timer::sleep(0.25); $app->q->echo(123); },
);

use LWP::UserAgent;
use LWP::ConnCache;
use Coro::LWP;

$app->coro->async(sub {

	my $ua = $app->http->ua;
	$ua->get("http://127.0.0.1:$port/sleep")->content;	# 123
	
	$server->stop;
});

$app->coro->async(sub {

	my $ua = $app->http->ua;
	$ua->get("http://127.0.0.1:$port/plus7_6")->content;	# 13
	$ua->get("http://127.0.0.1:$port/plus1_4")->content;	# 5
	
});
	
$server->loop;


```

### WebSockets

Http-сервера поддерживают так же и веб-сокеты.
Обработчики событий на веб-сокетах являются идентификатором, например, как `minus` в следующем примере.

```perl

$app->coro;

my $server = $app->httpServer->new(port=>$port, guards=>4, test=>0)->on(
	"/plus" => sub { my $q = $app->q; $q->echo($q->id + $q->id2) },
	"/sleep" => sub { Coro::Timer::sleep(1); $app->q->echo(123); },
)->message(
	"minus" => sub { my ($a, $b, $to) = @_; $app->contact->message($to => $a-$b) },
);

my $cv = AE::cv();
my $counter = 0;

my $ws = $app->httpWs->new("ws://127.0.0.1:$port/_ws_")->on(
	"equal1" => sub {
		shift;			# -1
		$cv->send if ++$counter == 2;
	},
	"equal2" => sub {
		shift;			# 4
		$cv->send if ++$counter == 2;
	},
);

$app->coro->async(sub {

	my $ua = $app->http->ua;
	$ua->get("http://127.0.0.1:$port/sleep")->content;	# 123
	
	$server->stop;
});

$app->coro->async(sub {
	$ws->message("minus" => 3, 4 => "equal1");
	$ws->message("minus" => 5, 1 => "equal2");
});

$app->coro->async(sub {

	my $ua = $app->http->ua;
	$ua->get("http://127.0.0.1:$port/plus7_6")->content;	# 13
	$ua->get("http://127.0.0.1:$port/plus1_4")->content;	# 5
	
});

$server->loop;

$cv->recv;

$ws->close;