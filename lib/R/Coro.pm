package R::Coro;
# управление волокнами

use common::sense;
use R::App;

our $SIGINT;

sub setsigint {
	$SIGINT = AnyEvent->signal (signal => "INT", cb => sub {
		print STDERR "CORO INT!!!\n";
		$app->{coro}->stop;
		$app->processManager->stop if $app->{processManager};
		exit;
	});
}

# устанавливает Coro
# конструктор - синглетон
sub new {
	my ($cls) = @_;
	
	return $cls if ref $cls;
	
	use Coro qw//;
	use AnyEvent qw//;
	use AnyEvent::Handle qw//;
	use Coro::AnyEvent qw//;
	use Coro::State qw//;
	use Coro::Timer qw//;
	use Coro::Handle qw//;
	use Coro::Signal qw//;
	use Coro::LWP qw//;
	
	$app->raise->setdie;	# восстанавливаем хэндлер в главном coro-волокне
	
	setsigint();
	
	bless {
		async => 0,			# количество волокон coro запущенных через async
		last => undef,		# последнее волокно
		atdie => {},		# обработчики исключения, если возвращают undef, то поток - завершается, иначе - рестартует
		atexit => {},		# обработчики завершения. Запускаются в другом волокне. Получают объект
		signal => Coro::Signal->new,	# сигнал для run
		#var => AnyEvent->condvar,
	}, $cls;
}


# порождает поток
sub async {
	my ($self, $code) = splice @_, 0, 2;
	
	my $coro = Coro->new(sub {
		$app->raise->setdie;
		
		my $connect = $app->connect->new;

		# переключаем коннект
		Coro::on_enter(sub { $app->{connect} = $connect });
		
		NEXT: eval { $code->(@_); };
		if(my $error = $@) {
			if(my $atdie = $self->{atdie}{int $Coro::current}) {
				goto NEXT if defined $atdie->($@);
				delete $self->{atdie}{int $Coro::current};
			} else {
				my $err = int $error;
				$app->log->error(":red space", "волокно " . ($Coro::current->{desc} // $Coro::current) . " завершилось в результате ошибки:", ":reset", "$err) $error");
			}
		}
		return;
	}, @_);
	
	$coro->on_destroy(closure $coro, sub {
		my ($coro) = @_;
		my $addr = int $coro;
		delete $self->{atdie}{$addr};
		if(my $atexit = delete $self->{atexit}{$addr}) {
			$atexit->($coro);
		}
		$self->{signal}->send if 0 == --$self->{async} && $self->{signal};
	});
	
	$self->{last} = $coro;
	$self->{async}++;
	
	$coro->ready;
	
	$self
}

# запускает волокна
sub run {
	my ($self) = @_;
	$self->{signal}->wait;
	$self
}


# завершает coro->run
sub stop {
	my ($self) = @_;
	
	$self->{stopped} = 1;
	
	#msg1 "killall!!!";
	
	Coro::killall();
	
	$self
}

# возвращает последний
sub last {
	my ($self) = @_;
	$self->{last}
}

# устанавливает описание
sub desc {
	my ($self, $desc) = @_;
	
	$self->last->desc( $desc );
	
	$self
}

# устанавливает код на завершение потока
*atexit = \&destroyer;
*ondestroy = \&destroyer;
*on_destroy = \&destroyer;
sub destroyer {
	my ($self, $code) = @_;
	$self->{atexit}{int $self->last} = $code;
	$self
}


# устанавливает код на ошибку
*onerror = \&atdie;
*on_error = \&atdie;
sub atdie {
	my ($self, $code) = @_;
	$self->{atdie}{int $self->last} = $code;
	$self
}



# возвращает текущий
sub me {
	$Coro::current
}

# # устанавливает-возвращает данные текущего coro по ключу
# sub pull {
	# my $self = shift;
	# if(@_>1) {
		# $self->{pull}{int $Coro::current}{$_[0]} = $_[1];
		# $self
	# }
	# else {
		# $self->{pull}{int $Coro::current}{$_[0]}
	# }
# }


1;