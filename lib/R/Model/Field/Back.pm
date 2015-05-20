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

# выполняется при извлечении столбца back из upFld
sub deep_copy {
	my ($self, $upFld) = @_;
	#::msg ":bold black", "dc back!", ":reset", $upFld->model .".". $upFld->name .".". $self->name;
	$self = $self->SUPER::deep_copy($upFld);
	$self->{As} = $upFld->join($self->{ref}) unless $self->{As};
	$self
}

# # проверяет, что такой есть и возвращает столбец
sub getlike {
	my ($self, $key) = @_;
	my $fld;
	#::msg ":magenta", "back!", ":reset", $self->model . "." . $self->name . ".$key", $self->{toSelf}{back}{name}, $self->{toRef}{name};
	die "нет поля по обратной ссылке $self->{model}.$self->{name}.$key" unless $fld = $self->{ref}{fieldset}{field}{$key};
	$fld->deep_copy($self);
}

# возвращает As и col
sub column {
	my ($self) = @_;
	return $self->{As}, $self->{ref}{ref}{col};
}


# sub deadlock {
	# my ($self) = @_;
	# $self->like($self->{ref}{name});
# }

# свойство обратной ссылки
#	author.books
sub row {
	my ($self, $bean) = @_;
	my $bk = $self->{ref};
	$bk->bean->find($bk->{name} => $bean);
}


sub rowset { goto &row }


1;