package R::Model::Type::String;
# объект представляющий значение

use common::sense;
use R::App;

# тип столбца в базе
sub typeCol {
	my ($field, $length) = @_;
	$length //= ((1 << 16) - 1);
	$field->{real_max_length} = $length;
	$field->{max_length} = $app->perl->size($length);
	
	$app->meta->getTextType($length);
}

# устанавливается в check филда
sub onCheck {
	my ($check, $val) = @_;
	
	my $field = $check->stash("field");
	
	$check->error("превышена максимальная длина значения ".($field->{real_max_length})." для поля $field->{name}") if $field->{max_length} < length $val;
}

# # конструктор - вызывается, когда значение из базы преобразуется к типу
# sub fromCol {
	# my ($cls, $val, $field) = @_;
	
	# die "превышена максимальная длина значения $field->{real_max_length} для поля $field->{name}" if $field->{max_length} < length $val;
	
	# $val
# }

# # преобразует объект к значению в столбце. Может не использоваться, если fromCol вернёт не объект
# sub toCol {
	# my ($self) = @_;
	
# }


1;