package R::Row::Session;
# сессия

use base R::Model::Row;


# вызывается для создания структуры базы
sub setup {
	my ($fields) = @_;

	$fields->
	
	pk('binary(20)')->
	ref('user')->required->
	col(now => 'datetime')->
	#col(new_pass => 'tinyint')->null->remark("0/1 - сессия создана для регистрации")->
	
	#meta(engine => 'memory')->
	
	end;

}

# сохраняет now
sub onSave {
	my ($self) = @_;
	$self->now( Utils::now() );
}

# удаляет все просроченные сессии
sub clean {
	my ($self) = @_;
	$self->Model->find(now__lt => Utils::now(time-3600))->erase;
	$self
}

1;