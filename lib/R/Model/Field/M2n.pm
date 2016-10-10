package R::Model::Field::M2n;
# поле многие-к-одному

use base R::Model::Field::M2m;

use common::sense;
use R::App;


# конструктор
# sub new {
	# my $cls = shift;
	# my $self = $cls->SUPER::new(@_);
	
	# $self
# }

# выдаёт краткую информацию о себе
sub info {
	my ($self) = @_;
	"*> " . $self->toRef->ref->model;
}

# возвращает или устанавливает инпут
sub input {
	my $self = shift;
	if(@_==1) { $self->SUPER::input(@_) }
	else { $self->{input} //= $self->toRef->fieldset->{input} }
}

# свойство m2n из row
sub row {
	my $self = shift;
	my $bean = shift;
	
	# переворачиваем
	my $back = $self->{toSelf}{back};
	my $back_name = $back->{name};
	my $ref = $self->{toRef};
	my $ref_name = $ref->{name};
	#msg(":red", "m2n.row", ":reset", $self->name, $back->{name}, $back->{toSelf}{back}{name});

	
	if(ref $back eq "R::Model::Field::Back") {
		$bean->$back_name(1)->$ref_name(@_);
	} else {	# а тут assign
		$bean->$back_name->$ref_name(@_);
	}
	
}

# свойство из rowset
sub rowset {
	my ($self, $bean, @args) = @_;
	$self->{back}->bean->find($self->{back}{name} => $bean);
}



1;