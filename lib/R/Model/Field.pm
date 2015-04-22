package R::Model::Field;
# поле таблицы

use strict;
use warnings;

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
		check=>[]
	}, $cls;
	
	push @{$fieldset->{fieldset}}, $fieldset->{field}{$name} = $self;
	
	$self->add_method
}

# создаёт метод в модели
sub add_method {
	my ($self, $prop, $alter) = @_;
	my $name = $self->{name};
	
	return $self if $name eq "id" and $self->isa("R::Model::Field::Col");
	
	my $Prop = ucfirst $self->{model};
	my $SUB = "R::Row::${Prop}::$name";
	my $SUBSET = "R::Rowset::${Prop}::$name";
	
	main::msg $SUB;
	
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

# копирует себя и дополняет
sub copy {
	my ($self, @args) = @_;
	bless {like=>{}, %$self, @args}, ref $self;
}

# производит подобный
sub like {
	my ($self, $key) = @_;
	my $fld = $self->{like}{$key};
	unless($fld) {
		die "нет столбца $key у $self->{model}".($self->{As}? " as $self->{As}": "")." при запросе у $self->{name}" unless $fld = $self->{fieldset}{field}{$key};
		$fld = $fld->copy(upFld=>$self);
	}
	$fld
}

# строит join
sub join {
	my ($self, $to, $from) = @_;
	my $c = $::app->connect;
	$to->{As} = "A" . (1+@$from);
	push @$from, "INNER JOIN " . $c->word($to->{tab}) . " As $to->{As} ON $to->{As}." . $c->word($to->{col}) . "=$self->{As}." . $c->word($self->{col});
	$self
}


1;