package R::Persistent;
# Класс для создания цепочек выполнения. Должен наследоваться генераторами данных для цепочек 

use common::sense;
use R::App;
use AnyEvent;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

# клонирует себя для 
sub persistent_clone {
	my ($self, $new) = @_;
	$new = bless {%$self, Parent=>$self}, ref $self;
	delete $new->{Then};
	delete $new->{Fail};
	delete $new->{Done};
	$new
}

# выполняет функцию или выполняет цепочку, если всё ok
# получает функцию или цепочку. Если ничего не указано - возвращает новый 
sub then(&) {
	my ($self, $new) = @_;
	$new = $self->persistent_clone if @_==1;
	push @{$self->{Then}}, $new;
}

# аналог then, но выполняется в случае ошибки
sub fail(&) {
	my ($self, $new) = @_;
	$new = $self->persistent_clone if @_==1;
	push @{$self->{Fail}}, $new;
}

# выполняется в любом случае
sub done(&) {
	my ($self, $new) = @_;
	$new = $self->persistent_clone if @_==1;
	push @{$self->{Done}}, $new;
}

# аналог then для цепочек
sub pipe(@) {
	my ($self, @new) = @_;
	@new = $self->persistent_clone if @_==1;
	push @{$self->{Then}}, map { $_->emitter } @new;
}

# аналог fail для цепочек
sub bad(@) {
	my ($self, @new) = @_;
	@new = $self->persistent_clone if @_==1;
	push @{$self->{Fail}}, map { $_->emitter } @new;
}

# аналог done для цепочек
sub keep {
	my ($self, @new) = @_;
	@new = $self->persistent_clone if @_==1;
	push @{$self->{Done}}, map { $_->emitter } @new;
}


# завершает часть цепочки - возвращает родительскую цепочку
sub end {
	my ($self) = @_;
	my $parent = $self->{Parent};
	delete $self->{Parent};
	$parent;
}

# возвращает функцию-замыкание с собой
sub emitter {
	my ($self) = @_;
	$self->{Emitter} //= Utils::closure($self, $self->can("sucess"));
}


# отправляет данные по цепочке
sub sucess {
	my ($self, @args) = @_;
	for my $code (@{$self->{Then}}, @{$self->{Done}}) {
		$code->(@args);
	}
}

# эмитит исключение
sub failure {
	my ($self, @args) = @_;
	
	for my $code (@{$self->{Fail}}, @{$self->{Done}}) {
		$code->(@args);
	}
}

# устанавливает функцию, которая будет вызываться по таймеру до тех пор, пока не произойдёт событие
sub progress {
	my ($self, $sec, $after) = @_;
	AnyEvent->timer (after => $after // 0, interval => $sec // $app->ini->{persistent}{interval} // 10, cb => sub {
		
	});
}

1;
