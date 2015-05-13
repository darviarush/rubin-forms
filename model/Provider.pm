package R::Row::Provider;
# сессия

use base R::Model::Row;


# вызывается для создания структуры базы
sub setup {
	my ($fields) = @_;

	$fields->
	
	col(name => 'varchar(255)')->
	col(url => 'varchar(255)')->
	
	# http://habrahabr.ru/post/145988/
	# http://oauth.vk.com/authorize?client_id={client_id}&redirect_uri=mysite.com/vklogin&response_type=code
	
	data(
		[1, 'vk', 'https://oauth.vk.com/authorize?client_id=CLIENT_ID&scope=offline,messages,status,notify&redirect_uri=REDIRECT_URI&response_type=code&v=API_VERSION'],
		[2, 'odnoklassniki', ''],
		[3, 'mail.ru', '']
	)

}

1;