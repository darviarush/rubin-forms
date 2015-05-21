package R::Model::Fieldset;
# таблица - менеджер полей, дополнительных опций таблицы базы и ключей

use strict;
use warnings;

require R::Model::Row;
require R::Model::Rowset;
require R::Model::Index;
require R::Model::Field::Col;
require R::Model::Field::Ref;
require R::Model::Field::Back;
require R::Model::Field::M2m;
require R::Model::Field::Compute;


our $pk_type = "int unsigned";
our $default_charset = "utf8_general_ci";
our $engine = "INNODB";

# конструктор
sub new {
	my ($cls, $name) = @_;
	
	my $meta = $::app->modelMetafieldset;
	
	my $tab = $meta->word($name);
	
	$meta->{fieldset}{$name} = my $self = bless {
		name => $name,	# имя филдсета
		tab => $tab,	# имя таблицы в базе
		field=>{},		# филды имя=>филд
		fieldset=>[],	# порядок филдов
		pk=>undef,		# primary key
		indexes=>{},		# индексы
		indexref=>{},	# индексы-ссылки
		engine => undef,
		options => undef,	# дополнительные опции таблицы
		charset => undef,	# collate таблицы
		remark => undef,	# комментарий таблицы
		paging => undef,	# размер страницы
		ordering => undef,	# сортирвка по умолчанию
		data => [],
		testdata => []
	}, $cls;
	
	my $Prop = ucfirst $name;
	
	# создаём роусет
	{no strict "refs";
	@{"R::Row::${Prop}::ISA"} = "R::Model::Row" unless @{"R::Row::${Prop}::ISA"};
	@{"R::Rowset::${Prop}::ISA"} = "R::Model::Rowset" unless @{"R::Rowset::${Prop}::ISA"};
	my $getter = sub {$_[0]};
	my $fs = Utils::closure($self, $getter);
	my $ff = Utils::closure($self->{field}, $getter);
	my $mm = Utils::closure($::app->model, $name, sub { my($model, $name, $self, @args)=@_; $model->$name(@args) });
	*{"R::Row::${Prop}::Fieldset"} = $fs;
	*{"R::Rowset::${Prop}::Fieldset"} = $fs;
	*{"R::Row::${Prop}::Field"} = $ff;
	*{"R::Rowset::${Prop}::Field"} = $ff;
	*{"R::Row::${Prop}::Model"} = $mm;
	*{"R::Rowset::${Prop}::Model"} = $mm;
	};

	$self->pk($pk_type)->autoincrement;
	
	# создаём свойство в модели
	# если конструктор филдсета был вызван не из app->model, то тут будут подгружены и пакеты модели
	$::app->model->$name(undef);
	
	# порядок создания таблиц - в начале те, у которых нет ссылок на следующие
	unshift @{$meta->{fields}}, $self;
	
	$self
}

our %META = Utils::set(qw/charset paging ordering engine options remark/);

# устанавливает метаинформацию для базы
sub meta {
	my ($self, %args) = @_;
	while(my($k, $v) = each %args) {
		die "нет опции `$k` в meta" unless exists $META{$k};
		$self->{$k} = $v;
	}
	$self
}

# возвращает последний филд
sub last {
	my ($self) = @_;
	my $x = $self->{fieldset};
	$x->[$#$x];
}

# добавляет вычислимый столбец
sub compute {
	my ($self, $name) = @_;
	R::Model::Field::Compute->new($self, $name);
	$self
}

# добавляет поле
sub col {
	my ($self, $name, $type) = @_;
	R::Model::Field::Col->new($self, $name, $type);
	$self
}

# добавляет поле-ссылку
sub ref {
	my ($self, $name, $to_model, $bk_name, $fk_name) = @_;	
	R::Model::Field::Ref->new($self, $name, $to_model, $bk_name, $fk_name);
	$self
}

# ссылка многие-ко-многим
#	$name - имя филда m2m
#	$to_model - имя модели
#	$name_from_model - имя обратной связи в $to_model
#	$m2m_model - имя модели-связи
#	$alias1 - название ref на себя
#	$alias2 - название ref на модель
sub m2m {
	my ($self, $name, $to_model, $name_from_model, $m2m_model, $alias1, $alias2) = @_;
	
	my $to_fieldset = $::app->modelMetafieldset->fieldset($to_model);
	
	$to_model = $name, $name .= "s" unless defined $to_model;
	
	$name_from_model //= $self->{name} . "s";
	unless($m2m_model) {
		$name =~ /s$/; my $x = $` // $name;
		$name_from_model =~ /s$/; my $y = $` // $name_from_model;
		$m2m_model = $x . ucfirst $y;
	}
	
	$alias1 //= $self->{name};
	$alias2 //= ($alias1 eq $to_model? 'any' . $to_model: $to_model);
	
	my $m2m_fieldset = $::app->modelMetafieldset->fieldset($m2m_model)->
	pk(undef)->
	ref($alias1 => $self->{name})->
	ref($alias2 => $to_model)->
	unique("$alias1, $alias2");
	
	my $ref_from = $m2m_fieldset->{field}{$alias1};
	my $ref_to = $m2m_fieldset->{field}{$alias2};
	
	my $ref1 = R::Model::Field::M2m->new($name, $ref_from, $ref_to);
	my $ref2 = R::Model::Field::M2m->new($name_from_model, $ref_to, $ref_from);
	$ref1->{back} = $ref2;
	$ref2->{back} = $ref1;
	
	$self
}

# добавляет валидатор
sub check {
	my ($self, $name, @args) = @_;
	$self->last->check({name=>$name, args=>[@args]});
	$self
}


# добавляет или удаляет pk
sub pk {
	my ($self, $type, $name) = @_;
	
	$name //= "id";
	
	my $pk = $self->{pk};
	$self->{pk} = undef, $pk->delete if $pk;
	
	if(defined $type) {
		$pk = $self->{pk} = R::Model::Field::Col->new($self, $name, $type);
		$pk->{autoincrement} = 0;
		$pk->{pk} = 1;
	}
	$self
}

# добавляет автоинкремент
sub autoincrement {
	my ($self) = @_;
	$self->last->{autoincrement} = 1;
	$self
}

# делает филд нулевым
sub null {
	$_[0]->last->{null} = 1;
	$_[0]
}

# делает филд обязательным
sub required {
	$_[0]->last->{null} = 0;
	$_[0]
}


# добавляет значение по умолчанию к последнему филду
sub default {
	my ($self, $default, $raw) = @_;
	$self->last->{default} = $raw? $default: $::app->connect->quote($default);
	$self
}

sub raw_default {
	my ($self, $default) = @_;
	$self->default($default, 1);
}

# добавляет комментарий к последнему филду
sub remark {
	my ($self, $comment) = @_;
	my $fld = $self->last->remark($comment);
	$self
}

# добавляет индекс
sub _add_index {
	my ($keyword, $self, $idx, $name) = @_;
	my @idx = split /\s*,\s*/, $idx // $self->last->{name};
	$name ||= ($keyword eq "INDEX"? 'idx': 'unq') . "_" . join "__", @idx;
	$self->{indexes}{$name} = R::Model::Index->new($keyword, [@idx], $name, $self);
	$self
}

sub index { unshift @_, 'INDEX'; goto &_add_index; }
sub unique { unshift @_, 'UNIQUE'; goto &_add_index; }

# просто для окончания, чтобы можно было столбец закомментировать
sub end {}

# в новую таблицу добавляются обязательные данные
sub data {
	my ($self, @args) = @_;
	push @{$self->{data}}, @args;
	$self
}

# в новую таблицу добавляются тестовые данные
sub testdata {
	my ($self, @args) = @_;
	push @{$self->{testdata}}, @args;
	$self
}


# запускает данные
sub run_data {
	my ($self, $rows) = @_;
	my $model = $self->{name};
	for my $row (@$rows) {

		if(CORE::ref $row eq "ARRAY") {
			my $bean = $::app->model->$model(undef);
			my $fieldset = $self->{fieldset};
			my $i = 0;
			for my $val (@$row) {
				my $fld = $fieldset->[$i++];
				while(CORE::ref($fld) =~ /^R::Model::Field::(?:Back|M2m)$/) { $fld = $fieldset->[$i++] }
				my $name = $fld->{name};
				$bean->$name($val);
			}
			$bean->store;
		} else {
			die "Что-то неясное попало в инициализирующие данные: $row";
		}
		
	}
	$self
}

# возвращает имена столбцов таблицы
sub col_keys {
	my ($self) = @_;
	map { $_->{col} } grep { !$_->{compute} } @{$self->{fieldset}};
}

# синхронизация таблицы
sub sync {
	my ($self) = @_;
	
	return $self if $self->{sync};
	$self->{sync} = 1;
	
	my $c = $::app->connect;
	my $tab = $self->{tab};
	my $info = $c->info->{$tab};
	
	# синхронизируем вначале зависимые таблицы
	while(my ($name, $indexref) = each %{$self->{indexref}}) {
		$indexref->fk->fieldset->sync;
	}
	
	# создаём или редактируем
	if(!$info) {
		my $listener = $::app->listener;
		$listener->fire("$self->{name}.create", $self);

		my $sql = $self->create_table;
		$c->do($sql);		
	} else {
	
		# опции таблицы
		my $tab_info = $c->tab_info->{$self->{tab}};
		$tab_info->{charset} = undef if !$self->{charset} and ($tab_info->{charset} // "") eq 'utf8_unicode_ci';
		
		my @a = $self->sql;
		my @b = $self->sql($tab_info);
		my $i = 0;
		for my $a (@a) {
			my $b = $b[$i++];
			if($a ne $b) {
				main::msg "1) $a";
				main::msg "2) $b";
				$c->do($self->alter($a));
			}
		}
		
		# столбцы
		my %is;
		my $num = 1;
		my $after = 1;
		for my $field (@{$self->{fieldset}}) {
			if(!$field->compute) {
				$field->sync($after, $num++);
				$is{$after = $field->{col}} = 1;
			}
		}
		
		# индексы
		while(my ($name, $index) = each %{$self->{indexes}}) {
			$index->sync;
		}
		
		# удаляем индексы
		my $idx_info = $c->index_info->{$tab} // {};
		while(my ($k, $v) = each %$idx_info) {
			$c->do(R::Model::Index::drop(undef, $tab, $k)) if not exists $self->{indexes}{$k} and $k ne "PRIMARY";
		}
		
		# fk
		while(my ($name, $indexref) = each %{$self->{indexref}}) {
			$indexref->sync;
		}
		
		# удаляем fk
		my $fk_info = $c->fk_info->{$tab} // {};
		while(my ($k, $v) = each %$fk_info) {
			$c->do(R::Model::IndexRef::drop(undef, $tab, $k)) if !exists $self->{indexref}{$k};
		}
		
		
		# удаляем столбцы
		while(my ($k, $v) = each %$info) {
			$c->do(R::Model::Field::Col::drop(undef, $tab, $k)) if !$is{$k};
		}
	}
	
	$self;
}

# инкрементирует автоинкремент на указанное количество и возвращает последний id
sub auto_increment_inc {
	my ($self, $inc) = @_;
	my $c = $::app->connect;
	my $id = $c->query("INFORMATION_SCHEMA.TABLES", "AUTO_INCREMENT", ["WHERE", "TABLE_SCHEMA" => $c->basename, "TABLE_NAME" => $self->{tab}]);
	$id += $inc;
	$c->do("ALTER TABLE " . $c->word($self->{name}) . " AUTO_INCREMENT = " . $id);
	$id-1;
}


# возвращает дополнительные опции таблицы, которые можно использовать в alter table
sub sql {
	my ($self, $opt, $create) = @_;
	$opt //= $self;
	my $c = $::app->connect;
	
	my $collation = $opt->{charset} // $default_charset;
	$collation =~ /_/; 
	my $charset = $`;

	return (
		($create? "DEFAULT CHARACTER SET '$charset' COLLATE '$collation',":
		"CONVERT TO CHARACTER SET '$charset' COLLATE '$collation'"),
		"ENGINE=" . uc($opt->{engine} || $engine),
		"COMMENT=" . $c->quote($opt->{remark} // ""),
		($opt->{options}? $opt->{options}: ()),
	)
}

# возвращает alter table для таблицы (не для столбцов)
sub alter {
	my ($self, $sql) = @_;
	my $c = $::app->connect;
	"ALTER TABLE " . $c->word($self->{tab}) . " " . ($sql // join " ", $self->sql(undef, 1));
}

# возвращает create table
sub create_table {
	my ($self) = @_;
	
	my $connect = $::app->connect;
	
	my @sql = ("CREATE TABLE ", $connect->word($self->{tab}), " (\n");
	my @col;
	for my $field (@{$self->{fieldset}}) {
		push @col, $field->sql unless $field->compute;
	}
	
	while(my ($key, $idx) = each %{$self->{indexes}}) {
		push @col, $idx->sql;
	}
	
	while(my ($key, $idx) = each %{$self->{indexref}}) {
		push @col, $idx->sql;
	}
	
	push @sql, join ",\n", @col;
	
	push @sql, "\n) ", join " ", $self->sql(undef, 1);
	join "", @sql;
}

# переименовывает таблицу
sub rename_tab {
	my ($self, $tab) = @_;
	my $c = $::app->connect;
	join "", "ALTER TABLE ", $c->word($self->{tab}), " RENAME ", $c->word($tab);
}

# переименовывает столбец
sub rename {
	my ($self, $new_name) = @_;
	my $c = $::app->connect;
	$c->do($self->rename_tab($new_name));
}

# удаляет таблицу
sub drop {
	my ($self) = @_;
	
	my $listener = $::app->listener;
	$listener->fire("$self->{name}.drop", $self);
	return $self if $self->{noAction};
	
	my $c = $::app->connect;
	
	my $fk_info = $c->fk_info_backward->{$self->{tab}};
	while(my($name, $fk) = each %$fk_info) {
		$c->do(R::Model::IndexRef::drop(undef, $fk->{tab}, $name));
	}
	
	my $sql = "DROP TABLE " . $c->word($self->{tab});
	$c->do($sql);
	
	$self
}

1;