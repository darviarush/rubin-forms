package R::Cache::Vain;
# пример кэша
# использовать нельзя, т.к. он не 

use common::sense;
use R::App;


# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

# устанавливает
sub set {
	my ($self, $k, $v) = @_;
	$self->{$k} = $v;
}

# возвращает
sub get {
	my ($self, $k) = @_;
	$self->{$k}
}

# удаляет
sub del {
	my ($self, $k) = @_;
	delete $self->{$k};
}

# квантор существования
sub exists {
	my ($self, $k) = @_;
	exists $self->{$k};
}



1;