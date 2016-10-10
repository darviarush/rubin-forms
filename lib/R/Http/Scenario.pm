package R::Http::Scenario;
# сценарий

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

# очистка тестов
sub start {
	my $self = shift;
	
	$self->describe(@_);
	
	# сообщаем серверу, что новый сценарий стартовал
	($self->{guest} //= do {
		my $guest=$self->agent;
		$guest->{ID} = "*";
		$guest
	})->go("/__/start__scenario");
	
	$self
}

# описание
sub describe {
	my ($self, $describe) = @_;
	$app->log->info("=", ":on_cyan black", $describe);
}

# ситуация
sub context {
	my ($self, $context) = @_;
	$app->log->info("*", ":cyan", $context);
}

# создаёт и возвращает агента
sub agent {
	my ($self, $log) = @_;
	
	my $agent = $app->httpAgent->new("http://127.0.0.1:" . $app->ini->{site}{port})->log(1);
	
	$agent->{log_road} = $log // "guest";
	
	$agent
}




1;