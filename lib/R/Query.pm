package R::Query;
# 

use R::Utils::Connect;

sub new { my ($cls, $app) = @_; bless { app => $app }, $cls }


sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	eval "sub $AUTOLOAD { my (\$self, \@a) = \@_; ; \$self }}";
	die $@ // $! if $@ // $!;
	my $sub = *{$AUTOLOAD}{CODE};


	my $cls = "${AUTOLOAD}::$prop";
	my $load = $prop; $load =~ s![A-Z]!/$&!g;
	$load = "R/Query/".ucfirst($load).".pm";
	require $load if main::file("lib/$load");

	goto &$sub;
}

sub DESTROY {}

1;