package R::Bench;
# бенчмарк - измеряет время

use common::sense;
use R::App;

use Time::HiRes qw//;
use Benchmark qw/:hireswallclock/;

# конструктор
sub new {
	my ($cls) = @_;
	bless [], ref $cls || $cls;
}

# запоминает время
sub time {
	my ($self) = @_;
	
	#push @$self, Time::HiRes::time();
	push @$self, Benchmark->new;
	
	$self
}

# выдаёт сколько прошло времени в секундах с прошлого time
sub diff {
	my ($self) = @_;
	my $time = pop @$self;
	die "стек бенчмарка пуст" if !defined $time;
	#Time::HiRes::time() - $time
	my $bench = timediff(Benchmark->new, $time);
	wantarray? @$bench: $bench->[1];
}


# делает diff и выдаёт для лога
sub log {
	my ($self) = @_;
	my ($real, $user, $system, $children_user, $children_system, $iters) = $self->diff;
	(":bold black", $user, ($system || $iters? $system: ()), ($iters? $iters: ()))
}

# время запуска программы
sub start_time {
	my ($self) = @_;
	#push @$self, $^T;
	push @$self, bless [0,0,0,0,0,0], 'Benchmark';
	$self
}

1;