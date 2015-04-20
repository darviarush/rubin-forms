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
		else {
			# если нет id, то создаёт перед compute или геттере, а сеттер - забрасывает в set и сохраняет перед compute или при геттере
			my $bean = bless {id => $id->{id}}, $cls;
			
			my $field = $::app->{modelMetafieldset}{cls}{$cls}{field};
			while(my($k, $v) = each %$id) {
				$bean->$k($v) if exists $field->{$k};
			}
			$bean->{save} //= {};
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
	if(@_>1) { $self->{save}{id} = $val; $self }
	else { $self->save->{id} }
}


# проверяет - надо ли сохранять и вызывает store
sub save {
	my ($self) = @_;
	my $save = $self->{save};
	if($save) {
		$self->{save} = undef;
		$self->store($save);
	} elsif(!defined $self->{id}) {
		$self->store;
	}
	$self
}

# деструктор
sub DESTROY {
	my ($self) = @_;
	my $save = $self->{save};
	if($save) {
		$self->store($save);
	}
}

# сохраняет
sub store {
	my ($self, $save) = @_;

	my $fieldset = $self->Fieldset;
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
	$::app->auth->erase($self->Fieldset->{tab}, {id => $self->{id}});
	$self->{id} = undef;
	$self
}




1;