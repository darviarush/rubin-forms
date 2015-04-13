package R::Model::Metafieldset;
# база данных

use File::Find qw//;

use R::Model::Fieldset;


# конструктор
sub new {
	my ($cls) = @_;
	
	bless {
		name => undef,		# имя базы данных
		fieldset => {},		# имя => таблица
		cls => {},			# class => таблица
	}, $cls;
}

# создаёт и возвращает новую таблицу
sub fieldset {
	my ($self, $name) = @_;
	$self->{fieldset}{$name} ||= R::Model::Fieldset->new($name);
}

# загружает все модели
sub load_all_models {
	my ($self) = @_;

	File::Find::find({
		no_chdir => 1,
		wanted => sub {
			my $path = $File::Find::name;
			if($path =~ /([^\/]+)\.pm$/) {
				$self->fieldset(lcfirst $1);
			}
		}
	}, main::files($::app->model->{base}));
	
	$self
}

# синхронизирует базу
sub sync {
	my ($self) = @_;
	
	$self->load_all_models;
	
	my $c = $::app->connect;
	my $dbh = $c->dbh;
	
	$dbh->do("CREATE DATABASE ". $c->word($c->databasename) ." DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci"), $dbh->do("USE " . $c->word($c->databasename)) unless $dbh->{Name};
	
	
	my $fieldsets = $self->{fieldset};
	
	for my $fieldset (values %$fieldsets) {
		$fieldset->sync;
	}

	$self
}

1;