use strict;
use warnings;

use Test::More tests => 9;
use Msg;

our $app;

$app->ini->{connect}{DNS} =~ s/database=.*/database=test/;

$app->model->{base} = ""; # отключаем базис модели, чтобы не подгружались классы

my $c = $app->connect;

my $meta = $app->modelMetafieldset;
my $author = $meta->fieldset("author");
my $book = $meta->fieldset("book");

$book->
ref("author")->
ref("soauthor" => "author")->
m2m("review" => "author")->
col("name" => "varchar(255)");

$meta->sync;

my $idx = $c->get_index_info;
my $fk = $c->get_fk_info;

is 1, scalar keys %$fk;
is 2, scalar keys %$idx;


my $author1 = $app->model->author->new;
my $book1 = $app->model->book({});

$book1->name("Книга высокого полёта");

ok $book1->id;
ok $author1->id;

$book1->author($author1);
$book1->soauthor($author1);

$book1->review($author1, $app->model->author->new);

ok $book1->author->id;
is 1, $author1->books->count;
is 1, $author1->soauthorBooks->count;
is 2, $book1->review->count;
is 1, $author1->review->count;
my ($book) = $author1->review;
is $book1->id, $book->id;