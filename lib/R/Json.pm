package R::Json;
# кодирует-раскодирует в json

use common::sense;
use R::App;

use JSON::XS;
my $json_xs = JSON::XS->new->allow_nonref;
our $true = $JSON::XS::true;
our $false = $JSON::XS::false;

# конструктор синглетона
my $singleton;
sub new {
	my ($cls) = @_;
	$singleton = bless \(my $json=1), $cls;
	*new = sub {$singleton};
	$singleton
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

# возвращает true
sub true {
	$true
}

# возвращает false
sub false {
	$false
}

1;
