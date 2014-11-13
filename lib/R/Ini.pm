package R::Ini;
# подгружает в себя ini-файл

sub new {
	my ($cls, $app) = @_;
	my $ini = Utils::parse_ini("main.ini");
	$ini->{do} = Utils::parse_ini("main_do.ini");
	bless $ini, $cls;
}


1;