package Cron;

sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

sub interval {
	my ($self, $sec, $action, $param) = @_;
	push @{$self->{$sec}}, [$sec, $action, $param];
}

sub loop {
	for(;;) {
		if($self->{time()})
	}
}

1;