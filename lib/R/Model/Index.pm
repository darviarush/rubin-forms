package R::Model::Index;
# описывает индекс базы данных

Utils::has(qw/idx name type tab/);

# конструктор
sub new {
	my ($cls, $type, $idx, $name, $tab) = @_;
	bless {type=>$type, idx=>$idx, name=>$name, tab=>$tab}, $cls;
}

# перечисление столбцов
sub index {
	my ($self) = @_;
	"(" . join(", ", map {$c->word($_)} @{$self->{idx}}) . ")"
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
	my ($self) = @_;
	my $c = $::app->connect;
	"ALTER TABLE " . $c->word($self->tab) . " DROP INDEX " . $c->word($self->name);
}

# синхронизация с базой
sub sync {
	my ($self) = @_;
	my $c = $::app->connect;
	my $dbh = $c->dbh;
	my $info = $c->index_info;
	$info = $info->{$self->tab}{$self->name};
	if(!$info) {
		$dbh->do(main::msg $self->alter);
	} else {
		my $replace = 0;
		if(@{$info->{idx}} != @{$self->{idx}}) { $replace = 1; }
		else {
			my $i = 0;
			for my $idx (@{$info->{idx}}) {
				$replace = 1, last if $idx ne $self->{idx}[$i];
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

Utils::has(qw/fk keys/);

use base R::Model::Index;


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
	"CONSTRAINT " . $c->word($self->name) . " FOREIGN KEY " . $self->index . " REFERENCES " . $c->word($self->fk->tab) . " (" . join(", ", map {$c->word($_)} @{$self->keys}) . ")" . $on_delete . $on_update;
}

# удаление из базы
sub drop {
	my ($self) = @_;
	my $c = $::app->connect;
	"ALTER TABLE " . $c->word($self->tab) . " DROP FOREIGN KEY " . $c->word($self->name);
}


1;