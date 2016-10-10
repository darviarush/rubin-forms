package R::Process;
# работает с текущим процессом

use common::sense;
use R::App;

use POSIX qw/setsid :sys_wait_h/;
use Proc::FastSpawn;


# $SIG{'CHLD'} = sub {
	# kill_zombie();
# };

has qw/name/;

# конструктор
sub new {
	my ($cls, $name, $code) = @_;
	
	die "используйте: app->process->new(name => string_code)" if ref $code;
	
	bless {
		name => $name,
		pid => undef,
		exec => $code,
		bg => 1,
		fd => [0, 1, 2],
		savepid => 1,		# сохранять pid
	}, ref $cls || $cls;
}

# # деструктор - прибрать за собой
# sub DESTROY {
	# my ($self) = @_;
	# $self->stop;
# }

# вешается на конец выполнения программы, используется в тестах
my @PROCESSES;
sub done {
	my ($self) = @_;
	push @PROCESSES, $self;
	$self
}

END {
	for my $process (@PROCESSES) {
		$process->stop if $process->exists;
	}
}


# свойство bg - запускать процесс в фоне
sub bg {
	my $self = shift;
	die "ненужные параметры метода" if @_>0;
	$self->{bg} = 1;
	$self
}

# свойство fg - запускать процесс в текущем окружении
sub fg {
	my $self = shift;
	die "ненужные параметры метода" if @_>0;
	$self->{bg} = 0;
	$self
}

# не сохранять pid
sub nosavepid {
	my ($self) = @_;
	$self->{savepid} = 0;
	$self
}

# сохранять pid
sub yessavepid {
	my ($self) = @_;
	$self->{savepid} = 1;
	$self
}

# добавляет файловые дескрипторы, которые нужно передать дочернему процессу
sub fd {
	my $self = shift;
	push @{$self->{fd}}, map { ref($_)? $_->fileno: $_ } @_;
	$self
}

# # создаёт процесс
# sub fork {
	# my ($self) = @_;
	
	# #die "Инициализирована AnyEvent. Нельзя после её инициализации создавать процессы" if $AnyEvent::MODEL;
	
	# my $pid = fork;
	# die "не могу создать процесс: $!" if !defined $pid or $pid < 0;
	# if(!$pid) {
		# if($self->{bg}) {	# фоновый процесс
			# $self->newsid;	# новая сессия
			# $pid = fork;
			# die "не могу создать процесс: $!" if !defined $pid or $pid < 0;
			# exit if $pid;	# завершаем промежуточный процесс
		# }
		# $self->run;
		# exit
	# }
	# $self->{pid} = $pid;
	# $self->waitkid, undef $self->{pid} if $self->{bg};
	# $self
# }

# запускает процесс в текущем
sub run {
	my ($self) = @_;
	die "Process.run: процесс № " .$self->pid. " уже запущен, вначале остановите его" if $self->exists;
	
	for my $fd (@{$self->{fd}}) {
		fd_inherit $fd;
	}
	
	my $name = $self->{name};

	my $file = $app->file(my $path = "var/process/$name")->mkpath;
	
	
	$file->write("use lib 'lib';
use common::sense;
use R::App;
\$app->project_name('$app->{project_name}');
\$app->process_name('$self->{name}');
unlink '$path' or msg ':empty', 'не могу удалить `$path`: ', \$!;
msg1 'запустился', ':red', \$\$, ':black bold', \$app->process_name;
$self->{exec}
");
	
	utf8::encode($path);
	
	my $pid = spawn $^X, ["perl", $path];
	
	die "процесс $self->{name} не смог запуститься: $!" if !defined $pid;

	$self->pid($pid);
	
	$self->savepid if $self->{savepid};
	
	$self
}

# стартует процесс
sub start {
	my ($self) = @_;
	if($self->{bg}) {
		die "Process.start: процесс № " .$self->pid. " уже запущен, вначале остановите его" if $self->exists;
		my $pid = fork;
		die "не могу создать процесс для демонизации: $!" if !defined $pid or $pid < 0;
		if($pid == 0) {
			@{ $self->{fd} } = grep { $_ > 2 } @{ $self->{fd} };	# 0,1,2 - удаляем
			$self->newsid;	# новая сессия
			$self->run;		# запускаем
			exit;			# завершаем промежуточный процесс
		}
	}
	else {
		$self->run
	}
}
# рестартует процесс. Если процесс не был запущен, то он стартует
sub restart {
	my ($self) = @_;
	$self->stop if $self->exists;
	$self->start;
}

# отключает процесс от терминала
sub newsid {
	my ($self) = @_;
	die "Не удалось отсоединится от терминала\n" if setsid() < 0;
	my $maxfd = POSIX::sysconf(&POSIX::_SC_OPEN_MAX) || 1024;
	my %openfd = $app->perl->set( @{$self->{fd}} );
	for(my $i=0; $i<$maxfd; $i++) {
		close $i if !exists $openfd{$i};
	}
	open STDIN, "</dev/null";
	open STDOUT, ">/dev/null";
	open STDERR, ">&STDOUT";
	$self
}


# путь к pid-файлу
sub pidpath {
	my ($self) = @_;
	"var/$self->{name}.pid"
}


# пишет/читает из pid-файла
sub savepid {
	my ($self) = @_;
	my $path = $self->pidpath;
	open my $f, ">", $path or die $!;
	print $f $self->{pid};
	close $f;
	$self
}


# загружает pid
sub loadpid {
	my ($self) = @_;
	my $path = $self->pidpath;
	my $f;
	open $f, "<", $path and do {
		$self->{pid} = <$f>;
		close $f;
	};
	undef $!;
	$self
}


# загружает и удаляет pid-файл
sub erasepid {
	my ($self) = @_;
	unlink $self->pidpath;	
	$self
}

# посылает сигнал INT, если не указан другой
sub kill {
	my ($self, $sig) = @_;
	if($self->{pid}) {
		$sig //= "INT";
		kill $sig, $self->{pid};
	}
	$self
}

# процесс имеет pid-файл и существует указанный в нём процесс
sub exists {
	my ($self) = @_;
	return unless -e $self->pidpath;
	my $pid = $self->pid // $self->loadpid->pid;
	return if !$pid || !Num $pid;
	$self->check_pid;		# удаляем зомби, если это дочерний процесс
	kill 0, $pid;
}

# останавливает процесс
sub stop {
	my ($self, $sig, $timeout) = @_;
	$self->loadpid->kill($sig // "INT")->wait($timeout // 5)->erasepid
}

# ожидает завершения процесса
sub wait {
	my ($self, $seconds) = @_;
	$seconds //= 5;
	my $sec = $seconds;
	
	while($self->exists) {
		msg("закончилось время ожидания завершения процесса № ".$self->pid." ".$self->name.". Убиваю его 9-м сигналом"), kill(-9, $self->pid), last if 0 >= $sec--;
		if(0 and $app->{coro}) { Coro::Timer::sleep(1); } else { sleep(1) }
	}
	
	$sec = $seconds;
	
	while($self->exists) {
		die "закончилось время ожидания завершения процесса № ".$self->pid." ".$self->name if 0 >= $sec--;
		if(0 and $app->{coro}) { Coro::Timer::sleep(1); } else { sleep(1) }
	}
	
	$self
}

# ожидает завершения процесса, если он дочерний
sub waitkid {
	my ($self) = @_;
	waitpid $self->{pid}, 0;	#, WNOHANG;
	$self
}

# проверяет: существует ли процесс, если он дочерний
sub check_pid {
	my ($self) = @_;
	waitpid $self->{pid}, WNOHANG;
}


# удаляет всех зомби
sub kill_zombie {
	my ($self) = @_;
	my $kid;
	do { $kid=waitpid -1, WNOHANG; } while($kid);
	$self
}

# устанавливает/возвращает pid
sub pid {
	if(@_>1) {
		my ($self, $val) = @_;
		$self->{pid} = $val;
		$self
	} else {
		shift->{pid}
	}
}

# отправляет сигнал всем процессам, подходящим по маске
sub killall {
	my ($self, $sig, $name) = @_;
	local ($1, $`, $', $_);
	kill $sig, map { /(\d+)/ && $1 } grep { /$name/ } split "\n", `ps -A -o pid,command`;
	$self
}

1;
