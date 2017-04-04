# Процессы

```perl

use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

$app->man->conf;

```

## Процесс

```perl

123 # 123

```

## Менеджер процессов


Породим пару процессов:

```perl

$app->processManager->birth("first", 'sleep 10', sub {
	my ($process) = @_;
	$process->name;				# first
});
$app->processManager->birth("second", 'sleep 10', sub {
	my ($process) = @_;
	$process->name;				# second
});

sleep 1;

my $kids = $app->processManager->{kid};

0+keys %$kids;		# 2

my @ps = keys %$kids;

```

Убъём их.

```perl

$app->processManager->stop;

0+keys %$kids;		# 0

kill 0, $ps[0];		## 0
kill 0, $ps[1];		## 0
