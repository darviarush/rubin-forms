package R::Query;

sub new {
	my ($cls, $app) = @_;
	bless {app=>$app}, $cls;
}

sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $tab = $1;
	
	eval "sub $AUTOLOAD { if() }";
	my $sub = *$AUTOLOAD{code};
	goto &$sub;
}

1;