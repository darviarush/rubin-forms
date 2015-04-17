package R::Model::Field::Ref;
# поле таблицы базы данных - ссылка

use base R::Model::Field::Col;

use strict;
use warnings;

require R::Model::Index;
require R::Model::Field::Back;

Utils::has_const(qw/ref/);


# конструктор
sub new {
	my ($cls, $fieldset, $name, $to_model, $fk_name) = @_;
		
	my $self = $cls->SUPER::new($fieldset, $name, '');
	
	my $to_fieldset = $::app->modelMetafieldset->fieldset($to_model ||= $name);
	my $fk = $to_fieldset->{pk};
	
	%$self = (
		%$self,
		col=>$self->{col} . '_id',
		type=>$fk->{type},
		null=>1,
		ref=>$fk,
	);

	R::Model::Field::Back->new($to_fieldset, $self);

	$fk_name ||= "fk_" . $self->tab . "__" . $self->col . "__to__" . $fk->tab . "__" . $fk->col;
	
	$fieldset->{indexref}{$self->name} = R::Model::IndexRef->new($fk_name, $self, $fk);
	
	$self
}

# добавляем параметр
sub add_method {
	$_[0]->SUPER::add_method("_ref")
}

1;