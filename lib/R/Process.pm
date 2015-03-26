package R::Process;
# работает с процессами и нитями

use POSIX qw/:sys_wait_h/;
use threads ('yield',
	'stack_size' => 64*4096,
	'exit' => 'threads_only',
	'stringify');
use threads::shared;
#use forks;


sub new {
	my ($cls, $app) = @_;
	
	bless {app=>$app}, $cls;
}

# демонизирует
sub daemon {
	my ($self, $path) = @_;
	$path //= $_FRAMEWORK.'/watch/rubin.log';
	open STDOUT, '>', $path or die "Не могу перенаправить STDOUT. $!";
	open STDERR, '>>', $path or die "Не могу перенаправить STDERR. $!";
	open STDIN, "<", "/dev/null" or die "Не могу перенаправить STDIN. $!";
	my $pid = fork;
	die "Не могу выполнить fork. Error #$pid\n" if $pid<0;
	exit if $pid;	# это родительский процесс - убиваем его
	die "Не удалось отсоединится от терминала\n" if POSIX::setsid() == -1;
	$self
}

# расщепляем процесс 
sub fork {
	my ($self, $lord, $lords) = @_;

	#POSIX::setpgid($$); # устанавливаем свою группу процессов
	
	my $ini = $self->{app}->ini;
	$self->{lord} = $lord //= $self->{lord};
	$lords //= $ini->{site}{lords};
	
	for(my $i=0; $i<$lords; $i++) {
		threads->create($lord, $self) or die "not create subprocess `$i`. $!"; 
	}
	$! = undef;
	$self
}

# в новом процессе
# sub subprocess {
	# my ($app) = @_;
	# require AnyEvent;
	# local $SIG{KILL} = Utils::closure($app, sub { $_[0]->{connect}->close if $_[0]->{connect}; $_[0]->server->close });
	# my $w;
	# $w = AnyEvent->timer(after => 1, interval=>1, cb=>sub{});	# просто для того, чтобы срабатывал $SIG{'KILL'}
	# $app->{process}{lord}->(@_);
	# undef $w;
# }

# завершает работу с процессами
sub close {
	my ($self) = @_;
	for my $thr (threads->list) { $thr->detach; }
	my $app = $self->{app};
	$app->{server}->close if $app->{server};
	$app->{connect}->close if $app->{connect};
	
	#my @pids = map { my @x = split /\s*/, $_; POSIX::getppid() == $x[]? $x[1]: () } split /\n/, `ps -W`;
	kill -9, POSIX::getppid();	# убиваем группу парента
	#kill -9, $$;	# убиваем свою группу
	
	#main::msg ":space", ":red", $$, ":cyan", "server close";
	$self
}

sub end { $_[0]->close; exit }

# следит за изменением файлов и перезагружает сервер
sub spy {
	my ($self) = @_;
	
	setpgrp 0, $$;
	
	# демонизируемся
	my $_daemon = $self->{app}->ini->{site}{daemon};
	$self->daemon if $_daemon;
	
	# pipe my $rd, my $wr;
	# my $old=select $rd; $|=1; select $wr; $|=1; select $old;
	
	my $pid = CORE::fork;
	die "Ошибка создания дочернего процесса. $!" if $pid < 0;
	if($pid) {
		main::msg ":space", ":red", $$, ":reset", "spy start", ":green", $pid;
		$self->main_pid($pid);
		my $app = $self->{app};
		
		#$SIG{PIPE} =
		$SIG{INT} = $SIG{HUP} = my $exit = sub {
			kill -9, $self->{main_pid};
			$app->{hung}->close if $app->{hung};
			main::msg ":space", ":red", $$, ":reset", "spy exit";
			exit;
		};
		
		# перекомпиливать сторонние файлы проекта
		$app->hung if $app->ini->{site}{hung};
		
		# следить за изменениями
		my $_watch = $app->ini->{site}{watch};
		if($_watch) {
			$app->action->watch;	# перекомпилирует экшены, а на него в watch/action срабатывает $self->watch;
			$app->test->watch;		# запуск теста при изменении
			$self->watch;			# перезагружать сервер, если изменился какой-то из модулей проекта
		}
		
		# my $test = "";
		# my ($rdr, $wdr, $edr);
		# vec($test, fileno($rd), 1) = 1;
		# Utils::nonblock($rd);
		
		for(;;) {
			eval {
				sleep 1;
				# if(select $rdr=$test, $wdr=$test, $edr=$test, 0) {
					# main::msg "any:", <$rd>;
				# }
				$app->watch->run if $_watch;
				$self->create("restart=1") if waitpid $self->{main_pid}, WNOHANG;
			};
			main::msg ":red", "Сбой в цикле spy:\n$@" if $@;
		}
		
	}
	
	# require POSIX;
	# POSIX::dup2($wr, fileno STDOUT);
	# POSIX::dup2($wr, fileno STDERR);
	
	$self
}

# создаёт главный процесс 
sub create {
	my ($self, @ini) = @_;
	
	my @av = @ARGV;
	@av = "ini" if @av==1;	
	push @av, @ini;
	
	my $pid = CORE::fork;
	die "Ошибка создания процесса. $!" if $pid < 0;
	exec "perl", $0, @av unless $pid;
	
	$self->main_pid($pid);
	
	$self
}

# сохраняет pid
sub main_pid {
	my ($self, $pid) = @_;
	if(@_==1) { $self->{main_pid} }
	else {
		$self->{main_pid} = $pid;
		$self
	}
}

# главный процесс - следит за остальными и выполняет действия по крону
sub loop {
	my ($self, $cron) = @_;
	$SIG{INT} = $SIG{TERM} = Utils::closure($self, $self->can("end"));
	for(;;) {
		sleep 1;
		# задачи по крону
		eval {
			$cron->($self->{app});
		};
		main::msg(":red", "Сбойнула задача крона:\n$@$!"), $@ = $! = undef if $@ || $!;
		
		eval {
			my @joinable = threads->list(threads::joinable);
			for my $thr (@joinable) {		# проверяем наших лордов
				my @return = $thr->join;
				my $tid = $thr->tid;
				my $error = $thr->error;
				main::msg ":empty", ":red", "Завершился лорд № $tid", ":reset", ($error? "\nС ошибкой:\n$error": "");
				#(@return? "\nВернул: ": "")main::msg \@return if @return;
				threads->create($self->{lord}, $self);
			}
		};
		main::msg(":red", "Лорд завершился с ошибкой:\n$@$!"), $@ = $! = undef if $@ || $!;
	}
}

# перезагружать сервер, если изменился какой-то из модулей проекта
sub watch {
	my ($self) = @_;
	my $watch = $self->{app}->watch;
	my $dirs = [main::files("qq"), "main.ini", main::dirs("bin/make"), main::dirs("lib"), main::files("bin/qq.pl"), main::files("bin/ini.pl")];

	$watch->on(qr//, $dirs, sub {
		my ($path, $app) = @_;
		main::msg ":empty", ":time", " - ", ":red", "module", ":reset", " $path";
		$app->process->reset;
	});
	$self
}

# перезагружает сервер
sub reset {
	my ($self) = @_;
	kill HUP, $self->{main_pid};
}


1;