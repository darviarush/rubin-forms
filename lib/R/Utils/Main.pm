package R::Utils::Main;
# создаёт свойства

sub new {
	my ($cls, $app) = @_;
	bless {app => $app}, $cls;
}

sub app { $_[0]->{app} }


1;