package R::App;
# содержит различные объекты, необходимые для приложения
use Utils;

sub new { my ($cls) = @_; bless {}, $cls }


sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	if(@_ == 1) {		
		my $new = $prop; $new =~ s![A-Z]!::$&!g; $new = "R::".ucfirst($prop);
		my $load = $prop; $load =~ s![A-Z]!/$&!g;
		$load = main::file "lib/R/".ucfirst($load).".pm";
		require $load;
		$_[0]->{$prop} = $new->new($_[0]);
	}
	
	eval "sub $AUTOLOAD { my (\$self, \$val) = \@_; if(\@_ == 1) { \$self->{'$prop'} } else { \$self->{'$prop'} = \$val; \$self } }";
	
	$AUTOLOAD->(@_);
}

sub DESTROY {}


sub log {
	my ($app, @args) = @_;
	main::msg(@args);
	return $app;
}

sub log1 {
	my ($app, @args) = @_;
	main::msg1(@args);
	return $app;
}

1;