package R::Test;
# управляет тестами

use base R::Utils::Main;

use TAP::Harness;

sub verbosity {
	my($self, $verbosity) = @_;
	$self->{verbosity} = $verbosity;
	$self
}

sub run {
	my ($self, @tests) = @_;
	my $harness = TAP::Harness->new({
		color=>1,
		verbosity => $self->{verbosity} // $self->{app}->ini->{test}{verbosity} // 0,
		lib => [main::files('lib')],
		failures => 1,
		timer => 0
	});
	$harness->runtests(@tests);
	$self
}

sub watch {
	my ($self, @tests) = @_;
	$self->{app}->watch->on(qr/\.t$/, [main::files("t")], sub {
		my ($path, $app) = @_;
		$app->test->run($path);
	});
}

1;