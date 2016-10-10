package R::Css::Unit;
# класс для css типов

use common::sense;
use R::App;

use overload
	'""' => \&stringify,
	"qr" => \&stringify,
	'.' => \&concat,
	'bool' => \&bool,
	"0+" => sub { $_[0]->{msg}? 1: 0 },
	
	fallback => 1
;

# конструктор
sub new {
	my ($cls, $val, $unit) = @_;
	bless {
		val => $val,
		unit => $unit,
	}, ref $cls || $cls;
}

# объединяет со строкой
sub concat {
	my ($self, $str, $wrap) = @_;
	if($wrap) { $str . $self->stringify }
	else { $self->stringify . $str }
}

# переводит в строковое представление
sub stringify {
	my ($self) = @_;
	$self->{val} . $self->{unit}
}

# в 
sub bool {
	my ($self) = @_;
	$self
}

1;