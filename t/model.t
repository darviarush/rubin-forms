use strict;
use warnings;

use Test::More tests => 12;
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
is 1, $author1->books->count, "количество книг";
is 1, $author1->soauthorBooks->count, "книги в которых автор выступал соавтором";
is 2, $book1->readAuthors->count, "book1 прочло 2 автора";
is 1, $author1->readBooks->count, "author1 прочёл 1 книгу";
my ($book2) = $author1->readBooks;
is $book1->id, $book2->id;