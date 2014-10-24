package R::App;
# содержит

# конструктор: 
sub new { my ($cls) = @_; bless {}, $cls }


sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	eval "sub $AUTOLOAD { my (\$self, \$key, \$val) = \@_; if(\@_ == 2) { \$self->{'$prop'} } else { \$self->{'$prop'} = \$val; \$self } }";
	\&{$AUTOLOAD}->(@_);
}