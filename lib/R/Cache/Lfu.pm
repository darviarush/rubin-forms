package R::Cache::Lfu;
# кэш LFU, в зависимости от конфигурации может возвращать объект memcache или redis
# кэш имеет размер, при добавлении ключа-значения, когда размер кэша будет привышен, будут удалены старые ключи


use parent "R::Cache::Simple";

use common::sense;
use R::App;

use bytes;			# Внимание! Работаем только с байтами!

has qw/maxsize maxkeysize/;
has_const qw/size/;

# конструктор
sub new {
	my ($cls) = @_;

	die "используйте для установки переменных методы" if @_>1;
	
	my $self = $cls->SUPER::new;
	
	%$self = (%$self,
		size => 0,						# размер кэша
		maxkeysize => 1024*256,			# 256k
		maxsize => 1024*1024,			# 1m
		cache => {},		# ключ-значение
		fifo => {},		# ключи в порядке последнего доступа
		pos => {},		# ключ => позиция в fifo
		max => 0,						# максимальный индекс в fifo
		min => 0,						# минимальный индекс в fifo
	);
	
	$self
}


# устанавливает
sub set {
	my ($self, $k, $v, $destroyer) = @_;
	
	$self->setdestroy($k, $destroyer) if defined $destroyer;
	
	my $size = length($k) + length($v);
	$self->ondestroy($k, $v, 1), return $v if $size > $self->{maxkeysize};
	
	my $cache = $self->{cache};
	
	if(exists $cache->{$k}) {
		my $val = $cache->{$k};
		$size -= length($k) + length($val);
		$self->ondestroy($k, $val, 3, $v);
	}
	
	#$v = shared_clone($v) if ref $v;
	
	$self->{size} += $size;
	$cache->{$k} = $v;
	$self->update($k);
	
	$self->cleaning($k) if $self->{size} > $self->{maxsize};
	
	$v
}

# возвращает
sub get {
	my ($self, $k) = @_;
	
	my $cache = $self->{cache};
	
	$self->update($k) if exists $cache->{$k};		# в конец очереди
	
	$cache->{$k}
}

# удаляет
sub del {
	my ($self, $k, $type) = @_;
	
	my $cache = $self->{cache};
	return if !exists $cache->{$k};
	my $v = delete $cache->{$k};
	$self->{size} -= length($k) + length($v);
	
	# удаляем из pos и fifo
	my $fifo = $self->{fifo};
	my $pos = $self->{pos};
	delete $fifo->{delete $pos->{$k}};
	
	$self->ondestroy($k, $v, $type // 0);
	
	$v
}

# обновляет позицию ключа в очереди
sub update {
	my ($self, $k, $val) = @_;
	my $fifo = $self->{fifo};
	my $pos = $self->{pos};
	# удаляем, если есть
	delete $fifo->{ $pos->{$k} } if exists $pos->{$k};
	$pos->{$k} = my $max = $self->{max}++;
	$fifo->{$max} = $k;
	$self
}


# удаляет "лишние" старые ключи
# под старыми понимаются ключи, которые давно не использовались
sub cleaning {
	my ($self) = @_;
	
	my $maxsize = $self->{maxsize};
	my $fifo = $self->{fifo};
	my $pos = $self->{pos};
	my $cache = $self->{cache};
	my $max = $self->{max};
	my $min = $self->{min};
	my $newsize = $self->{size};

	while($newsize > $maxsize) {

		next if !exists $fifo->{$min++};
		
		my $k = delete $fifo->{$min-1};
		
		delete $pos->{$k};
		my $v = delete $cache->{$k};
		$newsize -= length($k)+length($v);
		
		$self->ondestroy($k, $v, 2);
	}
	
	$self->{min} = $min;
	$self->{size} = $newsize;
	
	$self
}


1;