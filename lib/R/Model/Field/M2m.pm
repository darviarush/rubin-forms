package R::Model::Field::M2m;
# поле многие-ко-многим

use base R::Model::Field;

use strict;
use warnings;

Utils::has_const(qw/back ref/);


# конструктор
sub new {
	my ($cls, $name, $ref1, $ref2) = @_;
	
	my $fieldset = $::app->modelMetafieldset->fieldset($ref1->ref->model);
	my $to_fieldset = $::app->modelMetafieldset->fieldset($ref2->ref->model);
	
	$name .= ucfirst($to_fieldset->{name}) . "s";
	
	my $self = $cls->SUPER::new($fieldset, $name);

	%$self = (
		%$self,
		back => $ref1,
		ref => $ref2,
	);

}

# свойство m2m
sub row {
	my ($self, $bean, @args) = @_;
	my $model1 = $self->{back}{back}{name};
	my $model2 = $self->{ref}{name};
	
	#::msg ref($bean)."->$model1->$model2";
	
	$bean->$model1->$model2(@args);
}

sub rowset { goto &row }

1;