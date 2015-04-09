package R::Rows::Session;
# сессия

use base R::Model::Row;


# вызывается для создания структуры базы
sub setup {
	my ($fields) = @_;

	$fields->
	
	->pk('binary(20)')
	->ref('user')->index
	->col(now => 'datetime')->index
	->col(new_pass => 'tinyint')->null->comment("0/1 - сессия создана для регистрации")
		
	->engine('memory')

}


# возвращает id пользователя, если он залогинен
sub user_id {
	my ($self, $user_id) = @_;
	$self->{app}{stash}{user_id} = $user_id // 0, return $self if @_>1;
	my $id = $self->{app}{stash}{user_id};
	return $id if defined $id;
	my $app = $self->{app};
	my $request = $app->request;
	my $sess = $request->cookie("sess");
	return $self->{app}{stash}{user_id} = 0 unless $sess;
	my $conn = $app->connect;
	$id = $conn->query("sess", "user_id", {id=>$sess}) // 0;
	$conn->update("sess", {now=>$conn->now}, {id=>$id}) if $self->{app}{stash}{user_id} = $id;
	return $id;
}

sub delete {
	my ($self) = @_;
	my $conn = $self->{app}->connect;
	eval { $conn->erase("sess", {now__lt => $conn->now(time-3600)}); };
	$conn->reconnect if $@;
	$self
}




1;