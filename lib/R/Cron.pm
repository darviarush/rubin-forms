package R::Cron;
# по времени запускает зарегистрированные команды


my @CRON; # задания

my $CRON = bless \@CRON, R::Cron;

# конструктор: 
sub new { $CRON }

sub on {
	my ($self, $interval, $callback) = @_;
	push @CRON, [time + $interval, $interval, $callback];
	$self
}

sub run {
	print "task run\n";
	for my $task (@CRON) {
		if($task->[0] <= time) {
			my($time, $interval, $fn) = @$task;
			ref $fn eq 'CODE'? $fn->(): $fn->run;
			$task->[0] += $interval;
		}
	}
	$CRON;
}

sub loop {
	my ($self) = @_;
	for(;;) { $self->run; sleep 1; }
}

sub alarm {
	my ($self, $alarm) = @_;
	$main::SIG{ALRM} = \&run;
	alarm($alarm // 1);
	$self;
}

1;