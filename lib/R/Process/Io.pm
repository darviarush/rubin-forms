package R::Process::Io;
# межпроцессорное взаимодействие
# его наследует клиент, а в сервере он используется как request

use common::sense;
use R::App;

use Storable qw//;
use Symbol;

# конструктор
sub new {
	my ($cls, $ns, $paddr) = @_;
	
	$ns //= gensym;
	
	bless {
		ns => $ns,
		paddr => $paddr,
		running => 1,
	}, ref $cls || $cls;
}


# отправляет строку в сокет
sub send {
	my ($self, $msg) = @_;
	
	#msg1 "$self", "$$ send", $msg;
	
	utf8::encode($msg) if utf8::is_utf8($msg);
	my $ns = $self->{ns};
	$ns->syswrite($msg);
	
	#msg1 "$self", "$$ send-end";
	
	$self
}

# считывает указанное кол. байт из сокета
sub recv {
	my ($self, $n) = @_;
	
	#msg1 "$self", "$$ recv", $n;
	
	#my $length = recv $self->{ns}, my $msg, $n, 0 or die "recv: $!";
	
	my($length, $msg);
	my $ns = $self->{ns};
	my $length = $ns->sysread($msg, $n) or die "recv: $!";
	
	die "прочитано $length байт, когда требуется $n" if $length != $n;
	
	#msg1 "$self", "$$ recv-end", $msg;
	
	$msg
}

# считывает 4 байта в сетевом формате N, а затем - строку из таких байт
sub read {
	my ($self) = @_;
	
	$self->recv( unpack "N", $self->recv(4) );
}

# записывает размер строки в сетевом формате N, а затем - строку
sub write {
	my ($self, $msg) = @_;

	utf8::encode($msg) if utf8::is_utf8($msg);
	$self->send( pack("NA*", length($msg), $msg) );
	
	$self
}

# замораживает данные и отправляет
sub freeze {
	my ($self, $data) = @_;
	
	$self->write(Storable::freeze($data));
	
	$self
}

# считывает и размораживает данные
sub thaw {
	my ($self) = @_;
	
	Storable::thaw( $self->read );
}

# отправляет команду
sub put {
	my $self = shift;
	$self->connect if !$self->{ns};
	$self->freeze(\@_);
}

# считывает данные
sub res {
	my $self = shift;
	my $ret = $self->thaw;
	$$ret
}


# закрывает соединение
sub close {
	my ($self) = @_;
	
	return $self if !$self->{running};
	
	$self->{ns}->close;
	$self->{running} = 0;
	$self
}

1;