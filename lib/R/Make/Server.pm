package R::Make::Server;
# задачи для работы с сервером

use common::sense;
use R::App;
use R::Make;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# хелпер для процесса
sub unicorn {
	$app->process->new($app->project_name => '
		$app->server->run;
	')
}

=pod
СЕРВЕР
		routers [маска]      список роутеров
        loop                 запускает одиночный сервер в консоли
        start                стартует сервер в фоне
		restart              перезапускает сервер
        status               ианформация о запущенном сервере
        stop                 останавливает сервер
        watch [scserver]     запускает отладочный сервер
=cut

category "СЕРВЕР";


name "routers";
args "[маска]";
desc "список роутеров";
spec "маска - регулярка для пути роутера";
sub routers {

	
	my $log = $app->log;
	$app->log( $log->new(log_as_is=>undef, log=>undef) );
	$app->meta;
	my $server = $app->server;
	$server->initialize;
	$app->log($log);


	my $route = $server->{"dispatchers"};

	my @route = keys %$route;
	@route = grep { m!$_[0]!o } @route if @_;
	@route = sort @route;

	my @rows;
	my @colors;

	# добавляем роутеры в список
	for my $key (@route) {
		my $dispatcher = $route->{$key};

		$key .= "  ~  " . $dispatcher->olduri if $dispatcher->olduri;
		
		push @rows, [$key, $dispatcher->cls, $dispatcher->action_name];
		push @colors, [":empty black bold", $dispatcher->color, ":reset"];
	}
	
	# добавляем сообщения в список
	my $message = $server->{messages};
	for my $key (keys %$message) {
		push @rows, [$key, "<message>"];
		push @colors, [":empty black bold", ":bold yellow on_green", ":reset"];
	}

	my @max;
	for my $row (@rows) {
		for(my $i=0; $i<@$row; $i++) {
			$max[$i] = length $row->[$i] if $max[$i] < length $row->[$i];
		}
	}

	my $k = 0;
	for my $row (@rows) {
		my $color = $colors[$k++];
		$app->log->info(
			$color->[0], $row->[0], " " x ($max[0] - length $row->[0]), " ",
			$color->[1], $row->[1],
			($row->[2] || $row->[3]?(" " x ($max[1] - length $row->[1]), $color->[2], $row->[2]): ()), " ",
			($row->[3]? (" " x ($max[2] - length $row->[2]), $row->[3]): ()),
		);
	}

	if($app->{processManager}) {
		$app->log( $log->new(log_as_is=>undef, log=>undef) );
		$app->{processManager}->stop;
		$app->log($log);
	}
	
	#$? = 0;
	
}

name "loop";
desc "запускает одиночный сервер в консоли";
sub loop {
	$app->server->loop;
}

name "run";
desc "запускает многопоточный сервер в консоли";
default_task;
sub run {
	$app->server->run;
}

name "start";
desc "стартует сервер в фоне";
sub start {

	my $unicorn = &unicorn;

	if($unicorn->exists) {
		print STDERR "сервер уже запущен. Воспользуйтесь командой restart\n";
	} else {
		print STDERR "запускается сервер .";
		$unicorn->bg->start;
		
		for my $i (1..5) {
			sleep 1;
			print STDERR ".";
			undef $@;
			
			$@ = 1, last if !$unicorn->exists;
			
			eval {
				$app->httpAgent->go("/");
			};
			last if !$@;
		}
		if($@) {
			print STDERR " fail\nсервер не смог запуститься\n";
		} else {
			print STDERR " ok\nсервер запущен\n";
		}
	
	}
}


name "restart";
desc "перезапускает сервер";
rels "stop", "start";
sub restart {

	todo;
	# my $unicorn = &unicorn;
	
	# if($unicorn->exists) {
		# make("stop");
		# $app->log->default;
		# $unicorn->bg->start;
		# print STDERR "сервер перезапущен\n";
	# } else {
		# print STDERR "сервер не запущен\n";
		# make("start");
	# }

}


name "status";
desc "информация о запущенном сервере";
sub status {
	
	if(&unicorn->exists) {
		print STDERR "сервер запущен\n";
	} else {
		print STDERR "сервер не запущен\n";
	}

}


name "stop";
desc "останавливает сервер";
sub stop {

	my $unicorn = &unicorn;

	if($unicorn->exists) {
		print STDERR "сервер останавливается\n";
		$unicorn->stop;
		print STDERR "сервер остановлен\n";
		$? = 0;		# убиваемые процессы оставляют значение
	} else {
		$unicorn->erasepid;
		print STDERR "сервер не запущен\n";
	}
	
}

name "killall";
args "";
desc "удаляет все процессы perl";
sub killall {
	for my $line (split /\n/, `ps -a`) {
		$line =~ /(\d+)/;
		my $pid = $1;
		msg("kill -9 $line"), kill -9, $pid if $line =~ /\bperl\b/ && $pid != $$;
	}
}

name "watch";
args "[start|scserver]";
desc "перезапускает тестовый сервер, при изменении его файлов";
spec "
без параметров watch - запускается в консоли дефолтное задание
";
sub watch {

	my $server_param = '$app->server->loop';
	
	if(@_==0) {
	}
	elsif($_[0] eq "scserver") {
		$server_param = 'use R::Make; use R::Make::Scenario; make("scserver");';
	}
	elsif($_[0] eq "start") {
		$app->log->default;
	} else {
		print STDERR "используйте: watch [start|scserver]\n";
		exit;
	}
	
	my $unicorn = $app->process->new($app->project_name => $server_param)->fg->done;
	
	msg(":space", $app->project_name, "запущен. Остановите его"), exit if $unicorn->exists;
	
	my $lib = $app->file(qw(lib model view html/css/style.pass), $app->{project_name}, "etc/$app->{project_name}.ini");
	#->filter(/\.(?:pm|pl|pass|ini)|$/);
	
	# инициализируем
	$lib->watch;
	#msg1 $lib->{watch};
	
	# запускаем
	$unicorn->start;
	
	for(;;) {
		sleep 1;
		
		my ($changed, $new, $deleted) = $lib->watch;
		
		next if !( $changed->length || $new->length || $deleted->length );
		
		if($unicorn->exists) {
			print STDERR "Останавливаем unicorn # $unicorn->{pid}\n";
			$unicorn->stop;
		}
		else {
			print STDERR "Удалили зомби # $unicorn->{pid}\n";
			$unicorn->waitkid;	# удаляем зомби
		}
		
		$unicorn->start;
		print STDERR "Запустили unicorn # $unicorn->{pid}\n";
	}
	
}

1;