package R::Http::Server;
# http-сервер

use common::sense;
use R::App;


use Socket;
use Symbol;

has qw/socket/;

# конструктор
sub new {
	my ($cls, $port) = @_;
	my $self = bless {
		'socket' => undef
	}, $cls;
	$port //= $app->ini->{site}{port};
	die "Не указан порт";
	$self->connect();
}

# создаёт подключение
sub connect {
	my ($self, $_port) = @_;
	my $sd = gensym;  
	
	if($_port =~ /^\d+$/) {
		socket $sd, AF_INET, SOCK_STREAM, getprotobyname("tcp") or die "socket: $!\n";
		setsockopt $sd, SOL_SOCKET, SO_REUSEADDR, pack("l", 1) or die "setsockopt reuseaddr: $!\n"; # захватываем сокет, если он занят другим процессом
		unless( bind $sd, sockaddr_in($_port, INADDR_ANY) ) {
			if($! == 112) {
				sleep 2;
				bind $sd, sockaddr_in($_port, INADDR_ANY) or die "$$ bind: (".int($!).") $!\n";
			} else { die "$$ bind: (".int($!).") $!\n" }
		}
		listen $sd, SOMAXCONN or die "listen: $!\n";
	} else {
		socket $sd, PF_UNIX, SOCK_STREAM, 0 or die "socket: $!\n";
		unlink $_port;
		bind $sd, sockaddr_un($_port) or die "bind: $!\n";
		listen $sd, SOMAXCONN  or die "listen: $!\n";
	}

	$self->{socket} = $sd;
	$self
}

# отключает сервер
sub disconnect {
	my ($self) = @_;
	$self
}

# пытается перехватить запрос
sub accept {
	my ($self) = @_;
	my $ns = gensym;
	unless( accept $ns, $self->{sd} ) {
		undef $ns;
		die "not ns: $!" if $!;
		return;
	}
	
	$self->impulse($ns);
}


1;
