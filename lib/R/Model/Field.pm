package R::Model::Field;
# поле таблицы

use strict;
use warnings;

Utils::has(qw/tab col model name type fieldset/);

# дефолтные типы
our %column_type = (
	"int(11)" => "int",
	"tinyint(4)" => "tinyint",
	"int(10) unsigned" => "int unsigned"
);


# конструктор
sub new {
	my ($cls, $fieldset, $name, $type) = @_;
	my $meta = $::app->{modelMetafieldset};
	my $col = $meta->word($name);
	
	bless {
		cls=>$cls,
		tab=>$fieldset->{tab},
		col=>$col,
		model=>$fieldset->{name},
		name=>$name,
		type=>$type,
		fieldset=>$fieldset
	}, $cls;
}

# создаёт метод в модели, если его ещё нет
sub add_method {
	my ($self, $prop, $alter) = @_;
	my $name = $self->{name};
	my $model = $self->{model};
	my $Prop = ucfirst $model;
	my $SUB = "R::Rows::${Prop}::$name";
	
	$prop //= "";
	
	main::msg $SUB;
	
	my $ref = $alter // $name;
	
	eval("sub $SUB {
		unshift \@_, '$ref';
		goto &R::Model::Row::_pp$prop;
	}");
	die "$SUB: ".($@ // $!) if $@ // $!;
	
	$self
}


# возвращает представление филда в sql
sub sql {
	my ($self, $alter) = @_;
	my $sql = $::app->connect->word($self->col) . " $self->{type}";
	$sql .= " NOT NULL" if $alter && !$self->{null} || !$alter && !$self->{null} && !$self->{pk};
	$sql .= " PRIMARY KEY" if !$alter && $self->{pk};
	$sql .= " AUTO_INCREMENT" if $self->{autoincrement};
	$sql .= " DEFAULT $self->{default}" if $self->{default};
	$sql
}

# возвращает alter column
# $after - после какого столбца
# $rename - переименовать
sub alter {
	my ($self, $after, $rename) = @_;
	my $c = $::app->connect;
	
	$after //= 0;
	$rename //= 0;
	
	join "", "ALTER TABLE ", $c->word($self->{tab}), " ",
	($rename == 1? "MODIFY": $rename? "CHANGE": "ADD"), " COLUMN ", ($rename==1 || $rename==0? (): $c->word($rename) . " "), $self->sql(1), ($after == 1? " FIRST": $after? " AFTER " . $c->word($after): "");
}

# код для удаления столбца
sub drop {
	my ($self, $tab, $col) = @_;
	my $c = $::app->connect;
	"ALTER TABLE " . $c->word($tab // $self->tab) . " DROP COLUMN " . $c->word($col // $self->col);
}

# синхронизирует филд с базой
sub sync {
	my ($self) = @_;
	my $c = $::app->connect;
	my $info = $c->info->{$self->{tab}}{$self->{col}};
	my $sql;
	
	if(!$info) {
		my $sql = $self->alter;
		main::msg $sql;
		$c->dbh->do($sql);
	} else {
		if(my $what = $self->not_eq_info) {
			main::msg ':empty', '1) ', $self->alter_info;
			main::msg ':empty', '2) ', $self->sql;
			main::msg($what);
			$sql = $self->alter(undef, 1);
			main::msg $sql;
			$c->dbh->do($sql);
		}
	}
	$self
}

# сравнивает колумн с info
sub not_eq_info {
	my ($self) = @_;
	my $sql = $::app->connect->info->{$self->{tab}}{$self->{col}};
	return "(not in tab)" unless $sql;
	my $type = $column_type{$sql->{column_type}} // "";
	return "$self->{type} ne $sql->{column_type} || $type" if $self->{type} ne $sql->{column_type} && $self->{type} ne $type;
	my $null = $sql->{is_nullable} eq "YES";
	return "null and ne null" if $self->{null} && !$null;
	return "ne null and null" if !$self->{null} && $null;
	my $def1 = $self->{default} // "";
	my $def2 = $sql->{column_default} // "";
	return "DEFAULT $def1 ne $def2" if $def1 ne $def2;
	return "AUTO_INCREMENT and ne AUTO_INCREMENT" if $self->{autoincrement} && !$sql->{extra};
	return "ne AUTO_INCREMENT and AUTO_INCREMENT" if !$self->{autoincrement} && $sql->{extra};
}

# возвращает колумн из info
sub alter_info {
	my ($self) = @_;
	my $sql = $::app->connect->info->{$self->{tab}}{$self->{col}};
	($sql? $self->{col} . " " . (($column_type{$sql->{column_type}} || $sql->{column_type} || "").
	($sql->{is_nullable} eq "YES" || $sql->{column_key} =~ /PRI/? "": " NOT NULL").
	(defined($sql->{column_default})? " DEFAULT $sql->{column_default}": "").
	($sql->{column_key} =~ /PRI/? " PRIMARY KEY": "").
	($sql->{extra} ne ""? uc " $sql->{extra}": "")): "")
}

# это филд базы
sub compute { $_[0]->{compute} }



package R::Model::FieldCompute;

Utils::has(qw/fieldset name model/);

# конструктор
sub new {
	my ($cls, $fieldset, $name) = @_;
	bless {fieldset=>$fieldset, name=>$name, model=>$fieldset->{name}}, $cls;
}

# это вычисляемый филд
sub compute { 1 }

1;