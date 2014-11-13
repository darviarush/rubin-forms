use strict;
use warnings;

use Msg;
use Test::More tests => 1;

our $app;

$app->ini(Utils::parse_ini(__FILE__ . "/../main.ini"));

$app->query->user(1)->