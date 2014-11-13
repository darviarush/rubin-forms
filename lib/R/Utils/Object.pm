package R::Utils::Object;
# создаёт свойства

sub new {
	my ($cls, $app) = @_;
	bless {app => $app}, $cls;
}

sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/; my $prop = $1;
	
	die "В объекте $_[0] ещё нет ключа $prop" if not exists $_[0]->{$prop};
	
	eval "sub $AUTOLOAD { my (\$self, \$val) = \@_; if(\@_ == 1) { \$self->{'$prop'} } else { \$self->{'$prop'} = \$val; \$self }}";
	die $@ // $! if $@ // $!;
	my $sub = *{$AUTOLOAD}{CODE};
	
	goto &$sub;
}

sub DESTROY {}

1;