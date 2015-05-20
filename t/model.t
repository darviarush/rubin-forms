use strict;
use warnings;

use Test::More tests => 22;
use Msg;

our $app;

$app->ini->{connect} = $app->ini->{connect}{test};	# меняем базу

$app->model->{base} = "";	# отключаем базис модели, чтобы не подгружались классы

my $meta = $app->modelMetafieldset->database("test1");	# меняем базу
my $author = $meta->fieldset("author");
my $book = $meta->fieldset("book");

$book->
ref("author")->
ref("soauthor" => "author")->
m2m("readAuthors" => "author" => "readBooks")-> 
col("name" => "varchar(255)");

$meta->sync;

my $c = $app->connect;		# подключение к базе
my $idx = $c->get_index_info;
my $fk = $c->get_fk_info;


is undef, $fk->{author};
is 1, scalar keys %{$idx->{author}};
is 2, scalar keys %{$fk->{book}};
is 1, scalar keys %{$idx->{book}}, "ключи book";


my $author1 = $app->model->author->new;
my $book1 = $app->model->book({});

$book1->name("Книга высокого полёта");

ok $book1->id, "book1 имеет id";
ok !$author1->{id}, "author1 не имеет id";

$book1->author($author1);
$book1->soauthor($author1);

$book1->readAuthors->add($author1, $app->model->author->new);

ok $book1->author->id, "book1.author имеет id";

my ($author1_1) = $app->model->author->find(books=>$book1);
is $author1_1->id, $author1->id, "автор написал книгу";

is 1, $author1->books->count, "количество книг";
is 1, $author1->soauthorBooks->count, "книги в которых автор выступал соавтором";
my ($book3) = $author1->soauthorBooks;
is $book3->id, $book1->id, "книга написанная в соавторстве";
is 2, $book1->readAuthors->count, "book1 прочло 2 автора";
is 1, $author1->readBooks->count, "author1 прочёл 1 книгу";
my ($book2) = $author1->readBooks;
is $book1->id, $book2->id, "одинаковые id";

my $author2 = $app->model->author({});
$book2 = $app->model->book({ author => $author2, soauthor => $author1, name => "книга №1 в мире" });

my ($book2_1) = $author1->soauthorBooks->find(author__ne=>$author1);
ok !$book2_1, "ещё не сохранён";
$book2->save;
($book2_1) = $author1->soauthorBooks->find(author__ne=>$author1);

is $book2->id, $book2_1->id, "книга где автор не является одновременно и соавтором";

my ($book2_2) = $app->model->author->find(soauthorBooks__name__startswith => "книга")->limit(1)->order("-soauthorBooks__id");
ok $book2_2->id, "имя книги начинается на 'книга'";

msg "======================";
my $book_null;
($book2_2, $book_null) = $app->model->book->find(readAuthorReadBooks__author__id=>[$author1, $author2]);
ok !$book_null, "только одна книга у автора1";
ok $book2_2, "есть книга автора1";

($book2_2, $book_null) = $app->model->book->find(readAuthors__id=>[$author1, $author2]);
ok !$book_null, "m2m: только одна книга у автора1";
ok $book2_2, "m2m: есть книга автора1";

($book2_2) = $app->model->book->find(readAuthors__readBooks__name__endswith => 'полёта', readAuthors__readBooks__id__ne=>undef)->order("-readAuthors__readBooks__id")->limit(3);
ok $book2_2, "проверяем As у нескольких столбцов";
