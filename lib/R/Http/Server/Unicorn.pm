package R::Http::Server::Unicorn;
# http-сервер с интеграцией с базой и шаблонами

use parent qw/R::Http::Server/;

use common::sense;

use R::App;

use Term::ANSIColor;

# # выводим ошибки при завершении
# our $errput;
# END {
	# if(defined $errput and $errput ne "") {
		# if(!$app->ini->{site}{test}) {
			# $app->log->error( $errput );
		# }
		# else {
			# my $x = $app->file("html/error/works0.html")->read;
			# $x =~ s/\[% error %\]/$app->html->escape_ansi( $errput )/e;
			# $app->file("html/error/works.html")->write($x);
		# }
	# }
# }

# конструктор
sub new {
	my ($cls) = @_;
	
	$cls->SUPER::new(
		port => $app->ini->{site}{port},				# порт
		ritters => $app->ini->{site}{ritters} // 1,		# количество процессов
		guards => $app->ini->{site}{guards},			# количество волокон
		keepalives => $app->ini->{site}{keepalives},	# количество постоянных соединений
		websockets => $app->ini->{site}{websockets},	# количество веб-сокетов
		test => $app->ini->{site}{test},				# тестовый режим
	)
}

# запускается когда сокет уже создан, а воркеры ещё не порождены
sub setup {
	my $self = shift;
	
	msg ":space", "создание сокета $self->{port}:", ":bold black", $self->{bench_make};
	
	# создаём сервер кэша
	
	# запускаем шедулер
	#$app->shiva->start;
	$app->bench->time;
	$app->process->new("shiva" => '
		$app->shiva->loop
	')->fg->done->run;
	msg ":space", "запуск shiva:", $app->bench->log;
	
	# запускаем сервер кэша
	if($self->{ritters} > 1) {
		$app->bench->time;
		$app->process->new("cache-server" => '
			$app->casheServer->loop
		')->fg->done->run;
		msg ":space", "запуск сервера кэша:", $app->bench->log;
	}

	# запускаем сервер картинок
	$app->bench->time;
	
	require "model/Img.pm";
	die "нет \$R::Row::Img::_convert!" if !$R::Row::Img::_convert;
	
	$app->process->new("image-server" => '
		$app->processServer->new(name=>"img", remote=>$app->ini->{img}{port}, port=>$app->ini->{img}{port})->on(
			convert => sub {
				'. $R::Row::Img::_convert .'
			},
		);
	')->fg->done->run;
	msg ":space", "запуск сервера картинок:", $app->bench->log;
		
}

# инициализирует процесс рыцаря
sub initialize {
	my ($self) = @_;
	
	# общее время
	$app->bench->time;
	
	# первый рыцарь должен сохранить css
	my $first = $0 =~ /(\d+)$/? $1==1: 1;

	msg1 "RITTER $first";
	
	# если один воркер, то зачем нам лишние процессы?
	if($self->{ritters} < 2) {
		$app->bench->time;
		$app->cashe( $app->cacheBagatur );
		msg ":space", "замена клиента кэша на локальный кэш:", $app->bench->log;
	}
	
	# добавляем js-файл
	$app->bench->time;
	$app->js->require("html/js/app-rubin-forms.js");
	msg ":space", "загрузка js-файлов:", $app->bench->log;
	
	# загружаем модели, для того, чтобы появились все связи
	$app->bench->time;
	$app->meta;
	msg ":space", "загрузка моделей:", $app->bench->log;
	
	# подключаем символы
	$app->bench->time;
	$app->sign;
	msg ":space", "загрузка символов html:", $app->bench->log;
	
	# подключаем спрайты
	$app->bench->time;
	$app->sprite;
	msg ":space", "загрузка спрайтов:", $app->bench->log;
	
	# подключаем стили
	$app->bench->time;
	require "html/css/style.pass";
	msg ":space", "компиляция стилей:", $app->bench->log;
	
	if($first) {
		# компиллируем шаблоны
		$app->bench->time;
		$app->view->compile;
		msg ":space", "компилляция шаблонов:", $app->bench->log;
	}
	
	# загружаем шаблоны
	$app->bench->time;
	$app->view->load;
	msg ":space", "загрузка шаблонов:", $app->bench->log;
	
	if($first) {
		$app->bench->time;
		$app->css->include("html/sprite/*.css")->save("html/css/style.css");
		msg ":space", "сохранение стилей:", $app->bench->log;
		
		$app->bench->time;
		$app->js->save("html/js/app.js");
		msg ":space", "сохранение фронтэнд-скриптов:", $app->bench->log;
	}
	
	# очищаем css
	$app->css->clear;
	$app->cssOrig( $app->css );
	
	# очищаем js
	$app->js->clear;
	
	# добавляем диспетчеров из отображений
	$app->bench->time;
	$self->dispatchers( $app->view->routers );
	
	# # регистрируем диспетчеров из контроллеров
	# $self->controllers(
		# "/" => "Unicorn",
	# );
		
	# переименовываем диспетчеров, а именно: все индексы
	$self->rename_dispatchers( map {
		my $x=$_;
		$x=~s!/index$!!? (($x eq ""? "/": $x) => $_): ();
	} keys $self->{dispatch} );
	
	msg ":space", "добавление диспетчеров:", $app->bench->log;
	
	msg ":space", "общее время:", $app->bench->log;
	msg ":space", "от старта:", $app->bench->start_time->log;
	
	#msg1 "initialize";
	
}

# инициализирует волокно гвардейца
sub init {
	my ($self) = @_;
	#msg1 "init";
	$self
}

# вызывается перед обработкой запроса
sub before {
	my $self = shift;
	
	# my $q = $app->q;
	# my $path = $q->uri->path;
	# my $ip = $q->ip;
	
	# $app->cache->inc("vi-$path", "visit");			# подсчитываем посещения
	# $app->cache->inc("vi-$ip-$path", "visit-ip");		# подсчитываем уникальные посещения
	
	$self
}

# вызывается после обработки запроса
sub after {
	my ($self) = @_;

	$self
}

1;