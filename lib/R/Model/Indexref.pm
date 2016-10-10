package R::Model::Indexref;
# внешний ключ

use base qw/R::Model::Index/;

use common::sense;
use R::App;

has(qw/fk field/);

our $on_delete = " ON DELETE RESTRICT";
our $on_update = " ON UPDATE RESTRICT";

# конструктор
sub new {
	my ($cls, $name, $field, $fk) = @_;
	
	bless {
		name=>$name,
		field=>$field,
		fk=>$fk,
	}, $cls;
}

# возвращает таблицу
sub tab {
	my ($self) = @_;
	die "попытка установить свойство \"только для чтения\"" if @_>1;
	$self->field->tab
}

# возвращает fieldset
sub fieldset {
	my ($self) = @_;
	die "попытка установить свойство \"только для чтения\"" if @_>1;
	$self->field->fieldset
}

# возвращает connect
sub connect {
	my ($self) = @_;
	$self->fieldset->connect
}

# для таблицы
sub sql {
	my ($self) = @_;
	my $c = $self->connect;
	"CONSTRAINT " . $c->word($self->name) . " FOREIGN KEY ($self->{field}{col}) REFERENCES " . $c->word($self->fk->tab) . " (" . join(", ", map {$c->word($_)} $self->{fk}{col}) . ")" . $on_delete . $on_update;
}

# удаление из базы
sub drop {
	my ($self, $tab, $name) = @_;
	my $c = $self->connect;
	join "", "ALTER TABLE ", $c->word($tab // $self->tab), " DROP FOREIGN KEY ", ($c->{options}{fk_drop_exists}? "IF EXISTS ":()), $c->word($name // $self->name);
}

#our %REF_ENGINE = set(qw/INNODB XTRADB/);

# синхронизация с базой
sub sync {
	my ($self) = @_;
	
	#unless exists $REF_ENGINE{};
	
	my $sql_main = $self->fieldset->meta->{sql_main};
	my $sql_before = $self->fieldset->meta->{sql_before};
	my $sql_after = $self->fieldset->meta->{sql_after};
	my $c = $self->field->connect;
	my $info = $c->fk_info;
	$info = $info->{$self->tab}{$self->name};
	
	if(!$info) {
		push @$sql_after, $self->alter;
	} elsif(
		$info->{tab} ne $self->tab ||
		$info->{col} ne $self->{field}{col} ||
		$info->{ref_tab} ne $self->{fk}->tab ||
		$info->{ref_col} ne $self->{fk}{col}
	) {
		push @$sql_before, $self->drop;
		push @$sql_after, $self->alter;
	}
	$self
}