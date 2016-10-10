package R::Http::Ws;
# клиент веб-сокет на coro

use common::sense;
use R::App;

use AnyEvent;
#use AnyEvent::Socket;
#use AnyEvent::Handle;
use Protocol::WebSocket::Client;

use URI;

# конструктор
sub new {
	my ($cls, $url) = @_;
	bless {
		url => $url,
		message => {},			# сообщения
	}, ref $cls || $cls;
}


our %CLIENT;

# создаёт подключение
sub connect {
	my ($self) = @_;
	
	my $uri = URI->new($self->{url});
	
	my $ns = $app->processClient->new($uri->host, $uri->port)->docking;
	
	my $client = Protocol::WebSocket::Client->new(
		url => $self->{url},
		on_connect => sub {
			my ($client) = @_;
			my $self = $client->{_ws};
			msg1 "ws-client:connect" if $self->{test};
			if(my $connect = $self->{message}{connect}) {
				$connect->($client);
			}
			
			# произошёл коннект
			$self->{is_connect} = 1;
			
			# сообщения произошедшие до коннекта
			for my $message (@{$self->{before}}) {
				$CLIENT{int $self->{handle}}->write($message);
			}
		},
		on_write => sub {
			my ($client, $buf) = @_;
			msg1 "ws-client:on_write `$buf`" if $self->{test};
			$client->{_ws}{handle}->push_write($buf);
		},
		on_eof => sub {
			my ($client) = @_;
			msg1 "ws-client:on_eof" if $self->{test};
			if(my $disconnect = $client->{_ws}{message}{disconnect}) {
				$disconnect->($client);
			}
		},
		on_error => sub {
			my ($client) = @_;
			msg1 "ws-client:on_error" if $self->{test};
			if(my $error = $client->{_ws}{message}{error}) {
				$error->($client);
			}
		},
	);
	
	$client->on(read => sub {
		my ($client, $buf) = @_;
		#msg1 "ws-client:read (message)", $buf;
		my $message = $app->json->from($buf);
		#msg1 "ws-client:read (message)(args)", $message;
		
		if(my $args = $message->{message}) {
			my $key = shift @$args;
			if(my $call = $client->{_ws}{message}{$key}) {
				$call->(@$args);
			} else {
				msg "ws-client: нет обработчика! $buf", $client->{_ws}{message};
			}
		}
		else {
			msg "ws-client: некорректное сообщение! $buf";
		}
	});
	
	
	my $ae_handle = AnyEvent::Handle->new(
        fh     => $ns,
        on_eof => sub {
            my ($handle) = @_;
			msg1 "ws-h:eof" if $self->{test};
			$CLIENT{int $handle}->{_ws}->close;
        },
        on_error => sub {
            my ($handle, $info, $msg) = @_;
			msg1 "ws-h:error", $info, $msg if $self->{test};
			$CLIENT{int $handle}->{_ws}->close;
			die "ошибка на сокете клиента: $msg";
        },
        on_read => sub {
            my ($handle) = @_;
            my $buf = delete $handle->{rbuf};
			msg1 "ws-h:read", $buf if $self->{test};
            $CLIENT{int $handle}->read($buf);
        }
    );
	
	$self->{handle} = $ae_handle;
	$client->{_ws} = $self;
	$CLIENT{int $ae_handle} = $client;
	
	# Sends a correct handshake header
	$client->connect;
	
	$self
}


# корректно закрывает сокет
sub close {
	my ($self) = @_;
	
	my $handle = $self->{handle};
	my $client = delete $CLIENT{int $handle};
	
	$client->disconnect;
	$handle->destroy;
	
	$self->{closed} = 1;
	delete $client->{_ws};
	delete $self->{handle};
	
	$self
}
	 
	# # Parses incoming data and on every frame calls on_read
	# $client->read(...data from socket...);
	 
	# # Sends correct close header
	# $client->disconnect;
	
# подключает событие
sub on {
	my $self = shift;
	
	for(my $i=0; $i<@_; $i++) {
		my ($route, $code) = @_[$i, $i+1];
		$self->{message}{$route} = $code;
	}
	
	$self
}


# отправляет сообщение серверу
sub message {
	my $self = shift;
	
	$self->connect if !$self->{handle};

	my $message = $app->json->to(\@_);

	msg1 "ws-client:message", $message if $self->{test};
	
	if($self->{is_connect}) {
		$CLIENT{int $self->{handle}}->write($message);
	} else {
		push @{$self->{before}}, $message;
	}
	
	
	$self
}

1;
