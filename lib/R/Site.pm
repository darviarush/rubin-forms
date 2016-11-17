package R::Site;
# сервер

use common::sense;
use R::App;

# конструктор
sub new {
	my $cls = shift;
	bless {}, ref $cls || $cls;
}

1;