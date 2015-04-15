package R::Model::Row;
# наследный класс для моделей. Представляет запись

use warnings;
use strict;

our %compute;

# конструктор
# app->model->compute
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
			$id = $id->{id};
		}
		else {
			# если нет id, то создаёт перед compute или геттере, а сеттер - забрасывает в set и сохраняет перед compute или при геттере
			my $bean = bless {id => $id->{id}}, $cls;
			
			my $field = $::app->{modelMetafieldset}{cls}{$cls}{field};
			while(my($k, $v) = each %$id) {
				$bean->$k($v) if exists $field->{$k};
			}
			return $bean;
		}
	}
	bless {id=>$id}, $cls;
}

# Наследуется в остальных
sub setup {}

# возвращает/устанавливает идентификатор
sub id {
	my ($self, $val) = @_;
	if(@_>1) { $::app->model->{ref $self}{id} = $val; $self }
	else { $self->save->{id} }
}

# устанавливается свойство в set, при возврате любого свойства - сохраняется

# свойство
sub _pp {
	my ($name, $self, $val) = @_;
	if(@_>2) {
		main::msg 'set', ref($self), $name, $val;
		$::app->model->{ref $self}{$name} = $val;
		$self
	}
	else {
		main::msg 'get', ref($self), $name;
		$self->save;
		my $c = $::app->connect;
		my $field = $::app->{modelMetafieldset}{cls}{ref $self}{field}{$name};
		$c->query($field->{tab}, [$field->{col}], {id=>$self->{id}})
	}
}

# свойство ссылки
sub _pp_ref {
	my ($name, $self, $val) = @_;
	if(@_>2) {
		main::msg 'ref-set', ref($self), $name, $val;
		$val = {@_[2..$#_]} if @_>3;
		if(ref $val) {
			my $field = $::app->{modelMetafieldset}{cls}{ref $self}{field}{$name};
			my $model = $field->{ref};
			my $bean = $::app->model->$model($val);
			$self->save if !$bean->{id};
			$val = $bean->{id};
		}
		
		$::app->model->{ref $self}{$name} = $val;
		$self
	}
	else {
		main::msg 'ref-get', ref($self), $name, $val;
		my $id = _pp($name, $self);
		$::app->model->$name($id)
	}
}

# свойство обратной ссылки
sub _pp_back_ref {
	my ($name, $self) = @_;
	my $bk = $::app->{modelMetafieldset}{cls}{ref $self}{field}{$name};
	my $ref = $bk->{ref};
	my $model = $ref->{model};
	$self->save if !$self->{id};
	$::app->model->$model->find($ref->{name} => $self->{id});
}

# свойство m2m
sub _pp_m2m {
	my ($name, $self, $val) = @_;
	
}

# вычислимое свойство
sub _pp_compute {
	my ($name, @args) = @_;
	my $self = $args[0];
	$compute{ref $self}{$name}->(@args);
}


# проверяет - надо ли сохранять и вызывает store
sub save {
	my ($self) = @_;
	my $model = $::app->model;
	my $save = $model->{ref $self};
	if($save) {
		$model->{ref $self} = undef;
		$self->store($save);
	} elsif(!defined $self->{id}) {
		$self->store;
	}
	$self
}

# деструктор
sub DESTROY {
	my ($self) = @_;
	my $model = $::app->model;
	my $save = $model->{ref $self};
	if($save) {
		$model->{ref $self} = undef;
		$self->store($save);
	}
}

# сохраняет
sub store {
	my ($self, $save) = @_;

	my $fieldset = $::app->{modelMetafieldset}{cls}{ref $self};
	my $tab = $fieldset->{tab};
	my $field = $fieldset->{field};

	my $s = {};
	if($save) {
		while(my ($k, $v) = each %$save) {
			$s->{$field->{$k}{col}} = $v;
		}
	}
	
	my $c = $::app->connect;
	if($self->{id}) {
		$c->update($tab, $s, {id => $self->{id}});
	} else {
		$self->{id} = $c->append($tab, $s);
	}
	$self
}

# удаляет строку
sub erase {
	my ($self) = @_;
	my $fieldset = $::app->{modelMetafieldset}{cls}{ref $self};
	$::app->auth->erase($fieldset->{tab}, {id => $self->{id}});
}


1;