# Coro

```perl

use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

# добавим логирование
$app->man->conf;




```

## Переключение данных

```perl

use Coro;

```

Можем ли мы при переключении на иное волокно менять какие-то данные?

```perl

# use Coro::LocalScalar;

# my $appval;

# Coro::LocalScalar->new->localize($appval);

# $appval = 10;
# $appval # 10

# my @ps;
# push @ps, async {
	# 0+$appval # 0
	# $appval = 20;
	# cede;
	# $appval # 20
# };

# push @ps, async {
	# 0+0+$appval # 0
	# $appval = 30;
	# cede;
	# $appval # 30
# };

# 0+0+0+$appval # 10

# $_->join for @ps;

# 0+0+0+0+$appval # 10

```

Переменная в новом волокне будет undef.

```perl

# use Coro::Localize;	
# our $alias;

# $alias = 10;
# $alias # 10

# my @ps = ();
# push @ps, async {
	# corolocal $alias;
	# 0+$alias # 0
	# $alias = 20;
	# cede;
	# $alias # 20
# };

# push @ps, async {
	# corolocal $alias;
	# 0+0+$alias # 0
	# $alias = 30;
	# cede;
	# $alias # 30
# };

# 0+0+0+$alias # 10

# $_->join for @ps;

# 0+0+0+0+$alias # 10


```

Ну и просто:

```perl

my $appval = my $zval = 10;
$appval # 10
Coro::on_enter { $appval = $zval };

my @ps;
push @ps, async {
	my $xval = 55;
	Coro::on_enter { $appval = $xval };

	0+$appval # 55

	cede;
	0-$appval # -55
};

push @ps, async {
	my $yval = 66;
	Coro::on_enter { $appval = $yval };
	
	0+0+$appval # 66

	cede;
	0-0-$appval # -66
};

0+0+0+$appval # 10

$_->join for @ps;

0+0+0+0+$appval # 10



```

Ещё одна реализация.
Однако нам надо реализовать что-то вроде `$app->connect`.


## Переключения

```perl

my $x = 10;

$app->coro->async(sub {
	$x = 6;
	#Coro::AnyEvent::sleep( 1 );
	cede;
	$x;			# 11
	$x = 5;
});

$app->coro->async(sub {
	$x;			# 6
	$x = 11;
});

$x;			# 10

$app->coro->run;

$x;			# 5


```

## Исключения


`Coro` перекрывает в каждом порождённом волокне стандартные __DIE__ и __WARN__. `$app->coro->async` заменяет их на `$app->raise`.

```perl

my $x = 10;

$app->coro->async(sub {
	die "123";			#@ ~ : eval {...}
});

$app->coro->async(sub {
	$x = 11;
	die "456";
})->
atdie(sub {
	my ($error) = @_;
	$error;		#~ 456
	undef
})->
desc("mission")->
destroyer(sub {
	"destroy" # destroy
})->
async(sub {
	$x;		# 11
});


$app->coro->run;


```

## AnyEvent

```perl

$app->coro;

Coro::AnyEvent::sleep(1);

$app->coro->async(sub {
	Coro::AnyEvent::sleep(1);
});
$app->coro->async(sub {
	"test" # test
});
$app->coro->run;

0+%{ $app->coro->{async} };		# 0

```

## Межпроцессорные сигналы

Проверяем, что сигналы прерывают `$app->coro->run`.

```perl

$app->coro;

Coro::AnyEvent::sleep(1);

my $process = $app->process->new("test-signal-with-coro", '

	$app->ini( $app->ini->parse("etc/unicorn.ini") );
	$app->coro;
	Coro::AnyEvent::sleep(1);

	$app->coro->async(sub {
		Coro::AnyEvent::sleep(3);
	})->desc("sleeepper");
	$app->coro->run;
	
')->fg->start->done;

sleep 1;

$process->exists;			# 1

$process->stop->exists;		## undef


```

## condvar и signal

```perl

$app->coro;

use AnyEvent;
my $cv = AnyEvent->condvar;
$cv->send(1);

$cv->recv;		# 1
$cv->recv;		# 1

my $signal = Coro::Signal->new;

$signal->send;
$signal->wait;	## undef

my $signal = Coro::Signal->new;

$app->coro->async(sub {
	1 # 1
	$signal->wait;
	2 # 2
});

$app->coro->async(sub {
	3 # 3
	$signal->wait;
	4 # 4
});

$app->coro->async(sub {
	Coro::Timer::sleep(0.1);
	$signal->send;
	$signal->send;
});

$app->coro->run;

```

## AnyEvent server

```perl

my $server = $app->processServer->new()->make;
my $sd = $server->{sd};

$sd = $sh->fh if Isa $sd, "Coro::Handle";

AE::io();
