package R::Man;
# для тестов

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# конфигурация для тестов
sub conf {
	my ($self) = @_;
	
	# укажем конфигурационный файл, иначе он будет зависить от имени скрипта
	$app->ini( $app->ini->parse("etc/unicorn.ini") );
	
	$self
}

# конфигурация для баз
sub configure {
	my ($self, %opt) = @_;
	
	$self->conf;
	
	# не логировать sql
	$app->ini->{log}{sql} = $opt{logsql} // "no";
	$app->ini->{log}{cache} = $opt{logcache} // "no";
	
	# не кэшировать - "", val - использовать row->{val}, memory - R::Cache
	$app->ini->{model}{cache} = $opt{cache} // "val";
	
	# меняем название базы
	$app->ini->{connect}{database} = $opt{database} // "unicorn_miu_test";
	
	# таблицы будут в памяти - так быстрее
	$app->ini->{model}{engine} = $opt{engine} // "memory";
	
	if($opt{model} ne "no") {
		# дабы не пытаться подгружать модели с диска
		$app->meta($app->modelMetafieldset->base(undef));
	}
	
	# удалим базу, дабы не нарушать эксперимент
	$app->meta->drop;
	
	$self
}


# для форм
sub form {
	my ($self) = @_;
	
	# Подгружаем шаблоны в указанных директориях
	$app->view->compile->load("classes");
	
	# Создаём запрос, с которым будут взаимодействовать формы
	$app->q( $app->httpRequest->simple );
	
	$self
}

# для сценариев
sub scenario {
	my ($self) = @_;
	
	$app->ini;
	$app->ini( $app->perl->union( $app->{ini}, $app->{ini}{scenario}, $app->{ini}{'scenario-server'} ) );
	$app->log( $app->log->new );
	
	require "Sc.pm";
	
	$self
}


1;