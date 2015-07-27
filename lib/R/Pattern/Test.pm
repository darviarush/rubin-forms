package R::Pattern::Test;
# компилирует miu в тест и выполняет

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

1;
