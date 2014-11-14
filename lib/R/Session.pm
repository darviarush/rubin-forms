package R::Session;
# сессия

use base R::Utils::Main;

# возвращает объект Query::User или undef
sub user {

}

# возвращает id пользователя, если он залогинен
sub user_id {
	my ($self, $fld) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	return $request->{user_id} if $request->{user_id} and not $fld;
	my $sess = $request->cookie("sess");
	return unless $sess;
	my $conn = $app->connect;
	my @res = $conn->{dbh}->selectrow_array(join("", "SELECT user_id", ($fld? $fld: ()), " FROM sess WHERE id=?"), undef, $sess);
	$conn->update("sess", {now=>$conn->now}, {id=>$sess}) if $res[0];
	return $fld? @res: $res[0];
}

sub delete {
	my ($self) = @_;
	my $conn = $self->{app}->connect;
	eval { $conn->erase("sess", {now__lt => $conn->now(time-3600)}); }
	$self->connect->reconnect if $@;
	$self
}