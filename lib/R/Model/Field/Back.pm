package R::Model::Field::Back;
# обратная ссылка на филд

use base R::Model::Field;

use common::sense;
use R::App;

has qw/refset/;
has_const(qw/ref/);


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

# возвращает или устанавливает инпут
sub input {
	my $self = shift;
	if(@_==1) { $self->SUPER::input(@_) }
	else { $self->{input} //= $self->ref->fieldset->{inputset} }
}

# возвращает столбец в таблице, на к-ю ссылается
sub refTo {
	my ($self) = @_;
	$self->{ref}
}

# # блокируем клонирование для rowset->as
# sub cloneto {
	# my ($self) = @_;
	# die $self->model . ".". $self->name . ": Клонировать обратные ссылки в другую таблицу нельзя, так как это приведёт к созданию нового поля ref.\nВ будущем можно будет создать ref ...";
# }

# свойство обратной ссылки
#	author.books
sub row {
	my ($self, $bean, $idx) = @_;
	
	my $ref = $self->{ref};
	my $ref_name = $ref->{name};
	my $rows = $ref->bean->find($ref_name => $bean)->order("id");
	
	if(@_>2) {
		my ($ass_bean) = $rows->limit($idx-1, 1);
		unless($ass_bean) {
			$ass_bean = $ref->bean({$ref_name => $bean});
		}
		$ass_bean
	} else {
		wantarray? $rows->_rows: $rows;
	}
}


sub rowset { goto &row }

sub rowset_new {
	my ($self, $bean) = @_;
	my $ref = $self->{ref};
	my $ref_name = $ref->{name};
	$ref->bean({$ref_name => $bean});
}

1;