package R::Promise;
# обещания

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, $cls;
}

# выполняет функцию, если всё ok
sub then(&) {
	my ($self, $code) = @_;
	push @{$self->{Then}}, $code;
	$code->(@{$self->{Resolved}}) if exists $self->{Resolved};
	$self
}

# выполняется в случае отказа
sub fail(&) {
	my ($self, $code) = @_;
	push @{$self->{Fail}}, $code;
	$code->(@{$self->{Rejected}}) if exists $self->{Rejected};
}

# выполняется в любом случае
sub done(&) {
	my ($self, $code) = @_;
	push @{$self->{Done}}, $code;
	$code->(@{$self->{Resolved}}) if exists $self->{Resolved};
	$code->(@{$self->{Rejected}}) if exists $self->{Rejected};
}

# процесс закончен успешно
sub resolved {
	my ($self) = @_;
	exists $self->{Resolved};
}

# синоним для resolved
\&fulfilled = \&resolved;

# процесс упал
sub rejected {
	my ($self) = @_;
	exists $self->{Rejected};
}

# ожидание завершения процесса
sub pending {
	my ($self) = @_;
	!exists $self->{Resolved} and !exists $self->{Rejected};
}

# завершён в любом случае
sub settled {
	my ($self) = @_;
	!$self->pending
}

# возвращает функцию-замыкание с собой
sub resolver {
	my ($self) = @_;
	$self->{Resolver} //= closure \&resolve, $self;
}

# возвращает функцию-замыкание с собой
sub rejecter {
	my ($self) = @_;
	$self->{Rejecter} //= closure \&reject, $self;
}

# возвращает функцию-замыкание с собой
sub notifier {
	my ($self) = @_;
	$self->{Notifier} //= closure \&notify, $self;
}

# позволяет сообщить сколько прошло времени
sub notify (@) {
	my ($self) = @_;
	for my $code (@{$self->{Notify}}) {
		$code->(@args);
	}
}

# вызывается notify
sub progress (&) {
	my ($self, $code) = @_;
	push @{$self->{Notify}}, $code;
	#$code->(@{$self->{Resolved}}) if exists $self->{Resolved};
	$self
}

# устанавливает функцию, которая будет вызываться по таймеру до тех пор, пока не произойдёт событие
# sub progress {
	# my ($self, $sec, $after) = @_;
	# AnyEvent->timer (after => $after // 0, interval => $sec // $app->ini->{persistent}{interval} // 10, cb => sub {
		
	# });
# }

# аналог then для цепочек
# sub pipe(@) {
	# my ($self, @new) = @_;
	# push @{$self->{Then}}, map { $_->resolver } @new;
# }

# аналог fail для цепочек
# sub bad(@) {
	# my ($self, @new) = @_;
	# push @{$self->{Fail}}, map { $_->resolver } @new;
# }

# аналог done для цепочек
# sub keep {
	# my ($self, @new) = @_;
	# push @{$self->{Done}}, map { $_->resolver } @new;
# }

1;
