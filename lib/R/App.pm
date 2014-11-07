package R::App;
# содержит различные объекты, необходимые для приложения

sub new { my ($cls) = @_; bless {}, $cls }


sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	my $sub = (sub { my ($prop) = @_; sub { my ($self, $val) = @_; if(@_ == 1) { $self->{$prop} } else { $self->{$prop} = $val; $self }}})->($prop);
	#no strict 'refs';
	*{$AUTOLOAD} = $sub;
	#use strict 'refs';

	if(@_ == 1) {
		my $new = $prop; $new =~ s![A-Z]!::$&!g; $new = "R::".ucfirst($prop);
		my $load = $prop; $load =~ s![A-Z]!/$&!g;
		$load = main::file "lib/R/".ucfirst($load).".pm";
		require $load;
		$_[0]->{$prop} = $new->new($_[0]);
	}
		
	goto &$sub;
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