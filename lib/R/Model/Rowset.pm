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
	
	my ($id) = $self->_all;
	for my $val (@row) {
		$self->bean($val)->{save}{} = $id;
	}
	$self
}


# выбирает записи. Возвращает массив моделей или копию себя
sub find {
	my ($self, @filters) = @_;
	my $bean = bless {find=>[@{$self->{find}}, @filters]}, ref $self;
	wantarray? $bean->_rows: $bean;
}

# выбирает много столбцов
sub view {
	my ($self, $view) = @_;
	$view = [split /\s*,\s*/, $view] unless ref $view;
	unshift @$view, "id" unless grep {$_ eq "id" } @$view;
	$self->_rows($view);
	$self
}

# количество записей
sub count {
	my ($self, $view) = @_;
	$view //= "*";
	
	my $from = [];
	my $where = join "", $self->_where($from);
	
	$::app->connect->query($from, "count($view)", $where);
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

# возвращает id
sub _all {
	my ($self) = @_;
	my $from = [];
	my $where = join "", $self->_where($from);
	
	@{$::app->connect->query_all($from, "A1.id", $where)};
}

# возвращает bean
sub _rows {
	my ($self) = @_;
		#my $view = $self->{view} // "id";
	my $cls = ref $self;
	$cls =~ s/::Rowset::/::Row::/;
	map {bless $_, $cls} $self->_all;
}

# возвращает find c переименованными столбцами
sub _where {
	my ($self, $from, $N, $Ncol, $like) = @_;
	my $find = $self->{find};
	my $fieldset = $self->Fieldset;
	my $field = $fieldset->{field};
	
	#::msg $N, $fieldset->{name} . "->" . join ", ", @$find;

	$like //= {};
	my $c = $::app->connect;
	
	my $tab = $c->word($fieldset->{tab});	
	
	my $A = "A" . (1+@$from);
	push @$from, defined($N)? "INNER JOIN $tab As $A ON $N=$A.$Ncol": "$fieldset->{tab} As $A";
	
	my @where;
	
	for(my $i = 0; $i<@$find; $i+=2) {
		my ($key, $val) = @$find[$i, $i+1];
		
		$key = $`, $val = $self->find($' => $val) if $key =~ /__/;
		
		my $fld = $field->{$key};
		die "нет поля $key в $fieldset->{name}" unless $fld;

		my $col = $fld->{col};
		my ($NA);
		if(defined $col) { $NA = "$A.id"; $col = $c->word($col); }
		else { $NA = "$A.id"; $col = $c->word($fld->{ref}{col}); }
		
		if(ref $val) {
			if(Utils::isa($val, "R::Model::Row")) {
				$val->store if !$val->{id};
				$val = $val->{id};
			} elsif(Utils::isa($val, "R::Model::Rowset")) {
				push @where, $val->_where($from, $NA, $col);
				next;
			}
		}
		
		push @where, (@where? " AND ": ()), $A, ".", $col, "=", $c->quote($val);
	}
	
	#$from->[0] = $fieldset->{tab} if @$from == 1;
	
	return @where;
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

1;