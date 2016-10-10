package R::Model::Field::M2m;
# поле многие-ко-многим

use base R::Model::Field;

use common::sense;
use R::App;

has qw/refset/;
has_const(qw/back toSelf toRef/);


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
		back => undef,		# обратный field m2m из таблицы ref, устанавливается в fieldset->m2m
	);
	
	$self
}

# комментарий
sub remark {
	my ($self, $remark, $remark_bk) = @_;
	$self->{remark} = $remark;
	$self->toSelf->fieldset->meta(remark => $remark);
	$self->back->{remark} = $remark_bk // "bk: $remark";
	$self
}

# возвращает или устанавливает инпут
sub input {
	my $self = shift;
	if(@_==1) { $self->SUPER::input(@_) }
	else { $self->{input} //= $self->toRef->ref->fieldset->{inputset} }
}

# выдаёт краткую информацию о себе
sub info {
	my ($self) = @_;
	"=> " . $self->toRef->ref->model;
}

# возвращает столбец в таблице, на к-ю ссылается
sub refTo {
	my ($self) = @_;
	$self->{toRef}{ref}
}

# # блокируем клонирование для rowset->as
# sub cloneto {
	# my ($self) = @_;
	# die $self->model . ".". $self->name . ": Клонировать m2m ссылки в другую таблицу нельзя, так как это приведёт к созданию нового поля ref.\nВ будущем можно будет создать ref ...";
# }

# свойство m2m
sub row {
	my ($self, $bean, $idx, $size) = @_;
	
	# переворачиваем
	my $back = $self->{back};
	#msg(":red", "m2m.row", ":reset", $self->name, $back->{name}, $back->{toSelf}{back}{name});
	#$back->{toSelf}{back}{name} . "__" . $back->{toSelf}{name}
	
	my $rows = $back->bean->find($back->{name} => $bean)->order($back->{toSelf}{back}{name} . "__id");
	
	if(@_>2) {
		my ($ass_bean) = $rows->limit($idx-1, 1);
		# если нет с таким индексом, то - добавляем
		unless($ass_bean) {
	
			my $m2m = $self->toRef->bean({
				$self->toSelf->name => $bean
			});
			
			my $ref = $self->toRef->name;
			$ass_bean = $m2m->$ref;
		}
		
		$ass_bean
	} else {
		wantarray? $rows->_rows: $rows;
	}
}

sub rowset {
	my ($self, $bean, @args) = @_;
	$self->{back}->bean->find($self->{back}{name} => $bean);
}

sub rowset_new {
	my ($self, $bean) = @_;
	# переворачиваем
	my $back = $self->{back};
	
	todo;
	
	# my $ref = $self->{ref};
	# my $ref_name = $ref->{name};
	# $ref->bean({$ref_name => $bean});
}


1;