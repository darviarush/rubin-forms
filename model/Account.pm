package R::Row::Account;
# аккаунт пользователя - main.ru, vk и т.д.

use base R::Model::Row;


# вызывается для создания структуры базы
sub setup {
	my ($fields) = @_;

	$fields->
	
	ref("user")->index->
	col(code => 'varchar(255)')
	
}

1;