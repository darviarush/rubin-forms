package R::Model::Row;
# наследный класс для моделей. Представляет запись

use warnings;
use strict;

# операторы возвращающие строку
#use overload '""' => sub { $_[0]->name };

# операторы возвращающие число
#use overload '0+' => sub { $_[0]->id // 0 };


# конструктор
# app->model->модель
sub new {
	my ($cls, $id);
	if(@_>2) {
		my @args;
		($cls, @args) = @_;
		$id = {@args};
	} else {
		($cls, $id) = @_;
	}
	
	if(ref $id) {
		if(ref $id eq $cls) {
			$id->save if !$id->{id};
			$id = $id->{id};
		}
		elsif(ref $id eq "HASH") {
			# если нет id, то создаёт перед compute или геттере, а сеттер - забрасывает в set и сохраняет перед compute или при геттере
			my $bean = bless {id => $id->{id}}, $cls;
			return $bean->FromHash($id);
		}
		else {
			die "Нельзя ". ref($id) ." обратить в модель $cls";
		}
	}
	bless {id=>$id}, $cls;
}

# помощник
sub FromHash {
	my ($self, $hash) = @_;
	my $field = $self->Field;
	$self->{save} //= {};
	while(my($k, $v) = each %$hash) {
		$self->$k($v);	# if exists $field->{$k};
	}
	$self
}

# возвращает/устанавливает идентификатор
sub id {
	my ($self, $val) = @_;
	if(@_>1) {
		if(defined $self->{id} and $val ne $self->{id}) {
			die "попытка изменить id"; # нужно при изменении id изменить id во всех ссылающихся на него
			$self->{save}{id} = $val;
			#$self->save;
		} else {
			$self->{id} = $val;
		}
		$self
	}
	else { $self->save if !$self->{id}; $self->{id} }
}

# добавляет поля, которые должны запроситься при первом запросе
# compute-поля отбрасываются
# если compute-поле зависит от другого поля - устанавливается и другое поле
sub view {
	my ($self, @view) = @_;
	my $field = $self->Field;
	$self->{view} = [grep { !$field->{$_}->compute } map { my $fld=$field->{$_}; $fld->{rel}? @{$fld->{rel}}: $_ } @view];
	$self
}

# возвращает хэш с указанными полями. Поля могут быть любыми - так же и вычисляемыми
sub annotate {
	my ($self, @fields) = @_;
	my ($res) = $self->Model->find(id=>$self)->annotate(@fields);
	$res
}

# деструктор
sub DESTROY {
	my ($self) = @_;
	$self->save;
}

# сохраняет, если есть что
sub save {
	my ($self) = @_;

	my $save = $self->{save};
	return $self unless $save;
	
	my $c = $::app->connect;
	my $listener = $::app->listener;
	my $name = $self->Fieldset->{name};
	my $id = $self->{id};
	
	if(defined $id) {
	
		$listener->fire("$name.update,$name.save", $self);
		$self->{noAction} = undef, return $self if $self->{noAction};
	
		my ($tab, $s) = $self->ToCol;
		$c->update($tab, $s, { "id" => $id });
		$self->{id} = $id if $id = $s->{id};
	} else {
	
		$listener->fire("$name.add,$name.save", $self, 1);
		$self->{noAction} = undef, return $self if $self->{noAction};
	
		my ($tab, $s) = $self->ToCol;
		$c->add($tab, $s);
		$id = $self->{id} = $save->{id} // $c->last_id;
	}
	
	if(defined $id) {
		my $rel;
		$rel->{save}{$self->{ref}} = $id if $rel = $self->{rel};
		if($rel = $self->{rel_m2m}) {
			my $ref=$self->{ref_m2m};
			my $to_ref_col = $ref->{toRef}{col};
			my $to_self = $ref->{toSelf};
			$c->update($to_self->{fieldset}{tab}, {$to_ref_col=>$id}, {$to_self->{col}=>$rel, $to_ref_col=>undef}, "LIMIT 1");
			delete $self->{rel_m2m};
			delete $self->{ref_m2m};
		}
	}
	
	$self
}

# сохраняет - смотрит, есть ли с таким id запись и обязательно сохраняет, даже если нет $self->{save}
sub store {
	my ($self) = @_;
	
	if(my $id = $self->{id} // $self->{save}{id}) {
		unless($::app->connect->query($self->Fieldset->{tab}, "1", {id=>$id})) {
			$self->{save}{id} = $id;
			$self->{id} = undef;
		} else {
			$self->{id} //= $self->{save}{id};
			delete $self->{save}{id};
		}
	}
	$self->save;
}

# сохраняет первую попавшуюся
# sub replace {
	# my ($self) = @_;
	# $::app->connect->replace($self->ToCol);
	# $self
# }

# помощник 
sub ToCol {
	my ($self) = @_;
	my $fieldset = $self->Fieldset;
	my $tab = $fieldset->{tab};
	my $field = $fieldset->{field};

	my $s = {};
	my $save = $self->{save};
	while(my ($k, $v) = each %$save) {
		#$v = $v->id if ref $v;
		$s->{$field->{$k}{col}} = $v;
	}
	$self->{save} = undef;
	return ($tab, $s);
}

# удаляет строку
sub erase {
	my ($self) = @_;
	die "нельзя удалить не созданную запись без id" unless $self->{id};
	my $fieldset = $self->Fieldset;
	my $name = $fieldset->{name};
	$::app->listener->fire("$name.erase", $self);
	$self->{noAction} = undef, return $self if $self->{noAction};
	$::app->connect->erase($fieldset->{tab}, {id => $self->{id}});
	$self->{id} = undef;
	$self
}

# ===== события =====
# все события выполняются перед sql-запросом
# отменить можно установив $self->{noAction} в 1
# создание таблицы
#sub onCreate {}
# удаление таблицы
#sub onDrop {}
# создание записи
#sub onAdd {}
# измение записи
#sub onUpdate {}
# сохранение записи - 2-й параметр: 1-add или 0-update
#sub onSave {}
# удаление записи
#sub onErase {}

1;