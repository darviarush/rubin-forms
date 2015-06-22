package R::Request;
# заведует http-запросом

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls, $location) = @_;
	bless {}, $cls;
}




1;
