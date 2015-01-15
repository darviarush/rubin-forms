package R::Session;
# сессия

use strict;
use warnings;

sub new {
	my ($cls, $app) = @_;
	bless { app => $app }, $cls;
}

sub app { $_[0]->{app} }

sub reset { my ($self) = @_; delete $self->{app}{stash}{user_id}; $self }

# возвращает объект Query::User или undef
sub user {

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
	return 0 unless $sess;
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