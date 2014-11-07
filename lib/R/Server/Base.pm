# базовый класс для серверов
package R::Server::Base;

use Time::HiRes qw//;

# распечатывают статистику. Используются в драйверах
my %_STAT = ();

sub stat_start {
	my ($self) = @_;
	$self->{_STAT}{time} = Time::HiRes::time();
}

sub stat_begin {
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	msg ":empty", "\n", ":red", $request->method, ":reset", " ", $request->url, " ", ":red", $request->version, " ", ":cyan", "tid", ":reset", ":", " ", threads->tid(), ":cyan", " from ", ":reset", join(", ", threads->list());
	if($_req > 0) { msg ":empty", ":magenta", $_ ":reset", ":", " ", ":cyan", $request->{head}->{$_} for keys %{$request->{head}} };
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