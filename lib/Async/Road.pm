package R::Road;
# дорога для асинхронного выполнения

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		Road => [],
		RoadEssence => [],
	}, ref $cls || $cls;
}

# отправляет по дороге значение (сущность)
sub essence {
	my ($self, $chunk) = @_;
	my $args = [$chunk];
	my $ret = [];
	for my $code (@{$self->{Road}}) {
		for(@$args) {
			push @$ret, $code->();
		}
		$args = $ret;
	}
	push @{$self->{RoadEssence}}, @$args;
	$self;
}


# запускает дорогу
sub start {
	my $self = shift;
	local $_;
	my $essences = $self->{RoadEssence};
	$self->{RoadEssence} = [];
	$self->essence($_) for @$essences;
	@{$self->{RoadEssence}}
}


# если конец дороги - запускает её
sub end {
	my ($self) = @_;
	wantarray? $self->start: $self;
}

# добавляет в начальные данные
sub push (@) {
	my $self = shift;
	push @{$self->{RoadEssence}}, @_;
	$self;
}


# добавляет в дорогу фильтр
sub grep (&) {
	my ($self, $code) = @_;
	push @{$self->{Road}}, +(sub {
		my $code = shift;
		sub {
			my $val=$_;
			$code->()? $val: ();
		}
	})->($code);
	$self->end;
}

# добавляет в дорогу функцию
sub then (&) {
	my ($self, $code) = @_;
	push @{$self->{Road}}, $code;
	$self->end;
}



# аналог then
sub map {goto &then}

# аналог grep
sub filter {goto &grep}


# оборачивает метод в указанный
# sub road {
	# my ($name, $method) = @_;
	## получить метод
	# my ($class) = caller(0);
	
	
	# +(sub {
		# my $code = shift;
		# sub {
			# my $val=$_;
			# $code->()? $val: ();
		# }
	# })->($code);
# }


1;
