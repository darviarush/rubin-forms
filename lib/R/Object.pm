package R::Object;
# родитель для всех классов R::App, кроме R::App

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		
	}, ref $cls || $cls;
}

1;
