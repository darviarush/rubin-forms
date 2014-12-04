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
	#main::msg ":space", ":red", $$, ":cyan", "server close";
	$self
}

sub end { $_[0]->close; exit }

# следит за изменением файлов и перезагружает сервер
sub spy {
	my ($self) = @_;
	
	my $pid = CORE::fork;
	die "Ошибка создания сокета. $!" if $pid < 0;
	if($pid) {
		main::msg ":space", ":red", $$, ":reset", " spy start";
		$self->save_pid($pid);
		my $app = $self->{app};
		$SIG{PIPE} = $SIG{INT} = $SIG{HUP} = sub {
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
			$app->action->watch;	# перекомпилировать экшены
			$app->test->watch;		# запуск теста при изменении
			$self->watch;			# перезагружать сервер, если изменился какой-то из модулей проекта
		}
		
		for(;;) {
			sleep 1;
			$app->watch->run if $_watch;
			$self->create("restart=1") if waitpid $self->{main_pid}, WNOHANG;
		} 
	}
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
	
	$self->save_pid($pid);
	
	$self
}

# сохраняет pid
sub save_pid {
	my ($self, $pid) = @_;
	$self->{main_pid} = $pid;
	$self
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
		main::msg(":red", "Сбойнула задача крона: ".($@ || $!)), $@ = $! = undef if $@ || $!;
		
		eval {
			my @joinable = threads->list(threads::joinable);
			for my $thr (@joinable) {		# проверяем наших лордов
				my @return = $thr->join();
				my $tid = $thr->tid();
				my $error = $thr->error();
				main::msg ":empty", ":red", "Завершился лорд № $tid", ":reset", ($error? "\nС ошибкой: $error": "");
				#(@return? "\nВернул: ": "")main::msg \@return if @return;
				threads->create($self->{lord}, $self);
			}
		};
		main::msg(":red", "Лорд завершился с ошибкой: ".($@ || $!)), $@ = $! = undef if $@ || $!;
	}
}

# перезагружать сервер, если изменился какой-то из модулей проекта
sub watch {
	my ($self) = @_;
	my $watch = $self->{app}->watch;
	my $dirs = [main::files("qq"), "main.ini", main::dirs("lib"), main::files("bin/qq.pl"), main::files("bin/ini.pl"), main::files($self->{app}->action->{dir_c})];
	main::msg ;
	$watch->on(qr//, $dirs, sub {
		my ($path, $app) = @_;
		my $module = $path =~ m!/.*\.(\w+)\.pl$!? ($1 eq "act"? "action": $1): "module";
		main::msg ":empty", ":time", " - ", ":red", $module, ":reset", " $path";
		kill HUP, $app->process->{main_pid};
	});
	$self
}


1;