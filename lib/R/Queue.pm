package R::Queue;
# очереди

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# регистрирует канал и получателя
sub channel {
	my ($self, $name) = @_;
	
	$app->model->queue(undef)->channel($name);
	
	$self
}

# добавляет сообщение в канал
sub push {
	my $self = shift;
	
	$app->model->queue(undef)->push(@_);
	
	$self
}

# получает из очереди очередное сообщение по имени
sub pull {
	my $self = shift;
	
	$app->model->queue(undef)->pull(@_);
}


1;