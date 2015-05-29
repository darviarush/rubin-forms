package R::Row::Register;
# хранит коды до регистрации пользователя

use base "R::Model::Row";

sub setup {
	my ($fields) = @_;
	
	$fields->
	
	pk("binary(20)")->
	col("email" => "varchar(255)")->
	col("now" => "datetime")->
	
	end
}

# добавляет время создания
sub onAdd {
	my ($self) = @_;
	$self->now( Utils::now() );
}

# удаляет все просроченные регистрации
sub clean {
	my ($self) = @_;
	$self->Model->find(now__lt => Utils::now(time-3600))->erase;
	$self
}

1;