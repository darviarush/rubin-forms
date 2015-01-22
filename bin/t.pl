#!/usr/bin/perl

#= add file | t [verbosity] [tests ...]
#> тесты
#> add - добавить скелетон теста

($cmd, @ARGS) = @ARGV;

if($cmd eq "add") {
	main::msg ":red", "Укажите файл. qq t add <file>" unless @ARGS;
	Utils::write("t/$ARGS[0].t", "use strict;
use warnings;

use Msg;
use Test::More tests => 1;

our \$app;
");
	exit;
}

$verbosity = 1;
$verbosity = shift @ARGS if @ARGS and $ARGS[0] =~ /^-?\d+$/;

@tests = files(@ARGS? map({ "t/$_.t" } @ARGS): "t/*.t");

$app->test->verbosity($verbosity)->run(@tests);

