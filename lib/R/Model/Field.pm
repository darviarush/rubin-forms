package R::Model::Field;
# поле таблицы

Utils::has(qw/tab col model name type fieldset/);

# конструктор
sub new {
	my ($cls, $fieldset, $name, $type) = @_;
	my $col = $name;
	$col =~ s/[A-Z]/ "_" . lc $& /ge;
	
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
	my ($self, $name) = @_;
	no strict "refs";
	$name ||= $self->{name};
	my $model = $self->{model};
	my $fs = ucfirst $model;
	my $SUB = "R::Rows::${fs}::$name";
	
	unless(*{$SUB}{CODE}) {
		eval($self->{ref}?
		"sub $SUB {
			my (\$self, \$val) = \@_;
			if(\@_>1) {
				if(ref \$val) {
					my \$bean = \$::app->model->$name(\$val);
					\$self->${name}_id(\$bean->{id});
				} else {
					\$self->${name}_id(\$val);
				}
			}
			else { \$::app->model->$name(\$self->${name}_id) }
		}":
		"sub $SUB {
			my (\$self, \$val) = \@_;
			if(\@_>1) {
				\$::app->auth->save('$self->{tab}', {'$self->{col}' => \$val, id=>\$self->{id}});
				\$self->{id} //= \$::app->connect->{last_id};
				\$self
			}
			else {
				\$::app->auth->query('$self->{tab}', ['$self->{col}'], {id=>\$self->{id}})
			}
		}");
		die "$SUB: ".($@ // $!) if $@ // $!;
	}
	use strict "refs";
}


# возвращает представление филда в sql
sub sql {
	my ($self) = @_;
	my $sql = $::app->connect->word($self->col) . " $self->{type}";
	$sql .= " NOT NULL" if !$self->{null} && !$self->{pk};
	$sql .= " PRIMARY KEY" if $self->{pk};
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
	($rename == 1? "MODIFY": $rename? "CHANGE": "ADD"), " COLUMN ", ($rename==1 || $rename==0? (): $c->word($rename) . " "), $self->sql, ($after == 1? " FIRST": $after? " AFTER " . $c->word($after): "");
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
		#main::msg $self->alter_info;
		#main::msg $self->sql;
		if($self->alter_info ne $self->sql) {
			$sql = $self->alter(undef, 1);
			main::msg $sql;
			$c->dbh->do($sql);
		}
	}
	$self
}

# возвращает колумн из info
sub alter_info {
	my ($self) = @_;
	my $sql = $::app->connect->info->{$self->{tab}}{$self->{col}};
	($sql? (($column_type{$sql->{column_type}} || $sql->{column_type} || "").
	($sql->{is_nullable} eq "YES" || $sql->{column_key} =~ /PRI/? "": " NOT NULL").
	(defined($sql->{column_default})? " DEFAULT $sql->{column_default}": "").
	($sql->{column_key} =~ /PRI/? " PRIMARY KEY": "").
	($sql->{extra} ne ""? uc " $sql->{extra}": "")): "")
}

# это филд базы
sub compute { 0 }



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