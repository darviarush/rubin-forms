package R::Session;
# сессия

use base R::Utils::Main;

# возвращает объект Query::User или undef
sub user {

}

sub user_id {
	
}

sub delete {
	my ($self) = @_;
	$self->app->connect->dbh->do("DELETE FROM session WHERE ");
	$self
}