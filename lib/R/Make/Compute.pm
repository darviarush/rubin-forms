package R::Make::Compute;
# задачи для вычислений

use common::sense;
use R::App;
use R::Make;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

category "ВЫЧИСЛЕНИЯ";

name "-e";
args "выражение";
desc "вычисляет выражение на perl и печатает результат";
test {
	quit "нет выражения" if @_!=1;
};
task {
	
	my @ret = eval($_[0]);
	die $@ if $@;
	$app->log->info( @ret );


};


name "-r";
args "выражение";
desc "подгружает модели и вычисляет выражение на perl";
test {
	quit "нет выражения" if @_!=1;
};
task {

	$app->modelMetafieldset->load_all_models;
	#$app->bench->time;
	my @ret = eval($_[0]);
	die $@ if $@;
	$app->log->info( @ret );
	#$app->log->info( $app->bench->log );

};


name "-a";
args "выражение";
desc "подгружает шаблоны и вычисляет выражение на lukull";
test {
	quit "нет выражения" if @_!=1;
};
task {
	
	#$app->modelMetafieldset->load_all_models;
	$app->view->load;
	$app->q( $app->httpRequest->new );
	$app->q->uri( "/aim1" );
	#$app->bench->time;
	my @ret = $app->view->eval($_[0], {});
	$app->log->info( @ret );
	#$app->log->info( $app->bench->log );
	
};

name "-x";
args "выражение [-]";
desc "вычисляет выражение на lukull";
spec "- - вывести время выполнения";
test {
	quit "нет выражения" if @_<1;
};
task {
	$app->bench->time if $_[1];
	my @ret = $app->view->eval($_[0], {});
	$app->log->info( @ret );
	$app->log->info( $app->bench->log ) if $_[1];
	
};

name "-j";
args "выражение";
desc "вычисляет выражение на lukull в переводе на js";
test {
	quit "нет выражения" if @_!=1;
};
task {
	
	# $app->modelMetafieldset->load_all_models;
	# $app->view->load;
	# $app->q( $app->httpRequest->new );
	# $app->q->uri( "/aim1" );
	
	#$app->bench->time;
	my @ret = $app->view->new->lang("js")->eval($_[0], {});
	$app->log->info( @ret );
	#$app->log->info( $app->bench->log );
	
};

name "-js";
args "выражение";
desc "вычисляет выражение на js";
test {
	quit "нет выражения" if @_!=1;
};
task {
	
	# $app->modelMetafieldset->load_all_models;
	# $app->view->load;
	# $app->q( $app->httpRequest->new );
	# $app->q->uri( "/aim1" );
	
	#$app->bench->time
	my $ret = $app->viewJavascript->je->eval($_[0]);
	$ret = $@ if $@;
	$app->log->info( R::View::Javascript::_je_perl($ret) );
	#$app->log->info( $app->bench->log );
	
};



1;