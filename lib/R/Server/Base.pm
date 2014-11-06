# базовый класс для серверов
package R::Server::Base;

# распечатывают статистику. Используются в драйверах
my %_STAT = ();

sub stat_start {
	$_STAT{time} = Time::HiRes::time();
}

sub stat_begin {
	msg ":empty", "\n", ":red", "$_METHOD", ":reset", " $_URL ", ":red", "$_VERSION ", ":cyan", "tid", ":reset", ":", " ".threads->tid(), ":cyan", " from ", ":reset", join(", ", threads->list());
	if($_req > 0) { msg ":empty", ":magenta", $_ ":reset", ":", " ", ":cyan", $_HEAD->{$_} for keys %{$_HEAD} };
	if($_req > 1) { msg ":empty", ":CYAN", $_, ":RESET", ":", " ", (!defined($_POST->{$_})? (":RED", "null", ":RESET"): ref $_POST->{$_} eq "JSON::XS::Boolean"? (":RED", $_POST->{$_}, ":RESET"): ref $_POST->{$_}? Utils::Dump($_POST->{$_}): $_POST->{$_} ) for keys %$_POST };
}

sub stat_end {
	my ($RESPONSE, $head, $out) = @_;
	$RESPONSE =~ s/\s*$//;
	msg $RESPONSE;
	/: /, msg ":empty", ":GREEN", $`, ":RESET", ":", " ", ":YELLOW", $' for @$head;
	if($_req > 1) { msg $_ for @$out }
	my $time = Time::HiRes::time() - $_STAT{time};
	msg ":empty", ":MAGENTA", "sec", ":RESET", " $time";
}

1;