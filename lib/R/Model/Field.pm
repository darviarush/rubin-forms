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

# создаёт метод в модели, если его ещё нет
sub add_method {
	my ($self, $prop, $alter) = @_;
	my $name = $self->{name};
	my $model = $self->{model};
	my $Prop = ucfirst $model;
	my $SUB = "R::Row::${Prop}::$name";
	my $SUBSET = "R::Rowset::${Prop}::$name";
	
	$prop //= "";
	
	main::msg $SUB, $prop;
	
	my $ref = $alter // $name;
	
	eval("
	sub $SUB {
		unshift \@_, '$ref';
		goto &R::Model::Row::_pp$prop;
	}
	sub $SUBSET {
		unshift \@_, '$ref';
		goto &R::Model::Row::_pp$prop;
	}
	");
	die "$SUB: ".($@ // $!) if $@ // $!;
	
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

1;