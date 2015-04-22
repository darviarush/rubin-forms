package R::Model::Fieldset;
# таблица - менеджер полей, дополнительных опций таблицы базы и ключей

use strict;
use warnings;

require R::Model::Rowset;
require R::Model::Index;
require R::Model::Field::Col;
require R::Model::Field::Ref;
require R::Model::Field::Back;
require R::Model::Field::M2m;
require R::Model::Field::Compute;


our $pk_type = "int unsigned";
our $engine = "INNODB";

# конструктор
sub new {
	my ($cls, $name) = @_;
	
	my $meta = $::app->modelMetafieldset;
	
	my $tab = $meta->word($name);
	
	my $self = bless {
		name => $name,	# имя филдсета
		tab => $tab,	# имя таблицы в базе
		field=>{},		# филды имя=>филд
		fieldset=>[],	# порядок филдов
		pk=>undef,		# primary key
		indexes=>{},		# индексы
		indexref=>{},	# индексы-ссылки
		engine => undef,
		options => [],	# дополнительные опции таблицы
		data => [],
		testdata => []
	}, $cls;
	
	my $Prop = ucfirst $name;
	
	# создаём роусет
	{no strict "refs";
	unshift @{"R::Rowset::${Prop}::ISA"}, "R::Model::Rowset";
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

	# создаём метод модели и подгружаем класс модели
	my $row = $::app->model->$name(undef);

	$self->pk($pk_type)->autoincrement;
	$row->can("setup")->($self);
	
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
	R::Model::Field::Compute->new($name);
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
	my ($self, $name, $to_model, $fk_name) = @_;	
	R::Model::Field::Ref->new($self, $name, $to_model, $fk_name);
	$self
}

# ссылка многие-ко-многим
sub m2m {
	my ($self, $name, $to_model, $m2m_model) = @_;
	
	my $to_fieldset = $::app->modelMetafieldset->fieldset($to_model);
	
	$m2m_model //= $name . join "", sort ucfirst($self->{name}), ucfirst($to_fieldset->{name});
	
	my $m2m_fieldset = $::app->modelMetafieldset->fieldset($m2m_model)->
	pk(undef)->
	ref($self->{name})->
	ref($to_model)->
	unique("$self->{name}, $to_model");
	
	my $ref_from = $m2m_fieldset->{field}{$self->{name}};
	my $ref_to = $m2m_fieldset->{field}{$to_model};
	
	my $ref1 = R::Model::Field::M2m->new($name, $ref_from, $ref_to);
	my $ref2 = R::Model::Field::M2m->new($name, $ref_to, $ref_from);
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
	$pk->delete if $pk;
	
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

sub raw_default {
	my ($self, $default) = @_;
	$self->default($default, 1);
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
	my @idx = split /\s*,\s*/, $idx // $self->last->{name};
	$name ||= "idx_" . join "__", @idx;
	$self->{indexes}{$name} = R::Model::Index->new($keyword, [@idx], $name, $self);
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
		my $num = 1;
		my $after = 1;
		for my $field (@{$self->{fieldset}}) {
			if(!$field->compute) {
				$field->sync($after, $num++);
				$is{$after = $field->{col}} = 1;
			}
		}
		
		while(my ($k, $v) = each %$info) {
			$c->dbh->do(main::msg R::Model::Field::Col::drop(undef, $tab, $k)) if !$is{$k};
		}
		
		%is = (PRIMARY=>1);
		while(my ($name, $index) = each %{$self->{indexes}}) {
			$index->sync;
			$is{$index->{name}} = 1;
		}
		
		my $idx_info = $c->index_info->{$tab} // {};
		while(my ($k, $v) = each %$idx_info) {
			$c->dbh->do(main::msg R::Model::Index::drop(undef, $tab, $k)) if !$is{$k};
		}
		
		%is = ();
		while(my ($name, $indexref) = each %{$self->{indexref}}) {
			$indexref->sync;
			$is{$indexref->{name}} = 1;
		}
		
		my $fk_info = $c->fk_info->{$tab} // {};
		while(my ($k, $v) = each %$fk_info) {
			$c->dbh->do(main::msg R::Model::IndexRef::drop(undef, $tab, $k)) if !$is{$k};
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
	
	while(my ($key, $idx) = each %{$self->{indexes}}) {
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