package R::Model::Index;
# описывает индекс базы данных

use common::sense;
use R::App;


has(qw/idx name type fieldset/);

# конструктор
sub new {
	my ($cls, $type, $idx, $name, $fieldset) = @_;
	bless {type=>$type, idx=>$idx, name=>$name, fieldset=>$fieldset}, $cls;
}

# возвращает таблицу
sub tab {
	my ($self) = @_;
	die "попытка установить свойство \"только для чтения\"" if @_>1;
	$self->fieldset->tab
}

# возвращает коннект
sub connect {
	my ($self) = @_;
	$self->fieldset->connect
}

# перечисление столбцов
sub index {
	my ($self) = @_;
	my $c = $self->connect;
	my $field = $self->{fieldset}{field};
	"(" . join(", ", map {$c->word($field->{$_}{col})} @{$self->{idx}}) . ")"
}

# для тела таблицы
sub sql {
	my ($self) = @_;
	my $c = $self->connect;
	$self->{type} eq "PRIMARY KEY"? "PRIMARY KEY" . $self->index:
	"$self->{type} ". $c->word($self->{name}) . $self->index
}

# изменение ключа
sub alter {
	my ($self) = @_;
	my $c = $self->connect;
	"ALTER TABLE " . $c->word($self->tab) . " ADD " . $self->sql
}

# удаление ключа
sub drop {
	my ($self, $tab, $name) = @_;
	my $c = $self->connect;
	"ALTER TABLE " . $c->word($tab // $self->tab) . " DROP INDEX " . $c->word($name // $self->name);
}

# синхронизация с базой
sub sync {
	my ($self) = @_;
	my $c = $self->connect;
	my $info = $c->index_info;
	$info = $info->{$self->tab}{$self->name};
	
	my $sql_main = $self->fieldset->meta->{sql_main};
	
	if(!$info) {
		push @$sql_main, $self->alter;
	} else {
		my $replace = undef;
		if(@$info != @{$self->{idx}}) { $replace = "/* количество полей не совпадает " . @$info . " !=  " . @{$self->{idx}} . " */"; }
		else {
			my $i=0;
			my $field = $self->{fieldset}{field};
			for my $idx (@$info) {
				$replace = "/* имя поля не совпадает $idx->{col} ne " . $field->{$self->{idx}[$i]}{col} . " */", last if $idx->{col} ne $field->{$self->{idx}[$i]}{col};
				$i++;
			}
		}
		
		if($replace) {
			push @$sql_main, "$replace\nSET FOREIGN_KEY_CHECKS = 0";
			push @$sql_main, $self->drop;
			push @$sql_main, $self->alter;
			push @$sql_main, "SET FOREIGN_KEY_CHECKS = 1";
		}
	}
	$self
}

1;