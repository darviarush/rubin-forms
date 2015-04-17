package R::Model::Field::Compute;
# вычислимое поле

use base R::Model::Field;

use strict;
use warnings;


# конструктор
sub new {
	my ($cls, $fieldset, $name) = @_;
	
	my $self = $cls->SUPER::new($fieldset, $name);
	
	my $model = $fieldset->{name};
	my $row = $::app->model->$model(undef);
	my $code = $row->can($name);
	die "Нет метода $model.$name" unless $code;
	
	%$self = (
		%$self,
		code => $code
	);
	
	$self
}

# добавляем параметр
sub add_method {
	$_[0]->SUPER::add_method("_compute")
}


1;