use strict;
use warnings;

use Msg;
use Test::More tests => 1;

our $app;

$app->ini(Utils::parse_ini(__FILE__ . "/../main.ini"));

# инсерт
$app->query->user({ name=>'Иваныч',  })->id;
# апдейт
$app->query->user({ name=>'Иваныч' }, id__between => [1,2]);
# выборка
$app->query->user([
	"name",
	$app->query->msg(["text"], delete => undef)
], id__between => [1,2]);