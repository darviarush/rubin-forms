package R::Async::Process;
# ������������ �������

use common::sense;
use R::App;

use POSIX qw/setsid/;

# �����������
sub new {
	my ($cls, $name, $pid) = @_;
	bless {
		name => $name,
		pid => $pid
	}, ref $cls || $cls;
}

# ������������� ������
sub signal {
	my $self = shift;
	my $name = shift;
	if(@_) {
		
	}
	else {
		
	}
}

# �������� ������ kill
sub kill {
	my ($self) = @_;
	$self
}

# ���������� ��� �������� ��������
sub child {
	my ($self) = @_;
	$self
}

# ���������� ��������
sub parent {
	my ($self) = @_;
	$self
}

# ��������������
sub daemonize {
	my $self = shift;
	chdir("/")                      || die "can't chdir to /: $!";
	open(STDIN,  "< /dev/null")     || die "can't read /dev/null: $!";
	open(STDOUT, "> /dev/null")     || die "can't write to /dev/null: $!";
	defined(my $pid = fork())       || die "can't fork: $!";
	exit if $pid;                   # non-zero now means I am the parent
	(setsid() != -1)                || die "Can't start a new session: $!";
	open(STDERR, ">&STDOUT")        || die "can't dup stdout: $!";
	$self->{pid} = getppid();
	$self
}

# ���������� ���� id
sub pid {
	my ($self) = @_;
	$self->{pid}
}



1;
