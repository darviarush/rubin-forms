# Шива

Шива является планировщиком заданий.

## Инициализация

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

$app->man->conf;


```

## Добавление задания

минуты часы дни месяцы

```perl

my $count = 0;
# якобы начат цикл
$app->shiva->init;
$app->shiva->on("first-task" => "* * * * *" => sub {
	$count++;
});

$app->shiva->step;
$app->shiva->{now} = sub {time+60};
$app->shiva->step;
$app->shiva->{now} = sub {time+60*2};
$app->shiva->step;

$count;			# 2



```

## Удаление задания

```perl

#$app->shiva->off("first-task");