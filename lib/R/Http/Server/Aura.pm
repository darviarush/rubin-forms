package R::Http::Server::Aura;
# http-сервер на Coro

use base R::Http::Server;

use common::sense;
use R::App;

# подулючаем coro
$app->coro;

# конструктор
sub new {
	my ($cls) = @_;
	
	$cls->SUPER::new(
		port => $app->ini->{site}{port},			# порт
		ritters => $app->ini->{site}{ritters} // 1,	# количество процессов
		guards => $app->ini->{site}{guards},		# количество волокон
		test => $app->ini->{site}{test},			# тестовый режим
	)
}

# запускается когда сокет уже создан, а воркеры ещё не порождены
sub setup {
	my $self = shift;
	
	# общее время
	$app->bench->time;
	
	$app->bench->time;
	$app->connect;
	
	msg ":space", "создание сокета $self->{port}:", ":bold black", $self->{bench_make};
	msg ":space", "коннект к базе:", ":bold black", $app->bench->log;
	
	
	# загружаем модели, для того, чтобы появились все связи
	$app->bench->time;
	$app->modelMetafieldset->load_all_models;
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
	
	# компиллируем шаблоны
	$app->bench->time;
	$app->view->compile;
	msg ":space", "компилляция шаблонов:", $app->bench->log;
	
	# загружаем шаблоны
	$app->bench->time;
	$app->view->load;
	msg ":space", "загрузка шаблонов:", $app->bench->log;
	
	$app->bench->time;
	$app->css->include("html/sprite/*.css")->save("html/css/style.css")->clear;
	$app->cssOrig( $app->css );
	msg ":space", "сохранение стилей:", $app->bench->log;
	
	$app->bench->time;
	$app->js->save("html/js/app.js");
	msg ":space", "сохранение фронтэнд-скриптов:", $app->bench->log;
	
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
	
	# создаём сервер кэша
	
	# запускаем шедулер
	$app->shiva->start;
	
	$app->connect->close if $self->role ne "loop";
	
}


# инициализирует воркер
sub init {
	my ($self) = @_;

	# подключаем базу данных
	$app->connect->connect if $self->role ne "loop";
	
	$self
}

# вызывается перед обработкой запроса
sub before {
	my $self = shift;
	
	# my $q = $app->q;
	# my $path = $q->uri->path;
	# my $ip = $q->ip;
	
	# $app->cache->inc("vi-$path", "visit");			# подсчитываем посещения
	# $app->cache->inc("vi-$ip-$path", "visit-ip");	# подсчитываем уникальные посещения
	
	$app->connect->reconnect;
	
	$self
}

# вызывается после обработки запроса
sub after {
	my ($self) = @_;

	$self
}

# нормальное завершение процесса воркера или крона
END {
	$app->connect->close if $app->{connect}; 
}






1;