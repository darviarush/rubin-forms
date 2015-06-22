package R::File;
# интерфейс для работы с файлами и директориями

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

1;
