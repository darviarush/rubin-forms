# Сессии

Сессии основаны на R::Cache::Ttl

## Инициализация

```perl



use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

# добавим логирование
$app->man->conf;



```

Создадим наше приложение c кэшем и очередями:

```perl

#$app->httpServerUnicorn->run;

0;		# 0

