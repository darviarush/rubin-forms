package R::Listener;
# обработчик событий

use common::sense;
use R::App;

# конструктор
sub new {
	my ($self) = @_;
	bless {listen=>{}}, $cls;
}

# установка слушателя
sub on {
	my ($self, $on, @listen) = @_;
	$self->{lastKey} = $on;
	my @on = split /\s*,\s*/, $on;
	for my $on (@on) {
		if($on =~ s/^-//) { unshift @{$self->{listen}{$on}}, @listen }
		else { push @{$self->{listen}{$on}}, @listen }
	}
	$self
}


# установка слушателя
sub then (&) {
	my ($self, @listen) = @_;
	$self->on($self->{lastKey}, @listen);
}


# удаление слушателя
sub off {
	my ($self, $on, @listen) = @_;
	my @on = split /\s*,\s*/, $on;
	if(@listen) {
		for $on (@on) {
			my $list = $self->{listen}{$on};
			for(my $i=0; $i<@$list; $i++) {
				my $listen = $list->[$i];
				splice @$list, $i, 1 if grep { $listen == $_ } @listen;
			}
		}
	} else {
		delete $self->{listen}{$_} for @on;
	}
	$self
}

# сообщение
sub fire {
	my ($self, $on, @args) = @_;
	my @on = split /\s*,\s*/, $on;
	for my $on (@on) {
		my $list = $self->{listen}{$on};
		next unless $list;
		for my $listen (@$list) {
			$listen->(@args);
			$self->{"stopFire"} = undef, last if $self->{"stopFire"};
		}
	}
	$self
}

# останавливает цепочку выполнения
sub stop {
	my ($self) = @_;
	$self->{"stopFire"} = 1;
	$self
}

# проверяет - есть ли цепочка
sub exists {
	my ($self, $on) = @_;
	!!$self->{$on};
}

1;