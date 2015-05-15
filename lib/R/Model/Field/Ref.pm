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
	my ($cls, $fieldset, $name, $to_model, $bk_name, $fk_name) = @_;
		
	$to_model ||= $name;
	#die "Нет модели $to_model" unless $::app->modelMetafieldset->{fieldset}{$to_model};

	my $self = $cls->SUPER::new($fieldset, $name, '');
	
	my $to_fieldset = $::app->modelMetafieldset->fieldset($to_model);
	my $fk = $to_fieldset->{pk};
	
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
		back=>R::Model::Field::Back->new($to_fieldset, $self, $bk_name),
	);

	$fk_name ||= "fk_" . $self->tab . "__" . $self->col . "__to__" . $fk->tab . "__" . $fk->col;
	
	$fieldset->{indexref}{$fk_name} = R::Model::IndexRef->new($fk_name, $self, $fk);
	
	$self
}

# выдаёт краткую информацию о себе
sub info {
	my ($self) = @_;
	"-> " . $self->ref->model . ($self->ref->name ne "id"? "." . $self->ref->name: "");
}

# свойство row
sub row {
	my ($self, $bean, $val) = @_;
		
	if(@_>2) {
		$val = {@_[2..$#_]} if @_>3;
		
		if(!ref $val) {
			$self->SUPER::row($bean, $val);
		} else {
			my $id;
			%$val = (%$val, id => $id) if !$val->{id} && $bean->id && defined($id = $self->SUPER::row($bean));
			my $new = $self->{ref}->bean($val);
			$bean->{save}{$self->{name}} = $new->id;
			$bean
		}
	}
	else {
		my $id = $self->SUPER::row($bean);
		my $new = $self->{ref}->bean($id);
		$new->{rel} = $bean;
		$new->{ref} = $self->{name};
		$new
	}
}

# свойство
#	book -> author (books => books)
sub rowset {
	my ($self, $bean) = @_;
	$self->{ref}->bean->find($self->{back}{name} => $bean)
}


1;