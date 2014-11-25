package R::Select;

use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK O_NDELAY);

sub new { my ($cls) = @_; bless { file => {}, rin => undef, win => undef, ein => undef, interval => undef }, $cls }

sub on {
	my ($self, $file, $ioe, $callback) = @_;
	my $fileno = ref $file? fileno($file): $file;
	$self->off($fileno) if exists $self->{file}{$fileno};
	$self->{file}{$fileno} = [$callback, $file, $ioe];
	vec($self->{rin} ||= '', $fileno, 1) = 1 if $ioe =~ /r/;
	vec($self->{win} ||= '', $fileno, 1) = 1 if $ioe =~ /w/;
	vec($self->{ein} ||= '', $fileno, 1) = 1 if $ioe =~ /e/;
	Utils::nonblock($file) if $ioe !~ /b/;
	$self
}

sub off {
	my ($self, $fileno) = @_;
	$fileno = fileno $fileno if ref $fileno;
	for my $key (qw/rin win ein/) {
		vec($self->{$key}, $fileno, 1) = 0;
		while(0 == substr $self->{$key}, length($self->{$key})-1) {
			$self->{$key} = substr $self->{$key}, 0, length($self->{$key})-1;
		}
		$self->{$key} = undef if 0 == length $self->{$key};
	}
	delete $self->{file}{$fileno};
	$self
}

sub select {
	my ($self, $interval) = @_;
	$self->{interval} = $interval if defined $interval;
	my ($nfound, $lefttime) = select $rin=$self->{rin}, $win=$self->{win}, $ein=$self->{ein}, $self->{interval};
	return ($rin, $win, $ein, $lefttime) if $nfound > 0;
}

sub run {
	my ($self, $interval) = @_;
	my @vec = $self->select($interval);
	$self->exec(@vec) if @vec;
	$self
}

sub exec {
	my ($self, $rin, $win, $ein) =  @_;
	while(my ($fileno, $val) = each %{$self->{file}}) {
		$val->[0]($val->[1], 0) if defined $rin and vec($rin, $fileno, 1);
		$val->[0]($val->[1], 1) if defined $win and vec($win, $fileno, 1);
		$val->[0]($val->[1], 2) if defined $ein and vec($ein, $fileno, 1);
	}
}

sub loop {
	my ($self, $timeout, $sub) = @_;
	$sub = $timeout, $timeout = 1 if ref $timeout;
	my $rtime = $timeout;
	for(;;) {
		my @vec = $self->select($rtime);
		if(@vec) {
			$self->exec(@vec);
			my $lefttime = $vec[3];
			$rtime = $lefttime || $timeout;
			next if $lefttime > 0.1;
		}
		$sub->();
		$rtime = $timeout;
	}
}

1;