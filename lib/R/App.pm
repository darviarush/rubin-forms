package R::App;
# содержит различные объекты, необходимые для приложения

use strict;
use warnings;
use vars '$AUTOLOAD';

sub new {
	my ($cls, $base) = @_;
	$base //= "R";
	bless {base => $base}, $cls;
}


sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	eval "sub $AUTOLOAD { my (\$self, \$val) = \@_; if(\@_ == 1) { \$self->{'$prop'} } else { \$self->{'$prop'} = \$val; \$self }}";
	die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	no strict "refs";
	my $sub = *{$AUTOLOAD}{CODE};
	use strict "refs";
	
	if(@_ == 1) {
		my ($self) = @_;
		my $base = $self->{base};
		my $new = $prop; $new =~ s![A-Z]!::$&!g; $new = $base."::".ucfirst $new;
		my $load = $prop; $load =~ s![A-Z]!/$&!g;
		$load = $base."/".ucfirst($load).".pm";
		require $load;
		$self->{$prop} = $new->new($_[0]);
	}
		
	goto &$sub;
}

sub DESTROY {}

1;