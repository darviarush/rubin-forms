package R::Model::Field::Back;
# обратная ссылка на филд

use base R::Model::Field;

use strict;
use warnings;

Utils::has_const(qw/back/);


# конструктор
sub new {
	my ($cls, $fieldset, $field) = @_;
	
	my $name = $field->name eq $fieldset->{name}? $field->model . "s": $field->name . ucfirst($field->model) . "s";
	
	my $self = $cls->SUPER::new($fieldset, $name);
	
	%$self = (
		%$self,
		back=>$field
	);
	
	$self
}

# добавляем параметр
sub add_method {
	$_[0]->SUPER::add_method("_back_ref")
}


1;