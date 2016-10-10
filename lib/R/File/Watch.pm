package R::File::Watch;
# объект-обёртка для результатов функции app->file->watch

use common::sense;
use R::App;

has qw/changed new deleted/;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

1;