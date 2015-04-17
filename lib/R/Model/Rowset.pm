package R::Model::Rowset;
# наборы моделей

use strict;
use warnings;

# конструктор
sub new {
	my ($cls, @args) = @_;
	if(ref $cls) {
		my $bean = $cls->Model(@args or {});
		$bean
	} else {
		bless {find=>[]}, $cls;
	}
}

# добавляет записи
# 1. создать модели
sub add {
	my ($self, @row) = @_;
	
	my $rel = $self->{rel};
	for my $val (@row) {
		
	}
}


# выбирает записи. Возвращает массив моделей или копию себя
sub find {
	my ($self, @filters) = @_;
	my $bean = bless {find=>[@{$self->{find}}, @filters]}, ref $self;
	wantarray? $bean->Rows: $bean;
}

# выбирает много столбцов
sub view {
	my ($self, $view) = @_;
	$view = [split /\s*,\s*/, $view] unless ref $view;
	unshift @$view, "id" unless grep {$_ eq "id" } @$view;
	$self->Rows($view);
	$self
}

# количество записей
sub count {
	my ($self, $view) = @_;
	$view //= "*";
	$::app->connect->query($self->Fieldset->{tab}, "count($view)", $self->_where);
}

# offset
sub offset {
	my ($self, $offset) = @_;
	$self->{offset} = $offset;
	$self
}

# limit
sub limit {
	my ($self, $limit) = @_;
	$self->{limit} = $limit;
	$self
}

# выборка страницы начиная с 1
sub page {
	my ($self, $page, $size) = @_;
	$self->{offset} = ($page-1) * $size;
	$self->{limit} = $size;
	$self
}

######################################################### Выборки #########################################################

# возвращает find c переименованными столбцами
sub _where {
	my ($self, $find) = @_;
	$find //= $self->{find};
	my $field = $self->Field;
	my $q = {};
	for(my $i = 0; $i<@$find; $i+=2) {
		my ($key, $val) = @$find[$i, $i+1];
		
		if(ref $val) {
			if(Utils::isa($val, "R::Model::Row")) {
				$val->store if !$val->{id};
				$val = $val->{id};
			} elsif(Utils::isa($val, "R::Model::Rowset")) {
				
			}
		}
		
		$q->{$field->{$key}{col}} = $val;
	}
	return $q;
}



#require R::Model::Query;

# выбирает объекты
# sub Rows {
	# my ($self) = @_;
	# my $view = 'id';
	
	# my $fields = $self->Field;
	
	# my $find = $self->{find};
	# my %like;
	# my (@from, @where);
	
	# for(my $i=0; $i<@$find; $i+=2) {
		# my ($key, $val) = @_;
		
		# my @key = split /__/, $key;
		
		# $fields->{$key[0]}->form(\@key, $val, \%like);
		# push @from, $query->from;
		# push @where, $query->where;
	# }
	
	# my $ref = $::app->connect->query_all(join("", @from), $view, join "", @where);
	# my $cls = ref $self;
	# $cls =~ s/::Rowset::/::Row::/;
	# return map {bless $_, $cls} @$ref;
# }


# возвращает from и where
# sub _sql {
	# my ($self, $branch) = @_;	# branch - ветка
	# my $i = 0;	# номер ветки
	# my ($from, $where) = ([], []);
	# for my $rel (@{$self->{rel}}) {
		# $i++;
		# if(ref $rel) {
			# my ($from1, $where1) = $rel->sql;
			
		# } else {
			
		# }
	# }
	# return ($from, $where);
# }



######################################################### Свойства #########################################################

# свойство
sub _pp {
	my ($name, $self) = @_;
	my $rows = $self->view($name);
	wantarray? $rows->Rows: $rows
}

# ссылка
sub _pp_ref {
	# my ($name, $self) = @_;
	# my $rows = $self->view($name);
	# wantarray? $rows->Rows: $rows
}


1;