package R::Row::Session;
# сессия

use base R::Model::Row;


# вызывается для создания структуры базы
sub setup {
	my ($fields) = @_;

	$fields->
	
	pk('binary(20)')->
	ref('user')->required->
	col(now => 'datetime')->
	col(new_pass => 'tinyint')->null->comment("0/1 - сессия создана для регистрации")->
	engine('memory');

}

sub delete {
	my ($self) = @_;
	my $conn = $self->{app}->connect;
	eval { $conn->erase("sess", {now__lt => $conn->now(time-3600)}); };
	$conn->reconnect if $@;
	$self
}

1;