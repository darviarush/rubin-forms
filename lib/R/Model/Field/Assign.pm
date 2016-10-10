package R::Model::Field::Assign;
# поле таблицы базы данных - ссылка один-к-одному обратная

use base R::Model::Field::Back;

use common::sense;
use R::App;


# конструктор
sub new {
	my ($cls, $fieldset, $field, $name) = @_;
	
	$name //= $field->name eq $fieldset->{name}? $field->model: $field->name . ucfirst($field->model);
	
	my $self = $cls->SUPER::new($fieldset, $field, $name);
	
	$self
}

# выдаёт краткую информацию о себе
sub info {
	my ($self) = @_;
	"<~ " . $self->ref->model . ($self->ref->name ne "id"? "." . $self->ref->name: "");
}

# возвращает или устанавливает инпут
sub input {
	my $self = shift;
	if(@_==1) { $self->SUPER::input(@_) }
	else { $self->{input} //= $self->ref->fieldset->{input} }
}

# свойство row
sub row {
	my ($self, $bean) = splice @_, 0, 2;
	
	my $ref = $self->{ref};
	my $ref_name = $ref->{name};
	my $id = $bean->id;
	my $new = $ref->bean->find($ref_name => $id)->exists;
	$new = $self->{ref}->bean(undef), $new->{if_add}{$ref_name} = $id unless $new;
	
	# $new->{rel} = $bean;
	# $new->{ref} = $self->{name};
		
	#if(@_>2) {
		#$val = {@_[2..$#_]} if @_>3;
		#$val = {id=>$val} if !ref $val;
		#$new->FromHash($val);
	#}
	
	$new->update(@_) if @_;
	
	$new
}


1;