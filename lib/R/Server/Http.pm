package R::Server::Http;
# драйвер для протокола qq: http

use base R::Server;

use Socket;

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
	my ($_port, $sd) = $self->{app}->ini->{site}{port};
	
	if($_port =~ /^\d+$/) {
		socket $sd, AF_INET, SOCK_STREAM, getprotobyname("tcp") or die "socket: $!\n";
		setsockopt $sd, SOL_SOCKET, SO_REUSEADDR, pack("l", 1) or die "setsockopt: $!\n"; # захватываем сокет, если он зан¤т другим процессом
		bind $sd, sockaddr_in($_port, INADDR_ANY) or die "bind: $!\n";
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

# бесконечный цикл ожидани¤ и выполнени¤ запросов
sub accept {
	my ($self, $ritter) = @_;
	
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	my $http_status = $app->serverHttpStatus;
	my $_test = $app->ini->{site}{test};
	
	#my $sel = IO::Socket->new($_socket);
	#$sel->add();
	
	# добавляем в векторы сокет
	# my ($vec, $out, $err) = ("", "", "");
	# my $sd = fileno($self->{sd});
	# vec($vec, $sd, 1) = 1;
	# vec($out, $sd, 1) = 1;
	# vec($err, $sd, 1) = 1;
	
	my($ns, $keep_alive);
	for(;;) {
		
		#my $nfound = select $vec, undef, undef, undef;
		#msg CYAN."nfound ".RESET." soc=$self->{sd} vec=$vec ".RED.$nfound.RESET;
		#$nfound = select undef, $out, undef, undef;
		#if $nfound == $sd
		#$nfound = select undef, undef, $err, undef;
		#next unless defined $nfound;
		
		#if $nfound == $sd;
		
		my ($HTTP, $ret) = ();
		$HTTP = <$ns> if $keep_alive;
		unless(defined $HTTP) {
			close $ns if $ns;
			accept $ns, $self->{sd} or die "not ns: $!";
			$self->{ns} = $ns;
			next unless defined($HTTP = <$ns>);
		}
		
		$self->stat_start() if $_test;
		
		if(my @param = $HTTP =~ m!^(\w+) $R::Request::RE_LOCATION (HTTP\/\d\.\d)\r?$!o) {
			
			# считываем заголовки
			my ($head, $body);
			/: (.*?)\r?$/ and $head->{$`} = $1 while defined($_ = <$ns>) and !/^\r?$/;
			
			# считываем данные
			if(my $CONTENT_LENGTH = $head->{"Content-Length"} and not exists $head->{'REQUEST_BODY_FILE'}) {
				read $ns, $body, $CONTENT_LENGTH;
			}
			
			$request->reset(@param, $head, $body);
			$response->reset();
			#main::msg ":cyan", $request;
			$self->stat_begin() if $_test;

			# настраиваем сессионное подключение (несколько запросов на соединение, если клиент поддерживает)
			$keep_alive = (lc $head->{Connection} eq 'keep-alive');
			
			$ritter->($self);
		} else {
			$response->error(400)
			->type("text/plain")
			->body("400 $http_status->{400}");
		}
		
		my $status = $response->{status};
		
		my $RESPONSE = "HTTP/1.1 $status $http_status->{$status}\n";
		my $body = $response->{body};
		
		unless(exists $response->{head}{"Content-Length"}) {
			my $len = 0;
			for my $text (@$body) {
				$text = JSON::to_json($text) if ref $text;
				$len += length $text;
			}
			$response->{head}{"Content-Length"} = $len;
		}
		
		$response->{head}{Connection} = "keep-alive" if $keep_alive;
		
		my ($k, $v);
		my $out_head = $response->{head};
		send $ns, $RESPONSE, 0;
		send $ns, "$k: $v\n", 0 while ($k, $v) = each %$out_head;
		send $ns, "\n", 0;
		send $ns, $_, 0 for @$body;
		
		$self->stat_end($RESPONSE) if $_test;
		
		%$request = (app=>$app);
		%$response = (app=>$app);
		($k, $v) = ();
	}
}


sub close { my ($self) = @_; close $self->{ns} if $self->{ns}; close $self->{sd}; }

1;
