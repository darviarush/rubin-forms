# Кэши

## Инициализация

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

$app->man->conf;

# отключим логирование
$app->ini->{log}{cache} = "no";


```

## Кэш

Кэш имеет максимальный размер.

```perl

my $cache = $app->cacheBagatur->new->maxsize(12)->maxkeysize(6);

```

Если размер ключа и значения привысит maxkeysize, то такой ключ добавляться не будет:

```perl

$cache->set("12"=>"34567");	# 34567
$cache->size;				# 0
$cache->exists("12");		# 

$cache->set("12"=>"34");	# 34
$cache->size;				# 4
$cache->exists("12");		# 1


$cache->set("11"=>"xx");
$cache->set("2"=>"yyy");

$cache->size;				# 12

```

Следующий ключ переполнит кэш и будет удалён ключ (ключи) к которому доступ осуществлялся позже всех.

```perl

$cache->set("444"=>"myz");
$cache->size;				# 10

$cache->exists("12");		# 
$cache->exists("11");		# 
$cache->exists("2");		# 1
$cache->exists("444");		# 1

```

Теперь удалиться 444, так как 2 будет позже считано.

```perl

$cache->get("2");			# yyy

$cache->set("666"=>"1");
$cache->size;				# 8
$cache->exists("444");		# 
$cache->get("666");			# 1

```

Остались ключи 666 и 2. Удалим 2:

```perl

$cache->del(2);				# yyy
$cache->size;				# 4


```

### Дестроер

Можно установить обработчик удаления ключа.

Это нужно, например, когда в кэше содержится счётчик посещений страниц и его нужно сохранить в базу. Или сессия - и в случае её завершения должно записываться время последнего посещения пользователя.

Дестроер нужно устанавливать до расщепления процессов.

```perl


my $counter = 0;
my $type = 10;
my $value = undef;
my $cache = $app->cacheBagatur->new->maxsize(12)->maxkeysize(6)->destroyer(sub {
	my ($self, $key, $val, $typ, $v) = @_;
	$counter++;
	$type = $typ;
	$value = $v;
});


```

Дестроер сработает, если ключ не будет помещён в кэш (ключ-значение больше maxkeysize). Тип - 1.

```perl

$counter;				# 0

$cache->set("123" => "4567");

$counter;				# 1
$type;					# 1
$value;					## undef
$cache->size;			# 0

```

При переполнении тип - 2.

```perl

$cache->set("111" => "111");
$cache->set("222" => "222");
$cache->set("333" => "333");

$counter;				# 2
$type;					# 2
$value;					## undef
$cache->size;			# 12

```

При удалении тип - 0.

```perl

$cache->del(222);

$counter;				# 3
$type;					# 0
$value;					## undef
$cache->size;			# 6
$cache->exists(333);	# 1

```

При замене ключа - тип 3 и передаётся новое значение.

```perl

$cache->set(333 => 44);

$counter;				# 4
$type;					# 3
$value;					# 44
$cache->size;			# 5
$cache->exists(333);	# 1

```

###  Время жизни ключа

Время жизни ключа можно установить методом `ttl(ключ, время_жизни)`. Время указывается в секундах.
Установим 0 секунд: ключ должен будет удалиться как только вызовется уборщик.

```perl

$cache->ttl(333, 0);

```

Теперь вызовем уборщик - он должен в проектах запускаться будет по крону.	

```perl

$cache->clean;			# 1

```

При удалении в дестроер передаётся тип 4.

```perl

$counter;				# 5
$type;					# 4
$cache->size;			# 0

$cache->set("12" => "34");
$cache->set("56" => "78");
$cache->set("90" => "00");

$cache->ttl(12, 0);
$cache->ttl(90, 0);

$cache->clean;			# 2

$counter;				# 7
$type;					# 4
$cache->size;			# 4
$cache->exists(56);		# 1

```

А теперь изменим ttl.

```perl

$cache->ttl(56, 0)->ttl(56);		## time
$cache->ttl(56, 1)->ttl(56);		## time + 1

$cache->clean;			# 0

$cache->exists(56);		# 1


```

### Несколько дестроеров

Можно определить какой дестройер будет срабатывать при удалении конкретного ключа.

```perl

$counter = 0;
my $minus = 0;

$cache->destroyer("minus" => sub {
	$minus--;
});

$cache->set("12" => "34", "minus");
$cache->set("13" => "67");
$cache->set("14" => "67");
$cache->set("15" => "68");

$minus					# -1

```

### utf8

Даже, если значениями или ключём будет utf8, то вычисления размера всё равно будут производиться в байтах.

```perl

$counter = 0;

$cache->set("ЯЯ"=>"Ю");

```

Было вытолкнуто 2 ключа, т.к. в utf8 русские буквы по 2 байта.

```perl

$counter;				# 2
$cache->size;			# 10

```

## Сервер кэша

Создадим сервер кэша, предварительно добавив ему дестройер, так как после запуска сервера это сделать будет нельзя - он в другом процессе.

```perl

my $process = $app->process->new("test-cache", '
	$app->man->conf;
	$app->cacheServer->loop;
')->fg->start->done;

```

Пусть запуститься:

```perl

sleep 1;

$process->exists;	# 1

```

Теперь опробуем кэш.

```perl

$app->cache->set(12 => {a=>3});

$app->cache->get(12);	## {a=>3}

$app->cache->close;


```

### Локи в межпроцессорном кэше

```perl

# use forks;
# use forks::shared deadlock => {detect=> 1, resolve => 1};

# if(!fork) {
	# $cache->set("90", "11");
	# exit;
# }

# sleep 1;
# $cache->exists(90);		# 1

