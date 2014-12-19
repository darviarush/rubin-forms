package R::Server::Http;
# драйвер для протокола qq: http

use base R::Server;

use Socket;
use Symbol;

use R::Request; # из него получаем $R::Request::RE_LOCATION

# конструктор
sub new {
	my ($cls, $app) = @_;
	my $self = bless { app => $app }, $cls;
	$self->create;
}

# создаёт подключение
sub create {
	my ($self) = @_;
	my $_port = $self->{app}->ini->{site}{port};
	my $sd = gensym;  
	
	if($_port =~ /^\d+$/) {
		socket $sd, AF_INET, SOCK_STREAM, getprotobyname("tcp") or die "socket: $!\n";
		setsockopt $sd, SOL_SOCKET, SO_REUSEADDR, pack("l", 1) or die "setsockopt reuseaddr: $!\n"; # захватываем сокет, если он занят другим процессом
		bind $sd, sockaddr_in($_port, INADDR_ANY) or die "$$ bind: $!\n";
		listen $sd, SOMAXCONN or die "listen: $!\n";
	} else {
		socket $sd, PF_UNIX, SOCK_STREAM, 0 or die "socket: $!\n";
		unlink $_port;
		bind $sd, sockaddr_un($_port) or die "bind: $!\n";
		listen $sd, SOMAXCONN  or die "listen: $!\n";
	}

	$self->{sd} = $sd;
	$self
}

# инициализации в новом треде
# sub bind {
	# my ($self) = @_;
	# close $self->{ns} if $self->{ns};
	# $self
# }

# бесконечный цикл ожидания и выполнения запросов
sub loop {
	my ($self, $ritter) = @_;
	require AnyEvent;
	$self->{ritter} = $ritter // ($self->{app}->ini->{site}{ext}? $self->can("tan"): $self->can("ritter"));
	$self->{wait} = AnyEvent->condvar;
	my $w = AnyEvent->io(fh=>$self->{sd}, poll=> 'r', cb=> Utils::closure($self, $self->can("accept")));
	$self->{wait}->recv;
	#main::msg ":space", ":magenta", $$, threads->tid, ":cyan", "exit";
	undef $w;
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

# обрабатывает одиночный запрос
sub impulse {
	local ($_);
	my ($self, $ns) = @_;
					
	my $HTTP = <$ns>;
	return $self->close_ns($ns) unless defined $HTTP;
	
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	my $http_status = $app->serverHttpStatus;
	my $_test = $app->ini->{site}{test};
	
	my $keep_alive;
	
	$self->stat_start if $_test;
	
	if(my @param = $HTTP =~ m!^(\w+) $R::Request::RE_LOCATION (HTTP\/\d\.\d)\r?$!o) {
		
		# считываем заголовки
		my ($head, $body);
		/: (.*?)\r?$/ and $head->{$`} = $1 while defined($_ = <$ns>) and !/^\r?$/;
		
		# считываем данные
		if(my $CONTENT_LENGTH = $head->{"Content-Length"} and not exists $head->{'REQUEST_BODY_FILE'}) {
			read $ns, $body, $CONTENT_LENGTH;
		}
		
		$request->reset(@param, $head, $body);
		$response->reset;

		$self->stat_begin if $_test;

		# настраиваем сессионное подключение (несколько запросов на соединение, если клиент поддерживает)
		$keep_alive = ($head->{Connection} =~ /keep-alive/i);
		$self->{ritter}->($self);
	} else {
		$response->status(400)
		->type("text/plain")
		->body("400 $http_status->{400}");
	}
	
	my $status = $response->{status};
	
	my $RESPONSE = "HTTP/1.1 $status $http_status->{$status}\n";
	my $body = $response->{body};
	
	unless(exists $response->{head}{"Content-Length"}) {
		my $len = 0;
		for my $text (@$body) {
			$text = "$text" if ref $text;
			$len += length $text;
		}
		$response->{head}{"Content-Length"} = $len;
	}
	
	$response->{head}{Connection} = "keep-alive" if $keep_alive;
	
	my ($k, $v);
	my $out_head = $response->{head};
	my $cookie = $response->{cookie};
	send $ns, $RESPONSE, 0;
	send $ns, "$k: $v\n", 0 while ($k, $v) = each %$out_head;
	send $ns, "Set-Cookie: $_\n", 0 for @$cookie;
	send $ns, "\n", 0;
	send $ns, $_, 0 for @$body;

	$self->stat_end($RESPONSE) if $_test;
	
	%$request = (app=>$app);
	%$response = (app=>$app);

	if($keep_alive) {
		require AnyEvent;
		$self->{impulse}{$ns} = [ $ns, AnyEvent->io(fh=>$ns, poll=> 'r', cb=> Utils::closure($self, $ns, $self->can("impulse")))] unless exists $self->{impulse}{$ns};
	} else {
		$self->close_ns($ns);
	}
}

# закрывает сокет и все ns
sub close {
	my ($self) = @_ ;
	while(my ($k, $v) = each %{$self->{impulse}}) {
		my ($ns, $w) = @$v;
		undef $w;
		CORE::close $ns;
		undef $ns;
	}
	delete $self->{impulse};
	CORE::close $self->{sd} if $self->{sd};
	undef $self->{sd};
	$self->{wait}->send if $self->{wait};	# выходим из бесконечного цикла
	$self
}

# закрывает ns
sub close_ns {
	my ($self, $ns) = @_;
	if($self->{impulse}{$ns}) {
		undef $self->{impulse}{$ns}[1];
		delete $self->{impulse}{$ns};
	}
	CORE::close $ns;
	undef $ns;
	$self
}

1;
