package R::Rows::User;
# модель пользователя

use base R::Model::Row;


# вызывается для создания структуры базы
sub setup {
	my ($fields) = @_;

	$fields->
	
	col(email => "varchar(255)")->
	col(pass => "varchar(255)")->
	col(is_admin => "tinyint")->default(0)->
	col(name => "varchar(255)")->
	ref(ava => "img")->
	col(description => 'mediumtext')->
	
	index('email, pass')

}

1;