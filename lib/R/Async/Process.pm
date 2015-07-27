package R::Async::Process;
# представляет процесс

use common::sense;
use R::App;

use POSIX qw/setsid/;

# конструктор
sub new {
	my ($cls, $name, $pid) = @_;
	bless {
		name => $name,
		pid => $pid
	}, ref $cls || $cls;
}

# устанавливает сигнал
sub signal {
	my $self = shift;
	my $name = shift;
	if(@_) {
		
	}
	else {
		
	}
}

# посылает сигнал kill
sub kill {
	my ($self) = @_;
	$self
}

# возвращает все дочерние процессы
sub child {
	my ($self) = @_;
	$self
}

# возвращает родителя
sub parent {
	my ($self) = @_;
	$self
}

# демонизируется
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

# возвращает свой id
sub pid {
	my ($self) = @_;
	$self->{pid}
}



1;
