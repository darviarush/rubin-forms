package R::Process;
# работает с процессами и нитями

use POSIX ":sys_wait_h";
use threads ('yield',
	'stack_size' => 64*4096,
	'exit' => 'threads_only',
	'stringify');
use threads::shared;


sub new {
	my ($cls, $app) = @_;
	bless {app=>$app}, $cls;
}

# демонизирует
sub daemon {
	my ($self, $path) = @_;
	$path //= dirname($0).'/rubin.log';
	open STDOUT, '>', $path or die $!;
	open STDERR, '>>', $path or die $!;
	open STDIN, "<", "/dev/null" or die $!;
	my $pid = fork;
	die "Не могу выполнить fork\n" if $pid<0;
	exit if $pid;	# это родительский процесс - убиваем его
	die "Не удалось отсоединится от терминала\n" if POSIX::setsid() == -1;
	$self
}

# расщепляем процесс 
sub fork {
	my ($self, $lord, $lords) = @_;
	$lords //= $self->{app}->ini->{site}{lords};
	for(my $i=0; $i<$lords; $i++) {
		threads->create($lord) or die $!;
	}
	$! = undef;
	$self
}


# главный процесс - следит за остальными и выполняет действия по крону
sub loop {
	my ($self, $cron) = @_;
	$SIG{INT} = $SIG{TERM} = sub { my ($self) = @_; sub { $self->end_server; exit; }};
	for(;;) {
		sleep 1;
		# задачи по крону
		eval {
			$cron->($self->{app});
		};
		main::msg(":red", "Збойнула задача крона: ".($@ || $!)), $@ = $! = undef if $@ || $!;
		
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

# завершает работу с процессами
sub close {
	for my $thr (threads->list()) { $thr->detach();  }
	$self
}

# тестирует - можно ли перезагружать
sub test {
	my $test = shift // $0;
	my $res = `perl -c $test`;
	return $? == 0? undef: $res;
}

# перезагружает сервер
sub reload {
	my ($self) = @_;
	#print STDERR `nginx -s reload`;
	if(my $res = $self->test) {
		main::msg ":RED", $res, ":RESET";
	} else {
		$self->end_server;
		exec $0, @::ARGV;
	}
	$self
}

sub end_server {
	my ($self, $end_server) = @_;
	if(@_>1) {
		$self->{end_server} = $end_server;
	} else {
		$self->{end_server}->($self->{app});
	}
	$self
}

# перезагружать сервер, если изменился какой-то из модулей проекта
sub watch {
	my ($self) = @_;
	$self->{app}->watch->on(qr//, ["qq", "main.ini", grep { defined $_ and -e $_ and m!/action/.*\.(?:htm|act)\.pl$! } values %INC], sub {
		my ($path, $app) = @_;
		my $module = m!/.*\.(?:(act)|htm)\.pl$!? ($1? "action": "htm"): "module";
		main::msg ":empty", ":time", " - ", ":red", $module, ":reset", " $path";
		$app->process->reload;
	});
	$self
}


1;