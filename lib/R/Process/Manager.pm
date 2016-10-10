package R::Process::Manager;
# управляет процессами
# порождает и восстанавливает завершившиеся процессы
# завершает все процессы

use common::sense;
use R::App;

use POSIX qw/setsid :signal_h :errno_h :sys_wait_h/;

my $singleton;

# конструктор-синглетон
sub new {
	my ($cls) = @_;
	
	$singleton //= bless {
		kid => {},	# pid=>процесс
	}, ref $cls || $cls;
}

my $sec = 5;

# завершает все дочерние процессы
sub stop {
	my ($self) = @_;
	
	my $kids = delete $self->{kid};
	
	return $self if !$kids;
	
	my @pid = keys %$kids;
	msg "$$: отправляем потомкам сигнал INT", join ", ", @pid;
	kill 'INT', @pid;
	
	msg "$$: ожидаем завершения потомков";
	for(;;) {
		while(my $kid = waitpid(-1, &WNOHANG)) {
			msg("$$: нет процессов"), last if $kid < 0;	# нет процессов
			#msg("процесс $kid не завершился"), kill "KILL", $kid if !WIFEXITED($?);	# процесс не завершился
			# процесс завершился
			if(my $birth = delete $kids->{$kid}) {
				msg "$$: завершился $kid - $birth->{name}";
				$birth->{destroy}->($birth);	# выполняем декструктор
			}
			else {
				msg "$$: завершившийся киндер $kid не принадлежит менеджеру процессов!"
			}
		}
		
		# опрашиваем: вдруг процесс уже завершился, но нам не сказал
		for my $kid (keys %$kids) {
			my $birth = $kids->{$kid};
			if(!kill 0, $kid) {					# процесс завершился
				delete $kids->{$kid};
				msg "$$:завершился $kid - $birth->{name}";
				$birth->{destroy}->($birth);	# выполняем декструктор
			}
			elsif($birth->{check} > $sec) {
				msg "$$: процесс $kid - $birth->{name} не смог завершиться за $sec секунд. Убиваю его 9-м сигналом";
				kill 9, $kid;
			}	# гасим вусмерть процесс
			else {
				$birth->{check}++;
			}
		}

		last if !keys %$kids;
		msg "$$: не завершены потомки:" . join ", ", keys %$kids;
		sleep 1;
	}
	
	$self
}


END {
	msg("$$: завершение менеджера процессов"), $singleton->stop if $singleton && $singleton->{kid};
	
	$singleton->{destroy}->($singleton) if $singleton && $singleton->{destroy};
}

# добавляет файловые дескрипторы, которые нужно передать всем дочерним процесcам
sub fd {
	my $self = shift;
	@{$self->{fd}} = map { ref($_)? $_->fileno: $_ } @_;
	$self
}

# порождает процесс
sub birth {
	my ($self, $name, $birth, $destroy) = @_;
	
	die "используйте: app->processManager->birth(name => string_code, [destroy])" if ref $birth;
	
	my $process = $app->process->new($name => $birth)->fd(@{$self->{fd}})->nosavepid->run;
	$process->{destroy} = $destroy // sub {};
	
	$self->{kid}{$process->pid} = $process;
	
	$self
}

# бесконечный цикл ожидания и восстановления потомков
sub loop {
	my ($self) = @_;
	
	# цикл восстановления процессов
	for(;;) {
		sleep 1;
		
		while(my $kid = waitpid -1, WNOHANG) {
			msg("$$: нет процессов"), last if $kid < 0;	# нет процессов
			msg("$$: процесс $kid не завершился. Я его закилял 9-м сигналом!"), kill "KILL", $kid if !WIFEXITED($?);	# процесс не завершился. Что, поменял состояние?! Работать не хочешь?! Умри, сука!!!
			# процесс завершился
			if(my $birth = delete $self->{kid}{$kid}) {	# если забитый появится
				msg "$$: Завершился обработчик $kid - $birth->{name}. Восстанавливаю";
				$birth->{destroy}->($birth);	# выполняем декструктор
				$self->birth(@$birth{qw/name exec destroy/});
			}
		}
	}
}

# количество процессов
sub count {
	my ($self) = @_;
	my $kid = $self->{kid};
	!$kid? 0: scalar keys %$kid;
}


# # сигнал аларм для серверов
# our $sig_alarm = $app->signal->new;
# our $timeout_alarm = $app->ini->{site}{alarm} // 1;
# $SIG{ALRM} = sub {  $sig_alarm->send; alarm $timeout_alarm };


# # выполняется при привышении обработчиком таймаута
# #sub analarm {}

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
	# # устанавливаем через can, чтобы on_alarm можно было переопределять
	# $sig_alarm->cb( closure $self, $self->can("on_alarm") );
	# $self
# }



1;