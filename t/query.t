use strict;
use warnings;

use Msg;
use Test::More tests => 1;

our $app;

ok 1;
__END__

$app->ini(Utils::parse_ini(__FILE__ . "/../main.ini"));

# инсерт
is $app->query->user({ name=>'Иваныч' })->id, 1;
# апдейт
$app->query->user({ name=>'Иваныч', id => 1 }, id__between => [1,2]);
# выборка
$app->query->user([
	"name",
	$app->query->msg(["text"], delete => undef)
], id__between => [1,2]);