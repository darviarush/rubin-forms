package R::Shiva;
# энтропия - выполняет задачи по времени
# лета - река времени
# исида-сотис - Сириус Л в созвездии Большого Пса

use common::sense;
use R::App;

use Algorithm::Cron;


# конструктор
sub new {
	my ($cls) = @_;
	bless {
		loop => 0,					# признак, что shiva не запущен
		tasks => {},				# задания по имени
		times => {},				# задания по времени (в минутах): time => task
		run => undef,				# время предыдущего запуска
		now => sub {time()},		# текущее время 
	}, ref $cls || $cls;
}


# добавляет в process manager
sub start {
	my ($self) = @_;
	
	$app->processManager->birth("shiva" => '$app->shiva->loop');
	
	$self
}

# подгржает необходимые модули
sub setup {
	my ($self) = @_;
	
	$app->meta;		# загружаем модели: в них - задания для шивы
	
	$self
}

# инициализирует Шиву
sub init {
	my ($self) = @_;
	$self->{loop} = 1;
	$self->{run} = int($self->{now}->() / 60);
	
	# парсит крон-время
	#require "Algorithm/Cron.pm";
	
	my $tasks = $self->{tasks};
	while(my ($key, $task) = each %$tasks) {
		$self->init_on($task);
	}
	
	$self
}

# бесконечный цикл ожидания и выполнения заданий
sub loop {
	my ($self) = @_;
	
	msg1 "shiva loop";
	$self->setup;
	$self->init;
	msg1 "shiva setup start";
	
	for(;;)	{
		sleep 60;					# срабатывает раз в минуту
		$self->step;				# делаем шаг
	}
}

# делает шаг
sub step {
	my ($self) = @_;
	
	my $run = int( $self->{now}->() /  60);
	my $next_run = $run;
	my $times = $self->{times};
	
	#msg1 "step: run:", ":size10000", $app->perl->strftime("%H:%M", $run*60);
	
	for(my $min = $self->{run}; $min <= $run; $min++) {
		#msg1 "step: min:", $app->perl->strftime("%H:%M", $min*60);
		my $tasks = delete $times->{$min};
		next if !$tasks;
	
		for my $task (@$tasks) {
			$task->{code}->($min*60, $task);
			
			# $min, а не time, т.к. если время прошло, то надо выполнить всё равно
			my $time = int($task->{times}->next_time($min*60) / 60);
			
			# время проверки от прошлого срабатывания
			$next_run = $time if $time < int($self->{now}->() / 60) && $next_run > $time;
			
			#msg1 $task->{name}, $app->perl->strftime("%H:%M", $time*60);
			push @{$self->{times}{$time}}, $task;
		}
		
	}
	
	$self->{run} = $next_run;
	
	$self
}

# инициализирует задание и отправляет его в очередь
sub init_on {
	my ($self, $task) = @_;
	
	return $self if $task->{times};			# уже инициализирован
	
	my $times = $task->{times} = Algorithm::Cron->new(crontab => $task->{cron}, base => "local");
	
	my $Time = $self->{now}->();
	my $time = int($times->next_time($Time) / 60);
	
	push @{$self->{times}{$time}}, $task;
	
	$self
}


# добавляет задание
sub on {
	my ($self, $name, $times, $code) = @_;
	
	msg(":red", "задание `$name` - уже добавлено"), return $self if exists $self->{tasks}{$name};
	
	my $task = $self->{tasks}{$name} = {
		name => $name,
		cron => $times,
		code => $code,
	};
	
	$self->init_on($task) if $self->{loop};			# инициализируем
	
	$self
}

# удаляет задание по имени
sub off {
	my ($self, $name) = @_;
	
	die "задания `$name` - нет среди добавленных. Не могу удалить" if exists $self->{tasks}{$name};
	
	my $task = delete $self->{tasks}{$name};
	my $sec = $task->{sec};	# время следующего запуска
	my $name = $task->{name};
	if(defined $sec) {
		my $times = $self->{times};
		@{$times->{$sec}} = grep { $_->{name} ne $name } @{$times->{$sec}};
		delete $times->{$sec} if !@{$times->{$sec}};
	}
	
	
	$self
}

# проверяет существование задания
sub exists {
	my ($self, $name) = @_;
	exists $self->{tasks}{$name}
}

1;