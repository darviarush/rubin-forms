package R::Connect::Monetdb;
# драйвер для СУБД Монетдб

use base R::Connect;

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

1;