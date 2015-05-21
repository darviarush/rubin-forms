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
		back => undef,		# обратный field m2m из таблицы ref, устанавливается в fieldset->m2m
	);

	$self
}

# комментарий
sub remark {
	my ($self, $comment) = @_;
	$self->toSelf->fieldset->meta(remark => $comment);
	$self
}

# выдаёт краткую информацию о себе
sub info {
	my ($self) = @_;
	"=> " . $self->toRef->ref->model;
}

# выполняется при извлечении столбца back из upFld
# бросает back на таблицу связи
sub deep_copy {
	my ($self, $upFld) = @_;
	#::msg ":bold black", "dc m2m!", ":reset", $upFld->model .".". $upFld->name .".". $self->name;
	$self = $self->SUPER::deep_copy($upFld);
	my $back = $self->{upFld}->like($self->{toSelf}{back}{name});
	$self->{As} = $back->{As} unless $self->{As};
	$self
}

# проверяет, что такой есть и возвращает столбец
# создаёт переход: бросает back на таблицу связи, а потом с неё на таблицу
sub getlike {
	my ($self, $key) = @_;

	#::msg ":on_red white", "m2m!", ":reset", $self->model . "." . $self->name . ".$key";
	
	die "нет поля по ссылке m2m $self->{model}.$self->{name}.$key" unless $self->{toRef}{ref}{fieldset}{field}{$key};
	
	my $toRef = $self->{upFld}->like($self->{toSelf}{back}{name})->like($self->{toRef}{name});
	$toRef->like($key);
}

# возвращает As и col
sub column {
	my ($self) = @_;
	return $self->{As}, $self->{toRef}{col};
}

# свойство m2m
sub row {
	my ($self, $bean, $idx, $size) = @_;
	
	# переворачиваем
	my $back = $self->{back};
	::msg("m2m.row", $self->name, $back->{name}, $back->{toSelf}{back}{name});
	
	my $rows = $back->bean->find($back->{name} => $bean)->order($back->{toSelf}{back}{name} . "__" . $back->{toSelf}{name});
	
	if(@_>2) {
		my ($ass_bean) = $rows->limit($idx-1, 1);
		# если нет с таким индексом, то - добавляем нужное количество
		unless($ass_bean) {
			my $n = $idx - $rows->count;
			my $id = $bean->id;
			die "$bean не имеет id" unless $id;
			
			my $c = $::app->connect;
			my $to_self_col = $self->{toSelf}{col};
			my $to_ref = $self->{toRef}{ref};
			
			$c->insert($self->{toRef}{fieldset}{tab}, [$to_self_col], [map { [$id] } 1..$n]);
			
			$ass_bean = $to_ref->bean({});
			$ass_bean->{rel_m2m} = $id;
			$ass_bean->{ref_m2m} = $self;
			$ass_bean->{save}{id} = $to_ref->{fieldset}->auto_increment_inc($n);
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



1;