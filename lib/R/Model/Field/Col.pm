package R::Model::Field::Col;
# поле таблицы базы данных

use base R::Model::Field;

use strict;
use warnings;


Utils::has_const(qw/tab col type null pk autoincrement/);

# конструктор
sub new {
	my ($cls, $fieldset, $name, $type) = @_;
	
	my $meta = $::app->{modelMetafieldset};
	my $col = $meta->word($name);
	
	my $self = $cls->SUPER::new($fieldset, $name);
	
	%$self = (
		%$self,
		tab=>$fieldset->{tab},
		col=>$col,
		type=>$type,
		null=>0,
		compute=>0,
	);
	
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
	my ($self, $after, $num) = @_;
	my $c = $::app->connect;
	my $info = $c->info->{$self->{tab}}{$self->{col}};
	my $sql;
	
	if(!$info) {
		my $sql = $self->alter($after);
		main::msg $sql;
		$c->dbh->do($sql);
	} else {
		if(my $what = $self->not_eq_info($num)) {
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

# дефолтные типы
our %column_type = (
	"int(11)" => "int",
	"tinyint(4)" => "tinyint",
	"int(10) unsigned" => "int unsigned"
);

# сравнивает колумн с info
sub not_eq_info {
	my ($self, $num) = @_;
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
	return "ordinal_position $num != $sql->{ordinal_position}" if $sql->{ordinal_position} != $num;
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


# свойство филда - устанавливается в класс row
sub row {
	my ($self, $bean, $val) = @_;
	if(@_>2) {
		#main::msg 'set', ref($bean), $name, $val;
		$bean->{save}{$self->{name}} = $val;
		$bean
	}
	else {
		#main::msg 'get', ref($bean), $name;
		$bean->save;
		my $c = $::app->connect;
		$c->query($self->{tab}, [$self->{col}], {id=>$bean->{id}})
	}
}

# устанавливается в класс rowset-а
sub rowset {
	my ($self, $bean, $val) = @_;
	$bean->view($self->{name});
}


1;