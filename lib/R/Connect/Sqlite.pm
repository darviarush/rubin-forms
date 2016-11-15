package R::Connect::Sqlite;
# драйвер для СУБД скулат

use base R::Connect;

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

1;