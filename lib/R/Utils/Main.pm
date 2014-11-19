package R::Utils::Main;
# создаёт свойства

sub new {
	my ($cls, $app) = @_;
	bless {app => $app}, $cls;
}

sub app { if(@_>1) { $_[0]->{app} = $_[1]; $_[0] } else { $_[0]->{app} } }


1;