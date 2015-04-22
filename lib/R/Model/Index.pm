package R::Model::Index;
# описывает индекс базы данных

use strict;
use warnings;

Utils::has(qw/idx name type tab fieldset/);

# конструктор
sub new {
	my ($cls, $type, $idx, $name, $fieldset) = @_;
	bless {type=>$type, idx=>$idx, name=>$name, tab=>$fieldset->{tab}, fieldset=>$fieldset}, $cls;
}

# перечисление столбцов
sub index {
	my ($self) = @_;
	my $c = $::app->connect;
	my $field = $self->{fieldset}{field};
	"(" . join(", ", map {$c->word($field->{$_}{col})} @{$self->{idx}}) . ")"
}

# для тела таблицы
sub sql {
	my ($self) = @_;
	my $c = $::app->connect;
	"$self->{type} ". $c->word($self->{name}) . $self->index
}

# изменение ключа
sub alter {
	my ($self) = @_;
	my $c = $::app->connect;
	"ALTER TABLE " . $c->word($self->tab) . " ADD " . $self->sql
}

# удаление ключа
sub drop {
	my ($self, $tab, $name) = @_;
	my $c = $::app->connect;
	"ALTER TABLE " . $c->word($tab // $self->tab) . " DROP INDEX " . $c->word($name // $self->name);
}

# синхронизация с базой
sub sync {
	my ($self) = @_;
	my $c = $::app->connect;
	my $dbh = $c->dbh;
	my $info = $c->get_index_info;
	#::msg $self->tab, $self->name, $info;
	$info = $info->{$self->tab}{$self->name};
	if(!$info) {
		$dbh->do(main::msg $self->alter);
	} else {
		my $replace = 0;
		if(@$info != @{$self->{idx}}) { ::msg "1111"; $replace = 1; }
		else {
			my $i=0;
			my $field = $self->{fieldset}{field};
			for my $idx (@$info) {
				$replace = 1, last if $idx->{col} ne $field->{$self->{idx}[$i++]}{col};
			}
		}
		
		if($replace) {
			$dbh->do(main::msg $self->drop);
			$dbh->do(main::msg $self->alter);
		}
	}
	$self
}


package R::Model::IndexRef;
# внешний ключ

our @ISA = qw/R::Model::Index/;

Utils::has(qw/fk keys/);

our $on_delete = " ON DELETE RESTRICT";
our $on_update = " ON UPDATE RESTRICT";

# конструктор
sub new {
	my ($cls, $name, $field, $fk) = @_;
	bless {name=>$name, idx=>[$field->col], tab=>$field->tab, field=>$field, fk=>$fk, keys=>[$fk->col]}, $cls;
}

# для таблицы
sub sql {
	my ($self) = @_;
	my $c = $::app->connect;
	"CONSTRAINT " . $c->word($self->name) . " FOREIGN KEY ($self->{idx}[0]) REFERENCES " . $c->word($self->fk->tab) . " (" . join(", ", map {$c->word($_)} @{$self->keys}) . ")" . $on_delete . $on_update;
}

# удаление из базы
sub drop {
	my ($self, $tab, $name) = @_;
	my $c = $::app->connect;
	"ALTER TABLE " . $c->word($tab // $self->tab) . " DROP FOREIGN KEY " . $c->word($name // $self->name);
}

# синхронизация с базой
sub sync {
	my ($self) = @_;
	my $c = $::app->connect;
	my $dbh = $c->dbh;
	my $info = $c->fk_info;
	$info = $info->{$self->tab}{$self->name};
	if(!$info) {
		$dbh->do(main::msg $self->alter);
	} elsif(
		$info->{tab} ne $self->{tab} ||
		$info->{col} ne $self->{idx}[0] ||
		$info->{ref_tab} ne $self->{fk}{tab} ||
		$info->{ref_col} ne $self->{keys}[0]
	) {
		$dbh->do(main::msg $self->drop);
		$dbh->do(main::msg $self->alter);
	}
	$self
}
1;