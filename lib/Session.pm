package R::Session;
# ������

use base R::Utils::Main;

# ���������� ������ Query::User ��� undef
sub user {

}

sub user_id {
	
}

sub delete {
	my ($self) = @_;
	$self->app->connect->dbh->do("DELETE FROM session WHERE ");
	$self
}