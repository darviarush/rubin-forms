# Файлы

Для работы с файлами используется `$app->file("имя файла1", "имя файла2"...)`.

```perl


use lib "lib";
use common::sense;
use R::App qw/$app msg msg1/;

$app->man->conf;


```

## Пути

```perl

my $file = $app->file("root/mmd/dir1/dir2/name.ext1.ext2.ext3");

$file->ext;					# ext3
$file->exts;				# ext1.ext2.ext3
$file->name;				# name.ext1.ext2
$file->nik;					# name
$file->file;				# name.ext1.ext2.ext3
$file->dir;					# root/mmd/dir1/dir2
$file->subdir("root/mmd")->path;				# dir1/dir2/name.ext1.ext2.ext3
$file->subdir("root/mmd" => "rss/mmx")->path;	# rss/mmx/dir1/dir2/name.ext1.ext2.ext3

$file->ext("ee")->path;					# root/mmd/dir1/dir2/name.ext1.ext2.ee
$file->exts("ee")->path;				# root/mmd/dir1/dir2/name.ee
$file->name("nn")->path;				# root/mmd/dir1/dir2/nn.ext3
$file->nik("nik")->path;				# root/mmd/dir1/dir2/nik.ext1.ext2.ext3
$file->dir("dir")->path;				# dir/name.ext1.ext2.ext3

```

Проверим как он работает с файлом без расширения.

```perl

my $file2 = $app->file("xxx/mmd");
$file2->nik;					# mmd
$file2->name;					# mmd
$file2->file;					# mmd
$file2->dir;					# xxx
$file2->ext;					# 
$file2->exts;					# 

$file2->file("mmx")->path;		# xxx/mmx
$file2->nik("mmx")->path;		# xxx/mmx
$file2->name("mmx")->path;		# xxx/mmx
$file2->ext("wxt")->path;		# xxx/mmd.wxt
$file2->exts("wxt")->path;		# xxx/mmd.wxt

```

Ну и с файлом без директории и без расширения.

```perl

my $file3 = $app->file("mmd");
$file3->nik;					# mmd
$file3->name;					# mmd
$file3->file;					# mmd
$file3->dir;					# 
$file3->ext;					# 
$file3->exts;					# 

$file3->dir("dir")->path;		# dir/mmd
$file3->file("mmx")->path;		# mmx
$file3->nik("mmx")->path;		# mmx
$file3->name("mmx")->path;		# mmx
$file3->ext("wxt")->path;		# mmd.wxt
$file3->exts("wxt")->path;		# mmd.wxt

```

### sub

Добавляет к пути файла поддиректорию или файл.

```perl

my $file1 = $app->file("mm1", "mm2/");
my $file2 = $file1->sub("uni.ext");

$file2->path(0);		# mm1/uni.ext
$file2->path(1);		# mm2/uni.ext

```

Старый файл не поменялся.

```perl

$file1->path(0);		# mm1

```

### pwd и cwd

Возвращают текущий каталог.

```perl

$app->file->pwd;		#~ rubin-forms

```

### abs

Превращает все пути в коллекции в абсолютные.

```perl

$app->file("/./abc/./x")->abs->path;			# /abc/x
$app->file("/./abc/../x")->abs->path;			# /x
$app->file("/abc/y/../../x/..")->abs->path;		# /
$app->file(".")->abs->path;							## $app->file->pwd
$app->file("x/y")->abs->path;							## $app->file->pwd . "/x/y"

```

## Изменения

### watch

Запоминает время файлов при первом вызове и сравнивает - не изменились ли при втором.
Возвращает пусто или 3 файловых объекта: изменившиеся, появившиеся и исчезнувшие файлы.

```perl

my $file = $app->file("var/man-file")->rm->mkdir;

$file->sub("1")->write("1");
$file->sub("2")->write("2");

my ($changed, $new, $deleted) = $file->watch;

$changed->length;		# 0
$new->length;			# 3
$deleted->length;		# 0

my ($changed, $new, $deleted) = $file->watch;

$changed->length;		# 0
$new->length;			# 0
$deleted->length;		# 0

$file->sub("3")->write("3");

my ($changed, $new, $deleted) = $file->watch;

$changed->length;		# 0
$new->join;				# var/man-file/3
$deleted->length;		# 0

$file->length;			# 1

sleep 1;

$file->sub("1")->write("1");
$file->sub("3")->write("3");
$file->sub("2")->rm;

my ($changed, $new, $deleted) = $file->watch;

$changed->join;			#~ 1
$changed->join;			#~ 3
$changed->length;		# 3

```

Изменено 3 файла, так как изменился и каталог.

```perl

$new->length;			# 0
$deleted->join;			# var/man-file/2

```

В скалярном контексте возвращается объект:

```perl

my $watch = $file->watch;

$watch->{changed}->length;		# 0
$watch->{new}->length;			# 0
$watch->{deleted}->length;		# 0

$file->rm;

```

### cmpmtime

Подобно `watch`, но сравнивает два файловых массива. Файлы сравниваются "от рута", которые и являются элементами файловых коллекций.

Для примера создадим в каталоге "var/man-file1" 3 файла.

```perl

my $file1 = $app->file("var/man-file1")->rm->mkdir;
my $file2 = $app->file("var/man-file2")->rm->mkdir;

$file1->sub("1")->write("123");
$file1->sub("2")->write("123");
$file1->sub("3")->write("123");

$file2->sub("1")->write("123");
$file2->sub("2")->write("123");
$file2->sub("4")->write("123");

my ($changed, $new, $deleted) = $file1->cmpmtime( $file2 );

```

По нулям `changed` - так как файлы появились одновременно и время модификации у них - одно и то же. Но удален файл 3, т.к. его нет в каталоге `$file2`. Новых файлов 1, это файл - 4, так как он присудствует в массиве `$file2`, но нет аналогичного ему в `$file1`.

```perl

$changed->join;			# 
$new->join;				# var/man-file2/4
$deleted->join;			# var/man-file2/3

```

Подождём и изменим `$file2/1` и `$file1/2`. В `$changed` отобразится только файл `$file2/1`, т.к. файлы справа должны быть младше файлов слева, но не наоборот.

```perl

sleep 1;

$file2->sub("1")->write("abc");
$file1->sub("2")->write("abc");

my ($changed, $new, $deleted) = $file1->cmpmtime( $file2 );

$changed->join;			# var/man-file2/1
$new->join;				# var/man-file2/4
$deleted->join;			# var/man-file2/3

$file1->rm;
$file2->rm;


```

## Поиск	

### glob

Считает имя файла маской и разыменовывает её, как это делает `glob`.

```perl

my $file1 = $app->file("*process*", "*form-*")->dir("man");
my $file2 = $file1->glob;

$file1->length;			# 2
$file2->length;			#> 2
$file2->join(", ");		#~ 33-process.man

```

`glob` может принимать параметры в виде фильров, как сокращение для `grep`.

```perl

$file1->glob("*.man")->length;				# 1
$file1->glob(qr/\.man$/)->length;			# 1
$file1->glob("-s")->length;					#> 2
$file1->glob(sub {-f $_})->length;			#> 2


```

### find

Поиск файлов в поддиректориях.

```perl

my $glob = $app->file("man")->find("*.{human,man}")->length;
my $regexp = $app->file("man")->find(qr/\.(hu)?man$/)->length;
my $code = $app->file("man")->find(sub { /\.(hu)?man$/ })->length;
my $test = $app->file("man")->find("-f")->length;

$glob;				## $regexp
$glob;				## $code
$glob;				## $test

```

Обратите внимание, что `*` в `glob` обозначает все символы, и `/` в том числе.

### grep

Фильтрует файлы.

```perl

my $f = $app->file("man/*")->glob;

$f->grep("*.man")->length;				##< $f->length
$f->grep(qr/\.man$/)->length;			##< $f->length
$f->grep("-s")->length;					## $f->length
$f->grep(sub {-f $_})->length;			## $f->length

```

### reverse

Переворачивает файлы в коллекции

```perl

$app->file("1", "2")->reverse->path;	# 2



```

## Ввод-вывод

### replace

Заменяет тело файла. Тело файла передаётся в `$_` и из этой переменной будет записано в файл, а сам файл - 1-м параметром.

```perl

my $file = $app->file("var/man1")->write("123")->replace(sub {
	my $self = shift;
	ref $self;			# R::File
	s/2/5/;
});

$file->read;			# 153

```

Ну и для двух файлов:

```perl

$file = $file->from($file, $app->file("var/man2")->write("123"))->replace(sub {
	my ($self, $idx) = @_;
	s/1/$idx . $self->file/e;
});

$file->read;				# 0man153
$file->eq(1)->read;		# 1man223

