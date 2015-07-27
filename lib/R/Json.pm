package R::Json;
# кодирует-раскодирует в json

use common::sense;
use R::App;

use JSON::XS;
my $json_xs = JSON::XS->new->allow_nonref;

# конструктор синглетона
my $singleton;
sub new {
	$singleton //= do {
		my ($cls) = @_;
		bless {}, $cls;
	}
}


# декодирует из json
sub from ($$) {
	my ($self, $json) = @_;
	$json_xs->decode($json);
}


# кодирует в json
sub to ($$) {
	my ($self, $val) = @_;
	$json_xs->encode($val);
}


1;
