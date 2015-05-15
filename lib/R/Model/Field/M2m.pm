package R::Model::Field::M2m;
# поле многие-ко-многим

use base R::Model::Field;

use strict;
use warnings;

Utils::has_const(qw/back toSelf toRef/);


# конструктор
sub new {
	my ($cls, $name, $ref1, $ref2) = @_;
	
	my $fieldset = $ref1->ref->fieldset;
	#my $to_fieldset = $ref2->ref->fieldset;
	
	#$name .= ucfirst($ref2->{name}) . "s";
	
	my $self = $cls->SUPER::new($fieldset, $name);

	%$self = (
		%$self,
		toSelf => $ref1,	# на себя
		toRef => $ref2,		# на таблицу ref
		back => undef,		# обратный field из таблицы ref, устанавливается в fieldset->m2m
	);

	$self
}

# выдаёт краткую информацию о себе
sub info {
	my ($self) = @_;
	"=> " . $self->toRef->ref->model;
}

# комментарий
sub remark {
	my ($self, $comment) = @_;
	$self->toSelf->fieldset->comment($comment);
	$self
}


# свойство m2m
sub row {
	my ($self, $bean, $idx) = @_;
	
	my $rows = $self->{back}->bean->find($self->{back}{name} => $bean);
	
	if(@_>2) {
		my ($ass_bean) = $rows->limit($idx, 1);
		unless($ass_bean) {
			$ass_bean = 
		}
		$ass_bean
	} else {
		$rows
	}
}

sub rowset {
	my ($self, $bean, @args) = @_;
	$self->{back}->bean->find($self->{back}{name} => $bean);
}



1;