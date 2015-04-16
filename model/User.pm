package R::Row::User;
# модель пользователя

use base R::Model::Row;


# вызывается для создания структуры базы
sub setup {
	my ($fields) = @_;

	$fields->
	
	col(email => "varchar(255)")->
	col(pass => "varchar(255)")->
	col(is_admin => "tinyint")->default(0)->
	
	index('email, pass')
}

1;