package R::Process;
# �������� � ���������� � ������

use POSIX ":sys_wait_h";
use threads ('yield',
	'stack_size' => 64*4096,
	'exit' => 'threads_only',
	'stringify');
use threads::shared;


sub new {
	my ($cls, $app) = @_;
	bless {app=>$app}, $cls;
}

# ������������
sub daemon {
	my ($self, $path) = @_;
	$path //= dirname($0).'/rubin.log';
	open STDOUT, '>', $path or die $!;
	open STDERR, '>>', $path or die $!;
	open STDIN, "<", "/dev/null" or die $!;
	my $pid = fork;
	die "�� ���� ��������� fork\n" if $pid<0;
	exit if $pid;	# ��� ������������ ������� - ������� ���
	die "�� ������� ������������ �� ���������\n" if POSIX::setsid() == -1;
	$self
}

# ���������� ������� 
sub fork {
	my ($self, $lord, $lords) = @_;
	$lords //= $self->{app}->ini->{site}{lords};
	for(my $i=0; $i<$lords; $i++) {
		threads->create($lord) or die $!;
	}
	$! = undef;
	$self
}


# ������� ������� - ������ �� ���������� � ��������� �������� �� �����
sub loop {
	my ($self, $cron) = @_;
	$SIG{INT} = $SIG{TERM} = sub { my ($self) = @_; sub { $self->end_server; exit; }};
	for(;;) {
		sleep 1;
		# ������ �� �����
		eval {
			$cron->($self->{app});
		};
		main::msg(":red", "�������� ������ �����: ".($@ || $!)), $@ = $! = undef if $@ || $!;
		
		eval {
			my @joinable = threads->list(threads::joinable);
			for my $thr (@joinable) {		# ��������� ����� ������
				my @return = $thr->join();
				my $tid = $thr->tid();
				my $error = $thr->error();
				#if($tid == $cron) {
				#	print RED."���������� ���� � $tid\n".RESET."$error";
				#	$cron = threads->create(*cron::run)->tid();
				#} else {
					main::msg ":empty", ":red", "���������� ���� � $tid", ":reset", ($error? "\n� �������: $error": "").(@return? "\n������: ": "");
					main::msg \@return if @return;
					threads->create(*lord);
				#}
			}
		};
		main::msg(":red", "���� ���������� � �������: ".($@ || $!)), $@ = $! = undef if $@ || $!;
	}
}

# ��������� ������ � ����������
sub close {
	for my $thr (threads->list()) { $thr->detach();  }
	$self
}

# ��������� - ����� �� �������������
sub test {
	my $test = shift // $0;
	my $res = `perl -c $test`;
	return $? == 0? undef: $res;
}

# ������������� ������
sub reload {
	my ($self) = @_;
	#print STDERR `nginx -s reload`;
	if(my $res = $self->test) {
		main::msg ":RED", $res, ":RESET";
	} else {
		$self->end_server;
		exec $0, @::ARGV;
	}
	$self
}

sub end_server {
	my ($self, $end_server) = @_;
	if(@_>1) {
		$self->{end_server} = $end_server;
	} else {
		$self->{end_server}->($self->{app});
	}
	$self
}

# ������������� ������, ���� ��������� �����-�� �� ������� �������
sub watch {
	my ($self) = @_;
	$self->{app}->watch->on(qr//, ["qq", "main.ini", grep { defined $_ and -e $_ and m!/action/.*\.(?:htm|act)\.pl$! } values %INC], sub {
		my ($path, $app) = @_;
		my $module = m!/.*\.(?:(act)|htm)\.pl$!? ($1? "action": "htm"): "module";
		main::msg ":empty", ":time", " - ", ":red", $module, ":reset", " $path";
		$app->process->reload;
	});
	$self
}


1;