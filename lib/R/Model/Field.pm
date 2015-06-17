package R::Model::Field;
# поле таблицы

use strict;
use warnings;

Utils::has(qw/widget/);
Utils::has_const(qw/fieldset name model compute/);
Utils::has_array(qw/check/);


# конструктор
sub new {
	my ($cls, $fieldset, $name) = @_;
	
	my $self = bless {
		fieldset=>$fieldset,
		name=>$name,
		model=>$fieldset->{name},
		compute=>1,
		check=>[],
		widget=>{name => "input", args=>{}},
	}, $cls;
	
	push @{$fieldset->{fieldset}}, $fieldset->{field}{$name} = $self;
	
	$self->add_method;
	$self
}

# создаёт метод в модели
sub add_method {
	my ($self) = @_;
	my $name = $self->{name};
	
	return $self if $name eq "id" and $self->isa("R::Model::Field::Col");
	
	my $Prop = ucfirst $self->{model};
	my $SUB = "R::Row::${Prop}::$name";
	my $SUBSET = "R::Rowset::${Prop}::$name";
	
	my $cls = ref $self;
	$cls=~/([^:]+)$/;
	
	#main::msg "$1\t$self->{model}.$name";
	
	{no strict "refs";
	
		die "$SUB занят" if *{$SUB}{CODE};
		die "$SUBSET занят" if *{$SUBSET}{CODE};
		
		*{$SUB} = Utils::closure($self, $self->can("row"));
		*{$SUBSET} = Utils::closure($self, $self->can("rowset"));
	};
	
	$self
}

# удаляет из филдсета
sub delete {
	my ($self) = @_;
	my $fieldset = $self->{fieldset};
	delete $fieldset->{field}{$self->{name}};
	my $i=0;
	for my $field (@{$fieldset->{fieldset}}) {
		last if $field == $self;
		$i++;
	}
	splice @{$fieldset->{fieldset}}, $i, 1;
}

# возвращает row
sub bean {
	my ($self, @args) = @_;
	my $model = $self->{model};
	$::app->model->$model(@args);
}

# выдаёт краткую информацию о себе
sub info {"i"}

# добавляет комментарий
sub remark {
	my ($self, $comment) = @_;
	$self->{comment} = $comment;
	$self
}

# копирует себя и дополняет
sub copy {
	my ($self, @args) = @_;
	bless {like=>{}, %$self, @args}, ref $self;
}

# выполняется при извлечении столбца из upFld
sub deep_copy {
	my ($self, $upFld) = @_;
	$upFld->{like}{$self->{name}} = $self->copy(upFld=>$upFld, From=>$upFld->{From});
}

# проверяет, что такой есть и возвращает столбец
sub getlike {
	my ($self, $key) = @_;
	die "Попытка извлечь столбец из обычного столбца $self->{model}.$self->{name}.$key" unless $self->{Main};
	my $fld;
	die "нет столбца $self->{model}.$self->{name}.$key" unless $fld = $self->{fieldset}{field}{$key};
	#::msg ":cyan", "col!", ":reset", $self->model . "." . $self->name . ".$key";
	$fld->deep_copy($self)
}

# производит подобный
sub like {
	my ($self, $key) = @_;
	$self->{like}{$key} //= $self->getlike($key);
}

# строит join
sub join {
	my ($self, $to) = @_;
	my $c = $::app->connect;
	my $from = $self->{From};
	my $As = "A" . (1+@$from);
	my ($As0, $col) = $self->column;
	push @$from, "INNER JOIN " . $c->word($to->{tab}) . " As $As ON $As." . $c->word($to->{col}) . "=$As0." . $c->word($col);
	
	#::msg ":inline", ":red", "join!", ":reset", $self->name . " -> ", ":cyan", $sql;
	
	$As
}

# возвращает As и col
sub column {
	my ($self) = @_;
	return (($self->{upFld}? $self->{upFld}{As}: $self->{As}), $self->{col});
}

# возвращает строку, для column
sub prepare_column {
	my ($self) = @_;
	my $c = $::app->connect;
	my ($As, $col) = $self->column;
	my $from = $self->{From};
	(@$from!=1? "$As.": "") . $c->word($col)
}

1;