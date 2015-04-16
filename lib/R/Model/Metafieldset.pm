package R::Model::Metafieldset;
# база данных

use File::Find qw//;

require R::Model::Index;
require R::Model::Fieldset;


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

# Преобразовывает имя модели в стандартное имя столбца или таблицы
sub word {
	my ($self, $word) = @_;
	$word =~ s![A-Z]!"_" . lcfirst $&!ge;
	$word
}

# загружает все модели
sub load_all_models {
	my ($self) = @_;

	my $base = $::app->model->{base};
	
	File::Find::find({
		no_chdir => 1,
		wanted => sub {
			my $path = $File::Find::name;
			if($path =~ /([^\/]+)\.pm$/) {
				$self->fieldset(lcfirst $1);
			}
		}
	}, main::files $base) if $base;
	
	$self
}

# синхронизирует базу
sub sync {
	my ($self) = @_;
	
	$self->load_all_models;
	
	my $c = $::app->connect;
	my $info = $c->info;
	my $fk_info = $c->fk_info_backward;
	my $dbh = $c->dbh;
	
	$dbh->do(main::msg $self->create_database), $dbh->do(main::msg "USE " . $c->word($c->databasename)) unless $dbh->{Name};
	
	
	my $fieldsets = $self->{fieldset};
	my %tab;
	
	for my $fieldset (values %$fieldsets) {
		$fieldset->sync;
		$tab{$fieldset->{tab}} = 1;
	}
	
	my @sql;
	while(my($key, $val) = each %$info) {
		if(!exists $tab{$key}) {
			push @sql, "DROP TABLE " . $c->word($key);
			# удаление внешних ключей
			while(my($k, $idx) = each %{$fk_info->{$key}}) {
				my $sql = R::Model::IndexRef::drop(undef, $idx->{table_name}, $k);
				main::msg $sql;
				$dbh->do($sql);
			}
		}
	}
	
	for my $sql (@sql) {
		main::msg $sql;
		$dbh->do($sql);
	}

	$self
}

# sql для создания БД
sub create_database {
	my ($self) = @_;
	my $c = $::app->connect;
	"CREATE DATABASE ". $c->word($c->databasename) ." DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci"
}

1;