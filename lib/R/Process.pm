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
		threads->create(\&R::Process::subprocess, $self->{app}) or die "not create subprocess `$i`. $!"; 
	}
	$! = undef;
	$self
}

# в новом процессе
sub subprocess {
	my ($app) = @_;
	require AnyEvent;
	local $SIG{KILL} = Utils::closure($app, sub { $_[0]->{connect}->close if $_[0]->{connect}; $_[0]->server->close });
	my $w;
	my $w = AnyEvent->timer(after => 1, interval=>1, cb=>sub{});	# просто для того, чтобы срабатывал $SIG{'KILL'}
	$app->{process}{lord}->(@_);
	undef $w;
}

# завершает работу с процессами
sub close {
	my ($self) = @_;
	for my $thr (threads->list) { $thr->kill(KILL)->join; }
	my $app = $self->{app};
	$app->{server}->close if $app->{server};
	$app->{connect}->close if $app->{connect};
	main::msg ":space", ":red", $$, ":cyan", "server close";
	$self
}

sub end { $_[0]->close; exit }

# перезагружает сервер
# sub reload {
	# my ($self) = @_;
	## print STDERR `nginx -s reload`;
	
	# my $app = $self->{app};

	# @ARGV = "ini" if @ARGV==1;
	# push @ARGV, "restart=" . fileno($app->server->{sd}) if $ARGV[$#ARGV] !~ /^restart=\d+$/;
	
	# my $pid = CORE::fork;
	# die "Не могу создать процесс. $!" if $pid < 0;
	# exec $0, @ARGV unless $pid;	# процесс
	
	# sleep 3;
	
	# my $is = waitpid $pid, WNOHANG;	# удаляем зомби
	# kill(9, $pid), waitpid $pid, 0 unless $is;	# потомок почему-то не завершился - удаляем
	
	# $self
#}

# тестирует - можно ли перезагружать
# sub test {
	# my ($self, $test) = @_;
	# $test //= $0;
	# my $res = `perl -c $test`;
	# return $? == 0? undef: $res;
# }

# перезагружает сервер
sub reload {
	my ($self) = @_;
	#print STDERR `nginx -s reload`;
	my $app = $self->{app};
	
	@ARGV = "ini" if @ARGV==1;
	push @ARGV, "restart=1" if $ARGV[$#ARGV] eq "restart=1";
	
	$self->close;
	$app->server->close;
	
	my $pid = CORE::fork;
	die "Не могу создать процесс. $!" if $pid < 0;
	exec $0, @ARGV unless $pid;	# дочерний процесс
	
	sleep 3;
	
	my $is = waitpid $pid, WNOHANG;	# удаляем зомби
	if($is) {	# потомок не завершился - завершаюсь
		main::msg "Потомок не завершился - завершаюсь";
		$app->hung->close;
		$app->connect->close; 
		#open my $p, ">/dev/null" or die $!;
		#CORE::close $_ for 3..fileno $p; 
		exit;
	}
	
	# восстанавливаемся
	main::msg ":bold black", "Потомок завершился - восстанавливаюсь";
	$app->server->create;
	$self->fork
}

# главный процесс - следит за остальными и выполняет действия по крону
sub loop {
	my ($self, $cron) = @_;
	$SIG{INT} = $SIG{TERM} = Utils::closure($self, \&R::Process::end);
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
				#if($tid == $cron) {
				#	print RED."Завершился крон № $tid\n".RESET."$error";
				#	$cron = threads->create(*cron::run)->tid();
				#} else {
					main::msg ":empty", ":red", "Завершился лорд № $tid", ":reset", ($error? "\nС ошибкой: $error": "").(@return? "\nВернул: ": "");
					main::msg \@return if @return;
					threads->create(*lord);
				#}
			}
		};
		main::msg(":red", "Лорд завершился с ошибкой: ".($@ || $!)), $@ = $! = undef if $@ || $!;
	}
}

# перезагружать сервер, если изменился какой-то из модулей проекта
sub watch {
	my ($self) = @_;
	my $watch = $self->{app}->watch;
	$watch->on(qr//, [ grep { defined $_ and !exists $watch->{file}{$_} and -e $_ } "qq", "main.ini", values %INC], sub {
		my ($path, $app) = @_;
		my $module = $path =~ m!/.*\.(\w+)\.pl$!? ($1 eq "act"? "action": $1): "module";
		main::msg ":empty", ":time", " - ", ":red", $module, ":reset", " $path";
		$app->process->reload;
	});
	$self
}


1;