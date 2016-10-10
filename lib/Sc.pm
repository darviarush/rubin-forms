package Sc;
# тут собраны необходимые для сценариев методы

use common::sense;
use R::App;


# создаёт агента и авторизирует его
sub R::Http::Scenario::loginAgent {
	my ($self, $id, $name, $description) = @_;
	my $email = "$id\@mail.test";
	my $pass = "123";
	my $agent = $self->agent("agent$id");
	$agent->id( $id );
	$agent->go("/__/create/agent$id")->go("/")->form("LoginForm", email=>$email, pass => $pass);

	die "не установлена кука при логине" if !defined $agent->mech->cookie_jar->{COOKIES}{'127.0.0.1'}{"/"}{"sess"};
	
	$agent->go("/am$id")->form("AmEdit", firstname=>$name, description=>$description || "desc") if defined $name;
	
	$agent
}

# создаёт агента на стороне сервера
sub actionCreateAgent {
	my $id = $app->q->id;
	my $email = "$id\@mail.test";
	my $pass = "123";
	$app->model->user(email => $email, pass => $pass)->saveAs($id);
}


# возвращает последний код регистрации
sub R::Http::Agent::getRegisterCode {
	my $self = shift;
	$self->go("/__/get/register/code")->mech->content;
}

# возвращает последний код регистрации
sub actionGetRegisterCode {
	my $register = $app->model->register->order("-id")->exists;
	$app->q->echo($register->id) if $register;
}


# добавляет лайки пользователю
sub R::Http::Agent::inputLikes {
	my ($self, $cost) = @_;
	$self->go("/__/add/cost$cost")
}

# добавляет агенту лайки
sub actionAddCost {
	my $cost = $app->q->id;
	$app->q->user->cost($cost)
}


# возвращает по e-mail ссылку для продолжения регистрации
sub R::Http::Agent::getRegister {
	my ($self, $mail) = @_;
	$self->go("/__/get/register?mail=$mail")
}

# возвращает по e-mail ссылку для продолжения регистрации
sub actionGetRegister {
	my $email = $app->q->param("mail");
	$app->model->register->find(email => $email)->exists->id
}



package R::Http::Scenario;

package R::Http::Agent;


1;