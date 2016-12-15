package R::Object;
# суперкласс, стоящий во главе всех классов

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

1;