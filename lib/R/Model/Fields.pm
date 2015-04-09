package R::Model::Fields;
# менеджер полей, дополнительных опций таблицы базы и ключей

#our $pk_type = 'int primary key AUTO_INCREMENT';

# конструктор
sub new {
	my ($cls, $app) = @_;
	bless {
		cls=>$cls,
		app=>$app,
		field=>{},
		fieldset=>{},
		indexes=>[],
		engine => undef,
		options => [],
		insert => [],
		testdata => []
	}, $cls;
}

# добавляет и возвращает филд
sub field {
	my ($self, $name, $type) = @_;
	my $field = R::Model::Field->new($self->{app}, $self->{tab}, $name, $type);
	push @{$self->{fieldset}{$self->{tab}}}, $field;
	$self->{field}{$self->{tab}}{$name} = $field;
	$field
}

# возвращает последний филд
sub last {
	my ($self) = @_;
	my $x = $self->{fieldset}{$self->{tab}};
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
	my ($self, $name, $to_tab) = @_;
	my $field = $self->field($name . "_id", $type);
	my $field = R::Model::Field($self->{app}, $name . "_id", '');
	my ($tab, $fld) = split /\s*\.\s*/, $to_tab || $name;
	my $connect = $self->{app}->connect;
	$field->{ref} = $tab;
	$field->{ref_to} = join ".", $connect->SQL_WORD($name), $connect->SQL_WORD($fld || "id");
	$self
}

# добавляет pk
sub pk {
	my ($self, $type) = @_;
	$self->{no_pk} = 1;
	return if not defined $type;
	my $field = $self->field('id', $type);
	$field->{pk} = 1;
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

# добавляет значение по умолчанию к последнему филду
sub default {
	my ($self, $default, $raw) = @_;
	$self->last->{default} = $raw? $default: $self->{app}->connect->quote($default);
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
	my $connect = $self->{app}->connect;
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
sub insert {
	my ($self, @data) = @_;
	push @{$self->{insert}}, @data;
	$self
}


# в новую таблицу добавляются тестовые данные
sub testdata {
	my ($self, @data) = @_;
	push @{$self->{testdata}}, @data;
	$self
}


# устанавливает таблицу для всех полей и ключи
sub postsetup {
	my ($self, $tab) = @_;
	my $fieldset = $self->{fieldset}{$self->tab};
	$self->pk($pk_type)->autoincrement, unshift @$fieldset, pop @$fieldset unless $self->{no_pk};
	$self
}

# синхронизация
sub sync {
	
	
	
	
}

1;