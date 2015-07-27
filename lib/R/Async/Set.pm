package R::Async::Set;
# oop функции приведения

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

# oop grep
sub grep {
	my ($self, $code) = @_;
	my $ret = [];
	do { push @$ret, $_ if $code->() } for @$self;
	bless $ret, ref $self;
}

# oop map
sub map {
	my ($self, $code) = @_;
	my $ret = [];
	push @$ret, $code->() for @$self;
	bless $ret, ref $self;
}

# oop reduce
sub reduce {
	my ($self, $code) = @_;
	$a = $self->[0];
	do { $b=$_, $a = $code->() } for @{$self}[1..$#$self];
	$a
}


1;
