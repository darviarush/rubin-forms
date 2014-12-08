package R::Select;
# запускает функцию при изменении трубы или сокета

use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK O_NDELAY);
use Time::HiRes;

# конструктор
sub new { my ($cls) = @_; bless { file => {}, rin => undef, win => undef, ein => undef, interval => undef }, $cls }

# устанавливает обработчик на файл
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

# отключает обработчики от файла
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

# устанавливает выбор
sub select {
	my ($self, $interval) = @_;
	$self->{interval} = $interval if defined $interval;
	my $nfound = select $rin=$self->{rin}, $win=$self->{win}, $ein=$self->{ein}, $self->{interval};
	return ($rin, $win, $ein) if $nfound > 0;
}

# запускает выбор
sub run {
	my ($self, $interval) = @_;
	my @vec = $self->select($interval);
	$self->exec(@vec) if @vec;
	$self
}

# распознаёт файлы с изменениями
sub exec {
	my ($self, $rin, $win, $ein) =  @_;
	while(my ($fileno, $val) = each %{$self->{file}}) {
		$val->[0]($self->{app}, $val->[1], 0) if defined $rin and vec($rin, $fileno, 1);
		$val->[0]($self->{app}, $val->[1], 1) if defined $win and vec($win, $fileno, 1);
		$val->[0]($self->{app}, $val->[1], 2) if defined $ein and vec($ein, $fileno, 1);
	}
}

# бесконечный цикл с обработкой
sub loop {
	my ($self, $timeout, $sub) = @_;
	$sub = $timeout, $timeout = 1 if ref $timeout;
	my $rtime = $timeout;
	for(;;) {
		my $end = Time::HiRes::time + $rtime;
		my @vec = $self->select($rtime);
		$self->exec(@vec) if @vec;
		$rtime = $end - Time::HiRes::time;
		main::msg $rtime;
		if($rtime <= 0) {
			$sub->($self->{app});
			$rtime = $timeout;
		}
	}
}

1;