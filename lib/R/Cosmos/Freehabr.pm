package R::Cosmos::Freehabr;
# публикует на freehabr.ru

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

1;
