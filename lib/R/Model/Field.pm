package R::Model::Field;
# поле таблицы

use common::sense;
use R::App;


has_const qw/fieldset name model compute/;


# конструктор
sub new {
	my ($cls, $fieldset, $name) = @_;
	
	my $self = bless {
		fieldset=>$fieldset,
		name=>$name,
		model=>$fieldset->{name},
		compute=>1,				# вычислимое поле
		check=>undef,			# список чекеров. При установке первого чекера метод-свойство оборачивается в процедуру с чеком
	}, $cls;
	
	$self->register;
	$self->add_method;
	$self
}

# создаёт метод в модели
sub add_method {
	my ($self) = @_;
	my $name = $self->{name};
	
	return $self if $name eq "id" and $self->isa("R::Model::Field::Col");
	
	#my $Prop = ucfirst $self->{model};
	my $class_row = $self->fieldset->cls_row;
	my $class_rowset = $self->fieldset->cls_rowset;
	my $SUB = "${class_row}::$name";
	my $SUBSET = "${class_rowset}::$name";
	
	my $fld = $self->field_with_name($name);
	
	die "$SUB занят " . ($fld? "филдом $fld": "методом") . ", а надо филду " . $self->info2 if $class_row->can($name);
	die "$SUBSET занят " . ($fld? "филдом $fld": "методом") . ", а надо филду " . $self->info2 if $class_rowset->can($name);
	
	*{$SUB} = closure($self, $self->can("row"));
	*{$SUBSET} = closure($self, $self->can("rowset"));
	
	$self
}

# добавляет чекер по имени из зарегистрированных
sub check {
	my $self = shift;
	
	my $check = $self->{check};
	
	# оборачиваем в чекающую функцию, если 
	if(!defined $check) {
		$check = $self->{check} = $app->check->new->stash(
			field => $self,
			model => $self->fieldset->name
		);
	
		my $class_row = $self->fieldset->cls_row;
		my $name = $self->name;
		my $SUB = "${class_row}::$name";
		*$SUB = (sub {
			my ($self, $code) = @_;
			return sub {
		
				# валидируем и преобразовываем поля, если устанавливается значение
				# '+' => 1 - пропускаем
				if(@_ == 2) {
					my ($row, $val) = @_;
					my $e = $self->checking($val, $row);
					die "$self->{model}.$self->{name}: $e" if defined $e;
					return $code->($row, $val);
				}
				$code->(@_);
			}
		})->($self, \&$SUB);
	}
	
	if(ref $_[0]) {
		my $key = "field.$self->{model}.$self->{name}";
		$check->register($key, $check->class("field" . ucfirst($self->{model}) . ucfirst $self->{name} => shift));
		$check->add($key, @_);
	}
	else {
		$check->add(@_);
	}
	
	$self
}

# чекает 
sub checking {
	my ($self, $val, $row) = @_;
	my $check = $self->{check};
	return unless defined $check;
	#$check->{stash}{row} = $row // $self->bean(undef);
	my $e = $check->test($val);
	#undef $check->{stash}{row};
	delete $row->{save} if defined $e;
	$_[1] = $val;
	$e
}

# # когда произойдёт $app->meta->drop, то филды будут освобождены
# sub drop_method {
	# my ($self) = @_;
	# my $Prop = ucfirst $self->{model};
	# my $SUB = "R::Row::${Prop}::$name";
	# my $SUBSET = "R::Rowset::${Prop}::$name";
	
	# delete *{$SUB}{CODE};
	# delete *{$SUBSET}{CODE};
# }


# специальная информация для отладки
sub info2 {
	my ($self) = @_;
	ref($self)."=$self->{model}.$self->{name}"
}

# регистрирует филд в филдсете
sub register {
	my ($self, $before) = @_;
	my $fieldset = $self->fieldset;
	my $name = $self->name;
	$fieldset->{field}{$name} = $self;
	if($before) {
		unshift @{$fieldset->{fieldset}}, $self;
	}
	else {
		push @{$fieldset->{fieldset}}, $self;
	}
	$self
}

# # клонирует и добавляет в указанный филдсет
# sub cloneto {
	# my ($self, $fieldset) = @_;
	
	# $self = bless { %$self, fieldset => $fieldset, model => $fieldset->{name} }, ref $self;
	
	# $self->register;
	# $self->add_method;
	
	# $self
# }


# ищет филд в этом филдсете, который имеет такое же имя
sub field_with_name {
	my ($self, $name) = @_;
	my @bk = grep { $_->name eq $name and $_ != $self } @{$self->fieldset->{fieldset}};
	@bk? $bk[0]->info2: undef
}

# удаляет из филдсета
sub delete {
	my ($self) = @_;
	my $fieldset = $self->{fieldset};
	delete $fieldset->{field}{$self->{name}};
	my $i=0;
	for my $field (@{$fieldset->{fieldset}}) {
		last if $field == $self;
		$i++;
	}
	splice @{$fieldset->{fieldset}}, $i, 1;
}

# возвращает коннект
sub connect {
	my ($self) = @_;
	$self->fieldset->connect
}

# возвращает row
sub bean {
	my $self = shift;
	$self->fieldset->model(@_);
}

# выдаёт краткую информацию о себе
sub info {"i"}

# добавляет комментарий
sub remark {
	my ($self, $remark) = @_;
	$self->{remark} = $remark;
	$self
}


# берёт описание виджета из своих параметров
sub input {
	if(@_ == 1) {
		my ($self) = @_;
		return $self->{input} //= $self->fieldset->meta->{input_default};
	}
	my ($self, $type, @attr) = @_;
	$self->{input} = ref $type? { %$type, @attr }: { type=>$type, @attr };
	$self
}

1;