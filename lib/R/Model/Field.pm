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
	my $Prop = ucfirst $self->{model};
	my $SUB = "R::Row::${Prop}::$name";
	my $SUBSET = "R::Rowset::${Prop}::$name";
	
	main::msg $SUB;
	
	no strict "refs";
	
	die "$SUB занят" if *{$SUB}{CODE};
	die "$SUBSET занят" if *{$SUBSET}{CODE};
	
	*{$SUB} = Utils::closure($self, $self->can("row"));
	*{$SUBSET} = Utils::closure($self, $self->can("rowset"));
	
	use strict "refs";
	
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

1;