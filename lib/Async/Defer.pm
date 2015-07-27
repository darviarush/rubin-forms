package R::Async::Defer;
# умеет изменять состтояние promise

use common::sense;
use R::App;

use base "R::Async::Promise";

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, $cls;
}

# отправляет данные по цепочке
sub resolve (@) {
	my ($self, @args) = @_;
	$self->{Resolved} = [@args];
	for my $code (@{$self->{Then}}, @{$self->{Done}}) {
		$code->(@args);
	}
}

# синоним для resolve
\&fulfill = \&resolve;

# эмитит исключение
sub reject (@) {
	my ($self, @args) = @_;
	$self->{Rejected} = [@args];
	for my $code (@{$self->{Fail}}, @{$self->{Done}}) {
		$code->(@args);
	}
}

# возвращает Promise
sub promise {
	my ($self) = @_;
	bless $self, "R::Async::Promise";
}




1;
