package R::Model::Metafieldset;
# база данных

use R::Model::Fieldset;

# конструктор
sub new {
	my ($cls) = @_;
	
	bless {
		name => undef,		# имя базы данных
		fieldset => {},		# имя => таблица
	}, $cls;
}

# создаёт и возвращает новую таблицу
sub fieldset {
	my ($self, $name) = @_;
	$self->{fieldset}{$name} ||= R::Model::Fieldset->new($name);
}

# экшн
sub action {
	my ($self) = @_;

	my $name = $::app->request->{action};
	main::msg 'name', $name;
	#eval {
		$::app->model->$name;
	#};
	#$::app->response->error(404) if $@;
}

# загружает все модели
sub load_all_models {

	find({
		no_chdir => 1,
		wanted => sub {
			my $path = $File::Find::name;
			if($path =~ /.pm$/) {
				require $path;
			}
		}
	}, main::files($self->{base}));
}

# синхронизирует базу
sub sync {
	my ($self) = @_;
	
	my $models = $self->{models};
	
	for my $model (@$models) {
		$model->setup;
		$model->fields->postsetup;
	}
	
	for my $model (@$models) {
		$model->setup;
		$model->fields->postsetup;
	}
}

1;