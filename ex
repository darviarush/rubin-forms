#!/usr/bin/perl

use common::sense;
use lib "lib";
use R::App;


00000

#todo "хреш и бреш: шаблонизатор и т.д. ну и как оно";

msg ":bold cyan on_green inline", "123", undef, {a=>'z'};

exit;

my $promise = $app->promise->new;
$promise->then(\&msg);
$promise->resolve(44);
$promise->then(\&msg);
$promise->resolve(56);


#$app->file("ex")
# ->readline->then({
	# print;
# });