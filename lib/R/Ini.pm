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
		#bless $s, R::Ini;
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
	$AUTOLOAD =~ /([^:]+)$/; my $prop = $1;
	
	my $sub = (sub { my ($prop) = @_; sub { my ($self, $val) = @_; if(@_ == 1) { $self->{$prop} } else { $self->{$prop} = $setnew->($val); $self }}})->($prop);
	#no strict 'refs';
	*{$AUTOLOAD} = $sub;
	#use strict 'refs';
	
	goto &$sub;
}

sub DESTROY {}

1;