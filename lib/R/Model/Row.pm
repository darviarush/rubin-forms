package R::Model::Row;
# наследный класс для моделей. Представляет запись

use warnings;
use strict;

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
		$self->$k($v) if exists $field->{$k};
	}
	$self
}

# Наследуется в остальных
sub setup {}

# возвращает/устанавливает идентификатор
sub id {
	my ($self, $val) = @_;
	if(@_>1) { $self->{save}{id} = $val; $self }
	else { $self->save->{id} }
}


# деструктор
sub DESTROY {
	my ($self) = @_;
	$self->save;
}

# сохраняет, если есть что
sub save {
	my ($self) = @_;

	return $self unless $self->{save};
	
	my ($tab, $s) = $self->ToCol;
	
	my $c = $::app->connect;
	if($self->{id}) {
		$c->update($tab, $s, {id => $self->{id}});
	} else {
		$self->{id} = $c->append($tab, $s);
	}
	$self
}

# сохраняет - смотрит, есть ли с таким id запись 
sub store {
	my ($self) = @_;
	$::app->connect->store($self->ToCol);
	$self
}

# сохраняет первую попавшуюся
sub replace {
	my ($self) = @_;
	$::app->connect->replace($self->ToCol);
	$self
}

# помощник 
sub ToCol {
	my ($self) = @_;
	my $fieldset = $self->Fieldset;
	my $tab = $fieldset->{tab};
	my $field = $fieldset->{field};

	my $s = {};
	my $save = $self->{save};
	while(my ($k, $v) = each %$save) {
		$s->{$field->{$k}{col}} = $v;
	}
	$self->{save} = undef;
	return ($tab, $s);
}

# удаляет строку
sub erase {
	my ($self) = @_;
	$self->save;
	$::app->connect->erase($self->Fieldset->{tab}, {id => $self->{id}});
	$self->{id} = undef;
	$self
}




1;