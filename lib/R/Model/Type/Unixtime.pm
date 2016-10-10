package R::Model::Type::Unixtime;
# тип времени для колумнов

use parent qw/R::Model::Type::Datetime/;

use common::sense;
use R::App;

# возвращает тип колумна в базе 
sub typeCol { "int unsigned" }

# в представление столбца
sub toCol {
	my ($self) = @_;
	$self->epoch;
}

# конструктор - возвращает новый объект
sub fromCol {
	my ($field, $val) = @_;
	return if !defined $val;	# null
	$field->{class}->from_epoch(epoch => $val)->set_formatter("R::Model::Type::Datetime::Format")->set_time_zone($R::Model::Type::Datetime::time_zone);
}


1;