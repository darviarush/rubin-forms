package R::Ini;
# подгружает в себя ini-файл

use Utils;
use R::App;

our $setnew = sub {
	my ($s) = @_;
	if(ref $s eq "HASH") {
		while(my($key, $val) = each %$s) { $setnew->($val) }
		bless $s, R::Ini;
	}
	elsif(ref $s eq "ARRAY") {
		for my $val (@$s) { $setnew->($val) }
		bless $s, R::Ini::Array;
	}
	$s
};

sub new {
	my ($cls, $app) = @_;
	my $ini = Utils::parse_ini("main.ini");
	$ini->{do} = Utils::parse_ini("main_do.ini");
	
	$setnew->($ini);
	
	$ini;
}

sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	if(@_ == 1) { $_[0]->{$1} } else { $_[0]->{$1} = $setnew->($_[1]); $_[0] }
}

sub DESTROY {}

package R::Ini::Array;

sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	if(@_ == 1) { $_[0]->[$1] } else { $_[0]->[$1] = $R::Ini::setnew->($_[1]); $_[0] }
}

1;