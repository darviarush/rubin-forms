package R::Model::Field::Compute;
# вычислимое поле

use base R::Model::Field;

use strict;
use warnings;


# конструктор
sub new {
	my ($cls, $fieldset, $name) = @_;
	
	my $self = $cls->SUPER::new($fieldset, $name);
	
	my $model = $fieldset->{name};
	my $row = $::app->model->$model(undef);
	my $code = $row->can($name);
	die "Нет метода $model.$name" unless $code;
	
	%$self = (
		%$self,
		code => $code
	);
	
	$self
}

# переопределяем метод, чтобы не создавать существующий
sub add_method {$_[0]}

# выдаёт краткую информацию о себе
sub info {"*"}

# вычислимое свойство
# sub row {
	# my ($self, @args) = @_;
	# $self->{code}->(@args);
# }

sub rowset {
	my ($self, $rowset, @args) = @_;
	my $code = $self->{code};
	for my $bean ($rowset->find) {
		$code->($bean, @args);
	}
}

1;