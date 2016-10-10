package R::View::Deferred;
# отложенная вставка элементов из q. js и css

use common::sense;
use R::App;

use overload 
'""' => \&stringify;


# конструктор
sub new {
	my ($cls, $qcode) = @_;
	bless {qcode => $qcode}, ref $cls || $cls;
}

# стрингифицирует объект
sub stringify {
	my ($self) = @_;
	my $qcode = $self->{qcode};
	$self->{stringify} //= $qcode->($app->q);
}

1;