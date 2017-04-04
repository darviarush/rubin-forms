# Коннект к базе

Объект коннект представляет собой низкий уровень доступа к базе. Он используется ORM.

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



```

## Информация о структуре базы




## SQL-запросы

* do(sql) - выполняет модифицирующий запрос

```perl

$app->connect->do("create table A(id int)");		# 0E0

```

## Транзакции

Транзакции могут быть вложенные.

```perl

$app->connect->begin;
eval {
	$app->connect->dbh->{AutoCommit};  # 
	die "error";
	$app->connect->commit;
};
$app->connect->rollback if $@;
$app->connect->pool->dbh->{AutoCommit};  # 1

```

Или проще:

```perl

$app->connect->transaction(1, sub {
	$app->connect->dbh->{AutoCommit};  # 
	die "error";
});
$@;		#~ error
$app->connect->pool->dbh->{AutoCommit}  # 1