package R::Route;
# роутер - в него передаётся запрос и он 

use common::sense;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

# 
sub route {}

1;
