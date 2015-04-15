package R::Model::Rowset;
# наборы моделей

use strict;
use warnings;

# конструктор
sub new {
	my ($cls, @args) = @_;
	if(ref $cls) {
		my $name = $cls->model;
		my $model = $::app->model;
		$model->$name(@args or undef);
	} else {
		bless {_find=>[]}, $cls;
	}
}

# возвращает филдсет
sub fieldset {
	$::app->{modelMetafieldset}{fieldset}{$_[0]->model}
}

# выбирает записи. Возвращает массив моделей или копию себя
sub find {
	my ($self, @filters) = @_;
	
	my $view = $self->{_view} // ["id"];
	$self->{_view} = undef;
	
	my $find = [@{$self->{_find}}, @filters];
	
	if(wantarray) {
		my $fieldset = $self->fieldset;
		my $ref = $::app->connect->query_all($fieldset->{tab}, $view, $self->_where($find));
		return map {bless $_, $self->modelClass} @$ref;
	}
	
	bless {_find=>$find}, ref $self;
}

# устанавливает view для find
sub view {
	my ($self, $view) = @_;
	$view = [split /\s*,\s*/, $view];
	unshift @$view, "id" unless grep {$_ eq "id" } @$view;
	$self->{_view} = $view;
	$self
}

# количество записей
sub count {
	my ($self, $view) = @_;
	$view //= "*";

	my $find = $self->{_find};
	
	$::app->connect->query($self->fieldset->{tab}, "count($view)", $self->_where);
}

# возвращает 
sub _where {
	my ($self, $find) = @_;
	$find //= $self->{_find};
	my $field = $self->fieldset->{field};
	my $q = {};
	for(my $i = 0; $i<@$find; $i+=2) {
		my $col = $find->[$i];
		$q->{$field->{$col}{col}} = $find->[$i+1];
	}
	return $q;
}

1;