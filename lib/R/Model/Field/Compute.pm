package R::Model::Field::Compute;
# вычислимое поле

use base R::Model::Field;

use common::sense;
use R::App;

has(qw/code rel/);

# конструктор
sub new {
	my ($cls, $fieldset, $name, $relation_fields) = @_;
	
	my $self = $cls->SUPER::new($fieldset, $name);
	
	my $model = $fieldset->{name};
	my $code = $fieldset->{cls_row}->can($name);
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
sub add_method {
	my ($self) = @_;
	my $name = $self->{name};
	
	# todo:
	# если такого метода нет - берём методы set* и get*
	# устанавливаем метод query*
	
	my $cls_row = $self->fieldset->cls_row;
	my $cls_rowset = $self->fieldset->cls_rowset;
	
	if(!$cls_row->can($name)) {
		die "нет метода для столбца compute($name)";
	}
	
	if(!$cls_rowset->can($name)) {
		*{"${cls_rowset}::$name"} = closure $self, sub {
			my ($self, $rowset) = splice @_, 0, 2;
			my $name = $self->{name};
			if(@_) {	# setter
				todo;		# $row->links(1) возвращает первую. $rowset->links(1)-> ?
				for my $row ($rowset->_rows) {
					$row->$name(@_)->save;	# todo: переписать на множественный save или store
				}
				$self
			} else {		# getter
				wantarray? do {
					map { $_->$name } $rowset->_rows
				}: do {
					my $row = $rowset->exists // $self->bean(undef);
					$row->$name
				}
			}
		};
	}
	
	$self
}

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