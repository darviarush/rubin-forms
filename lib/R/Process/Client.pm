package R::Process::Client;
# tcp клиент. Базовый класс - его надо расширять

use parent qw/R::Process::Io/;

use common::sense;
use R::App;

use Socket;
use Symbol;

# конструктор
sub new {
	my ($cls, $remote, $port) = splice @_, 0, 3;
	bless {
		remote => $remote,
		port => $port,
		ns => undef,		# сокет
		hi_in => "hi!c",
		hi_out => "hi!s",
		@_
	}, ref $cls || $cls;
}

# переопределяется - вызывается при создании подключения
sub hi {
	my ($self) = @_;
	die "соединение не установлено" if $self->put("hi", $self->{hi_in})->res ne $self->{hi_out};
	$self
}

# переопределяется - вызывается при завершении сеанса с сервером
sub bay {
	my $self = shift;
	$self->put("bay");
}


# коннект к серверу
sub docking {
	my ($self, $remote, $port) = @_;
	
	my ($iaddr, $paddr);
	
	$remote  //= $self->{remote};
	$port  //= $self->{port};
	
	my $ns = gensym;
	
	if( defined $port ) {
		
		if ($port =~ /\D/) { $port = getservbyname($port, "tcp") }
		die "No port" unless $port;
		$iaddr   = inet_aton($remote)       || die "no host: $remote";
		$paddr   = sockaddr_in($port, $iaddr);
		my $proto   = getprotobyname("tcp");

		socket($ns, PF_INET, SOCK_STREAM, $proto)  || die "socket: $!";
		connect($ns, $paddr)               || die "connect: $!";
		
		
	}
	else {

		socket($ns, PF_UNIX, SOCK_STREAM, 0)     || die "unix socket: $!";
		connect($ns, sockaddr_un($remote))   || die "unix connect($remote): $!";
		
	}
	
	$ns;
}

# коннектится
sub connect {
	my ($self, $remote, $port) = @_;
	my $ns = $self->docking($remote, $port);
	
	# для Coro
	$ns = Coro::Handle->new_from_fh($ns) if $app->{coro};
	
	$self->{ns} = $ns;
	
	$self->hi;
	$self
}

# восстанавливает соединение, если его нет
sub reconnect {
	my ($self) = @_;
	
	return $self if $self->{ns} and $self->put("ping")->res == 1;
	
	$self->connect;
}

# закрывает соединение
sub close {
	my ($self) = @_;
	if($self->{ns}) {
		$self->bay;
		$self->{ns}->close;
		$self->{ns} = undef;
	}
	$self
}

# деструктор - закрываем соединение
sub DESTROY {
	my ($self) = @_;
	
	$self->close if $self->{ns};
}

1;