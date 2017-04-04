# Метаинформация о структуре модели

## Инициализация

Подключаем наш фреймворк:

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

```

Зададим конфигурацию:

```perl

$app->man->configure;

