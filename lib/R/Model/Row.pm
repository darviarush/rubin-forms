package R::Model::Row;
# наследный класс для моделей. Представляет запись

use warnings;
use strict;

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
			die "попытка изменить id";
			$self->{save}{id} = $val;
			$self->save;
		} else {
			$self->{id} = $val;
		}
		$self
	}
	else { $self->save if !$self->{id}; $self->{id} }
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
	my ($id, $rel);
	if($id = $self->{id}) {
		$c->update($tab, $s, {id => $id});
		if($id = $s->{id}) {
			$rel->{save}{$self->{ref}} = $id if $rel = $self->{rel};
			$self->{id} = $id;
		}
	} else {
		$id = $self->{id} = $c->append($tab, $s);
		$rel->{save}{$self->{ref}} = $id if $rel = $self->{rel};
	}
	$self
}

# сохраняет - смотрит, есть ли с таким id запись и обязательно сохраняет, даже если нет $self->{save}
sub store {
	my ($self) = @_;
	
	if(my $id = $self->{id} // $self->{save}{id}) {
		unless($::app->connect->query($self->Fieldset->{tab}, "1", $id)) {
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
	$self->save;
	$::app->connect->erase($self->Fieldset->{tab}, {id => $self->{id}});
	$self->{id} = undef;
	$self
}

1;