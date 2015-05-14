package R::Model::Field::Back;
# обратная ссылка на филд

use base R::Model::Field;

use strict;
use warnings;

Utils::has_const(qw/ref/);


# конструктор
sub new {
	my ($cls, $fieldset, $field, $name) = @_;
	
	$name //= $field->name eq $fieldset->{name}? $field->model . "s": $field->name . ucfirst($field->model) . "s";
	
	my $self = $cls->SUPER::new($fieldset, $name);
	
	%$self = (
		%$self,
		ref=>$field
	);
	
	$self
}

# выдаёт краткую информацию о себе
sub info {
	my ($self) = @_;
	"<- " . $self->ref->model . "." . $self->ref->name;
}


# свойство обратной ссылки
#	author.books
sub row {
	my ($self, $bean) = @_;
	my $bk = $self->{ref};
	$bk->bean->find($bk->{name} => $bean);
}


sub rowset { goto &row }


1;