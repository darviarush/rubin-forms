package R::Session;
# сессия

sub new {
	my ($cls, $app) = @_;
	bless { app => $app }, $cls;
}

sub app { $_[0]->{app} }

sub reset { my ($self) = @_; $self->{user_id} = undef; $self }

# возвращает объект Query::User или undef
sub user {

}

# возвращает id пользователя, если он залогинен
sub user_id {
	my ($self, $user_id) = @_;
	$self->{user_id} = $user_id, return $self if @_>1;
	return $self->{user_id} if $self->{user_id};
	my $app = $self->{app};
	my $request = $app->request;
	my $sess = $request->cookie("sess");
	return unless $sess;
	my $conn = $app->connect;
	my @res = $conn->query("sess", "user_id", $sess);
	$conn->update("sess", {now=>$conn->now}, {id=>$sess}) if $self->{user_id} = $res[0];
	return $fld? @res: $res[0];
}

sub delete {
	my ($self) = @_;
	my $conn = $self->{app}->connect;
	eval { $conn->erase("sess", {now__lt => $conn->now(time-3600)}); };
	$conn->reconnect if $@;
	$self
}

1;