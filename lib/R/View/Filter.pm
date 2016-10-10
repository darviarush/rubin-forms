package R::View::Filters;
# пакет содержит фильтры шаблонов

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

1;