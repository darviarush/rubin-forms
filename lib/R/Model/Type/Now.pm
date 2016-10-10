package R::Model::Type::Now;
# объект время изменения записи

use base R::Model::Type::Unixtime;

use common::sense;
use R::App;


# при сохранении добавляет
sub onAdd {
	my ($field, $row) = @_;
	$row->{save}{$field->{name}} = time;
}

1;