package R::Connect;
# подключение к базе и простенькие функции для запросов

use common::sense;
use R::App;

use DBI;
use POSIX qw/strftime/;
use Time::HiRes qw//;

sub ON_UPDATE {"ON UPDATE RESTRICT"}
sub ON_DELETE {"ON DELETE RESTRICT"}

# зарезервированные слова sql
my $SQL_WORD = $app->perl->setref(qw/ACCESSIBLE	 ADD	 ALL	 ALTER	 ANALYZE	 AND	 AS	 ASC	 ASENSITIVE	 BEFORE	 BETWEEN	 BIGINT	 BINARY	 BLOB	 BOTH	 BY	 CALL	 CASCADE	 CASE	 CHANGE	 CHAR	 CHARACTER	 CHECK	 COLLATE	 COLUMN	 CONDITION	 CONSTRAINT	 CONTINUE	 CONVERT	 CREATE	 CROSS	 CURRENT_DATE	 CURRENT_TIME	 CURRENT_TIMESTAMP	 CURRENT_USER	 CURSOR	 DATABASE	 DATABASES	 DAY_HOUR	 DAY_MICROSECOND	 DAY_MINUTE	 DAY_SECOND	 DEC	 DECIMAL	 DECLARE	 DEFAULT	 DELAYED	 DELETE	 DESC	 DESCRIBE	 DETERMINISTIC	 DISTINCT	 DISTINCTROW	 DIV	 DOUBLE	 DROP	 DUAL	 EACH	 ELSE	 ELSEIF	 ENCLOSED ESCAPED	 EXISTS	 EXIT	 EXPLAIN	 FALSE	 FETCH	 FLOAT	 FLOAT4	 FLOAT8	 FOR	 FORCE	 FOREIGN	 FROM FULLTEXT	 GENERAL GRANT	 GROUP	 HAVING	 HIGH_PRIORITY	 HOUR_MICROSECOND	 HOUR_MINUTE	 HOUR_SECOND	 IF	 IGNORE	 IGNORE_SERVER_IDS IN	 INDEX	 INFILE	 INNER	 INOUT	 INSENSITIVE	 INSERT	 INT	 INT1	 INT2	 INT3	 INT4	 INT8	 INTEGER	 INTERVAL	 INTO	 IS	 ITERATE	 JOIN	 KEY	 KEYS	 KILL	 LEADING	 LEAVE	 LEFT	 LIKE	 LIMIT	 LINEAR	 LINES	 LOAD	 LOCALTIME	 LOCALTIMESTAMP	 LOCK	 LONG	 LONGBLOB	 LONGTEXT	 LOOP	 LOW_PRIORITY	 MASTER_HEARTBEAT_PERIOD MASTER_SSL_VERIFY_SERVER_CERT	 MATCH	 MAXVALUE MEDIUMBLOB	 MEDIUMINT	 MEDIUMTEXT	 MIDDLEINT	 MINUTE_MICROSECOND	 MINUTE_SECOND	 MOD	 MODIFIES	 NATURAL	 NOT	 NO_WRITE_TO_BINLOG	 NULL	 NUMERIC	 ON	 OPTIMIZE	 OPTION	 OPTIONALLY	 OR	 ORDER	 OUT	 OUTER	 OUTFILE	 PARTITION PRECISION	 PRIMARY	 PROCEDURE	 PURGE	 RANGE	 READ	 READS	 READ_WRITE	 REAL REFERENCES	 REGEXP	 RELEASE	 RENAME	 REPEAT	 REPLACE	 REQUIRE	 RESIGNAL RESTRICT	 RETURN	 REVOKE	 RIGHT	 RLIKE	 SCHEMA	 SCHEMAS	 SECOND_MICROSECOND	 SELECT	 SENSITIVE	 SEPARATOR	 SET	 SHOW	 SIGNAL SLOW SMALLINT	 SPATIAL	 SPECIFIC	 SQL	 SQLEXCEPTION	 SQLSTATE	 SQLWARNING	 SQL_BIG_RESULT	 SQL_CALC_FOUND_ROWS	 SQL_SMALL_RESULT	 SSL	 STARTING	 STRAIGHT_JOIN	 TABLE	 TERMINATED	 THEN	 TINYBLOB	 TINYINT	 TINYTEXT	 TO	 TRAILING	 TRIGGER	 TRUE	 UNDO	 UNION	 UNIQUE	 UNLOCK	 UNSIGNED	 UPDATE	 USAGE	 USE	 USING	 UTC_DATE	 UTC_TIME	 UTC_TIMESTAMP	 VALUES	 VARBINARY	 VARCHAR	 VARCHARACTER	 VARYING	 WHEN	 WHERE	 WHILE	 WITH	 WRITE	 XOR	 YEAR_MONTH	 ZEROFILL
GENERATED	GET	IO_AFTER_GTIDS	IO_BEFORE_GTIDS MASTER_BIND OPTIMIZER_COSTS PARSE_GCOL_EXPR STORED VIRTUAL/);

sub SQL_WORD {
    $SQL_WORD
}



# типы столбцов для alter table
my $COLUMN_TYPE = {
    "int(11)" => "int",
    "int(10) unsigned" => "int unsigned",
    "tinyint(4)" => "tinyint",
    "tinyint(3) unsigned" => "tinyint unsigned",
    "bigint(21)" => "bigint",
    "bigint(20) unsigned" => "bigint unsigned",
    "smallint(5) unsigned" => "smallint unsigned",
    "smallint(6)" => "smallint",
};

sub COLUMN_TYPE {
    $COLUMN_TYPE
}

has qw/user password DNS basename charset collate/;

sub new {
	my $cls = shift;
	my %ini = @_;
	my $DNS = delete($ini{DNS});
	die "main.ini[connect]DNS не указан. См. main.sample.ini" unless defined $DNS;
	my ($sql_word) = $DNS =~ /^(?:dbi:)?(\w+)/i;
	$sql_word = lc $sql_word;
	die "main.ini[connect]DNS повреждён" unless $sql_word;
    
    my $self = $sql_word eq "mysql"? do {
        $ini{mysql_enable_utf8} = 1 if !exists $ini{mysql_enable_utf8};
        bless {}, ref $cls || $cls;
    }: do {
        my $name="connect" . ucfirst $sql_word;
        $app->$name->new
    };
    
    %$self = (%$self,
		sql_word => $self->SQL_WORD,
		column_type => $self->COLUMN_TYPE,
		DNS => $DNS,
		user => delete($ini{user}),
		password => delete($ini{password}),
		basename => delete($ini{database}) // ($DNS =~ /database=(\w+)/ and $1),
		charset => delete($ini{charset}),
		collate => delete($ini{collate}),
		log => scalar(delete($ini{'log'}) =~ /^yes$/i),
        log_prefix => '',
        sql_save => undef,            # собирает sql, вместо выполнения, если []
		options => {%ini},
	);
    
    $self
}


# деструктор
sub DESTROY {
	my ($self) = @_;
	$self->closeall;
}

# коннект
sub connect {
	my ($self) = @_;
	
	$self->close if $self->{dbh};
	
    my $dbh = $self->make_connect;
	
	$self->{dbh} = $dbh;
	my $currsql = $self->{CURR_SQL};
	
    my $charset = $self->{charset};
    my $collate = $self->{collate};
	$self->setnames($charset, $collate) if $charset;
	
	eval { $self->use($self->{basename}) }, $@ = undef if $self->{basename};
	
	$self->pool;	# connect всегда возвращает dbh, а do всегда делает release
	$self->{CURR_SQL} = $currsql;
	
	$self
}

# закрывает соединение
sub close {
	my ($self) = @_;
	$self->{dbh}->disconnect;
	undef $self->{dbh};
	$self->clean;
	$self
}

# переконнекчивается, если связь утрачена
sub reconnect {
	my ($self) = @_;
	if($self->{dbh}) {
		return $self if $self->{dbh}->ping;
		$self->close;
	}
	$self->connect;
	$self
}

# создаёт и возвращает подключение
sub make_connect {
	my ($self) = @_;
    
	my $dbh = DBI->connect($self->{DNS}, $self->{user}, $self->{password},
		{RaiseError => 1, PrintError => 0, PrintWarn => 0, %{$self->{options}}});
	
	if($app->{coro}) {
		require Coro::Mysql;
		$dbh = $dbh->Coro::Mysql::unblock;
		#msg1 "coro dbh!!!";
	}
    
    $dbh
}

# возвращает dbh
sub dbh { $_[0]->{dbh} }


# переключиться на БД
sub use {
	my ($self, $basename) = @_;
	$self->basename($basename);
	$self->do("USE " . $self->word($basename));
	$self
}

# устанавливает кодировку сессии
sub setnames {
	my ($self, $charset, $collate) = @_;
    my $dbh = $self->{dbh};
    $self->do("SET NAMES " . $dbh->quote($charset) . ($collate? " COLLATE " . $dbh->quote($collate): ""));
	$self
}

# отключает логирование в функции
sub nolog {
	my ($self, $cb) = @_;
	
	my $log = $self->{log};
	$self->{log} = 0;
	
	my ($res, @res);
	
	if(wantarray) { @res = $cb->(); } else { $res = $cb->() }
	
	$self->{log} = $log;
	
	wantarray? @res: $res;
}

# кеширует инф. о таблицах
sub tab_info {
	my ($self) = @_;
	$self->{tab_info} //= $self->get_tab_info;
}

# возвращает информацию о таблицах
sub get_tab_info {
	my ($self) = @_;
	
	my $sql = "select table_name as name, engine, table_collation as charset, table_comment as remark, create_options as options, table_type as type
		from information_schema.tables
		where table_schema=".$self->quote($self->basename);
	my $rows = $self->nolog(sub { $self->query_all($sql); });
	
	my $info = {};
	for my $row (@$rows) {	# создаём info
		$info->{$row->{name}} = $row;
	}
	return $info;
}


# кеширует инф. о столбцах таблиц
sub info {
	my ($self) = @_;
	$self->{info} //= $self->get_info;
}

# возвращает информацию о столбцах таблиц
sub get_info {
	my ($self) = @_;
	my $sql = "select table_name, column_name, data_type, column_type, column_default, is_nullable, character_maximum_length, extra, column_key, ordinal_position, column_comment, character_set_name, collation_name
		from information_schema.columns
		where table_schema=".$self->quote($self->basename);
	my $rows = $self->nolog(sub { $self->query_all($sql); });
	my $info = {};
	
	for my $row (@$rows) {	# создаём info
		$info->{$row->{table_name}}{$row->{column_name}} = $row;
	}
	return $info;
}

# кеширует информацию о ключах таблиц
sub index_info {
	my ($self) = @_;
	$self->{index_info} //= $self->get_index_info
}

# без кеширования
sub get_index_info {
	my ($self) = @_;
	my %rename = qw(Table tab Non_unique non_uniq Key_name name Seq_in_index pos Column_name col Comment comment Index_comment index_comment Null null Index_type type Packed packed Cardinality cardinality Sub_part part Collation charset);
	my $tab_info = $self->tab_info;
	my $fk_info = $self->fk_info;
	my $info = {};
	while(my ($tab, $in) = each %$tab_info) {
		my $sql = "SHOW KEYS FROM " . $self->word($tab);
		my $rows = $self->nolog(sub { $self->query_all($sql) });

		for my $row (@$rows) {
			next if exists $fk_info->{$tab}{$row->{Key_name}};

			%$row = map {(($rename{$_} // $_) => $row->{$_})} keys %$row;
			
			my $idx = $info->{$row->{tab}}{$row->{name}} //= [];
			push @$idx, $row;
		}
	}
	return $info;
}

# кеширует информацию о внешних ключах таблиц
sub fk_info {
	my ($self) = @_;
	$self->{fk_info} //= $self->get_fk_info;
}

# возвращает от каких ключей зависит какая таблица
sub fk_info_backward {
	my ($self) = @_;
	$self->fk_info;
	$self->{fk_info_backward}
}

# возвращает от каких ключей зависит какая таблица
sub get_fk_info_backward {
	my ($self) = @_;
	$self->{fk_info} = $self->get_fk_info;
	$self->{fk_info_backward}
}

# возвращает информацию о внешних ключах таблиц
sub get_fk_info {
	my ($self) = @_;
	my $sql = "SELECT table_name as tab,column_name as col,constraint_name as name,
referenced_table_name as ref_tab,referenced_column_name as ref_col,
ordinal_position as pos, position_in_unique_constraint as ref_pos
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA=" . $self->quote($self->basename) . "
AND referenced_column_name IS not null";
	my $rows = $self->nolog(sub { $self->query_all($sql); });
	my $info = {};
	my $bk = $self->{fk_info_backward} = {};
	for my $row (@$rows) {
		$info->{$row->{tab}}{$row->{name}} = $row;
		$bk->{$row->{ref_tab}}{$row->{name}} = $row;
	}
	return $info;
}

# очищает кеши
sub clean {
	my ($self) = @_;
	
	delete $self->{info};
	delete $self->{tab_info};
	delete $self->{index_info};
	delete $self->{fk_info};
	delete $self->{fk_info_backward};
	
	$self
}

# возвращает текущее время в формате базы
sub now {
	strftime("%F %T", @_>1? localtime @_[1..$#_]: localtime)
}

# переводит в camelcase
sub uc {
	my ($self, $word) = @_;
	local ($`, $', $&, $1);
	$word =~ s!_([A-Z])!ucfirst $1!ige;
	ucfirst $word
}

# переводит в decamelcase
sub lc {
	my ($self, $word) = @_;
	local ($`, $', $&);
	$word = lcfirst $word;
	$word =~ s![A-Z]!"_" . lcfirst $&!ge;
	$word
}

# сокращение
sub up {
	my ($self, $col) = @_;
	$self->word($self->uc($col))
}

# сокращение
sub down {
	my ($self, $col) = @_;
	$self->word($self->lc($col))
}

# оборачивает в `` если нужно
sub word {
	my ($self, $col) = @_;
	exists($self->{sql_word}{uc $col}) || $col !~ /^[a-z_][a-z0-9_]*(?:\.[a-z_][a-z0-9_]*)?$/i && $col !~ /^\(/? "`$col`": $col;
}

# оборачивает таблицу
sub tab_word {
	my ($self, $tab) = @_;
	exists($self->{sql_word}{uc $tab}) || $tab !~ /^[a-z_][a-z0-9_]*(?:\.[a-z_][a-z0-9_]*)?$/i? "`$tab`": $tab;
	$self
}

# формирует колумн
sub SQL_COL {
	my ($self, $col, $as) = @_;
	join "", ($as? ($self->word($as), "."): ()), $self->word($col);
}

# возвращает алиас таблицы. То есть бывает, что таблица содержит несколько ссылок на другую таблицу, тогда они не могут называться все как таблица на которую ссылаются. И так: author_id, soauthor_id - alias_tab = {soauthor_id => author_id}
sub TAB_ref {
	my ($self, $col) = @_;
	$col =~ s/_id$//;
	$self->{alias_tab}{$col} // $col;
}

# вспомогательный метод для пула
sub _pool_quote {
	my ($self, $s) = @_;
	$self->pool;
	my $res = $self->{dbh}->quote($s);
	$self->release;
	$res
}

# квотирование
sub quote {
	my ($self, $s) = @_;
	!defined($s)? "NULL":
	ref($s)? do {
		use Scalar::Util qw/blessed/;
		!blessed($s)? do {
			ref $s eq "ARRAY"? do {
				my %x = map { ($_=>$_) } @$s;
				"(".join(",", map{$self->quote($x{$_})} keys %x).")"
			}: die("не могу преобразовать ссылку в quote: `$s`");
		}:
		$s->isa("R::Model::Row")? $s->id:	# для ORM
		$s->can("toCol")? do {
			$s = $s->toCol;		# для типов базы данных
			$s =~ /^-?(?:[1-9]\d*|0)(?:\.\d+)?$/ && $s!=0? $s:
				$self->{dbh}? $self->{dbh}->quote($s): $self->_pool_quote($s)
		}:
		die("не могу преобразовать ссылку в quote: `$s`");
	}:
	$s =~ /^-?(?:[1-9]\d*|0)(?:\.\d+)?$/ && $s!=0? $s:
	$self->{dbh}? $self->{dbh}->quote($s): $self->_pool_quote($s)
}

# формирует ключ=значение через запятую, для UPDATE SET или REPLACE SET
sub DO_SET {
	my ($self, $p, $as) = @_;
	
	return $p if !ref $p;
	
	my @set = ();
	$p = {@$p} if ref $p eq "ARRAY";
	while(my($a, $b) = each %$p) {
		push @set, join("",
			$self->SQL_COL($a, $as), "=", (
				ref $b eq 'HASH'? scalar($self->replace($self->TAB_ref($a), $b)):
				ref $b eq "SCALAR"? $self->SQL_COL($$b, $as):
				ref $b eq "REF"? $$$b:
				$self->quote($b)
			)
		);
	}
	return wantarray? @set: join(", ", @set);
}

# формирует where
sub DO_WHERE {
	my ($self, $where, $as) = @_;
	
	if(ref $where) {
		my @SET;
		$where = [%$where] if ref $where eq "HASH";
		for(my $i = 0; $i<@$where; $i+=2) {
			my($a, $b) = ($where->[$i], $where->[$i+1]);
			my $op = $a=~s/__ne$//? "<>": $a=~s/__lt$//? "<": $a=~s/__gt$//? ">": $a=~s/__le$//? "<=": $a=~s/__ge$//? ">=": $a=~s/__like$//? " like ": $a=~s/__unlike$//? " not like ": $a=~s/__isnt$//? " is not ": $a=~s/__between//? " BETWEEN ": !defined($b)? " is ": "=";
			push @SET, join("", 
				$self->SQL_COL($a, $as), $op, (
					!defined($b)? "null":
					ref $b eq "ARRAY"? (
						$op eq " BETWEEN "? $self->quote($b->[0])." AND ".$self->quote($b->[1]): do {
							$op = " IN " if $op eq '=';
							join "", "(", join(", ", map { $self->quote($_) } @$b), ")" 
						}
					):
					ref $b eq 'HASH'? scalar($self->replace($self->TAB_ref($a), $b)):
					ref $b eq "SCALAR"? (ref $$b eq "SCALAR"? $$$b: $self->SQL_COL($$b, $as)):
					$self->quote($b)
				)
			);
		}
		return join(" AND ", @SET)." AND ".$where->[$#$where] if @$where % 2;
		return join(" AND ", @SET);
	}
	return $where =~ /^\d+$/? join("", $self->SQL_COL('id', $as), '=', $where): $where;
}

# формирует матрицу значений для INSERT
sub INS_SET {
	my ($self, $m) = @_;
	my $set = join ",", map {join "", "(", join(",", map {$self->quote($_)} @$_), ")"} @$m;
	return $set;
}

# формирует столбцы
sub FIELDS {
	my ($self, $fields) = @_;
	return map { $self->word($_) } @$fields if ref $fields eq "ARRAY";
	return map { my $val = $fields->{$_}; $_ eq $val? $_: $self->word($_) . ' As ' . $self->word($val) } keys %$fields if ref $fields eq "HASH";
	return $fields;
}

# возвращает массив названий столбцов
sub FIELDS_NAMES {
	my ($self, $fields) = @_;
	return @$fields if ref $fields eq "ARRAY";
	return keys %$fields if ref $fields eq "HASH";
	return split /,\s*/, $fields;
}

# формирует столбцы с таблицей
sub FOR_TAB_FIELDS {
	my ($self, $fields, $as) = @_;
	$as = $self->word($as);
	return map { ($as.".".$self->word($_)) } @$fields if ref $fields eq "ARRAY";
	return map { ($as.".".$fields->{$_}, ' as ', $self->word($_)) } keys %$fields if ref $fields eq "HASH";
	return map { $as.".".$self->word($_) } split /,\s*/, $fields;
}

# возвращает таблицу и её алиас, если он указан
sub TAB {
	return ($2, $1) if $_[1] =~ /^\s*(\w+)\s+(?:as\s+)?(\w+)\s*$/i;
	($_[1], $_[1]);
}

# выборки
sub sel {
	# возвращаем sql, если не указано что преобразовывать
	return $_[1] if !defined $_[2];

	my ($self, $tab, $view, @args) = @_;
	my @view = $self->FIELDS($view);
	die "not fields in sql query for `$tab`" unless @view;
	my $sep = " ";
	if(ref $tab) {
		$sep = "\n" if @$tab > 1;
		$tab = join "\n", @$tab;
	} else {
		$tab = $self->word($tab);
	}
	
	my $sql = join "", "SELECT ", join(", ", @view), "${sep}FROM ", $tab, 
		@args==1 && ref $args[0] eq "" && $args[0] =~ /^\s*(WHERE|GROUP|HAVING|ORDER|LIMIT)\b/i? (" ", $args[0]): @args>0 && defined($args[0])? $self->query_add($sep, \@args): ();
	$sql
}

# добавляет в push arg
sub query_compile {
	my ($self, $arg, $push, $as) = @_;
	my ($op, @val) = @$arg;
	my $val = (@val==1? $val[0]: \@val);
	if($op eq "WHERE") { # WHERE
		push @{$push->{where}}, $self->DO_WHERE($val, $as);
	} elsif($op eq "GROUP") {	# GROUP
		push @{$push->{group}}, $self->FOR_TAB_FIELDS($val, $as);
	} elsif($op eq "HAVING") { # HAVING
		push @{$push->{having}}, $self->DO_WHERE($val, $as);
	} elsif($op eq "ORDER") { # ORDER
		push @{$push->{order}}, $self->FOR_TAB_FIELDS($val, $as);
	} elsif($op eq "LIMIT") { # LIMIT
		die "Один LIMIT уже есть в SQL-запросе" if $push->{limit};
		$push->{limit} = join ", ", @val;
	} else {
		die "Что-то неясное попало в выражение для select";
	}
}

# добавляет к запросу указанное в массиве
sub query_add {
	my ($self, $sep, $args) = @_;
	my $push = {};
	for my $arg (@$args) {
		if(ref $arg eq 'ARRAY') { $self->query_compile($arg, $push) }
		else { push @{$push->{where}}, $self->DO_WHERE($arg) }
	}
	$self->query_join($push, $sep);
}

# объединяет все выражения в sql-запрос
sub query_join {
	my ($self, $arg, $sep) = @_;
	my @w;
	
	($arg->{where} && (@w=@{$arg->{where}})? ("${sep}WHERE ", @w==1? @w: join " AND ", map { join "", "(", $_, ")" } @w): ()), 
	($arg->{group} && (@w=@{$arg->{group}})? ("${sep}GROUP BY ", join ", ", @w): ()), 
	($arg->{having} && (@w=@{$arg->{having}})? ("${sep}HAVING ", @w==1? @w: join " AND ", map { join "", "(", $_, ")" } @w): ()),
	($arg->{order} && (@w=@{$arg->{order}})? ("${sep}ORDER BY ", join ", ", @w): ()), 
	($arg->{limit}? ("${sep}LIMIT ", $arg->{limit}): ());
}

sub flat2volume { my ($self, $join, @args) = @_; my ($tab) = @args; my ($as); ($as, $tab) = $self->TAB($tab); return {tab => $self->word($tab), as => $self->word($as), args=>[@args], join=>$join}; }

# выборки
sub sel_join {
	my ($self, @any) = @_;
	my (@st, @where, @view, @join, $push);
	my ($as_table, $table) = $self->TAB($_[1]);
	my ($fields, $real_fields, $real_new, @cols) = ([], []);
	@st = [[], \@any, $real_fields];
	
	while(@st) {
		my ($path, $args, $real) = @{ pop @st };
		my ($tab, $view, @args) = @$args;
		my ($as); ($as, $tab) = $self->TAB($tab);
		
		push @view, $self->FOR_TAB_FIELDS($view, $as);
		push @$fields, [$path, [ @cols = $self->FIELDS_NAMES($view) ] ];
		push @$real, @cols;
		my @real = ();
		for my $arg (@args) {
			if(ref $arg eq "ARRAY") {
				my ($op) = @$arg;
				if($op =~ /^(?:LEFT|INNER)$/) {
					$arg = $self->flat2volume(@$arg);
					my ($as1, $tab1) = ($arg->{as}, $arg->{tab});
					my $is1 = $as1 eq $tab1;
					unshift @real, $real_new = [$as1];
					push @st, [[@$path, $as1], $arg->{args}, $real_new];
					push @join, join "", "\n", $op, " JOIN ", $tab1, (!$is1? (' as ', $as1): ()), " ON ", $as1, '.', ($is1? $as: $as1), "_id=", $as, ".id";
				} else {
					$self->query_compile($arg, $push, $as);
				}
			} else {
				push @{$push->{where}}, $self->DO_WHERE($arg, $as);
			}
		}
		push @$real, @real;
	}
	my $sql = join "", "SELECT ", join(", ", @view), "\nFROM ", $self->word($table), ($table ne $as_table? (' as ', $as_table): ()), @join, $self->query_join($push, "\n");
	
	wantarray? ($sql, $fields, $real_fields): $sql;
}

# пакует строки для передачи клиенту
sub pack_rows {
	my ($self, $fld, $rows_start, $add_row) = @_;
	
	my ($i, @st, $row, $rows) = 0;
	my $old_path = -1;
	
	for my $field (@$fld) {
		my ($path, $cols) = @$field;
		
		splice(@st, scalar(@$path)), $st[$#$path] ++ if $old_path == @$path;
		
		$rows = $rows_start;
		$row = $rows->[$#$rows], $rows = ($row->[$_] ||= [[]]) for @st[0..$#$path];
		if( $#$rows == -1 ) { push @$rows, $row = [] } else { $row = $rows->[$#$rows] }
		
		if(not defined $add_row->[$i]) { $i += @$cols; pop @$rows if @$row == 0; }
		elsif(@$row == 0) { push @$row, $add_row->[$i++] for @$cols; }
		elsif($add_row->[$i] == $row->[0]) {	# сравниваем id
			$i += @$cols;
		} else {
			push @$rows, $row = [];
			push @$row, $add_row->[$i++] for @$cols;
		}
		
		$st[$old_path = scalar @$path] += scalar @$cols;
	}
	$self
}


# запрашивает строки и пакует их в формат для передачи
sub query_rows {
	my ($self, $tab, $view, @args) = @_;
	my ($sql, $fields, $real_fields) = $self->sel_join(@_);
    
    push(@{$self->{sql_save}}, $sql), return if $self->{sql_save};
    
	$self->{CURR_SQL} = $sql;
	$self->pool;
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute;
	my $rows = [];
	while(my $row = $sth->fetchrow_arrayref) {
		$self->pack_rows($fields, $rows, $row);
	}
	$sth->finish;
	my $res = {
		fields => $real_fields,
		rows => $rows
	};
	$self->release($res);
	$self->{CURR_SQL} = undef;
	return $res;
}

# аналог query_rows: запрашивает строки отдельными запросами
# отличие в том, что LIMIT может быть проставлен для отдельных подстрок
# INNER_JOIN тут работает так же как и LEFT_JOIN
sub quick_rows {
	my ($self, $tab, $view, @args) = @_;
	
	my @join = grep { ref $_ eq 'ARRAY' and $_->[0] =~ /^LEFT|INNER$/ } @args;
	@args = grep { !(ref $_ eq 'ARRAY' and $_->[0] =~ /^LEFT|INNER$/) } @args;
	
	my (@a);
	($tab, $view, @a) = @{$_->{args}}, $_->{a} = [@a], $_->{view} = $view for @join;
	
	my $rows = $self->query_all($tab, $view, @args);
	
	for my $row (@$rows) {
		for my $join (@join) {
			$row->{$join->{as}} = $self->quick_rows(($join->{tab}, $join->{view}, $row->{id}, @{$join->{a}}));
		}
	}
	
	return $rows;
}

# выбирает из пула dbh или создаёт подключение
our %CONNECT;	# существующие коннекты
sub pool {
	my $self = shift;
	
	$self->log_sql(@_) if $self->{log} && $self->{CURR_SQL};
	
	return $self if $self->{transaction};	# в транзакции не переключаемся - должен быть один и тот же dbh
	return $self if $self->{dbh};			# уже есть dbh у коннекта
	
	my $pool = $CONNECT{ ref $self } //= [];
	
	my $dbh = pop @$pool;
	if(!defined $dbh) {
		$self->connect;
	} else {
		$self->{dbh} = $dbh;
		$self->reconnect;		# за время пока dbh находился в пуле коннект мог быть утрачен
	}
	
	$self
}

# возвращает dbh в пул
sub release {
	my $self = shift;
	
	$self->log_ret(@_) if $self->{start_time};
	
	return $self if $self->{transaction};	# в транзакции не переключаемся - должен быть один и тот же dbh
	return $self if !$self->{dbh};			# dbh у коннекта нет
	
	# добавляем в пул
	push @{ $CONNECT{ ref $self } }, $self->{dbh};
	undef $self->{dbh};
	
	$self
}


# закрывает все соединения в пуле и свой
sub closeall {
	my ($self) = @_;
	$self->{dbh}->disconnect if $self->{dbh};
	undef $self->{dbh};
	
	my $pool = $CONNECT{ ref $self } // [];
	
	while( my $dbh = pop @$pool ) { $dbh->disconnect }
	
	$self->clean;
	$self
}

# запрашивает первую строку в виде массива
sub query {
	my ($self) = @_;
	my $sql = sel @_;
    
    push(@{$self->{sql_save}}, $sql), return if $self->{sql_save};
    
    $self->{CURR_SQL} = $sql;
	$self->pool;
	my @row = $self->{dbh}->selectrow_array($sql);
	$self->release(wantarray? \@row: $row[0]);
	$self->{CURR_SQL} = undef;
	return wantarray? @row: $row[0];
}

# запрашивает строку в виде массивов
sub query_array {
	my ($self) = @_;
	my $sql = sel @_;
    
    push(@{$self->{sql_save}}, $sql), return if $self->{sql_save};
    
    $self->{CURR_SQL} = $sql;
	$self->pool;
	my $row = $self->{dbh}->selectall_arrayref($self->{CURR_SQL});
	$self->release($row);
	$self->{CURR_SQL} = undef;
	$row
}

# запрашивает строки в виде хешей
sub query_all {
	my ($self) = @_;
	my $sql = sel @_;
    
    push(@{$self->{sql_save}}, $sql), return if $self->{sql_save};
    
    $self->{CURR_SQL} = $sql;
	$self->pool;
	my $row = $self->{dbh}->selectall_arrayref($self->{CURR_SQL}, {Slice=>{}});
	$self->release($row);
	$self->{CURR_SQL} = undef;
	$row
}

# массив значений столбца
sub query_col {
	my ($self) = @_;
	my $sql = sel @_;
    
    push(@{$self->{sql_save}}, $sql), return if $self->{sql_save};
    
    $self->{CURR_SQL} = $sql;
	$self->pool;
	my $row = $self->{dbh}->selectcol_arrayref($self->{CURR_SQL});
	$self->release($row);
	$self->{CURR_SQL} = undef;
	$row
}

# строка в виде хеша
sub query_ref {
	my $x = query_all(@_);
	$x->[0];
}

# сохраняет время
sub log_sql {
	my $self = shift;
	#$app->log->info(":inline empty nonewline", $self->{log_prefix}, $self->syntax($self->{CURR_SQL}, @_));
	$self->{start_time} = Time::HiRes::time();
	$self->{log_sql} = [ $self->syntax($self->{CURR_SQL}, @_) ];
}

# логирует запрос и ответ
sub log_ret {
	my $self = shift;
	$app->log->info(":inline empty", @{$self->{log_sql}}, (@_? (":red", " -> ", ":reset sep", @_): ()), ":bold black", Time::HiRes::time() - $self->{start_time});
	$self->{start_time} = undef;
	$self->{log_sql} = undef;
}

our $COLOR_NUM = ":cyan";
our $COLOR_WORD = ":magenta";
our $COLOR_STR = ":green";
our $COLOR_DO = ":bold black";

# подсветка синтаксиса
sub syntax {
	my ($self, $sql, $cw) = @_;
	#my $words = $self->{sql_word}; $words->{uc $_}
	#&& exists $self->{sql_word}{$_}
	$cw //= $COLOR_WORD;
	map { ((/^\d+$/? $COLOR_NUM: /^['"]/? $COLOR_STR: /^[A-Z_\d]+$/? $cw: ":reset"), $_) } split /(\w+|'(?:\\'|[^'])*'|"(?:\\"|[^"])*")/, $sql;
}

# id последней добавленной записи
sub last_id {
	my ($self) = @_;
	return $self->{last_id};
}

# количество изменённых строк последней операцией редактирования
sub last_count { $_[0]->{last_count} }
sub effected_rows { $_[0]->{last_count} }

# выполняет sql-запрос
sub do {
	my ($self, $sql) = @_;
    
    push(@{$self->{sql_save}}, $sql), return if $self->{sql_save};
    
	$self->{CURR_SQL} = $sql;
	$self->pool($COLOR_DO);
	my $dbh = $self->{dbh};
	
	my $ret = $dbh->do($self->{CURR_SQL});
	
	$self->{last_id} = $self->{CURR_SQL} =~ /^\s*INSERT\b/i? $dbh->selectrow_array("SELECT LAST_INSERT_ID()"): undef;
	
	if($self->{log}) {
		$self->release($COLOR_NUM, ($ret == 1? (): $ret), ($self->{last_id}? $self->{last_id}: ()));
	} else {
		$self->release;
	}
	$self->{CURR_SQL} = undef;
	$ret
}

# удаляет записи из таблицы
sub erase {
	my ($self, $tab, $where) = @_;
	
	my @rmtab;
	if(ref $tab) {
		if(@$tab == 1) { $tab = $self->word(@$tab) . " " }
		else { @rmtab = $tab->[0] =~ /(\s\w+)$/; $tab = join "\n", @$tab, "" }
	} else {
		$tab = $self->word($tab) . " ";
	}
	
	my $cond = $self->DO_WHERE($where);
	
	my $sql = join "", "DELETE", @rmtab, " FROM ", $tab, (defined($cond)? ("WHERE ", $cond): ());
	$self->{last_count} = $self->do($sql) + 0;
	$self
}

# изменяет запись
sub update {
	my ($self, $tab, $param, $where, $opt) = @_;
	my $SET = $self->DO_SET($param);
	my $from;
	if(ref $tab) {
		if(@$tab == 1) { $tab = $tab->[0]; }
		else {
			$from = $tab;
			($tab) = $from->[0] =~ /\s(\w+)$/;
		}
	}
	my $sql = join "", "UPDATE ", $self->word($tab), " SET ", $SET, ($from? ("\nFROM ", join "\n", @$from, ""): " "), (defined($where)? ("WHERE ", $self->DO_WHERE($where)): ()), (defined($opt)? " $opt": ());
	$self->{last_count} = $self->do($sql)+0;
	$self
}


# добавляет одну запись в таблицу и возвращает её id
sub append {
	my ($self, $tab, $param) = @_;
	$self->add($tab, $param)->last_id;
}

# добавляет одну запись в таблицу
sub add {
	my ($self, $tab, $param, $replace, $ansi) = @_;
	my $INSERT = $replace? "REPLACE": "INSERT";
	my $sql;
	if(defined($param) and 0!=keys %$param) {
		if($ansi) {
			my $SET = $self->INS_SET([[values %$param]]);
			$sql = join "", "$INSERT INTO ", $self->word($tab), " (", join(", ", $self->FIELDS([keys %$param])), ") VALUES ", $SET;
		} else {
			my $SET = $self->DO_SET($param);
			$sql = join "", "$INSERT INTO ", $self->word($tab), " SET ", $SET;
		}
	} else {
		$sql = join "", "$INSERT INTO ", $self->word($tab), " () VALUES ()";
	}
	$self->{last_id} = undef;
	$self->{last_count} = $self->do($sql) + 0;
	$self
}


# добавляет много записей в таблицу
sub insert {
	my ($self, $tab, $fields, $matrix) = @_;
	my $SET = $self->INS_SET($matrix);
	my $sql = join "", "INSERT INTO ", $self->word($tab), " (", join(", ", $self->FIELDS($fields)), ") VALUES ", $SET;
	$self->{last_id} = undef;
	$self->{last_count} = $self->do($sql)+0;
	$self
}


# добавляет или изменяет запись основываясь на наличии id в параметрах
sub save {
	my ($self, $tab, $param) = @_;
	if(my $id = $param->{id}) {
		delete $param->{id};
		$self->update($tab, $param, $id);
		$self->{last_id} = $id;
	} else {
		$self->add($tab, $param);
	}
	return $self;
}

# добавляет или изменяет первую попавщуюся запись
# sub replace {
	# my ($self, $tab, $param) = @_;
	# my $id = $self->query($tab, "id", $param, "LIMIT 1");
	# if($id) {
		# delete $param->{id};
		# $self->update($tab, $param, $id);
		# $self->{last_id} = $id;
	# } else {
		# $self->add($tab, $param);
	# }
	# return $self;
# }

# добавляет или изменяет первую попавщуюся запись
sub replace {
	my ($self, $tab, $param) = @_;
	$self->add($tab, $param, 1);
}


# добавляет или изменяет первую попавщуюся запись
sub store {
	my ($self, $tab, $param) = @_;
	my $id;
	if(ref($param) and ($id = $param->{id}) and $self->query($tab, "1", $id)) {
		delete $param->{id};
		$self->update($tab, $param, $id);
		$self->{last_id} = $id;
	} else {
		$self->add($tab, $param);
	}
	return $self;
}

# начинает транзакцию
sub begin {
	my ($self) = @_;
	
	$self->{transaction}++, return $self if $self->{transaction};
	
	$self->pool;
	
	die "begin: нет dbh" if !$self->{dbh};
	
	$self->{dbh}{AutoCommit} = 0;
	$self->{transaction} = 1;
	
	$self
}

# коммит
sub commit {
	my ($self) = @_;
	
	#msg1 "commit", $self->{transaction};
	
	$self->{transaction}--, return $self if $self->{transaction} > 1;

	$self->{transaction} = 0;
	
	die "commit: нет dbh" if !$self->{dbh};
	
	$self->{dbh}{AutoCommit} = 1;
	
	$self->release;
	
	$self
}

# откат транзакции
sub rollback {
	my ($self) = @_;
	
	#msg1 "rollback", $self->{transaction};
	
	$self->{transaction}--, return $self if $self->{transaction} > 1;
	
	local $@;
	eval { $self->{dbh}->rollback };

	$self->{transaction} = 0;

	if(my $dbh = $self->{dbh}) {
		$dbh->{AutoCommit} = 1;
		$self->release;
	}
	
	$self
}

# транзакция
sub transaction {
	my ($self, $eval, $block);
	if(@_ == 2) { ($self, $block) = @_; }
	else { ($self, $eval, $block) = @_; }
	
	$self->begin;

	eval {
		$block->();
		$self->commit;
	};
	
	if($@) {
		$self->rollback;		
		die $@ if !$eval;
	}
	
	$self
}


# # перечисление столбцов
# sub index {
	# my ($self) = @_;
	# my $c = $self->connect;
	# my $field = $self->{fieldset}{field};
	# "(" . join(", ", map {$c->word($field->{$_}{col})} @{$self->{idx}}) . ")"
# }

# # для тела таблицы
# sub sql {
	# my ($self) = @_;
	# my $c = $self->connect;
	# "$self->{type} ". $c->word($self->{name}) . $self->index
# }

# # изменение ключа
# sub alter {
	# my ($self, $tab, $op, ) = @_;
	# "ALTER TABLE " . $c->word($self->tab) . " ADD " . $self->sql
# }

# # удаление ключа
# sub drop {
	# my ($self, $tab, $name) = @_;
	# my $c = $self->connect;
	# "ALTER TABLE " . $c->word($tab // $self->tab) . " DROP INDEX " . $c->word($name // $self->name);
# }


# создаёт таблицу, столбец, индекс или ключ
# например:
#	create("test_tab")
#	create("test_tab.col_a", "int default 0")
#	create("test_tab.col_a", "int default 0")
#	create("test_tab:idx_a", "col1", "col2")
#	create("test_tab:idx_a:unique", "col1")
#	create("test_tab:fk_a:fk", "tab1", "col1")
#	create("test_tab:fk_b:fk", "tab2") - по умолчанию - колумн id
sub create {
	my ($self) = @_;
	todo;
	$self->do( $self->alter_create(@_) );
}

# удаляет таблицу, столбец, индекс или ключ
sub drop {
	my ($self) = @_;
	todo;
	$self->do( $self->alter_drop(@_) );
}

# изменяет опции таблицы, столбец, индекс или ключ
sub alter {
	my ($self) = @_;
	todo;
	$self->do( $self->alter_alter(@_) );
}

# переименовывает таблицу или столбец, если первый параметр "таблица.столбец"
# или индекс, если "tab:индекс", так же fk
sub rename {
	my $self = shift;
	$self->do( $self->alter_rename(@_) );
}

# возвращает sql для создания
sub alter_create {
	my ($self, $from, $info) = @_;
	
	if($from =~ /\./) {
		$self->alter_create_col($`, $', $info);
	} elsif($from =~ /:/) {
		my ($tab, $idx, $type) = split /:/, $from;
		$type //= "index";
		if($type ne "fk") {
			$self->alter_create_idx($tab, $idx, $type, $info, @_[3..$#_]);
		} else {
			$self->alter_create_fk($tab, $idx, $info, @_[3..$#_]);
		}
	} else {
		$self->alter_create_tab($from, $info);
	}
}

# возвращает sql для удаления
sub alter_drop {
	my ($self, $from) = @_;
	
	if($from =~ /\./) {
		$self->alter_drop_col($`, $');
	} elsif($from =~ /:/) {
		my ($tab, $idx) = ($`, $');
		if($self->index_info->{$tab}{$idx}) {
			$self->alter_drop_idx($tab, $idx);
		} else {
			$self->alter_drop_fk($tab, $idx);
		}
	} else {
		$self->alter_drop_tab($from);
	}
}

# возвращает sql для модификации
sub alter_alter {
	my ($self, $from, $info) = @_;
	
	if($from =~ /\./) {
		$self->alter_alter_col($`, $', $info);
	} elsif($from =~ /:/) {
		my ($tab, $idx) = ($`, $');
		if($self->index_info->{$tab}{$idx}) {
			$self->alter_alter_idx($tab, $idx, $info, @_[3..$#_]);
		} else {
			$self->alter_alter_fk($tab, $idx, $info, @_[3..$#_]);
		}
	} else {
		$self->alter_alter_tab($from, $info);
	}
}

# возвращает sql для переименования
sub alter_rename {
	my ($self, $from, $to) = @_;
	
	if($from =~ /\./) {
		$self->alter_rename_col($`, $', $to);
	} elsif($from =~ /:/) {
		my ($tab, $idx) = ($`, $');
		if($self->index_info->{$tab}{$idx}) {
			$self->alter_rename_idx($tab, $idx, $to);
		} else {
			$self->alter_rename_fk($tab, $idx, $to);
		}
	} else {
		$self->alter_rename_tab($from, $to);
	}
}

# переименовать таблицу
sub alter_rename_tab {
	my ($self, $from, $to) = @_;
	join "", "ALTER TABLE ", $self->word($from), " RENAME TO ", $self->word($to);
}

# переименовать столбец
sub alter_rename_col {
	my ($self, $tab, $col, $to) = @_;
	my $sql = $self->alter_info($tab, $col);
	join "", "ALTER TABLE ", $self->word($tab), " CHANGE ", $self->word($col), " ", $self->word($to), " ", $sql;
}

# возвращает колумн из info без названия столбца
sub alter_info {
	my ($self, $tab, $col) = @_;
	my $sql = ref $tab? $tab: $self->info->{$tab}{$col};
	my $column_type = $self->{column_type};
	($sql? (($column_type->{$sql->{column_type}} || $sql->{column_type} || "").
	($sql->{is_nullable} eq "YES" || $sql->{column_key} =~ /PRI/? "": " NOT NULL").
	(defined($sql->{column_default})? " DEFAULT $sql->{column_default}": "").
	($sql->{column_key} =~ /PRI/? " PRIMARY KEY": "").
	($sql->{extra} ne ""? uc " $sql->{extra}": "")): "")
}

# формирует индекс без его названия
sub sql_index {
	my $self = shift;
	join "", "(", join(", ", map { $self->word($_) } @_), ")";
}

# формирует индекс из info
sub alter_index {
	my ($self, $tab, $name) = @_;
	my $idx = $self->index_info->{$tab}{$name};
	join "", $idx->[0]{type}, " ", $self->sql_index( map {$_->{col}} @$idx )
}

# переименовывает индекс
sub alter_rename_idx {
	my ($self, $tab, $from, $to) = @_;
	my $idx = $self->index_info->{$tab}{$from};
	my $col = join ", ", map { $self->word($_->{col}) } @$idx;
	join "", "ALTER TABLE ", $self->word($tab), " DROP INDEX ", $self->word($from), ", ADD ", $idx->[0]{type}, " ", $self->word($to), "(", $col, ")"
}

# переименовывает fk
sub alter_rename_fk {
	my ($self, $tab, $from, $to) = @_;
	my $fk = $self->fk_info->{$tab}{$from};
	my $col = join ", ", map { $self->word($_->{col}) } $fk->{col};
	join "", "ALTER TABLE ", $self->word($tab), " DROP FOREIGN KEY ", $self->word($from), ", ADD CONSTRAINT ", $self->word($to), " FOREIGN KEY (", $self->word($fk->{col}), ") REFERENCES ", $self->word($tab), " (", join(", ", map {$self->word($_)} $self->{fk}{col}), ")", &ON_DELETE, &ON_UPDATE, $self->word($to), "(", $col, ")"
}

# изменить таблицу
sub alter_alter_tab {
	my ($self, $tab, $options) = @_;
	join "", "ALTER TABLE ", $self->word($tab), " ", $options
}

# изменить столбец
sub alter_alter_tab {
	my ($self, $tab, $col, $def, $after) = @_;
	$def = $self->alter_info($def) if ref $def;
	join "", "ALTER TABLE ", $self->word($tab), " MODIFY COLUMN ", $self->word($col), " ", $def, ($after==1? " FIRST": $after? (" AFTER ", $self->word($after)): ())
}


# изменить индекс
sub alter_alter_idx {
	my ($self, $tab, $name, @col) = @_;
	join "", "ALTER TABLE ", $self->word($tab), " alter INDEX ", $self->word($name)
}

# изменить ключ
sub alter_alter_fk {
	my ($self, $tab, $name) = @_;
	join "", "ALTER TABLE ", $self->word($tab), " alter FOREIGN KEY ", $self->word($name)
}



# удалить таблицу
sub alter_drop_tab {
	my ($self, $tab) = @_;
	join "", "DROP ", $self->word($tab)
}

# удалить столбец
sub alter_drop_tab {
	my ($self, $tab, $col) = @_;
	join "", "ALTER TABLE ", $self->word($tab), " DROP COLUMN ", $self->word($col)
}

# удалить индекс
sub alter_drop_idx {
	my ($self, $tab, $name) = @_;
	join "", "ALTER TABLE ", $self->word($tab), " DROP INDEX ", $self->word($name)
}

# удалить ключ
sub alter_drop_fk {
	my ($self, $tab, $name) = @_;
	join "", "ALTER TABLE ", $self->word($tab), " DROP FOREIGN KEY ", $self->word($name)
}


1;