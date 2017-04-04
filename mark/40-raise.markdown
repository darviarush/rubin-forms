# Трейсбэк

```perl



use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

# добавим логирование
$app->man->conf;


```

## Приёмы отладки

```perl

ref $app->raise->trace;			# R::Raise

$app->raise->tracex;			#~ app.raise.trace