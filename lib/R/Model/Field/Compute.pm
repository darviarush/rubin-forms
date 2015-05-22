package R::Model::Field::Compute;
# вычислимое поле

use base R::Model::Field;

use strict;
use warnings;

Utils::has(qw/code rel/);

# конструктор
sub new {
	my ($cls, $fieldset, $name, $relation_fields) = @_;
	
	my $self = $cls->SUPER::new($fieldset, $name);
	
	my $model = $fieldset->{name};
	my $row = $::app->model->$model(undef);
	my $code = $row->can($name);
	die "Нет метода $model.$name" unless $code;
	
	$relation_fields = [map {
		my $rel = $fieldset->{field}{$_};
		die "нет поля `$_` для связи $model.$name" unless $rel;
		if($rel->isa("R::Model::Field::Compute")) {
			map { $_->name } @{$rel->rel}
		} elsif($rel->compute) {
			die "вычислимое поле `$_` в связанных полях $model.$name";
		} else {
			$_
		}
	} @$relation_fields];
	
	%$self = (
		%$self,
		code => $code,
		rel => $relation_fields,
	);
	
	$self
}

# переопределяем метод, чтобы не создавать существующий
sub add_method {$_[0]}

# выдаёт краткую информацию о себе
sub info {"*" . (@{$_[0]->{rel}}? "  " . join(", ", @{$_[0]->{rel}}): "")}

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