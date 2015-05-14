package R::Row::User;
# модель пользователя

use base "R::Model::Row";


# вызывается для создания структуры базы
sub setup {
	my ($fields) = @_;
	
	$fields->
	
	col(email => "varchar(255)")->
	col(pass => "varchar(255)")->
	col(is_admin => "tinyint")->default(0)->
	
	unique('email')->
	
	testdata(
		[1, '@', '123', 1],
		[2, 'u@', '123', 0],
	);

}

sub login {
	my ($self, $email, $pass) = @_;
	
	die "Вы уже залогинены - разлогиньтесь!" if $self->{id};
	
	my ($user) = $self->Model->find(email=>$email, pass=>$pass);
	
	die "Неверный email или пароль" unless $user;
	
	$user
}


1;