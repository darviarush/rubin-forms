package R::Route;
# маршрут

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

# добавляет маршрут
sub route {
	my ($self, $) = @_;
	$self
}



1;
