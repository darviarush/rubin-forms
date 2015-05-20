package R::Model::Metafieldset;
# база данных

use File::Find qw//;

require R::Model::Index;
require R::Model::Fieldset;


# конструктор
sub new {
	my ($cls) = @_;
	
	my $ini = $::app->ini->{DNS};
	
	bless {
		name => undef,		# имя базы данных
		fieldset => {},		# имя => таблица
		fields => [],		# [таблица, таблица...] - порядок таблиц
		cls => {},			# class => таблица
		charset => $ini->{charset} // "utf8_unicode_ci",
		paging => $ini->{paging} // 6,		# размер страницы
	}, $cls;
}

# создаёт и возвращает новую таблицу
sub fieldset {
	my ($self, $name) = @_;
	$self->{fieldset}{$name} //= R::Model::Fieldset->new($name);
}

our %META = Utils::set(qw/charset paging/);

# устанавливает метаинформацию для базы
sub meta {
	my ($self, %args) = @_;
	while(my($k, $v) = each %args) {
		die "нет опции `$k` в meta" unless exists $META{$k};
		$self->{$k} = $v;
	}
	$self
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
	
	# подгружаем все модели
	$self->load_all_models;
	
	my $c = $::app->connect;
	my $info = $c->info;
	my $fk_info = $c->fk_info_backward;
	
	# создаём базу, если её нет
	$c->do($self->create_database), $c->do("USE " . $c->word($c->databasename)) unless $c->dbh->{Name};
	
	
	# синхронизация таблиц
	my $fieldsets = $self->{fieldset};
	my %tab;
	
	for my $fieldset (values %$fieldsets) {
		$fieldset->sync;
		$tab{$fieldset->{tab}} = 1;
	}
	
	# удаление внешних ключей
	my @sql;
	while(my($key, $val) = each %$info) {
		if(!exists $tab{$key}) {
			push @sql, "DROP TABLE " . $c->word($key);
			# удаление внешних ключей
			while(my($k, $idx) = each %{$fk_info->{$key}}) {
				my $sql = R::Model::IndexRef::drop(undef, $idx->{tab}, $k);
				$c->do($sql);
			}
		}
	}
	
	# удаление таблиц
	for my $sql (@sql) {
		$c->do($sql);
	}

	# выполняем функции синхронизации в установленном порядке
	
	my $_test = $::app->ini->{site}{test};
	for my $fieldset (@{$self->{fields}}) {

		my $name = $fieldset->{name};
		my $bean = $::app->model->$name(undef);

		if($_test && @{$fieldset->{testdata}}) {
			$fieldset->run_data($fieldset->{testdata});
			$bean->can("testdata")->($fieldset) if $bean->can("testdata");
		}
			
		if(@{$fieldset->{data}}) {
			$fieldset->run_data($fieldset->{data});
			$bean->can("data")->($fieldset) if $bean->can("data");
		}
		
		delete $fieldset->{sync};
	}
	
	$self
}

# sql для опций БД
sub sql {
	my ($self) = @_;
	$self->{charset} =~ /_/;
	" DEFAULT CHARACTER SET $` COLLATE $self->{charset}";
}

# sql для alter database
sub alter {
	my ($self) = @_;
	my $c = $::app->connect;
	"ALTER DATABASE " . $c->word($self->{name}) . $self->sql;
}

# sql для создания БД
sub create_database {
	my ($self) = @_;
	my $c = $::app->connect;
	"CREATE DATABASE ". $c->word($c->databasename) . $self->sql;
}

# если такой БД нет - создаёт и переключает на неё $app->connect
sub database {
	my ($self, $name) = @_;
	$self->{name} = $name;
	$self
}

# удаляет базу
sub drop {
	my ($self) = @_;
	$self->load_all_models;
	my $info = $::app->connect->info;
	for my $fieldset (@{$self->{fields}}) {
		$fieldset->drop if $info->{$fieldset->{tab}};
	}
	$self
}

1;