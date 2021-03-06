# Миграции

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

Файлы с миграциями располагаются в подпапке проекта migrate.

Новая миграция создаётся командой `myapp migrate`.

Создаётся файл миграции, куда записываются команды, которые приведут структуру базы в соответствие с моделью.
Разработчик, затем, вписывает код между ними для изменения данных.

Создаём модель:

```perl

my $mig = $app->meta->new("Testbase");

$mig->fieldset("kipsta")->
    col("a" => "int")->
    col("b" => "int")->
end;

```

Создаём новую миграцию:

```perl

my $migration_dir = "var/test/migration";

$mig->create_migration($migration_dir);

my $migration_file = $app->file()->read;

$mig->fieldset("kipsta")->sync;

$mig->existsTab("kipsta");		# 1

```

## Операции для редактирования структуры БД

* `fieldset.create` - создаёт таблицу со всеми её полями
* `fieldset.sync` - создаёт таблицу если её нет и редактирует её, если есть
* `fieldset.change` - модифицирует или создаёт последний столбец
