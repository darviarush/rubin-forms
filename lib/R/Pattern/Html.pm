package R::Pattern::Shibari;
# шаблонизатор html

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

1;
