package R::Model::Row;
# наследный класс для моделей. Представляет запись

# конструктор
sub new {
	my ($cls, $id) = @_;
	bless {id=>$id}, $cls;
}

# возвращает/устанавливает идентификатор
sub id { if(@_>1) { die "Изменять id через модель нельзя" } else { $_[0]->{id} } }


# выбирает записи. Возвращает tie-массив
sub filter {
	my ($self, @filters) = @_;
	$app->auth->query();
}

# 
sub save {
}

# вызывается при создании новой строки
sub add {
}

# апдейт записи
sub update {
}

# удаляет строку
sub erase {
	my ($self) = @_;
	$self->{app}->auth->erase($self->{tab}, {id => $self->{id}});
}

1;