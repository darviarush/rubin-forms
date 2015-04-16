package R::Model::Fieldset;
# таблица - менеджер полей, дополнительных опций таблицы базы и ключей

use strict;
use warnings;

require R::Model::Rowset;
require R::Model::Field;
require R::Model::Index;

#our $pk_type = 'int primary key AUTO_INCREMENT';
our $pk_type = "int unsigned";
our $engine = "INNODB";

# конструктор
sub new {
	my ($cls, $name) = @_;
	
	my $meta = $::app->modelMetafieldset;
	
	my $tab = $meta->word($name);
	
	my $self = bless {
		cls=>{},
		name => $name,	# имя филдсета
		tab => $tab,	# имя таблицы в базе
		field=>{},		# филды имя=>филд
		fieldset=>[],	# порядок филдов
		index=>{},		# индексы
		indexref=>{},	# индексы-ссылки
		engine => undef,
		options => [],	# дополнительные опции таблицы
		data => [],
		testdata => []
	}, $cls;
	
	my $modelClass = "R::Row::" . ucfirst $name;
	$meta->{cls}{$modelClass} = $self;
	
	my $Prop = ucfirst $name;
	
	# создаём роусет
	no strict "refs";
	unshift @{"R::Rowset::${Prop}::ISA"}, "R::Model::Rowset";
	use strict "refs";
	
	eval "sub R::Rowset::${Prop}::model {'$name'}
	sub R::Rowset::${Prop}::modelClass {'$modelClass'}";
	die $@ if $@;
	
	$self->pk($pk_type)->autoincrement;

	# создаём метод модели и подгружаем класс модели
	my $row = $::app->model->$name(undef);

	$row->can("setup")->($self);
	
	$self
}

# добавляет вычислимый столбец
sub compute {
	my ($self, $name) = @_;
	# оборачиваем в _pp_compute
	my $model = $self->{name};
	my $row = $::app->model->$model(undef);
	my $code = $row->can($name);
	die "Нет метода $model.$name" unless $code;
	my $field = $self->field($self, $name);
	$field->{compute} = 1;
	$R::Model::Row::compute{ref $row}{$name} = $code;
	$field->add_method("_compute");
	$self
}

# добавляет и возвращает филд
sub field {
	my ($self, $name, $type) = @_;
	my $field = R::Model::Field->new($self, $name, $type);
	push @{$self->{fieldset}}, $field;
	$self->{field}{$name} = $field;
	$field
}

# возвращает последний филд
sub last {
	my ($self) = @_;
	my $x = $self->{fieldset};
	$x->[$#$x];
}

# добавляет поле
sub col {
	my ($self, $name, $type) = @_;
	$self->field($name, $type)->add_method;
	$self
}

# добавляет поле-ссылку
sub ref {
	my ($self, $name, $to_model, $fk_name) = @_;
	$to_model ||= $name;
	my $field = $self->field($name, '');
	$field->{col} .= '_id';
	$field->{null} = 1;
	
	$field->add_method("_ref");
	
	#$field->add_method($name . "_id");
	$field->{ref} = $to_model;
	
	my $fk = $::app->modelMetafieldset->fieldset($to_model)->back_ref($field);
	
	$fk_name ||= "fk_" . $field->tab . "__" . $field->col . "__to__" . $fk->tab . "__" . $fk->col;
	
	$self->{indexref}{$field->name} = R::Model::IndexRef->new($fk_name, $field, $fk);
	
	$self
}

# объявляет обратную ссылку
sub back_ref {
	my ($self, $field) = @_;
	my $id = $self->{field}{id};
	
	$field->{type} = $id->{type};
	
	my $ref_name = $field->name eq $self->{name}? $field->model . "s": $field->name . ucfirst($field->model) . "s";
	
	my $back = $self->field($ref_name);
	$back->{compute} = 1;
	$back->{ref} = $field;
	$back->add_method("_back_ref");
	
	$id
}

# ссылка многие-ко-многим
sub m2m {
	my ($self, $name, $to_model) = @_;
	
	my $to_fieldset = $::app->modelMetafieldset->fieldset($to_model);
	
	my $m2m_model = $name . join "", sort ucfirst($self->{name}), ucfirst($to_fieldset->{name});
	
	my $fieldset = $::app->modelMetafieldset->fieldset($m2m_model)->
	pk(undef)->
	ref($self->{name})->
	ref($to_model);
	
	my $ref = $self->field($name . ucfirst($to_fieldset->{name}) . "s");
	$ref->{compute} = 1;
	$ref->add_method("_m2m");
	
	my $ref2 = $to_fieldset->field($name . ucfirst($self->{name}) . "s");
	$ref2->{compute} = 1;
	$ref2->add_method("_m2m");
	
	$self
}

# добавляет валидатор
sub check {
	my ($self, $name, @args) = @_;
	push @{$self->last->{check}}, {name=>$name, args=>[@args]};
	$self
}


# добавляет или удаляет pk
sub pk {
	my ($self, $type) = @_;
	
	delete $self->{field}{'id'};
	shift @{$self->{fieldset}};
	
	if(defined $type) {
		my $pk = $self->field('id', $type);
		$pk->{type} = $type;
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
sub require {
	$_[0]->last->{null} = 0;
	$_[0]
}


# добавляет значение по умолчанию к последнему филду
sub default {
	my ($self, $default, $raw) = @_;
	$self->last->{default} = $raw? $default: $::app->connect->quote($default);
	$self
}

# добавляет комментарий к последнему филду
sub comment {
	my ($self, $comment) = @_;
	$self->last->{comment} = $comment;
	$self
}

# синонимы
sub remark { goto &comment }
sub rem { goto &comment }

# добавляет индекс
sub _add_index {
	my ($keyword, $self, $idx, $name) = @_;
	my @idx = split /\s*,\s*/, $idx // $self->last;
	$name ||= "idx_" . join "__", @idx;
	$self->{indexes}{$name} = R::Model::Index->new($keyword, [@idx], $name, $self->{tab});
	$self
}

sub index { unshift @_, 'INDEX'; goto &_add_index; }
sub unique { unshift @_, 'UNIQUE'; goto &_add_index; }

# добавляют опции таблицы
sub engine { $_[0]->{engine} = $_[1]; $_[0] }
sub options { push @{$_[0]->{options}}, $_[1]; $_[0] }

# в новую таблицу добавляются обязательные данные
sub data {
	my ($self, @data) = @_;
	push @{$self->{data}}, @data;
	$self
}


# в новую таблицу добавляются тестовые данные
sub testdata {
	my ($self, @data) = @_;
	push @{$self->{testdata}}, @data;
	$self
}


# синхронизация таблицы
sub sync {
	my ($self) = @_;
	
	return $self if $self->{sync};
	$self->{sync} = 1;
	
	my $c = $::app->connect;
	my $tab = $self->{tab};
	my $info = $c->info->{$tab};

	while(my ($name, $indexref) = each %{$self->{indexref}}) {
		$indexref->fk->fieldset->sync;
	}
	
	if(!$info) {
		my $sql = $self->create_table;
		main::msg $sql;
		$c->dbh->do($sql);
	} else {
		my %is;
		for my $field (@{$self->{fieldset}}) {
			if(!$field->compute) {
				$field->sync;
				$is{$field->{col}} = 1;
			}
		}
		
		while(my ($k, $v) = each %$info) {
			$c->dbh->do(main::msg R::Model::Field::drop(undef, $tab, $k)) if !$is{$k};
		}
		
		while(my ($name, $index) = each %{$self->{index}}) {
			$index->sync;
		}
		
		while(my ($name, $indexref) = each %{$self->{indexref}}) {
			$indexref->sync;
		}
	}
	
	$self;
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
	
	while(my ($key, $idx) = each %{$self->{index}}) {
		push @col, $idx->sql;
	}
	
	while(my ($key, $idx) = each %{$self->{indexref}}) {
		push @col, $idx->sql;
	}
	
	push @sql, join ",\n", @col;
	
	push @sql, "\n) ENGINE=", ($self->{engine} || $engine), (@{$self->{options}}? " " . join(" ", @{$self->{options}}): ());
	join "", @sql;
}

# переименовывает таблицу
sub rename {
	my ($self, $tab) = @_;
	my $c = $::app->connect;
	join "", "ALTER TABLE ", $c->word($self->{tab}), " RENAME ", $c->word($tab);
}

1;