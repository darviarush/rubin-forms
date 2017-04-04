# ORM - объектно-реляционная модель

## Инициализация

Подключаем наш фреймворк:

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

```

Зададим конфигурацию:

```perl

#$app->coro;

$app->man->configure;


```

## Таблицы

Таблицы называются филдсетами (fieldset).

Создать их можно так:

```perl

ref $app->meta->fieldset("author");	# R::Model::Fieldset

```

Но только один раз:

```perl

my $author = $app->meta->fieldset("author");
$app->meta->fieldset("author");		## $author
# синхронизируем таблицу author с базой
$app->meta->sync;

```

Когда таблица создана, то становится доступен её манипулятор в `$app->model`:

```perl

ref $app->model->author(undef);		# R::Row::Author

ref $app->model->author;			# R::Rowset::Author

```

С undef запись не сохраняется: 

```perl

# посчитаем количество строк
$app->model->author->count;			# 0

```

А с {} - сохраняется.

```perl

$app->model->author({});
$app->model->author->count;			# 1

```

Удалим все записи в таблице:

```perl

$app->model->author->erase;
$app->model->author->count;			# 0

```

Добавим 3-х авторов c id = 1, 2 и 3:

```perl

$app->model->author->add(1,2,3);	#@ ~  Для добавления в таблицу используйте insert

$app->model->author->insert(1,2,3);

$app->model->author->count;			# 3

```

Найдём авторов с id больше 1:

```perl

$app->model->author->find(id__gt => 1)->rows;		## [bless({id=>2}, "R::Row::Author"), bless({id=>3}, "R::Row::Author")]


```

## Разновидности полей

### Столбцы

Обычные поля таблицы создаются `col(имя => тип)`


### Ссылки

Ссылки на другие таблицы создаются `ref(имя => таблица => обратное_поле => тип)`.

* `ref(имя)` - имя является одновременно именем таблицы, на которую указывает ссылка
* `ref(имя => таблица)` - тут всё ясно
* `ref(имя => таблица => обратное_поле)` - обратное_поле это имя обратной ссылки. См. Обратные ссылки
* `ref(имя => таблица => обратное_поле => тип)`



### Обратные ссылки

Когда создаётся ссылка `таблица1->ref("таблица2")`, то в таблице2 создаётся обратная ссылка на таблицу1, по которой доступны все записи таблицы1 ссылающиеся на таблицу2.

```perl

$app->meta->fieldset("author")->
	col(name => "varchar(255)")->remark("имя автора")->
	ref("oscar" => "oscar" => "oscarauthors")->remark("ссылка на премию Оскара")->
end;

$app->meta->sync;

my $author = $app->model->author(name => "Большак");
my $pisatel = $app->model->author(name => "Иваныч");

$author->oscar->saveAs(10)->oscarauthors->add($author, $pisatel);

$author->oscar->id;		# 10
$pisatel->oscar->id;	# 10

$author->oscar->oscarauthors->count;		# 2
$author->oscar->oscarauthors(1)->id;		## $author->id
$pisatel->oscar->oscarauthors(2)->id;		## $pisatel->id


```

### Вычислимые столбцы

Вычислимые столбцы реально не существуют. Они просто запускают функцию, которая что-то делает.

```perl

package R::Row::Uniq {
	
	use base "R::Model::Row";
	
	sub setup {
		shift->
			col(name => "varchar(255)")->remark("имя")->
			col(surname => "varchar(255)")->remark("фамилия")->
			compute(fullname => qw/name surname/)->remark("полное имя")->
		meta(
			remark => "уникальный пользователь",
			ordering => "id",
		);
	}
	
	# свойство для обработки вычислимого столбца
	sub fullname {
		if(@_ == 1) {
			my ($self) = @_;
			$self->name . " " . $self->surname
		} else {
			my ($self, $fullname) = @_;
			my ($name, $surname) = split /\s+/, $fullname;
			$self->name($name)->surname($surname);
		}
	}
}

$app->meta->fieldset("uniq")->setup->sync->autoinctrement_set(1);

$app->model->uniq(name => "Иван", surname => "Единорог")->save;
$app->model->uniq(name => "Антон", surname => "Городецкий")->save;
$app->model->uniq(fullname => "Лариса Лисята")->save;

#$app->model->uniq->find(fullname => "Иван Единорог")->count;		# 1

[ map {$_->{val}} $app->model->uniq->view("fullname") ];	## [{ id=>1, name=>"Иван", surname=>"Единорог" }, { id=>2, name=>"Антон", surname=>"Городецкий" }, { id=>3, name=>"Лариса", surname=>"Лисята" }]


join ", ", $app->model->uniq->fullname;			# Иван Единорог, Антон Городецкий, Лариса Лисята
#$app->model->uniq->find(name=>[qw/Иван Антон/])->update(fullname => "Элис Маск");
#join ", ", $app->model->uniq->fullname;			# Элис Маск, Элис Маск, Лариса Лисята


```

### Счётчики

Счётчики используются для подсчёта ссылок на эту запись из других таблиц.
Это удобно, т.к. не нужно каждый раз выполнять запрос на подсчёт ссылок.

`counter("имя поля" => "m2m поле или таблица.ссылка")`
`counter("имя поля" => "m2m поле или таблица.ссылка" => "тип")`
`counter("имя поля" => "m2m поле или таблица.ссылка" => filter)`
`counter("имя поля" => "m2m поле или таблица.ссылка" => "тип" => filter)`

Тип - тип поля счётчика. Необязателен. Если не указан, то берётся дефолтный тип для pk.

```perl

$app->meta->fieldset("author")->
	ref("soauthor" => "author" => "soauthors")->remark("ссылка на соавтора")->
	m2m("books")->remark("ссылка на книги (таблицу book)")->
	counter("count_soauthors" => "author.soauthor")->remark("счётчик соавторов, которые ссылаются на этого автора")->
	counter("count_books" => "books")->remark("счётчик книг")->
	counter("count_niks" => "nik.author")->remark("сколько у автора псевдонимов")->
	counter("count_niks_on_s" => "nik.author" => sub {
		my ($nik, $author) = @_;
		$nik->nik =~ /s/i
	})->remark("сколько у автора псевдонимов имеющих буву s")->
	
	# создадим ссылку многие-ко-многим
	m2m("readers" => "reader")->remark("читатели")->
	
	counter("count_readers_on_s" => "readers" => sub {
		my ($reader, $author, $op, $readerAuthor) = @_;
		$reader->name =~ /s/i
	})->remark("количество читателей автора с буквой s в имени")->
end;

# обратите внимание, что ссылка на ники автора объявлена после счётчика. На самом деле ссылки и счётчики могут быть расставлены в любом порядке
$app->meta->fieldset("nik")->
	col("nik" => "varchar(255)")->remark("ник автора")->
	ref("author")->remark("ссылка на автора, у которого есть псевдоним")->
end;

$app->meta->fieldset("reader")->
	col("name" => "varchar(255)")->remark("имя читателя")->
end;

# таблица book создалась автоматически
ref $app->meta->exists("book");	# R::Model::Fieldset

# синхронизируем структуру модели с базой
$app->meta->sync;

my $author1 = $app->model->author({});

$author1->count_soauthors;		# 0
$author1->count_books;			# 0
$author1->count_niks;			# 0
$author1->count_niks_on_s;		# 0
$author1->count_readers_on_s;	# 0

$author1->soauthors->add({}, {});
$author1->books->add({}, {});
$author1->niks->add({nik=>"Sisop"}, {nik=>"Avis"}, {nik=>"Bito"});
$author1->readers->add({name => "Soks"}, {name=>"Aio"});

# сбрасываем кэш
delete $author1->{val};

$author1->count_soauthors;		# 2
$author1->count_books;			# 2
$author1->count_niks;			# 3
$author1->count_niks_on_s;		# 2
$author1->count_readers_on_s; 	# 1


```

Типовая ситуация, когда нужно изменить счётчики на обоих объектах, учавствующих в связи.
Например, есть m2m-поле - подписчики пользователя, и если оба пользователя ссылаются друг на друга, то у обоих счётчик должен быть увеличен, а если один перестал ссылаться на другого - то уменьшен.

```perl

$app->meta->fieldset("user")->
	m2m("subscribers" => "user")->remark("связь сам-к-себе")->
	counter("friends_count" => "subscribers" => sub {
		my ($user, $subscriber, $op) = @_;
		# счётчик будет обновляться в $subscriber, поэтому нам надо обновить его в $user, если что
		$user->friends_count($op => 1)->save if $user->subscribers->exists($subscriber);
	})->remark("подписчик подписывается на пользователя")->
end;

```

Тут в `$op` передаётся "+" или "-". А вот такой `if` возвращает `undef`, если условие не выполняется и `$user`, если выполняется.

```perl

$app->meta->sync;

my $user1 = $app->model->user->new->saveAs(1);
my $user2 = $app->model->user->new->saveAs(2);

```

Обратите внимание, что параметры фильтра friends_count: ($user2, $user1, "+", $subscriberUser)

```perl

$user1->subscribers->add($user2);
$user1->friends_count;	# 0
$user2->friends_count;	# 0

$user2->subscribers->add($user1);

# сбрасываем кэш val (если он есть)
delete $user1->{val};
delete $user2->{val};

$user1->friends_count;	# 1
$user2->friends_count;	# 1

$user2->subscribers->del($user1);

# сбрасываем кэш val (если он есть)
delete $user1->{val};
delete $user2->{val};

$user1->friends_count;	# 0
$user2->friends_count;	# 0

```

## Чекеры

Для валидации при установке в поле или его модификации используют чекеры.

Создать новую очередь чекеров можно так:

```perl

my $check = $app->check->new;

ref $check;				# R::Check

$check->add("trim")->add("min_length", 1)->add("max_length", 10);

$check->test(my $x=" ");		# минимум 1 символ

```

Переменная `$x` будет модифицирована чекером `trim`, поэтому мы не можем оставить там константу.

Стандартное сообщение об ошибке можно поменять для конкретного чекера.

```perl

$check->error("максимум 10 символов");

```

Так - для последнего элемента в очереди.
А так - для конкретного:

```perl

$check->error("min_length" => "он же пустой!");

```

Конечно если есть чекеры с одинаковым именем, то установится для последнего

```perl

$check->test(my $x=" ");				# он же пустой!
$check->test(my $x="1234567890-");		# максимум 10 символов

```

Если значение правильное:

```perl

$check->test(my $x="я!");					## undef

```

В чекеры часто надо передать дополнительные параметры - общие для всех чекеров очереди. Для поля модели на котром стоит чекер это поле и модель, для инпутов форм это форма и инпут. Установить их можно через `stash`:

```perl

#$check->stash(model => );


```

## Запросы

Рассмотрим работу с запросами на примере режиссёров и сериалов.

```perl

$app->meta->fieldset("filmmaker")->
	col(name => "varchar(255)")->
	m2m("serial")->
end;

$app->meta->fieldset("serial")->
	col(name => "varchar(255)")->
end;


$app->meta->sync;


```

### save

Сохраняет запись. Если нечего сохранять - то ничего не делает.
Если указан `id`, то обновляет запись, иначе - создаёт новую.

```perl

my $id = $app->model->serial({name=>'unionic'})->save->id;
my $x = $app->model->serial($id);
$x->exists;			## $x

```

`save` так же запускается при разрушении объекта ORM:

```perl

$app->model->serial($id)->name("union");
$app->model->serial($id)->name;				# union

```

Ну а если изменений в записи нет, то - ничего не делает.

### store

Проверяет, что такая запись существует, и либо обновляет, либо создаёт её.

```perl

my $x = $app->model->serial(undef)->name("uix")->store;
$x->name("aix")->store;

```

### insert

Вставляет в таблицу несколько записей.

* `insert(зап1, зап2...)`
* `insert([зап1, зап2...])`

где записями могут быть хэши или массивы с набором полей и объекты записей.

```perl

$app->model->filmmaker(9)->exists;		## undef

my $filmmaker1 = $app->model->filmmaker(9)->name("Баньши Ка");
$app->model->filmmaker->insert({name => "Бим-Бим Ка", id => 10}, $filmmaker1);

$app->model->filmmaker->count;		# 2

```

### into

into вставляет выборку в таблицу.

* `into(fieldset, [ст1, ст2...])`
* `into(rowset, [ст1, ст2...])`
* `into("имя филдсета", [ст1, ст2...])`

Если имена не указаны, то для вставки беруться имена.

```perl

$app->model->filmmaker->find(name__startswith => "Б")->view("name", "id")->into("serial");

join ", ", $app->model->serial->name;		# union, aix, Бим-Бим Ка, Баньши Ка

```

### update

* `update(поле1 => знач1, ...)`

```perl

$app->model->serial->find(id=>[1, 10])->update(name => "это точно Книга!");

$app->model->serial->find(name => "это точно Книга!")->count;		# 2


```

### erase

Запрос на удаление записей.

```perl

$app->model->serial->find(name__startswith => "Баньши")->erase;

$app->model->serial->count;		# 3


```

## Страницы

Для постраничной навигации используются функции `page` и `qpage`.
Данные методы используются в классе `RubinPages`.

* `page([id элемента в начале страницы], [кол. элементов на странице])` - создаёт запрос на выборку страницы
* `is_prev_page` - возвращает id предыдущей страницы или `undef`
* `is_next_page` - возвращает id следующей страницы или `undef`

Под `id` понимается массив значений для полей в `order`.

Страницы строятся в соответствии с запросом.
Если в `order` запроса не одно поле, то в `page` должен передаваться массив со значениями параметров.

Тем не менее нужно учитывать, что поле `id` всегда присутствует в запросе страницы. Если оно не указано последним в `order`.

Если парамтр "количество элементов на странице" не задан, то используется параметр таблицы `paging` чтобы узнать количество элементов на странице, если она не указана. Если `paging` в таблице нет, то используется `paging` меты. Мета получает `paging` из `app->ini->{model}{paging}`

Пример:

```perl


$app->meta->fieldset("place")->
	col("name"=>"varchar(255)")->remark("имя места")->
	col("number"=>"int")->remark("номер места")->
	col("gender"=>"char(1)")->remark("пол места")->
	meta(
		paging => 3,
	)->
end;

$app->meta->sync;

```

Создаём 20 записей в таблице `place`.

```perl

$app->model->place->insert( map {{ name => "Музей №$_", number => int((10-$_)/2) }} 1..20);

my $page = $app->model->place->order("id")->page(undef, 3);

```

Мы жёстко задали 3 записи на страницу. Если параметр не указывать, то метод `page` воспользуется параметром филдсета `paging`.

```perl

$page->is_prev_page;		## undef
$page->is_next_page;		## [4]
join ", ", $page->name;		# Музей №1, Музей №2, Музей №3

```

А тут используется параметр филдсета `paging`.

```perl

$page = $page->page([4]);

```

`is_prev_page` возвращает или `undef` или массив [val1...] - id страницы.
Обратите внимание, что выдан пустой массив. Это значит, что предыдущая страница есть, и она - первая.

```perl

$page->is_prev_page;		## []
$page->is_next_page;		## [7]
join ", ", $page->name;		# Музей №4, Музей №5, Музей №6

```

Что будет, если мы передадим идентификатор страницы не выравненный по её началу? В таком случае он будет считаться за начало страницы.

```perl

$page = $page->page([5]);

# 2,3,4
$page->is_prev_page;		## [2]
$page->is_next_page;		## [8]
join ", ", $page->name;		# Музей №5, Музей №6, Музей №7

```

Ну и конец страницы:

```perl

$page = $page->page([20]);

$page->is_prev_page;		## [17]
$page->is_next_page;		## undef
join ", ", $page->name;		# Музей №20

```

И то же для иной сортировки:

```perl

my $page = $app->model->place->order("number")->page;

#msg1 scalar $app->model->place->order("number", "-id")->annotates("number", "id");

$page->is_prev_page;		## undef
$page->is_next_page;		## [-3,17]
join " ", map {join ",", @$_} $page->annotates("number", "id");		# -5,20 -4,19 -4,18

```

Для следующей страницы:

```perl

$page = $page->page([-3, 17]);
$page->is_prev_page;		## []
$page->is_next_page;		## [-2,14]
join " ", map {join ",", @$_} $page->annotates("number", "id");		# -3,17 -3,16 -2,15

```

Для 3-й страницы:

```perl

$page = $page->page([-2, 14]);

#$app->connect->{log} = 1;

$page->is_prev_page;		## [-3,17]

#$app->connect->{log} = 0;

$page->is_next_page;		## [0,11]
join " ", map {join ",", @$_} $page->annotates("number", "id");		# -2,14 -1,13 -1,12


```

Проведём тестирование по данным.

```perl

# $app->meta->fieldset("testpage")->
	# col("a"=>"int")->remark("первое число")->
	# col("b"=>"int")->remark("второе число")->
	# meta(
		# paging => 3,
	# )->
# sync;

# $app->model->testpage->view("id", "a", "b")->insert([
	# [6,1,1],
	# [2,1,2],
	# [1,1,3],
	# [10,2,1],
	# [3,2,2],
	# [5,3,1],
	# [16,3,2],
	# [11,3,3],
	# [8,3,4],
	# [4,3,5],
	# [7,3,6],
# ]);


```

#### Страницы в запросе

* `qpage([параметр], [кол. элементов на странице])` - берёт из параметра `app->q->param("page")`. Параметр по умолчанию называется `page`
* `url_prev_page` - url предыдущей страницы
* `url_next_page` - url следующей страницы

```perl

$app->q( $app->httpRequest->new );
$app->q->uri("/new/");

my $page = $app->model->place->order("number", "id")->qpage("page");

$page->url_prev_page;		# /new/
$page->url_next_page;		# /new/?page=-3%2C16