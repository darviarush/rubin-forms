package R::App;
# содержит различные объекты, необходимые для приложения

sub new {
	my ($cls) = @_;
	bless {}, $cls;
}


sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	eval "sub $AUTOLOAD { my (\$self, \$val) = \@_; if(\@_ == 1) { \$self->{'$prop'} } else { \$self->{'$prop'} = \$val; \$self }}";
	die $@ // $! if $@ // $!;
	my $sub = *{$AUTOLOAD}{CODE};
	
	if(@_ == 1) {
		my $new = $prop; $new =~ s![A-Z]!::$&!g; $new = "R::".ucfirst $new;
		my $load = $prop; $load =~ s![A-Z]!/$&!g;
		$load = "R/".ucfirst($load).".pm";
		require $load;
		$_[0]->{$prop} = $new->new($_[0]);
	}
		
	goto &$sub;
}

sub DESTROY {}

1;