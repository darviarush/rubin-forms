use strict;
use warnings;

use Test::More tests => 1;
use Msg;

our $app;

my $to = 'darviarush@mail.ru'

$app->mail->send(to => $to, subject => "Тема: Тестовое письмо №1 с $host", body => "Тело: Тестовое письмо №1 c $host");


$app->mail->send(to => $to, action => "register", data => {});