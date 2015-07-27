package R::Async::Watch;
# объект следит за файлами и позволяет установить события на изменение файлов и каталогов, их удаление и появление в каталогах

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls, $file) = @_;
	bless {
		file => $file,
	}, ref $cls || $cls;
}

# изменился файл
sub modify {
	my ($self, $watcher) = @_;
	$self->{MODIFY} = $watcher;
	$self
}

# добавлен файл или каталог
sub add {
	my ($self, $watcher) = @_;
	$self->{ADD} = $watcher;
	$self
}

# удалён файл или каталог
sub erase {
	my ($self, $watcher) = @_;
	$self->{ERASE} = $watcher;
	$self
}




1;
