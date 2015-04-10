package R::Model::Fieldset;
# таблица - менеджер полей, дополнительных опций таблицы базы и ключей

use strict;
use warnings;

use R::Model::Field;

#our $pk_type = 'int primary key AUTO_INCREMENT';
our $pk_type = "int unsigned";
our $engine = "INNODB";

# конструктор
sub new {
	my ($cls, $name) = @_;
	
	my $tab = $name;
	$tab =~ s![A-Z]!"_" . lcfirst $&!ge;
	my $self = bless {
		cls=>$cls,
		name => $name,	# имя филдсета
		tab => $tab,	# имя таблицы в базе
		field=>{},		# филды имя=>филд
		fieldset=>[],	# порядок филдов
		indexes=>[],	# индексы
		engine => undef,
		options => [],	# дополнительные опции таблицы
		data => [],
		testdata => []
	}, $cls;
	
	$self->pk($pk_type)->autoincrement;
	
	my $row = $::app->model->$name;
	
	$row->can("setup")->($self);

	$self
}


# добавляет вычислимый столбец
sub compute {
	my ($self, $name) = @_;
	my $field = R::Model::FieldCompute->new($self, $name);
	push @{$self->{fieldset}}, $field;
	$self->{field}{$name} = $field;
	$self
}

# добавляет и возвращает филд
sub field {
	my ($self, $name, $type) = @_;
	my $field = R::Model::Field->new($self, $name, $type);
	push @{$self->{fieldset}}, $field;
	$self->{field}{$name} = $field;
	$field->add_method;
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
	$self->field($name, $type);
	$self
}

# добавляет поле-ссылку
sub ref {
	my ($self, $name, $to_model) = @_;
	my $field = $self->field($name . "_id", '');
	$field->{null} = 1;
	
	
	$to_model ||= $name;
	
	$field->add_method($name . "_id");
	
	$field->{ref} = $to_model;
	
	$field->add_method;
	
	#$::app->modelMetafieldset->fieldset($to_model)->back_ref($field, $self);
	
	$self
}

# объявляет обратную ссылку
sub back_ref {
	my ($self, $field) = @_;
	#$field->{type} = ;
}

# добавляет или удаляет pk
sub pk {
	my ($self, $type) = @_;
	if(defined $type) {
		my $pk = $self->field('id', $type);
		$pk->{type} = $type;
		$pk->{autoincrement} = 0;
	} elsif(exists $self->{field}{'id'}) {
		delete $self->{field}{'id'};
		shift @{$self->{fieldset}};
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

# добавляет индекс
sub _add_index {
	my ($keyword, $self, $idx) = @_;
	my $connect = $::app->connect;
	my @idx = split /\s*,\s*/, $idx // $self->last;
	$_ = $connect->SQL_WORD($_) for @idx;
	push @{$self->{indexes}}, "$keyword(" . join(",", @idx) . ")";
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


# синхронизация
sub sync {
	my ($self) = @_;
	
	my $c = $::app->connect;
	my $tab = $self->{tab};
	my $info = $c->info->{$tab};

	if(!$info) {
		$c->dbh->do($self->create_table);
	} else {
		my %is;
		for my $field (@{$self->{fieldset}}) {
			$field->sync;
			$is{$field->{col}} = 1;
		}
		
		while(my ($k, $v) = each %$info) {
			$c->dbh->do("ALTER TABLE " . $c->SQL_WORD($tab) . " DROP COLUMN " . $c->SQL_WORD($k)) if !$is{$k};
		}
	}
	
}

# возвращает create table
sub create_table {
	my ($self) = @_;
	my @sql = ("CREATE TABLE ", $::app->connect->SQL_WORD($self->{tab}), " (\n");
	for my $field (@{$self->{fieldset}}) {
		push @sql, $field->sql, ",\n" unless $field->compute;
	}
	
	push @sql, join(", ", @{$self->{indexes}}), "\n";
	
	push @sql, ") ENGINE=", ($self->{engine} || $engine), (@{$self->{options}}? " " . join(" ", @{$self->{options}}): ());
	join "", @sql;
}

# переименовывает таблицу
sub rename {
	my ($self, $tab) = @_;
	my $c = $::app->connect;
	join "", "ALTER TABLE ", $c->SQL_WORD($self->{tab}), " RENAME ", $c->SQL_WORD($tab);
}

1;