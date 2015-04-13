package R::Model::Row;
# наследный класс для моделей. Представляет запись

# конструктор
sub new {
	my ($cls, $id) = @_;
	
	if(ref $id) {
		
		if(ref $id eq $cls) {
			$id = $id->{id};
		}
		else {
			my $bean = bless {id => $id->{id}}, $cls;
			my ($model) = $cls =~ /([^:]+)$/;
			my $field = $::app->modelMetafieldset->fieldset(lcfirst $model)->{field};
			while(my($k, $v) = each %$val) {
				$bean->$k($v) if exists $field->{$k};
			}
			return $bean;
		}
		
	}
	
	bless {id=>$id}, $cls;
}

# возвращает/устанавливает идентификатор
sub id { if(@_>1) { die "Изменять id через модель нельзя" } else { $_[0]->{id} } }

# устанавливает view для find
sub view {
	my ($self, $view) = @_;
	$self->{_view} = [split /\s*,\s*/, $view];
	$self
}


# выбирает записи. Возвращает tie-массив
sub find {
	my ($self, @filters) = @_;
	my $cls = ref $self;
	my $fieldset = $::app->{modelMetafieldset}{cls}{$cls};
	
	my $view = $self->{_view} // ["id"];
	delete $self->{_view};
	
	my $ref = $app->auth->query_all($fieldset->{tab}, $view, @filters);
	
	return map {bless $_, $cls} @$ref;
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
	my $fieldset = $::app->{modelMetafieldset}{cls}{ref $self};
	$::app->auth->erase($fieldset->{tab}, {id => $self->{id}});
}

1;