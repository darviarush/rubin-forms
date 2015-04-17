package R::Model::Field::M2m;
# поле многие-ко-многим

use base R::Model::Field;

use strict;
use warnings;

Utils::has_const(qw/m2m to ref/);


# конструктор
sub new {
	my ($cls, $fieldset, $name, $to_fieldset, $m2m_fieldset) = @_;
	
	$name .= ucfirst($to_fieldset->{name}) . "s";
	
	my $self = $cls->SUPER::new($fieldset, $name);

	%$self = (
		%$self,
		m2m => $m2m_fieldset,
		to => $to_fieldset,
		ref => $m2m_fieldset->{field}{$fieldset->{name}}
	);

}

# добавляем параметр
sub add_method {
	$_[0]->SUPER::add_method("_m2m")
}


1;