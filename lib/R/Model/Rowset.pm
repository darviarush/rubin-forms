package R::Model::Rowset;
# наборы моделей

use strict;
use warnings;

require POSIX;

# конструктор
sub new {
	my ($cls, @args) = @_;
	if(ref $cls) {
		my $bean = $cls->Model(undef);
		$bean->FromHash(@args==1? {id=>$args[0]}: (@args or {}));
	} else {
		bless {find=>[]}, $cls;
	}
}

# возвращает id
sub id {
	my ($self) = @_;
	if(@_>1) {
		die "попытка проапдейтить столбец id";
	} else {
		my $ref = $self->view("id");
		wantarray? @{$ref->_col_ref}: @{$ref->limit(1)->_col_ref};
	}
}

# добавляет записи в m2m
sub add {
	my ($self, @row) = @_;
	
	my $m2m = $self->Field->{$self->{find}[0]};
	my $ref_val = $self->{find}[1];
	
	$ref_val = $m2m->toRef->ref->bean($ref_val)->id if ref $ref_val;

	my $ref = $m2m->{toRef}{col};
	my $back = $m2m->{toSelf}{col};
	my $mod = $m2m->{toSelf}{ref};
	my @matrix;
	for my $val (@row) {
		my $bean = $mod->bean($val);
		$bean->save if !$bean->{id};
		push @matrix, [$ref_val, $bean->{id}];
	}
	
	my $c = $::app->connect;
	$c->insert($m2m->{toRef}{tab}, [$ref, $back], \@matrix);
	
	$self
}

# удаляет записи из m2m
sub del {
	my ($self, @row) = @_;
	
	die "доделать!";
	
	my ($m2m, $ref_val) = @{$self->{find}};
	$m2m = $self->Field->{$m2m};
	
	my $c = $::app->connect;
	$c->erase($m2m->{toRef}{tab}, {});
	$self
}

# создаёт копию себя заменяя ключи
sub _clone {
	my ($self, @args) = @_;
	my $bean = bless {%$self, @args}, ref $self;
	wantarray? $bean->_rows: $bean;
}

# выбирает записи. Возвращает массив моделей или копию себя
sub find {
	my ($self, @filters) = @_;
	$self->_clone(find => [@{$self->{find}}, @filters]);
}

# выбирает много столбцов
sub view {
	my ($self, @view) = @_;
	$self->_clone(view => [($self->{view}? @{$self->{view}}: ()), @view]);
}

# сортировка записей
sub order {
	my ($self, @order) = @_;
	$self->_clone(order => [($self->{order}? @{$self->{order}}: ()), @order]);
}

# offset
sub offset {
	my ($self, $offset) = @_;
	$self->_clone(offset => $offset);
}

# limit
sub limit {
	my ($self, $limit) = @_;
	$self->_clone(@_==3? (offset => $limit, limit => $_[2]): (limit => $limit));
}

# выборка страницы начиная с 1
sub page {
	my ($self, $page, $size) = @_;
	$size //= $self->Fieldset->{paging} // $::app->{modelMetafieldset}{paging};
	$self->_clone(offset => ($page-1) * $size, limit => $size);
}

# количество страниц
sub pages {
	my ($self, $size) = @_;
	$size //= $self->Fieldset->{paging} // $::app->{modelMetafieldset}{paging};
	POSIX::ceil($self->count / $size);
}


# основная функция для count, max и др. функций агрегации
sub __FN__ {
	my ($name, $self, $_view) = @_;
	$_view //= "*";
	my ($from, $view, $where) = $self->_query("$name($_view) as $name");
	$::app->connect->query($from, $view, $where);
}


# количество записей
sub count {	unshift @_, "count"; goto &__FN__; }
# и так понятно:
sub sum { unshift @_, "sum"; goto &__FN__; }
sub avg { unshift @_, "avg"; goto &__FN__; }
sub max { unshift @_, "max"; goto &__FN__; }
sub min { unshift @_, "min"; goto &__FN__; }

# добавляет having
sub having {
	my ($self, @having) = @_;
	$self->_clone(having => [($self->{having}? @{$self->{having}}: ()), @having]);
}

# добавляет группировку записей
sub aggregate {
	my ($self, @aggregate) = @_;
	$self->_clone(aggregate => [($self->{aggregate}? @{$self->{aggregate}}: ()), @aggregate]);
}


# выдаёт аннотацию - хэш с данными и произвольными полями
sub annotate {
	my ($self, @annotate) = @_;
	$self->view(@annotate)->_all;
}

# вставить выбранные записи в указанную таблицу
sub insert_into {
	
}

# проапдейтить записи
sub update {
	my ($self, @set) = @_;
	my ($from, $view, $where) = $self->_query("");
	my $c = $::app->connect;
	$c->update($from, {@set}, $where);
}

# удалить выбранные записи (rel?)
sub erase {
	my ($self) = @_;
	my $fieldset = $self->Fieldset;
	my $name = $fieldset->{name};
	my $listener = $::app->listener;
	if( $listener->exists("$name.erases") ) {
		$listener->fire("$name.erases", $self);
		return $self if $self->{noAction};
	} elsif( $listener->exists("$name.erase") ) {
		for my $bean ($self->find) {
			$listener->fire("$name.erase", $bean);
			return $self if $bean->{noAction};
		}
	}
	
	my $c = $::app->connect;
	
	$c->erase($fieldset->{tab}, {id => $self->_col_ref});
	
	$self
}


######################################################### Выборки #########################################################

# возвращает "сырой" sql-запрос
sub _query {
	my ($self, $view) = @_;
	
	#::msg ":red", ":inline", $self;
	
	my $c = $::app->connect;
	
	my $from = [];
	my $fld = $self->Field->{id}->copy(As=>"A1", From=>$from, Main=>1);
	push @$from, $c->word($fld->{tab}) . " As $fld->{As}";
	
	my @where = $self->_where($fld);

	my $find = $self->{find};
	
	my @view;	
	if(!$view && $self->{view}) {
		$self->{find} = [map {($_ => 1)} @{$self->{view}}];
		@view = $self->_where($fld);
	}

	my @aggregate;
	if($self->{aggregate}) {
		$self->{find} = $self->{aggregate};
		@aggregate = $self->_where($fld);
	}
	
	my @having;
	if($self->{having}) {
		$self->{find} = $self->{having};
		@having = $self->_where($fld);
	}
	
	
	my @order;
	if($self->{order}) {
		$self->{find} = [map { my $desc = s/^-//; ($_ => $desc)} @{$self->{order}}];
		@order = $self->_where($fld);
	}
	
	$self->{find} = $find;
	
	# пошли
	my $sep = @$from==1? " ": "\n";
	
	if(@view) {
		$view = join ", ", map { $_->prepare_column	} @view;
	} else {
		$view //= $fld->prepare_column;
	}
	
	my $FILTER = sub {
		my $op = $_->{op};
		my $val = $_->{val};
		
		if(!defined $val) {
			$op = $op eq "="? " IS ": " IS NOT ";
			$val = "NULL";
		}
		elsif(ref $val eq "ARRAY" and $op eq " BETWEEN ") {
			$val = $c->quote($val->[0]) . " AND " . $c->quote($val->[1]);
		} elsif(ref $val eq "ARRAY") {
			$op = " IN ";
			$val = $c->quote($val);
		} elsif($op =~ /^[+-]$/) {
			$val =~ s/[_%]/\\$&/g;
			if($op eq "-") { $val = "%$val" } else { $val .= "%" }
			$val = $c->quote($val);
			$op = " LIKE ";
		} else {
			$val = $c->quote($val);
		}
		
		join "", $_->prepare_column, $op, $val;
	};
	
	my $where = join " AND ", map { $FILTER->() } @where;
	
	if(@aggregate) {
		$where .= "${sep}GROUP BY " . join ", ", map { $_->prepare_column } @aggregate;
	}
	
	if(@having) {
		$where .= "${sep}HAVING " . join " AND ", map { $FILTER->() } @having;
	}
	
	if(@order) {	
		$where .= "${sep}ORDER BY " . join ", ", map {
			my $desc = $_->{val};
			$_->prepare_column . ($desc? " DESC": "");
		} @order;
	}
	
	$where .= $sep . "LIMIT " . ($self->{offset}? (0+$self->{offset}) . ", ": "") . (0+$self->{limit}) if $self->{limit};
	
	$from = $c->word($fld->{tab}) if @$from == 1;
	
	#::msg "fff:", $from, $view, $where;
	
	return $from, $view, $where;
}

# возвращает массив хешей
sub _all {
	my ($self, $_view) = @_;
	my ($from, $view, $where) = $self->_query($_view);
	my $ref = $::app->connect->query_all($from, $view, $where);
	wantarray? @$ref: $ref;
}

# возвращает массив значений
sub _col_ref {
	my ($self, $_view) = @_;
	my ($from, $view, $where) = $self->_query($_view);
	$::app->connect->query_col($from, $view, $where);
}

# возвращает beans
sub _rows {
	my ($self) = @_;
	#my $view = $self->{view} // "id";
	my $cls = ref $self;
	$cls =~ s/::Rowset::/::Row::/;
	map {bless $_, $cls} $self->_all;
}

our %OP = ("ne"=>"<>", "lt"=>"<", "le"=>"<=", "gt"=>">", "ge"=>">=", "like"=>" LIKE ", "ilike"=>" ILIKE ", "between"=>" BETWEEN ", "regexp"=>" REGEXP ", "iregexp" => " IREGEXP ", "startswith" => "+", "endswith" => "-");

# возвращает find c переименованными столбцами
sub _where {
	my ($self, $fromFld) = @_;
	my $find = $self->{find};
	
	my @where;
	
	for(my $i = 0; $i<@$find; $i+=2) {
		my ($key, $val) = @$find[$i, $i+1];
		
		# if(ref $val and Utils::isa($val, "R::Model::Row")) {
			# $val->save if !$val->{id};
			# $val = $val->{id};
		# }
		
		#::msg ":inline", ":green", "$fromFld->{model}.$fromFld->{name}", ":reset", $key, $val;
		
		my $fld;
		my $op = "=";
		if($key =~ /__/) {
			$key = $`;
			my $next_key = $';
			$fld = $fromFld->like($key);
			if(exists $OP{$next_key}) { $op = $OP{$next_key} }
			else { $val = $fld->bean->find($next_key => $val) }
		} else {
			$fld = $fromFld->like($key);
		}
		
		if(ref $val and Utils::isa($val, "R::Model::Rowset")) {
			push @where, $val->_where($fld);
			next;
		}
		
		#die "val уже есть: $fld->{model}.$fld->{name}=$fld->{val}" if exists $fld->{val};
		$fld = $fld->copy if exists $fld->{val};	# расщепляем
		$fld->{val} = $val;
		$fld->{op} = $op;
		#$fld->deadlock;			# конечный филд
		push @where, $fld;
	}
	
	return @where;
}


1;