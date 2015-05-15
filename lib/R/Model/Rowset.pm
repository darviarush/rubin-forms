package R::Model::Rowset;
# наборы моделей

use strict;
use warnings;

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
sub erase {
	
}


# выбирает записи. Возвращает массив моделей или копию себя
sub find {
	my ($self, @filters) = @_;
	my $bean = bless {find=>[@{$self->{find}}, @filters]}, ref $self;
	wantarray? $bean->_rows: $bean;
}

# выбирает много столбцов
sub view {
	my ($self, @view) = @_;
	$self->{view} = [@view];
	
	#unshift @$view, "id" unless grep {$_ eq "id" } @$view;
	wantarray? $self->_rows: $self;
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
	if(@_==3) {
		$self->{offset} = $limit;
		$self->{limit} = $_[2];
	}
	else {
		$self->{limit} = $limit;
	}
	wantarray? $self->_rows: $self;
}

# выборка страницы начиная с 1
sub page {
	my ($self, $page, $size) = @_;
	$self->{offset} = ($page-1) * $size;
	$self->{limit} = $size;
	$self
}

# количество записей
sub count {
	my ($self, $view) = @_;
	$view //= "*";
	my ($count) = $self->_all("count($view) as count");
	$count->{count}
}

######################################################### Выборки #########################################################

# возвращает id
sub _all {
	my ($self, $view) = @_;
	
	my $c = $::app->connect;
	
	#my $find = $self->{find};
	#if(@$find == 2 && )
	
	my $fld = $self->Field->{id}->copy(As=>"A1");
	my $from = [$c->word($fld->{tab}) . " As $fld->{As}"];
	
	# if(!$view && $self->{view}) {
		# my $find = $self->{find};
		# $self->{find} = [map {} $self->{view}]
		# my @view = $self->_where($from, $fld);
		# $self->{find} = $find;
	# }
	
	my $where = join " AND ", map {
		my $col = $_->{col};
		my $val = $_->{val};
		join "", (@$from==1? (): ($_->{As} // $_->{upFld}{As}, ".")), $c->word($col), "=", $c->quote($val);
	} $self->_where($from, $fld);
	
	$view //= (@$from!=1? "$fld->{As}.": "") . $c->word($fld->{col});
	
	$from = $c->word($fld->{tab}) if @$from == 1;
	
	@{$::app->connect->query_all($from, $view, $where)};
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
	my ($self, $from, $fromFld) = @_;
	my $find = $self->{find};
	
	my @where;
	
	for(my $i = 0; $i<@$find; $i+=2) {
		my ($key, $val) = @$find[$i, $i+1];
		
		my $fld;
		if($key =~ /__/) {
			$key = $`;
			my $next_key = $';
			$fld = $fromFld->like($key);
			$val = $fld->bean->find($next_key => $val);
		} else {
			$fld = $fromFld->like($key);
		}
		
		if(Utils::isa($fld, "R::Model::Field::M2m")) {
			$val = $fld->toSelf->bean->find($fld->{toRef}{name} => $val);
			$fld = $fromFld->like($fld->{toSelf}{back}{name});
		}
		
		if(Utils::isa($fld, "R::Model::Field::Back") && !$fld->{As}) {
			my $ref = $fld->ref->copy(upFld=>$fromFld);
			$fromFld->join($ref, $from);
			$fld = $fromFld->{like}{$fld->{name}} = $ref;
		}
		
		if(ref $val) {
			if(Utils::isa($val, "R::Model::Row")) {
				$val->save if !$val->{id};
				$val = $val->{id};
			} elsif(Utils::isa($val, "R::Model::Rowset")) {
				$fromFld->join($fld, $from) unless $fld->{As};
				push @where, $val->_where($from, $fld);
				next;
			}
		}
		
		die "val уже есть: $fld->{model}.$fld->{name}=$fld->{val}" if exists $fld->{val};
		$fld->{val} = $val;
		push @where, $fld;
		# my $col = $fld->{col};
		# my $As = $fld->{As} // $fld->{upFld}{As};
		# push @where, (@where? " AND ": ()), $As, ".", $c->word($col), "=", $c->quote($val);
	}
	
	#$from->[0] = $fieldset->{tab} if @$from == 1;
	
	return @where;
}


1;