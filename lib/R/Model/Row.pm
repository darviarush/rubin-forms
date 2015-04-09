package R::Model::Row;
# наследный класс для моделей. Представляет запись

# в конце запроса происходит сохранение всех изменённых записей (?)

# конструктор
sub new {
	my ($cls, $app) = @_;
	my $self = bless {app=>$app}, $cls;
	
	$self
}

# возвращает менеджер полей
sub fields {
	my ($self) = @_;
	$self->{_fields} ||= $self->{app}->modelFields;
}

# выбирает записи. Возвращает tie-массив
sub filter {
	my ($self, @filters) = @_;
	$app->auth->query();
}

# 
sub update {
}


1;