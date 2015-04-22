package R::Model::Field::M2m;
# поле многие-ко-многим

use base R::Model::Field;

use strict;
use warnings;

Utils::has_const(qw/back toSelf toRef/);


# конструктор
sub new {
	my ($cls, $name, $ref1, $ref2) = @_;
	
	my $fieldset = $::app->modelMetafieldset->fieldset($ref1->ref->model);
	my $to_fieldset = $::app->modelMetafieldset->fieldset($ref2->ref->model);
	
	$name .= ucfirst($to_fieldset->{name}) . "s";
	
	my $self = $cls->SUPER::new($fieldset, $name);

	%$self = (
		%$self,
		toSelf => $ref1,	# на себя
		toRef => $ref2,		# на таблицу ref
		back => undef,		# обратный field из таблицы ref, устанавливается в fieldset->m2m
	);

	$self
}

# свойство m2m
sub row {
	my ($self, $bean, @args) = @_;	
	$self->{back}->bean->find($self->{back}{name} => $bean);
}

sub rowset { goto &row }



1;