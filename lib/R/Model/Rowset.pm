package R::Model::Rowset;
# наборы моделей

use strict;
use warnings;

# конструктор
sub new {
	my ($cls, @args) = @_;
	if(ref $cls) {
		my $name = $cls->model;
		my $bean = $::app->model->$name(@args or {});
		$bean
	} else {
		bless {find=>[]}, $cls;
	}
}

# возвращает филдсет
sub fieldset {
	$::app->{modelMetafieldset}{fieldset}{$_[0]->model}
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
	push @{$self->{find}}, @filters;
	wantarray? $self->_rows: $self
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
	$::app->connect->query($self->fieldset->{tab}, "count($view)", $self->_where);
}

# выбирает объекты
my %operators = qw(eq = ne <> lt < le <= gt > ge >= in in like like ilike ilike between between regexp regexp);
sub _rows {
	my ($self, $view) = @_;
	$view //= 'id';
	
	my $meta = $::app->{modelMetafieldset};
	my $fieldset = $meta->{cls}{$self->modelClass};
	
	my $find = $self->find;
	
	my %like;	# подобные ключи
	my (@from, @where);
	
	for(my $i=0; $i<@$find; $i+=2) {
		my ($key, $val) = @$find[$i, $i+1];
		
		my @key = split /__/, $key;
		my $op = $operators{$key[$#key]};
		pop @key if $op;

		my $field = $fieldset->{field}{$key[0]};
		my ($from, $where) = $field->from_sql(\@key, $val, \%like);
		push @from, @$from;
		push @where, @$where;
	}
	
	my $sql = "SELECT id FROM " . $c->word($fieldset->{tab}) . ;
	
	my $fieldset = $self->fieldset;
	#my $ref = $::app->connect->{db}->query_all($fieldset->{tab}, $view, $self->_where($self->{find}));
	my $cls = $self->modelClass;
	return map {bless $_, $cls} @$ref;
}

# возвращает find c переименованными столбцами
sub _where {
	my ($self, $find) = @_;
	$find //= $self->{find};
	my $field = $self->fieldset->{field};
	my $q = {};
	for(my $i = 0; $i<@$find; $i+=2) {
		my $col = $find->[$i];
		$q->{$field->{$col}{col}} = $find->[$i+1];
	}
	return $q;
}

# возвращает from и where
sub _sql {
	my ($self, $branch) = @_;	# branch - ветка
	my $i = 0;	# номер ветки
	my ($from, $where) = ([], []);
	for my $rel (@{$self->{rel}}) {
		$i++;
		if(ref $rel) {
			my ($from1, $where1) = $rel->sql;
			
		} else {
			
		}
	}
	return ($from, $where);
}

# определяет что метод делает и заменяет его
# sub AUTOLOAD {
	# our $AUTOLOAD =~ /([^:]+)$/;
	# my $prop = $1;
	# my $Prop = ucfirst $prop;
	
	# my $eval = "sub $AUTOLOAD { \@_>1? R::Row::$Prop->new(\@_[1..\$#_]): R::Rowset::$Prop->new }";
	# eval $eval;
	# die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	# no strict "refs";
	# my $sub = *{$AUTOLOAD}{CODE};
	# use strict "refs";
# }

sub DESTROY {}

1;