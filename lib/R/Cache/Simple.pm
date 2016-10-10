package R::Cache::Simple;
# кэш с базовыми функциями

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;

	bless {
		cache => {},		# набор ключей
		destroyer => {},	# дестройер => индекс
		destroy => {},		# ключ => индекс дестроера
	}, $cls;
}



# устанавливает ключ-значение
sub set {
	my ($self, $k, $v, $destroyer) = @_;
	$self->setdestroy($k, $destroyer) if defined $destroyer;
	#$v = shared_clone($v) if ref $v;
	$self->{cache}{$k} = $v
}

# возвращает значение по ключу
sub get {
	my ($self, $k) = @_;
	$self->{cache}{$k}
}

# удаляет ключ
sub del {
	my ($self, $k, $type) = @_;
	my $cache = $self->{cache};
	return if !exists $cache->{$k};
	my $v = delete $cache->{$k};
	$self->ondestroy($k, $v, $type // 0);
	$v
}

# квантор существования
sub exists {
	my ($self, $k) = @_;
	exists $self->{cache}{$k};
}

# увеличивает значение ключа на 1
sub inc {
	my ($self, $k, $destroyer) = @_;
	$self->add($k, +1, $destroyer)
}

# уменьшает значение ключа на 1
sub dec {
	my ($self, $k, $destroyer) = @_;
	$self->add($k, -1, $destroyer)
}

# добавляет число
sub add {
	my ($self, $k, $v, $destroyer) = @_;
	$self->set($k, $self->get($k) + $v, $destroyer)
}

# вычитает число
sub sub {
	my ($self, $k, $v, $destroyer) = @_;
	$self->add($k, -$v, $destroyer);
}

my @destroyers;	# дестроеры sub
# добавляет обработчик удаления ключей и меняет класс объекта кэша, если нужно
sub destroyer {
	my ($self, $key, $sub) = @_;
	
	$sub = $key, $key = "" if @_ == 2;
	
	my $index = @destroyers;
	push @destroyers, $sub;
	
	$self->{destroyer}{$key} = $index;
	
	$self
}

# обработчик удаления ключей
sub ondestroy {
	my ($self, $key) = @_;
	my $destroyer = delete $self->{destroy}{$key};
	if(defined $destroyer) {
		$destroyers[$destroyer]->(@_);
	}
	elsif(defined( $destroyer = $self->{destroyer}{""} )) {
		$destroyers[$destroyer]->(@_);
	}
}

# устанавливает дестроер на ключ
sub setdestroy {
	my ($self, $key, $destroyer) = @_;
	
	my $index = $self->{destroyer}{$destroyer};
	die "Дестройер $destroyer на данном объекте не установлен" if !defined $index;
	
	$self->{destroy}{$key} = $index;
	
	$self
}

# возвращает значение из кэша по ключу, если такого нет - то выполняет функцию и устанавливает
sub ret {
	my ($self, $k, $cb) = @_;
	my $cache = $self->{cache};
	if(exists $cache->{$k}) {
		$self->get($k)
	}
	else {
		$self->set($k => $cb->($self, $k))
	}
}

1;