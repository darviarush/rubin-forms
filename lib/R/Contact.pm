package R::Contact;
# контакты через web-сокеты со всех http-серверов

use common::sense;
use R::App;

use Protocol::WebSocket::Frame;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		byuser => {},		# контакты по пользователю
		byns => {},			# контакты по сокету
	}, ref $cls || $cls;
}


# возвращает массив контактов по пользователю
sub byuser {
	my ($self, $user) = @_;
	
	$user = $user->id if ref $user;
	
	return if !$user;

	values %{$self->{byuser}{$user}};
}

# возвращает массив контактов по пользователям
sub byusers {
	my $self = shift;
	
	map {
		my $user = $_;
		$user = $user->id if ref $user;
		
		$user? values( %{$self->{byuser}{$user}} ): ()
	} @_;
}

# регистрирует контакт по пользователю
# должен вызываться при изменении кук в q
sub connect {
	my ($self) = @_;
	
	my $q = $app->{q};
	my $message = $q->{is_message};
	
	$q->cookie;		# распарсить куки
	$message->{incookie} = $q->{incookie};

	my $user = $q->user->id;
	$message->{user} = $user;
	
	$message->{ns} = $q->{ns};
	$self->{byns}{int $q->{ns}} = $message;

	return $self if !$user;
	
	$self->{byuser}{$user}{int $q->{ns}} = $message;
	
	$self
}

# отключает контакт
sub disconnect {
	my ($self, $ns) = @_;

	$ns //= $app->q->{ns};
	
	if( my $contact = delete $self->{byns}{int $ns} ) {
		if( my $user = $contact->{user} ) {
			if( my $contacts = $self->{byuser}{$user} ) {
				delete $contacts->{int $ns};
				delete $self->{byuser}{$user} if !%$contacts;
			}
		}
	}
	
	$self
}

# устанавливает куки в q
sub init {
	my ($self) = @_;
	
	my $q = $app->q;
	%{$q->{incookie}} = %{$q->{is_message}{incookie}};
	
	$self
}

# смена кук - вызывается после обработки сообщения
sub change {
	my ($self) = @_;
	
	my $q = $app->{q};
	
	%{$q->{is_message}{incookie}} = (%{$q->{is_message}{incookie}}, %{$q->{outcookie}});
	
	
	if($q->user->id != $q->{is_message}{user}) {
		$self->disconnect;
		$self->connect;
	}
	
	$self
}

# отправляет сообщение всем браузерам текущего пользователя или, если нет пользователя, то в текущий web-сокет
sub message {
	my $self = shift;
	
	my $json = $app->json->to(\@_);
	my $send = Protocol::WebSocket::Frame->new($json)->to_bytes;
	
	my $q = $app->{q};
	my $user = $q->user->id;
	
	# отправляем
	if($user) {
		for my $contact ( $self->byuser($user) ) {
			$contact->{ns}->print( $send );
		}
	}
	elsif( $q->{is_message} ) {
		$q->{ns}->print( $send );
	}

	$self
}

# отправляет сообщение в текущий сокет
sub emit {
	my $self = shift;
	
	my $json = $app->json->to(\@_);
	my $send = Protocol::WebSocket::Frame->new($json)->to_bytes;
	
	my $q = $app->{q};
	if( $q->{is_message} ) {
		$q->{ns}->print( $send );
	}

	$self
}


# отправляет сообщение всем сокетам
sub broadcast {
	my $self = shift;
	
	my $json = $app->json->to(\@_);
	my $send = Protocol::WebSocket::Frame->new($json)->to_bytes;
	
	my $byns = $self->{byns};
	
	for my $contact (values %$byns) {
		$contact->{ns}->print($send);
	}
	
	$self
}

1;