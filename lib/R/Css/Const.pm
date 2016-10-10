package R::Css::Const;
# константы css

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}


# если функция не найдена
use vars '$AUTOLOAD';

sub AUTOLOAD {
	my ($prop) = $AUTOLOAD =~ /([^:]+)$/;
	
	eval "sub $AUTOLOAD {
		my \$self = shift;
		if(\@_) { \$self->{'$prop'} = \$_[0]; \$self } else { \$self->{'$prop'} }
	}";
	die "not make $AUTOLOAD: $@" if $@;
	
	my $self = shift;
	if(@_) {
		$self->{$prop} = $_[0];
		$self
	} else {
		$self->{$prop};
	}
}

sub DESTROY {}

1;