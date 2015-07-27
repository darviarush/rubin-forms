package R::Async::Cmp;
# сравнивает два файла или каталога рекурсивно, если время во втором меньше первого, то удаляет 

use base "R::Async::Watch";

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

1;
