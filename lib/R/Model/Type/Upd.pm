package R::Model::Type::Upd;
# объект время изменения записи

use base R::Model::Type::Unixtime;

use common::sense;
use R::App;


# при сохранении добавляет
sub onSave {
	my ($field, $row) = @_;
	$row->{save}{$field->{name}} = time;
}

1;