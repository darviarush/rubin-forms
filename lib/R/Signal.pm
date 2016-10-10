package R::Signal;
# сигнал - запускает обработчики

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless [], ref $cls || $cls;
}

# добавляет обработчик
sub cb {
	my ($self, $cb) = @_;
	
	die "функция-обработчик должна быть ссылкой на код, а не $cb" if ref $cb ne "CODE";
	
	push @$self, $cb;
	$self
}

# отправляет сигнал со всеми параметрами
sub send {
	my $self = shift;
	local $_;
	$_->(@_) for @$self;
	$self
}

1;