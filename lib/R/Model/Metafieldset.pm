package R::Model::Metafieldset;
# база данных

use common::sense;
use R::App;

require R::Model::Index;
require R::Model::Indexref;
require R::Model::Fieldset;

# все меты по именам
our %META;

# строковые типы
our $string_types = {"varchar"=>1, "char"=>1, "text"=>1, "mediumtext"=>1, "tinytext"=>1, "lagetext"=>1};

our $type_to_input = {"mediumtext" => "area", "lagetext"=>"area"};

our $default_checks = {};

has qw/name fields cls charset paging string_types type_to_input input_default input inputset column_type types pk_type engine base connect model lang cache/;

# конструктор
sub new {
	my ($cls, $name, $connect, $ini) = @_;

	$name //= "R";
	# может быть только одна мета с таким именем
	return $META{$name} if exists $META{$name};
	 
	$connect //= $app->connect;
	
	my $database = $connect->basename;
	$ini //= $app->ini->{model};
	
	my $self = bless {
		name => $name,		# мета-имя. Оно используется для создания классов
		database => $database,	# имя базы
		fieldset => {},		# имя => таблица
		fields => [],		# [таблица, таблица...] - порядок таблиц
		cls => {},			# class => таблица
		charset => "utf8_unicode_ci",		# если charset не соврпадает с началом collate до _, то записывается через ":": ucs1:wsc12
		paging => 6,						# размер страницы
		ordering => undef,					# массив или строка через пробел или "," с сортировкой по умолчанию для всех таблиц, например, id или -id
		string_types => $string_types,		# строковые типы
		type_to_input => $type_to_input,	# тип к вводу
		input_default => "line",			# дефолтный input для всех столбцов - вычислимых так же
		input => "select",					# дефолтный input для ref
		inputset => "checkboxes",			# дефолтный input для множественных полей
		column_type => $connect->{column_type},		# типы столбцов для alter table
		types_path => "lib/R/Model/Type",	# пути к директориям с типами через ":"
		types => undef,			# типы столбцов: имя=>класс Perl. Пример: {unixtime => "R::Model::Type::Unixtime", ...}
		# при установке: (ref $x? тип->new($x): $x)->toCol()
		# при возврате: тип->fromCol($x)
		checks => {%$default_checks},			# дефолтные валидаторы
		pk_type => "int unsigned",
		engine => "InnoDB",
		base => "model",		# путь к директории из которой подгружать модели, может содержать несколько, через "," или " "
		bases => {},			# какие модели уже загружены: "catalog"=>1
		connect => $connect,	# коннект к базе
		cache => $app->cache,	# кэш
		model => undef,			# объект созданного специального класса для меты
		lang => "Rus",			# дефолтный язык для match-индексов
		addtestdata => $app->ini->{site}{test},		# нужно ли при синхронизации добавлять тестовые данные
		touch => undef,			# булево значение, означает, что во всех таблицах будут поля now и upd
		softerase => undef,	# 1 - мягкое удаление во всех таблицах
	}, ref $cls || $cls;
	
	$self->meta(%$ini) if $ini;
	
	# загружаем типы
	$self->{types} //= do {
		return if !$self->{types_path};
		my $get_types = {};
		my @path = split /:/, $self->{types_path};
		my @files = $app->file(@path)->find;
		$app->file(@path)->find(sub {
			my $path = $_;
			if($path =~ /([^\/]+)\.pm$/) {
				my $name = lc $1;
				$path =~ s/^lib\///;
				$path =~ s/\.pm$//;
				$path =~ s/\//::/g;
				$get_types->{$name} = $path;
			}
			undef
		});
		$get_types
	};
	
	# создаём класс с методами для $meta->model->mymodel(...)
	my $cls_model = "R::Model";
	if($name ne "R") {
		my $eval = $app->file("lib/R/Model.pm")->read;
		$cls_model = "R::MetaModel::$name";
		$eval =~ s/^package R::Model;/package $cls_model;/;
		eval $eval;
		die $@ if $@;
		
		*{"${cls_model}::Metafieldset"} = closure $self, sub { shift() };
	}
	else {	# подгружаем model
		$app->model;
	}
	
	$self->{model} = $cls_model->new;
	
	$META{$name} = $self;
	
	$self
}

# закрывает метаописание
sub close {
	my ($self) = @_;
	
	delete $META{$self->name};
	$self->connect->close;
	$self->connect->connect if $self->connect == $app->connect;
	$app->{modelMetafieldset} = undef if $app->{modelMetafieldset} == $self;
	$self
}

# создаёт и возвращает новую таблицу
sub fieldset {
	my ($self, $name, $cls_row_name) = @_;
	$self->{fieldset}{$name} // R::Model::Fieldset->new($name, $self, $cls_row_name);
}

our %Meta = $app->perl->set(qw/name charset paging ordering pk_type engine input_default input inputset base types_path lang addtestdata touch softerase/);

# устанавливает метаинформацию для базы
sub meta {
	my ($self, %args) = @_;
	while(my($k, $v) = each %args) {
		next if $k eq "cache";
		die "нет опции `$k` в meta" unless exists $Meta{$k};
		$self->{$k} = $v;
	}
	$self
}

# проверяет на существование филдсет по имени и возвращает его, если тот есть
sub exists {
	my ($self, $name) = @_;
	$self->{fieldset}{$name}
}

# существует ли БД
sub existsDatabase {
	my ($self) = @_;
	!!$self->connect->query("information_schema.schemata", "1", {schema_name => $self->{database}});
}


# проверяет таблицу на существование
sub existsTab {
	my ($self, $tab) = @_;
	!!$self->connect->info->{$tab}
}

# проверяет колумн на существование
sub existsCol {
	my ($self, $tab) = @_;
	
	$tab =~ /\./; my $col = $'; $tab = $`;
	
	!!$self->connect->info->{$tab}{$col};
}

our %inspect = $app->perl->set(qw/sync syncing synced setup setuped/);

# проверяет, что есть такой обработчик
sub _inspect {
	my ($self, $name) = @_;
	die "нет зарегистрированного события $name" if !exists $inspect{$name};
}

# устанавливает обработчик события на мету
sub on {
	my ($self, $name, $cb) = @_;
	$self->_inspect($name);
	($self->{signal}{$name} //= $app->signal->new)->cb($cb);
	$self
}

# возбуждает событие на мете
sub fire {
	my ($self, $name) = splice @_, 0, 2;
	$self->_inspect($name);
	my $signal = $self->{signal}{$name};
	$signal->send(@_) if $signal;
	$self
}

# проверяет - установлено ли событие
sub on_exists {
	my ($self, $name) = @_;
	if(ref $name) {	# одно из должно быть усановлено
		for my $n (@$name) {
			$self->_inspect($n);
			return 1 if exists $self->{signal}{$n}
		}
		undef
	}
	else {
		$self->_inspect($name);
		$self->{signal}{$name}
	}
}

# синоним
*load = \&load_all_models;

# загружает все модели
sub load_all_models {
	my ($self, $base) = @_;
	
	# подгружаем дефолтные модели, например: модель миграций
	$self->default_fieldsets if !$self->{default_fieldsets};
	$self->{default_fieldsets} = 1;
	
	$base //= $self->{base};
	
	# если нечего загружать
	return $self if !defined $base;
	
	# модели должны загружаться только раз
	return $self if exists $self->{bases}{$base};
	
	$self->{bases}{$base} = 1;
	
	# копируем, т.к. в $fieldsets будут добавляться таблицы порождённые m2m в начало и указатель for-а будет сбиваться
	my @fieldsets;
	
	$app->file($base)->find->sort->then(sub {
		my $path = $_->path;
		if($path =~ /^$base(.*)\.pm$/) {
			my $name = my $cls = $1;
			$name =~ s/\///g;
			$name = lcfirst $name;
			
			$cls =~ s!^/!!;
			$cls =~ s/\//::/g;
			
			require $path;
			
			unshift @fieldsets, $self->fieldset($name, $cls);
		}
		undef
	}) if $base;

	$self->setup(\@fieldsets);
	
	$self
}


# запускает сетапы на моделях
sub setup {
	my ($self, $fieldsets) = @_;
	
	my $flag = $self->{flag_load};	# undef будет только в 1-й load, а в последующих - нет
	$self->{flag_load} = 1;
	#my $fields = $self->{fields};

	# устанавливаем обработчики событий
	$_->setup_on for @$fieldsets;
	
	$self->fire("setup") if !$flag;
	
	# вызываем сетапы на моделях
	$_->setup for @$fieldsets;
	
	$self->fire("setuped") if !$flag;
	
	$self->{flag_load} = $flag;
	
	$self
}

# загружает модели миграции
sub migrateload {
	my ($self) = @_;
	
	$self->default_fieldsets;
	
	my @fieldsets;
	my $migrate = $self->{name};
	
	my @keys = sort keys %{"${migrate}::Row::"};
	
	for my $i (@keys) {
		my $cls = $i;
		$cls =~ s/::$//;
		my $name = lcfirst $cls;
		#msg1 $cls, $name;
		unshift @fieldsets, $self->fieldset($name, $cls);
	}
	
	$self->setup(\@fieldsets);
	
	$self
}

# создаёт филдсет миграций
sub default_fieldsets {
	my ($self) = @_;
	
	$self->create("_migrate", sub {	shift->
		pk("varchar(255)")->remark("применённые миграции")->
		meta(
			remark => "список применённых миграций"
		);
	});

	$self
}

# запускает setup, если такого филдсета нет
# филдсет в сетап передаётся и параметром и в $_
sub create {
	my ($self, $name, $setup) = @_;
	
	return $self if $self->exists($name);
	
	$self->fieldset($name)->setup($setup);
	
	$self
}

# возвращает текстовый тип для базы по размеру
sub getUIntType {
	my ($self, $max) = @_;
	
	return $max if $max =~ /^(?:tiny|small|medium|big)?int(?:\s+unsigned)?$/i;
	
	$max = $app->perl->size($max);
	
	if($max < 1 << 8) {
		"tinyint unsigned"
	}
	elsif($max < 1 << 16) {
		"smallint unsigned"
	}
	elsif($max < 1 << 24) {
		"mediumint unsigned"
	}
	elsif($max < 1 << 32) {
		"int unsigned"
	}
	elsif($max < 1 << 64) {
		"bigint unsigned"
	}
	else {
		die "слишком большое значение $max: максимум 1024G-1"
	}
}


# возвращает текстовый тип для базы по размеру
sub getTextType {
	my ($self, $length) = @_;
	
	return "varchar(255)" if $self->{engine} eq "memory";
	
	return $length if $length =~ /^(?:tiny|medium|long)?text$/i;
	
	$length = $app->perl->size($length);
	
	if($length < 1 << 8) {
		"tinytext"
	}
	elsif($length < 1 << 16) {
		"text"
	}
	elsif($length < 1 << 24) {
		"mediumtext"
	}
	elsif($length < 1 << 32) {
		"longtext"
	}
	else {
		die "слишком большое значение $length: максимум 4G-1"
	}
}

# синхронизация используемая в скриптах - запрашивает 
sub sync_for_script {
	my ($self) = @_;
	
	$self->presync;
	
	my $sql_before = $self->{sql_before};
	my $sql_main = $self->{sql_main};
	my $sql_after = $self->{sql_after};
	
	# спрашиваем: применить ли указанные действия?
	msg "Будут выполнены следущие действия:\n";
	my $c = $self->connect;
	$app->log->info(":empty", $c->syntax($_)) for @$sql_before, @$sql_main, @$sql_after;
	return $self if !$app->tty->confirm("Выполнить синхронизацию?");
	
	$self->syncing->synced;
}

# синхронизирует базу
sub sync {
	my ($self) = @_;
	$self->presync->syncing->synced;
}

# формирует запросы для синхронизации базы
sub presync {
	my ($self, $yes, $_test) = @_;
	
	$self->fire("sync");
	
	my $c = $self->connect;

	# создаём базу, если её нет
	$c->do($self->create_database) if !$self->existsDatabase;

	$c->do("USE " . $c->word($self->{database}));
	
	
	# подгружаем все модели
	#$self->load_all_models;
	
	# сбрасываем кеши
	$c->clean;
	
	my $info = $c->info;
	my $fk_info = $c->fk_info_backward;
	
	# синхронизация таблиц
	my $sql_before = $self->{sql_before} = [];
	my $sql_main = $self->{sql_main} = [];
	my $sql_after = $self->{sql_after} = [];

	
	for my $fieldset (@{$self->{fields}}) {
		$fieldset->{sync} = $fieldset->{synced} = undef;
	}
	
	#my $fieldsets = $self->{fieldset};
	my %tab;
	
	for my $fieldset (@{$self->{fields}}) {
		$fieldset->presync;
		$tab{lc $fieldset->{tab}} = 1;
	}
	
	# удаление таблицы
	my @sql;
	while(my($key, $val) = each %$info) {
		if(!exists $tab{lc $key}) {
			push @sql, "DROP TABLE " . $c->word($key);
			# удаление внешних ключей
			while(my($k, $idx) = each %{$fk_info->{$key}}) {
				my $sql = R::Model::Indexref::drop($self, $idx->{tab}, $k);
				push @$sql_before, $sql;
				#exit;
			}
		}
	}

	unshift @$sql_main, @sql;
	
	#push @$sql_before, "SET FOREIGN_KEY_CHECKS = 0";
	#push @$sql_after, "SET FOREIGN_KEY_CHECKS = 1";
	
	$self
}

# синхронизация после presync
sub syncing {
	my ($self) = @_;
	
	my $sql_before = $self->{sql_before};
	my $sql_main = $self->{sql_main};
	my $sql_after = $self->{sql_after};
	
	my $c = $self->connect;
	
	# удаление внешних ключей, как задала синхронизация таблиц
	for my $sql (@$sql_before) {
		$c->do($sql);
	}
	
	# синхронизайия таблиц
	for my $sql (@$sql_main) {
		$c->do($sql);
	}
	
	# создание fk-ключей
	for my $sql (@$sql_after) {
		$c->do($sql);
	}

	$c->clean;

	$self->fire("syncing");
	
	$self
}
	

# выполняем функции синхронизации в установленном порядке 
sub synced {
	my ($self, $_test) = @_;
	
	die "ненужный параметр test в synced" if @_>1;
	
	for my $fieldset (@{$self->{fields}}) {

		$fieldset->sync_data;
		
		delete $fieldset->{sync};
	}
	
	$self->fire("synced");
	
	
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
	my $c = $self->connect;
	"ALTER DATABASE " . $c->word($self->{database}) . $self->sql;
}

# sql для создания БД
sub create_database {
	my ($self) = @_;
	my $c = $self->connect;
	"CREATE DATABASE ". $c->word($self->{database}) . $self->sql;
}

# если такой БД нет - создаёт и переключает на неё (???)
sub database {
	my ($self, $name) = @_;
	$self->{database} = $name;
	$self
}

# удаляет данные из всех таблиц
sub truncate {
	my ($self) = @_;
	
	$self->connect->do("SET foreign_key_checks=0");
	
	for my $fieldset (@{$self->{fields}}) {
		$fieldset->truncate;
	}
	
	$self->connect->do("SET foreign_key_checks=1");
	
	$self
}

# удаляет таблицы базы
sub drop {
	my ($self) = @_;
	
	#$self->load_all_models;
	my $info = $self->connect->info;
	for my $fieldset (@{$self->{fields}}) {
		$fieldset->drop if delete $info->{$fieldset->{tab}};
	}
	
	for my $tab (keys %$info) {
		#$self->fieldset($tab)->meta(tab=>$tab)->drop;
		R::Model::Fieldset::drop($self, $tab);
	}
	
	$self->connect->clean;
	
	$self
}


# сгружает в указанную директорию структуру базы в виде моделей
# Создаётся папка с именем базы
sub down {
	my ($self, $outdir) = @_;
	
	local ($a, $b);
	
	my $c = $self->connect;
	
	$app->file($outdir //= $c->basename)->mkdir->rmdown;
	
	my $tab_info = $c->tab_info;
	my $info = $c->info;
	my $index_info = $c->index_info;
	
	while(my ($tab, $cols) = each %$info) {
		
		my $name = $tab;  #$c->uc( $tab );
		
		my $file = $app->file("$outdir/$name.pm")->open(">");
		
		msg $tab;
		
		print $file "package R::Row::$name;
# модель $tab

use base R::Model::Row;

use common::sense;
use R::App;


# вызывается для создания структуры базы
sub setup {
	my (\$fields) = \@_;
	\$fields->pk(undef)->
	
	
";
	
		$self->{col_to_name} = {};
	
		for my $col (sort { $a->{ordinal_position} <=> $b->{ordinal_position} } values %$cols) {
			print $file "\t" . $self->declare_col($tab, $col) . "->\n";
		}
		
		my $idx_info = $index_info->{$tab};
		
		print $file "\n" if %$idx_info;
		
		my $pk_index = $idx_info->{"PRIMARY"};
		print $file "\tprimary_key('" . join(",", map {$_->{col}} @$pk_index) . "')->\n" if @$pk_index > 1;
		
		while(my ($idx, $cols) = each %$idx_info) {
			next if $idx eq 'PRIMARY';
			print $file "\t" . ($cols->[0]{non_uniq}? "index": "unique") . "('" . join(", ", map {$self->{col_to_name}{$_->{col}}} @$cols) . "' => '$idx')->\n";
		}
		
		my $declare_tab = $self->declare_tab($tab_info->{$tab});
		print $file "\n" . $declare_tab . "->\n" if $declare_tab;
		
		$self->{col_to_name} = {};
		
		print $file "

	end;
	
}

# тестовые данные
sub testdata {
}

1;
";
		close $file;
	}

	
	$self
}

# возвращает код представления модели в setup
sub declare_col {
	my ($self, $tab, $col) = @_;
	
	my $name = $col->{column_name};
	
	my $pk_index = $self->connect->index_info->{$tab}{"PRIMARY"};
	
	my @col;
	if(@$pk_index==1 && $col->{column_key} eq "PRI") {
		$self->{col_to_name}{$name} = "id";
		
		my $real_name = $name ne "id" ? " => '$name'": "";
		
		push @col, "pk('$col->{column_type}'$real_name)";
	}
	else {
		if($app->can($name) || R::Model::Fieldset->can($name) || R::Model::Row->can($name) || R::Model::Rowset->can($name)) {
			my $fname = "a_$name";
			$self->{col_to_name}{$name} = $fname;
			push @col, "col('$fname' => '$col->{column_type}' => '$name')";
		} else {
			$self->{col_to_name}{$name} = $name;
			my $real_name = $name !~ /^[a-z_0-9]+$/ ? " => '$name'": "";
			push @col, "col('$name' => '$col->{column_type}'$real_name)";
		}
	}
	
	
	my $extra = $col->{extra};
	push @col, "->autoincrement" if $extra =~ s/auto_increment//;
	push @col, "->null" if $col->{is_nullable} =~ /YES/;
	
	push @col, ($col->{column_default} =~ /^CURRENT_TIMESTAMP$/i? "->default_raw": "->default") . "(". $self->connect->quote($col->{column_default}) .")" if defined $col->{column_default};
	my $set;
	push @col, (substr($col->{collation_name}, 0, length($col->{character_set_name})+1) eq $col->{character_set_name} . "_"? "->charset('$col->{collation_name}')": "->charset('$col->{character_set_name}:$col->{collation_name}')") if $col->{character_set_name};
	
	push @col, "->extra('$extra')" if $extra ne "";
	
	push @col, "->remark(" . $self->connect->quote($col->{column_comment}) . ")" if $col->{column_comment};
	
	join "", @col;
}


# декларирует информацию о таблице
sub declare_tab {
	my ($self, $meta) = @_;
	local ($`, $');
	my @meta;
	
	push @meta, "\t\ttab => '$meta->{name}',\n" if $meta->{name};
	push @meta, "\t\tcompute => 1,\t# table_type=$meta->{type}\n" if $meta->{type} !~ /TABLE/i;
	push @meta, "\t\tengine => '$meta->{engine}',\n" if $meta->{engine};
	push @meta, "\t\tcharset => '$meta->{charset}',\n" if $meta->{charset};
	push @meta, "\t\tremark => '$meta->{remark}',\n" if $meta->{remark};
	push @meta, "\t\toptions => '$meta->{options}',\n" if $meta->{options};
	
	return "" if !@meta;
	unshift @meta, "\tmeta(\n";
	push @meta, "\t)";
	join "", @meta;
}

1;