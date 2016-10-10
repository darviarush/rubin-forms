package R::Process::Server;
# tcp-сервер на интернет и unix-сокетах и даже на разделяемой памяти (todo)
# протокол для данного сервера придумываете сами
# сервер на http - app->httpServer

#use parent qw/R::Process::Io/;

use common::sense;
use R::App;

use Socket;
use Symbol;
use AnyEvent;


#use POSIX qw/setsid :signal_h :errno_h :sys_wait_h/;

# сигнал аларм для серверов
# our $sig_alarm = $app->signal->new;
# our $timeout_alarm = $app->ini->{site}{alarm};
# $SIG{ALRM} = sub {  $sig_alarm->send; alarm $timeout_alarm } if $timeout_alarm;



has qw/role alarm request/;

# конструктор
sub new {
	my $cls = shift;
	
	if(@_==1) { unshift @_, "port" }
	
	$cls = ref $cls || $cls;
	
	my $self = bless {
		name => $cls,		# имя сервера
		port => undef,		# порт
		ritters => 1,		# количество процессорных обработчиков
		guards => undef,		# количество волоконных обрабочиков
		keepalives => undef,	# максимальное количество постоянных соединений
		websockets => undef,	# максимальное количество web-сокетов
		request => ref $app->processIo,		# класс запроса
		dispatch => {},		# диспетчера (роутеры)
		dispatchers => {}, 	# дополнительная информация о диспетчерах: кто, откуда
		#alarm => $timeout_alarm,
		#timeout => $app->ini->{site}{timeout} // 1,
		signals => [],		# очередь condvar для передачи параметров ждущему волокну
		signal => undef,	# waitsig, использующийся для ожидания поступления хоть однного signals
		waitsig => undef,	# отсюда берётся signal
		@_
	}, $cls;
	
	$self
}

# открывает сокет из файлового номера
sub from_fileno {
	my ($self, $fileno) = @_;
	
	$self->{sd} = $app->use($self->{guards}? "Coro::Socket": "IO::Socket")->new_from_fd($fileno, "r");
	
	$self
}

# создаёт подключение
sub make {
	my ($self) = @_;
	
	die "make без параметров" if @_>1;
	
	$app->bench->time;
	
	my $_port = $self->{port};
	
	$app->bench->diff, die "не указан порт" if !defined $_port;
	
	my $sd = gensym;  
	
	# если указан порт, то ожидается tcp-сокет
	if(Num $_port) {
		socket $sd, AF_INET, SOCK_STREAM, getprotobyname("tcp") or die "socket: $!\n";
		setsockopt $sd, SOL_SOCKET, SO_REUSEADDR, pack("l", 1) or die "setsockopt reuseaddr: $!\n"; # захватываем сокет, если он занят другим процессом
		setsockopt $sd, SOL_SOCKET, SO_KEEPALIVE, pack("l", 1) or die "setsockopt keepalive: $!\n"; # проверять что сокет существует и закрывать его если нет
		#After 30 secs idle send KeepAlive probe
		#setsockopt($sd, IPPROTO_TCP, TCP_KEEPIDLE, pack("l", 30));
		#Rest probes after 30 secs.
		#setsockopt($sd, IPPROTO_TCP, TCP_KEEPINTVL, pack("l", 30));
		
		
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
		#msg1 $sd, sockaddr_un($_port), $_port;
		listen $sd, SOMAXCONN  or die "listen: $!\n";
	}
	
	$self->{sd} = $sd;
	
	# сохраняем время ушедшее на создание сокета
	$self->{bench_make} = $app->bench->diff;
	
	$self
}

# инициализация сервера
sub setup {}

# инициализация воркера (ritter-a)
sub initialize {
	my ($self) = @_;
	
	$self->on(
		"hi" => sub {
			my ($hi) = @_;
			my ($in, $out) = $self->hi;
			msg("неверный протокол: клиент указал приветствие `$hi`"), return $app->q->close if $in ne $hi;
			$out;
		},
		"bay" => sub { $app->q->close; undef }, 
		"ping" => sub { 1 },
	);
	
	$self
}

# инициализация гвардейца (волокна)
sub init {}

# # выполняется при нормальном завершении воркера
# sub destroyer {}

# инициализация и бесконечный цикл ожидания и выполнения запросов
sub loop {
	my ($self) = @_;
	
	$self->role("loop");
	
	$self->make;
	$self->setup;
	$self->birth;	
}

# инициализация, порождение обработчиков и восстановление грохнувшихся
sub run {
	my ($self) = @_;
	
	$self->role("run");
	
	# запускаем обработчики
	$self->start;
	
	# цикл восстановления процессов
	$app->processManager->loop;
}

# порождает обработчики
sub start {
	my ($self) = @_;
	
	$self->role("run");
	
	# создание сокета
	$self->make;
	# инициализация
	$self->setup;
	
	#msg "$$: Запускается сервер", $self->{name}; # для инициализации файлового лога
	
	# порождение обработчиков
	my $ritters = $self->{ritters};
	
	my $cls = ref($self);
	my $sd = $self->{sd}->fileno;
	my %args = %$self;
	#msg1 \%args;
	delete @args{qw/sd messages dispatch dispatchers signal signals waitsig/};
	my $args = $app->perl->dump(\%args);

	my $birth = '
		$app->use("'.$cls.'")->new(%{'.$args.'})->from_fileno('.$sd.')->role("ritter")->birth;
	';
	
	$app->processManager->fd($sd);
	
	for(my $i=1; $i<=$ritters; $i++) {
		$app->processManager->birth("$self->{name}-ritter$i", $birth);
	}
	
	$self
}

# пораждает обработчик
sub birth {
	my ($self) = @_;
	
	#my $q = $self->request->new;
	#$app->q($q);
	
	$self->initialize;
	
	if($self->{guards}) {
		$self->guard;
	}
	else {
		$self->init;
		$self->accept;
	}
}

# возвращает очередной сигнал (AnyEvent->condvar) для отправки свободному волокну
sub signal {
	my $self = shift;
	
	my $signals = $self->{signals};
	my $signal = shift @$signals; 		# берём из очереди свободного гвардейца
	if(!$signal) {						# все гвардейцы заняты, ожидаем
		($self->{signal} = $self->{waitsig})->wait;
		$signal = shift @$signals;
	}
	$signal
}

# запускает обработчики на волокнах
sub guard {
	my ($self) = @_;
	
	die "guard: лишние параметры" if @_>1;
	
	$app->coro;
	
	$app->q("<NO-REQUEST!!!>");
	
	Coro::on_enter(sub { $app->{q} = "<NO-REQUEST!!!>" });

	my $guards = $self->{guards};
	for(my $i = 0; $i<$guards; $i++) {
		$self->new_guard($i);
	}

	# accept
	$self->{waitsig} = Coro::Signal->new;
	
	#$self->{sendsig} = Coro::Signal->new;
	my $sd = $self->{sd} = Coro::Handle->new_from_fh($self->{sd});	# делаем коронным
	$sd->timeout(0.25);
	
	while( defined $self->{sd} ) {
		
		if(my @res = $sd->accept) {
			$self->signal->send(ns => $res[0], paddr => $res[1]);	# отправляем ns и paddr ожидающему гвардейцу
		}
	
	}
	
	$sd->close;
	
	$self
}

# порождает гвардейца c номером $i
sub new_guard {
	my ($self, $i) = @_;
	
	my $coro = $app->coro->async(sub {
		# создаём q
		my $q = $self->request->new;
		# при переключении на обработчик восстанавливаем $app->q
		Coro::on_enter(sub { $app->{q} = $q });
		# инициализация воркера
		$self->init;

		# бесконечный цикл
		for(;;) {
			eval {
				for(;;) {
					# сигнал
					push @{$self->{signals}}, my $signal = AnyEvent->condvar;
					delete($self->{signal})->send if $self->{signal};
					%$q = (%{$self->request->new}, $signal->recv);
					$self->impulse;
					%$q = ();
					
				}
			};
			if($@) {
				$app->log->error(":red space", "при обработке запроса у " . ($Coro::current->{desc} // $Coro::current) . " возникла ошибка:", ":reset", "$@");
			}
		}
	})->desc("guard$i")->destroyer(closure $self, $i, sub {
		my ($self, $i) = @_;
	
		# destroyer сработает в другом волокне, но $app->q будет тем же
		$app->q->close;
		
		# восстанавливаем грохнувшихся	
		if($self->{sd} && !$app->coro->{stopped}) {
			$app->log->info("погиб гвардеец $i, сервера $self->{name}. Восстанавливаю");
			Coro::AnyEvent::sleep(3) if $app->ini->{site}{test};
			$self->new_guard($i);
		}

	})->last;
	
	$self->{guard}[$i] = $coro;
	
	$self
}

# деструктор
sub DESTROY {
	my ($self) = @_;
	
	$self->stop if $self->{sd};
	
	$self
}

# остановить сервер
sub stop {
	my ($self) = @_;

	return $self if !$self->{sd};
	
	undef $self->{sd};
	
	while(@{$self->{guard}}) {
		my $coro = shift @{$self->{guard}};

		$coro->call(sub { $app->q->close }), $coro->cancel if $coro;
	}
	
	my $cv = delete $self->{ae_cv};
	$cv->send if $cv;
	
	# if($self->{role} =~ /^(?:run|ritter)$/) {
		# $app->processManager->stop;
	# }
	
	$self
}

# бесконечный цикл ожидания и выполнения запросов
sub accept {
	my ($self) = @_;
	
	AnyEvent::fh_unblock $self->{sd};
	
	$self->{ae_cv} = &AE::cv;
	
	$self->{ae_sd} = AE::io($self->{sd}, 0, sub {
	
		return if !$self->{sd};
	
		AnyEvent::fh_block $self->{sd};
		
		my $ns = gensym;
	
		my $paddr = accept $ns, $self->{sd} or die "accept не сработал: $!";
		
		AnyEvent::fh_unblock $self->{sd};
		
		my $q = $self->request->new($ns, $paddr);
		$app->q( $q );
	
		$self->impulse;
	
	});
	
	$self->{ae_cv}->recv;
}

# обработчик запроса
sub impulse {
	my ($self) = @_;
	
	my $q = $app->q;
	
	$self->ritter;
	
	return $self if !$q->{running};
	
	my $darkhound = [$q->{ns}, $q->{paddr}, $q->{is_message}];
	$self->{ae_darkhounds}{int $darkhound} = $darkhound;
	
	if($self->{guards}) {
		
		# клиент всегда пишет первым
		push @$darkhound, AE::io($darkhound->[0]->fh, 0, closure $self, int $darkhound, sub {
			my ($self, $intdarkhound) = @_;	
			my $darkhound = delete $self->{ae_darkhounds}{$intdarkhound};
			$self->signal->send(ns => $darkhound->[0], paddr => $darkhound->[1], is_message => $darkhound->[2]);
		});
		
	} else {

		AnyEvent::fh_unblock $q->{ns};
		$app->q("<NO-REQUEST>");
		
		# клиент всегда пишет первым
		push @$darkhound, AE::io($darkhound->[0], 0, closure $self, int $darkhound, sub {
			my ($self, $intdarkhound) = @_;
			my $darkhound = delete $self->{ae_darkhounds}{$intdarkhound};
			my $q = $self->request->new;
			
			$q->{ns} = $darkhound->[0];
			$q->{paddr} = $darkhound->[1];
			$q->{is_message} = $darkhound->[2];
			
			$app->q( $q );
			
			AnyEvent::fh_block $q->{ns};
			
			#alarm $self->{alarm} if $self->{alarm};	# импульс должен пройти за установленное время
			$self->impulse;
			#alarm 0 if $self->{alarm};					# отключаем таймаут

			#AnyEvent::fh_unblock $q->{ns};	# делается в impulse
			
			$app->q("<NO-REQUEST-2>");
		});
		
	}
	
	$self
}

# запускается на каждый вызов
sub ritter {
	my ($self) = @_;
	
	my $q = $app->{q};
	
	my $args = eval { $q->thaw };
	msg(":on_red yellow", "сообщение не по протоколу:", ":reset", "$@"), return $q->close if $@;
	
	my $method = shift @$args;
	
	my $on = $self->{dispatch}{$method};
	
	msg("не зарегистрирован обработчик `$method`"), return $q->close if !$on;
	
	my $ret = $on->(@$args);
	$q->freeze(\$ret) if defined $ret;
	
	$self
}

# возвращает приветствие для сравнения
sub hi {
	return "hi!c", "hi!s";
}

# устанавливает обработчики
sub on {
	my $self = shift;
	for(my $i=0; $i<@_; $i+=2) {
		my ($method, $sub) = @_[$i, $i+1];
		$self->{dispatch}{$method} = $sub;
	}
	$self
}

# # выполняется при привышении обработчиком таймаута
# sub analarm {}

# # обработчик сигнала alrm
# # проверяет, чтобы время app->q->{now} не выходило за пределы $self->{alarm}
# # это обработчик без Coro. Он завершает процесс воркера
# sub on_alarm {
	# my ($self) = @_;

	# #my $q = $app->{q};
	# #return if !$q or time - $q->{now} < $self->{alarm};
	
	# msg "ALRM $$ " . ref($self) . " время: $self->{alarm} сек";
	
	# $SIG{"ALRM"} = "DEFAULT";
	
	# alarm 1;
	
	# eval { $self->analarm };
	# msg "обработчик analarm завершился крахом: ".ref($self)." $$ $@" if $@;
	
	# eval { $self->destroyer };
	# msg "обработчик destroyer в alarm завершился крахом: ".ref($self)." $$ $@" if $@;
	
	# alarm 0;
	# #$self->set_alarm->accept;

	# $app->processManager->stop;
	
	# exit;
# }

# # устанавливает обработчик сигнала alarm для воркера
# sub set_alarm {
	# my ($self) = @_;	
	
	# # не устанавливать с гвардией!
	# #delete $self->{alarm} if $self->{guards};
	
	# # устанавливаем через can, чтобы on_alarm можно было переопределять
	# #$sig_alarm->cb( closure $self, $self->can("on_alarm") ) if $self->{alarm};
	
	
	# $self
# }


1;