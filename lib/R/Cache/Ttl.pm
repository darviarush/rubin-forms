package R::Cache::Ttl;
# Кэш с временем жизни ключей
# 

use parent "R::Cache::Simple";

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	$cls->SUPER::new->new_ttl;
}

# добавляет  необходимые свойства для ttl
sub new_ttl {
	my ($self) = @_;
	
	$self->{times} = {};		# содержит время в сек., а в них - массивы с ключами к удалению
	$self->{keytime} = {};	# ключ => время на к-е установлен
	$self->{clean} = time;	# время предыдущей уборки
	
	$self
}


# вернуть кэш, а если его нет - выполнить функцию и установить
# $lifetime в секундах
sub ret {
	my ($self, $key, $lifetime, $sub) = @_;
	
	return $self->SUPER::ret($key, $lifetime) if @_ == 3;
	
	return $self->get($key) if $self->exists($key);
	
	$self->ttl($key, $lifetime);
	
	$self->set($key => $sub->($self, $key))
}

# устанавливаем время жизни ключа в секундах
sub ttl {
	my ($self, $key, $lifetime) = @_;
	
	# зачем обновлять время, если такого ключа нет?
	return $self if !exists $self->{cache}{$key};
	
	my $keytimes = $self->{keytime};
	return unpack "L", $keytimes->{$key} if @_ == 2;
	
	my $times = $self->{times};
	
	my $time = pack "L", $app->perl->seconds($lifetime) + time;
	
	# если уже есть
	if(defined( my $keytime = $keytimes->{$key} )) {
		my $timeset = $times->{ $keytime };
		
		if(@$timeset <= 1) {
			delete $times->{ $keytime };
		} else {
			local $_;
			@$timeset = grep { $_ ne $key } @$timeset;
		}
	}
	
	# обратная связь - чтобы можно было найти по ключу
	$keytimes->{$key} = $time;
	
	push @{ $times->{ $time } //= [] }, $key;
	
	$self
}

# вызывается кроном и очищает очередь
# возвращает количество удалённых ключей
sub clean {
	my ($self) = @_;

	my $cache = $self->{cache};
	my $times = $self->{times};
	my $keytimes = $self->{keytime};
		
	my $clean = $self->{clean};			# предыдущая уборка
	my $now = $self->{clean} = time;	# текущая уборка
	
	my $count = 0;
	
	for(; $clean <= $now; $clean++) {
		
		my $keys = delete $times->{ pack "L", $clean };
		
		if($keys) {
			for my $key (@$keys) {
				delete $keytimes->{$key};
				$self->del( $key, 4 ), $count++ if exists $cache->{$key};
			}
		}
	}
	
	$count
}


1;