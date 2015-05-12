package R::Model::Field::Ref;
# поле таблицы базы данных - ссылка

use base R::Model::Field::Col;

use strict;
use warnings;

require R::Model::Index;
require R::Model::Field::Back;

Utils::has_const(qw/ref back/);


# конструктор
sub new {
	my ($cls, $fieldset, $name, $to_model, $fk_name) = @_;
		
	$to_model ||= $name;
	#die "Нет модели $to_model" unless $::app->modelMetafieldset->{fieldset}{$to_model};

	my $self = $cls->SUPER::new($fieldset, $name, '');
	
	
	
	my $to_fieldset = $::app->modelMetafieldset->fieldset($to_model);
	my $fk = $to_fieldset->{pk};
	
	::msg 'from', $fieldset->{name}, $name, 'to', $to_model, $to_fieldset->{field}{id};
	
	# например:
	#	book.author_id -> author.id
	# тогда:
	#	book.author_id =>
	#		ref => author.id
	#		back => author.books { ref => book.author_id }
	
	%$self = (
		%$self,
		col=>$self->{col} . '_id',
		type=>$fk->{type},
		null=>1,
		ref=>$fk,
		back=>R::Model::Field::Back->new($to_fieldset, $self),
	);

	$fk_name ||= "fk_" . $self->tab . "__" . $self->col . "__to__" . $fk->tab . "__" . $fk->col;
	
	$fieldset->{indexref}{$self->name} = R::Model::IndexRef->new($fk_name, $self, $fk);
	
	$self
}

# свойство row
sub row {
	my ($self, $bean, $val) = @_;
	if(@_>2) {
		$val = {@_[2..$#_]} if @_>3;
		if(ref $val) {
			my $ref = $self->{ref}->bean($val);
			$ref->save unless $ref->{id};
			$val = $ref->{id};
		}
		
		$bean->{save}{$self->{name}} = $val;
		$bean
	}
	else {
		my $id = $self->SUPER::row($bean);
		$self->{ref}->bean($id)
	}
}

# свойство
#	book -> author (books => books)
sub rowset {
	my ($self, $bean) = @_;
	$self->{ref}->bean->find($self->{back}{name} => $bean)
}


1;