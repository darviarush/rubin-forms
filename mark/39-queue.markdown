# Очереди заданий

## Инициализация

Подключаем наш фреймворк:

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

```

Зададим конфигурацию:

```perl

$app->man->configure(logsql=>"no");



```

## app->queue

`app->queue` служит интерфейсом к модели `Queue`.

```perl

require "model/Queue.pm";

$app->meta->fieldset("queue")->setup;
$app->meta->sync;

```

Создаём пару каналов.

```perl

$app->queue->channel("mail-agent");
$app->queue->channel("icq-agent");

```

И поставим в очереди несколько заданий:

```perl

$app->queue->push("mail-agent", "mail1");
$app->queue->push("icq-agent", "icq1");
$app->queue->push("mail-agent", "mail2");

```

Возьмём задание из очереди:

```perl

my $task = $app->queue->pull("mail-agent", 1);

$task->id;			#> 0
$task->args;		# mail2

```

Укажем, что выполнили его:

```perl

$task->pop;

$app->queue->pull("icq-agent", 1)->pop->args;		# icq1

$app->queue->pull("mail-agent", 1)->pop->args;		# mail1


```

Больше заданий нет:

```perl

$app->queue->pull("mail-agent", 1);					## undef

$app->queue->pull("icq-agent", 1);					## undef


