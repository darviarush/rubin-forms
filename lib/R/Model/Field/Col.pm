package R::Model::Field::Col;
# поле таблицы базы данных

use base R::Model::Field;

use common::sense;
use R::App;


# counter - установлено, если поле является счётчиком
has qw/col type null pk autoincrement real_type extra counter/;

# конструктор
sub new {
	my ($cls, $fieldset, $name, $type, $col, $next) = @_;
	
	my $dop_param;
	$dop_param = $col, $col = $next if ref $col;
	
	my $meta = $fieldset->meta;
	$col //= $meta->connect->lc($name);
	
	my $self = $cls->SUPER::new($fieldset, $name);
	
	%$self = (
		%$self,
		col=>$col,
		class=>undef,				# заполняется register_class, если есть
		dop_param => $dop_param,	# для enum и подобных типов, используется register_class
		type=>$type,				# может быть изменён register_class
		real_type=>$type,			# тип который и был
		null=>0,
		compute=>0,
		extra => undef,		# дополнительно к столбцу
	);
	
	$self->register_class;
	
	$self
}

# устанавливает класс для возвращения-установки значений
sub register_class {
	my ($self) = @_;
	
	my $type = $self->type;
	my @args;
	@args = split /\s*,\s*/, $2 if $type =~ s!^(\w+)\((.*)\)$!$1!;
	
	#msg1 $type if $self->name eq "description";
	
	my $class = $self->fieldset->meta->{types}{$type};

	if(defined $class) {
		my $path = $class;
		$path =~ s!::!/!g;
		require "$path.pm";
		$self->{class} = $class;
		$self->{class_args} = [@args];
		$self->{type} = $class->can("typeCol")->($self, @args);
		
		# регистриуем обработчики положить в базу, взять из базы
		#my $toCol = $class->can("toCol");
		#$self->{toCol} = $toCol if $toCol;
		
		my $fromCol = $class->can("fromCol");
		$self->{fromCol} = $fromCol if $fromCol;
		
		# регистрируем обработчики. Они отличаются тем, что 1-м параметром в них будет поле
		$self->fieldset->setup_on_args($class, $self);
	
		# регистрируем чекер, если есть
		if($class->can("onCheck")) {
			my $key = "type.$type";
			my $check = $app->check;
			$check->register($key, $check->class("type" . ucfirst $type => $class->can("onCheck"))) if !$check->exists($key);
			$self->check($key);
		}
	}
	
	$self
}

# возвращает таблицу
sub tab {
	my ($self) = @_;
	$self->{fieldset}{tab}
}

# выдаёт краткую информацию о себе
sub info {
	""
}

# возвращает или устанавливает инпут
sub input {
	my $self = shift;
	if(@_==1) { $self->SUPER::input(@_) }
	else {
		$self->{input} //= do {
			my $meta = $self->fieldset->meta;
			$meta->type_to_input->{$self->real_type} // $meta->input_default
		}
	}
}

# добавляет collate
sub charset {
	if(@_==1) {
		shift->{charset}
	}
	else {
		my ($self, $charset) = @_;
		# дописать die if not string type
		$self->{charset} = $charset;
		$self
	}	
}

# # возвращает все индексы в которых участвует колумн
# sub indexes {
	# my ($self) = @_;
	# $self
# }

# # возвращает все fk, которые указывают на колумн
# sub fk_to_col {
	# my ($self) = @_;
	# $self
# }

# указывает sync переименовать столбец
sub rename {
	my ($self, $from) = @_;
	$self->{rename} = $from;
	$self
}

# возвращает представление филда в sql
sub sql {
	my ($self, $alter) = @_;
	my $c = $self->connect;
	my $sql = $c->word($self->col) . " $self->{type}";
	$sql .= " NOT NULL" if !$self->{null} && !(!$alter && $self->{pk});
	$sql .= " PRIMARY KEY" if !$alter && $self->{pk};
	$sql .= " DEFAULT " . $self->{default} if defined $self->{default};
	$sql .= " AUTO_INCREMENT" if $self->{autoincrement};
	$sql .= " $self->{extra}" if defined $self->{extra};
	$sql .= " COMMENT " . $c->quote($self->{remark}) if defined $self->{remark};
	$sql
}

# возвращает alter column
# $after - после какого столбца
# $rename - переименовать
sub alter {
	my ($self, $after, $rename) = @_;
	my $c = $self->connect;
	
	$after //= 0;
	#$rename //= 0;
	
	join "", "ALTER TABLE ", $c->word($self->tab), " ",
	($rename == 1? "MODIFY": $rename? "CHANGE": "ADD"), " COLUMN ", (!$rename || $rename==1? (): $c->word($rename) . " "), $self->sql(1), ($after eq 1? " FIRST": $after? " AFTER " . $c->word($after): "");
}

# код для удаления столбца
sub drop {
	my ($self, $tab, $col) = @_;
	my $c = $self->connect;
	"ALTER TABLE " . $c->word($tab // $self->tab) . " DROP COLUMN " . $c->word($col // $self->col);
}

# синхронизирует филд с базой
sub sync {
	my ($self, $after, $num) = @_;
	
	$after //= $self->fieldset->{field}{$self->{after}}->col;
	
	my $rename = $self->{rename};
	my $c = $self->connect;
	my $col = $self->{col};
	my $info = $c->info->{$self->tab}{$col};
	my $sql;
	my $sql_main = $self->fieldset->meta->{sql_main};
	
	if( !$info && $rename ) {
		$info = $c->info->{$self->tab}{$rename};
		$self->{sync_rename} = $rename;	# для fieldset->sync
	} else {
		$rename = undef;	# устарел ренэйм
	}
	
	if(!$info) {
		my $sql = $self->alter($after);
		push $sql_main, $sql;
	} else {
		if(my $what = $self->not_eq_info($num, $rename)) {
		
			$self->fieldset->drop_relation($col);
			
			$sql = $self->alter($after, $rename // 1);	# 1-modify, rename - change
		
			push @$sql_main,
			"/*\n1) " . $self->alter_info . "\n".
			'2) ' . $self->sql . "\n" .
			$what . " */\n" . $sql;
		}
		elsif($rename) {
			$self->fieldset->drop_relation($col);
			$sql = $self->alter($after, $rename);
			push @$sql_main, $sql;
		}
	}
	$self
}

# сравнивает колумн с info
sub not_eq_info {
	my ($self, $num, $col) = @_;
	my $column_type = $self->fieldset->meta->{column_type};
	my $sql = $self->connect->info->{$self->tab}{$col // $self->{col}};
	return "(not in tab)" unless $sql;
	my $col_type = lc $sql->{column_type}; 
	$col_type = $column_type->{$col_type} // $col_type // "";
	my $type = lc $self->{type};
	$type = $column_type->{$type} // $type;
	return "$type ne $col_type" if $type ne $col_type;
	my $null = $sql->{is_nullable} eq "YES";
	return "null and ne null" if $self->{null} && !$null;
	return "ne null and null" if !$self->{null} && $null;
	
	my $def1 = $self->{raw_default} // "";
	my $def2 = $sql->{column_default} // "";
	my $re_dec = qr/^-?(?:\d*\.\d+|\d+)(?:E-?\d+)?$/i;
	
	$def1 = 0 if $def1 eq "0000-00-00";
	$def2 = 0 if $def2 eq "0000-00-00";
	
	if($def1 =~ $re_dec && $def2 =~ $re_dec) {
		return "DEFAULT $def1 != $def2" if $def1 != $def2;
	} else {
		return "DEFAULT $def1 ne $def2" if $def1 ne $def2;
	}
	
	my $extra = $sql->{extra};
	my $autoincrement = $extra =~ s/auto_increment//i;
	
	return "AUTO_INCREMENT and ne AUTO_INCREMENT" if $self->{autoincrement} && !$autoincrement;
	return "ne AUTO_INCREMENT and AUTO_INCREMENT" if !$self->{autoincrement} && $autoincrement;
	return "extra $self->{extra} ne $extra" if $self->{extra} ne $extra;
	#return "ordinal_position $num != $sql->{ordinal_position}" if $sql->{ordinal_position} != $num;
	return "comment $self->{remark} ne $sql->{column_comment}" if $self->{remark} ne $sql->{column_comment};
}

# возвращает колумн из info
sub alter_info {
	my ($self) = @_;
	my $column_type = $self->fieldset->meta->{column_type};
	my $c = $self->connect;
	my $sql = $c->info->{$self->tab}{$self->{col}};
	($sql? $self->{col} . " " . (($column_type->{$sql->{column_type}} || $sql->{column_type} || "").
	($sql->{is_nullable} eq "YES" || $sql->{column_key} =~ /PRI/? "": " NOT NULL").
	(defined($sql->{column_default})? " DEFAULT " . $c->quote($sql->{column_default}): "").
	($sql->{column_key} =~ /PRI/? " PRIMARY KEY": "").
	($sql->{extra} ne ""? uc " $sql->{extra}": "")):
	($sql->{column_comment} ne ""? " COMMENT ".$c->quote($sql->{column_comment}): ""))
}


# синхронизация столбца
sub change {
	my ($self) = @_;
	
	my $c = $self->connect;
	
	# сброс кэшей
	$c->clean;
	
	my $meta = $self->fieldset->meta;
	
	#for my $fieldset (@{$self->meta->{fields}}) {
	#	$fieldset->{sync} = $fieldset->{synced} = undef;
	#}
	
	my @keys = qw/sql_before sql_main sql_after/;
	
	#my @old = @$meta{@keys};
	@$meta{@keys} = ([], [], []);
	
	$self->sync;
	
	# запись в базу
	for my $sql (map {@$_} @$meta{@keys}) {
		$c->do($sql);
	}
	
	# восстанавливаем
	#@$meta{@keys} = @old;
	
	# сброс кэшей
	$c->clean;
	
	$self
}


# свойство филда - устанавливается в класс row
sub row {
	my ($self, $bean, $val, $val2) = @_;
	
	my $name = $self->{name};
	
	if(@_==3) {

		#my $toCol = $self->{toCol};
		#$val = $toCol->($val) if defined $toCol;
		$val = $val->toCol if Can $val, "toCol";	# ? может убрать ?
		
		$bean->{save}{$name} = $val;
		$bean
	}
	elsif(@_>3) {
		die "допустимые операторы: +, -, * и /" if $val !~ /^[\+\*\-\/]$/;
	
		#my $toColOp = $self->{toColOp};
		#$val2 = $toColOp->($self, $val, $val2) if defined $toColOp;
		
		$bean->{save}{$name} = [$val, $val2];
		$bean
	}
	else {
		
		# возвращаем из сейва, если это не ['+' => 1]
		goto RET if $bean->{save} and exists $bean->{save}{$name} and !ref($val = $bean->{save}{$name});
		
		# есть отображение
		$val = $bean->{val}{$name}, goto RET if exists $bean->{val}{$name};
		
		# есть в кэше, возможно что свойство уже подгружено
		$val = $bean->CacheGet($name), goto RET if $bean->CacheExists($name);
		
		# сохраняем, чтобы получить id
		$bean->save if $bean->{save} and not defined $bean->{id};
		
		# возвращаем default столбца, если нет идентификатора
		return $self->{raw_default} unless defined $bean->{id};

		# запрашиваем
		my $c = $self->connect;
		
		# если нужно подгрузить несколько свойств
		if(my $view = $bean->{view}) {
			my %col = ($self->{col} => $name);
			my $fields = $self->{fieldset}{field};
			for my $cname (@$view) {
				my $field = $fields->{$cname};
				$col{$field->{col}} = $cname;
			}
			delete $bean->{view};
			$val = $c->query_ref($self->tab, \%col, {id=>$bean->{id}});
			# устанавливаем и в val и в кэш
			while(my ($k, $v) = each %$val) {
				$bean->{val}{$k} = $v;
				$bean->CacheSet($k, $v);
			}
			$val = $val->{$name}
		} else {
			# подгружаем одно свойство
			$val = $c->query($self->tab, [$self->{col}], {id=>$bean->{id}});
			# устанавливаем и в val и в кэш
			$bean->{val}{$name} = $val;
			$bean->CacheSet($name, $val);
		}
		
		RET: 
		my $fromCol = $self->{fromCol};
		defined($fromCol)? $fromCol->($self, $val): $val
	}
}

# устанавливается в класс rowset-а
sub rowset {
	my ($self, $bean, $val) = @_;

	if(@_>2) {
		#my $toCol = $self->{toCol};
		#$val = $toCol->($val) if defined $toCol;
		
		$bean->update($self->{name}=>$val);
	} else {
		my $ref = $bean->view($self->{name});
		
		if(my $fromCol = $self->{fromCol}) {
			local $_;
			return wantarray? map { $fromCol->($self, $_) } @{$ref->_col_ref}:
				$fromCol->($self, @{$ref->limit(1)->_col_ref}[0]);
		}
		
		wantarray? @{$ref->_col_ref}: @{$ref->limit(1)->_col_ref}[0];
	}
}

1;