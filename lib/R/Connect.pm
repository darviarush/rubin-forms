package R::Connect;
# подключение к базе и простенькие функции для запросов

use strict;
use warnings;

use DBI;
use POSIX qw/strftime/;


our $CURR_SQL;

# зарезервированные слова sql
our %SQL_WORD = (
mysql => {Utils::set(qw/ACCESSIBLE	 ADD	 ALL	 ALTER	 ANALYZE	 AND	 AS	 ASC	 ASENSITIVE	 BEFORE	 BETWEEN	 BIGINT	 BINARY	 BLOB	 BOTH	 BY	 CALL	 CASCADE	 CASE	 CHANGE	 CHAR	 CHARACTER	 CHECK	 COLLATE	 COLUMN	 CONDITION	 CONSTRAINT	 CONTINUE	 CONVERT	 CREATE	 CROSS	 CURRENT_DATE	 CURRENT_TIME	 CURRENT_TIMESTAMP	 CURRENT_USER	 CURSOR	 DATABASE	 DATABASES	 DAY_HOUR	 DAY_MICROSECOND	 DAY_MINUTE	 DAY_SECOND	 DEC	 DECIMAL	 DECLARE	 DEFAULT	 DELAYED	 DELETE	 DESC	 DESCRIBE	 DETERMINISTIC	 DISTINCT	 DISTINCTROW	 DIV	 DOUBLE	 DROP	 DUAL	 EACH	 ELSE	 ELSEIF	 ENCLOSED ESCAPED	 EXISTS	 EXIT	 EXPLAIN	 FALSE	 FETCH	 FLOAT	 FLOAT4	 FLOAT8	 FOR	 FORCE	 FOREIGN	 FROM FULLTEXT	 GENERAL GRANT	 GROUP	 HAVING	 HIGH_PRIORITY	 HOUR_MICROSECOND	 HOUR_MINUTE	 HOUR_SECOND	 IF	 IGNORE	 IGNORE_SERVER_IDS IN	 INDEX	 INFILE	 INNER	 INOUT	 INSENSITIVE	 INSERT	 INT	 INT1	 INT2	 INT3	 INT4	 INT8	 INTEGER	 INTERVAL	 INTO	 IS	 ITERATE	 JOIN	 KEY	 KEYS	 KILL	 LEADING	 LEAVE	 LEFT	 LIKE	 LIMIT	 LINEAR	 LINES	 LOAD	 LOCALTIME	 LOCALTIMESTAMP	 LOCK	 LONG	 LONGBLOB	 LONGTEXT	 LOOP	 LOW_PRIORITY	 MASTER_HEARTBEAT_PERIOD MASTER_SSL_VERIFY_SERVER_CERT	 MATCH	 MAXVALUE MEDIUMBLOB	 MEDIUMINT	 MEDIUMTEXT	 MIDDLEINT	 MINUTE_MICROSECOND	 MINUTE_SECOND	 MOD	 MODIFIES	 NATURAL	 NOT	 NO_WRITE_TO_BINLOG	 NULL	 NUMERIC	 ON	 OPTIMIZE	 OPTION	 OPTIONALLY	 OR	 ORDER	 OUT	 OUTER	 OUTFILE	 PARTITION PRECISION	 PRIMARY	 PROCEDURE	 PURGE	 RANGE	 READ	 READS	 READ_WRITE	 REAL REFERENCES	 REGEXP	 RELEASE	 RENAME	 REPEAT	 REPLACE	 REQUIRE	 RESIGNAL RESTRICT	 RETURN	 REVOKE	 RIGHT	 RLIKE	 SCHEMA	 SCHEMAS	 SECOND_MICROSECOND	 SELECT	 SENSITIVE	 SEPARATOR	 SET	 SHOW	 SIGNAL SLOW SMALLINT	 SPATIAL	 SPECIFIC	 SQL	 SQLEXCEPTION	 SQLSTATE	 SQLWARNING	 SQL_BIG_RESULT	 SQL_CALC_FOUND_ROWS	 SQL_SMALL_RESULT	 SSL	 STARTING	 STRAIGHT_JOIN	 TABLE	 TERMINATED	 THEN	 TINYBLOB	 TINYINT	 TINYTEXT	 TO	 TRAILING	 TRIGGER	 TRUE	 UNDO	 UNION	 UNIQUE	 UNLOCK	 UNSIGNED	 UPDATE	 USAGE	 USE	 USING	 UTC_DATE	 UTC_TIME	 UTC_TIMESTAMP	 VALUES	 VARBINARY	 VARCHAR	 VARCHARACTER	 VARYING	 WHEN	 WHERE	 WHILE	 WITH	 WRITE	 XOR	 YEAR_MONTH	 ZEROFILL
GENERATED	GET	IO_AFTER_GTIDS	IO_BEFORE_GTIDS MASTER_BIND OPTIMIZER_COSTS PARSE_GCOL_EXPR STORED VIRTUAL/)}
);


sub new {
	my ($cls, $app) = @_;
	my ($sql_word) = $app->ini->{connect}{DNS} =~ /^dbi:(\w+)/i;
	my $self = bless { app => $app, sql_word => $SQL_WORD{lc $sql_word} }, $cls;
	$self->connect
}


# коннект
sub connect {
	my ($self) = @_;
	$self->close if $self->{dbh};
	my $ini = $self->{app}->ini->{connect};
	$self->{dbh} = my $dbh = DBI->connect($ini->{DNS}, $ini->{user}, $ini->{password},
		{RaiseError => 1, PrintError => 0, PrintWarn => 0});
	my $collate = $ini->{charset} // "utf8_unicode_ci";
	my ($charset) = $collate =~ /^([^_]+)/;
	$self->do("SET NAMES " . $dbh->quote($charset) . ($collate =~ /_/? " COLLATE " . $dbh->quote($collate): ""));
	$self
}

# закрывает соединение
sub close {
	my ($self) = @_;
	$self->{dbh}->disconnect;
	delete $self->{info};
	delete $self->{tab_info};
	delete $self->{index_info};
	delete $self->{fk_info};
	delete $self->{fk_info_backward};
	$self
}

# переконнекчивается, если связь утрачена
sub reconnect {
	my ($self) = @_;
	if($self->{dbh}) {
		return $self if $self->{dbh}->ping;
		$self->close;
	}
	$self->connect
}

# возвращает имя базы данных
sub basename {
	my ($self) = @_;
	$self->{basename} //= ($self->{app}->ini->{connect}{DNS} =~ /database=(\w+)/ and $1)
}

# возвращает dbh
sub dbh { $_[0]->{dbh} }

# возвращает app
sub app { $_[0]->{app} }

# кеширует инф. о таблицах
sub tab_info {
	my ($self) = @_;
	$self->{tab_info} //= $self->get_tab_info;
}

# возвращает информацию о таблицах
sub get_tab_info {
	my ($self) = @_;
	my $dbh = $self->{dbh};
	my $sql = "select table_name as name, engine, table_collation as charset, table_comment as remark, create_options as options
		from information_schema.tables
		where table_schema=".$self->quote($self->basename);
	my $rows = $dbh->selectall_arrayref($sql, {Slice=>{}});
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
	my $dbh = $self->{dbh};
	my $sql = "select table_name, column_name, data_type, column_type, column_default, is_nullable, character_maximum_length, extra, column_key, ordinal_position
		from information_schema.columns
		where table_schema=".$self->quote($self->basename);
	my $rows = $dbh->selectall_arrayref($sql, {Slice=>{}});
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
	my $tab_info = $self->get_tab_info;
	my $fk_info = $self->get_fk_info;
	my $info = {};
	while(my ($tab, $in) = each %$tab_info) {
		my $sql = "SHOW KEYS FROM " . $self->word($tab);
		my $rows = $self->{dbh}->selectall_arrayref($sql, {Slice=>{}});

		for my $row (@$rows) {
			next if exists $fk_info->{$tab}{$row->{Key_name}};

			%$row = map {(($rename{$_} // $_) => $row->{$_})} keys %$row;
			
			my $idx = $info->{$row->{tab}}{$row->{name}} //= [];
			push @$idx, $row;
		}
	}
	return $info;
}

# без кеширования
# sub get_index_info {
	# my ($self) = @_;
	# my $sql = "SELECT table_name as tab,column_name as col,constraint_name as name,ordinal_position as pos
# FROM information_schema.KEY_COLUMN_USAGE
# WHERE TABLE_SCHEMA=" . $self->quote($self->basename) . "
# AND referenced_column_name IS null";
	# my $rows = $self->dbh->selectall_arrayref($sql, {Slice=>{}});
	# my $info = {};
	# for my $row (@$rows) {
		# my $idx = $info->{$row->{tab}}{$row->{name}} //= [];
		# push @$idx, $row;
	# }
	# return $info;
# }


# кеширует информацию о внешних ключах таблиц
sub fk_info {
	my ($self) = @_;
	return $self->{fk_info} if $self->{fk_info};
	$self->get_fk_info;
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
	$self->get_fk_info;
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
	my $rows = $self->dbh->selectall_arrayref($sql, {Slice=>{}});
	my $info = {};
	my $bk = $self->{fk_info_backward} = {};
	for my $row (@$rows) {
		$info->{$row->{tab}}{$row->{name}} = $row;
		$bk->{$row->{ref_tab}}{$row->{name}} = $row;
	}
	return $info;
}


# возвращает текущее время в формате базы
sub now { main::msg 'nnn?', @_[1..$#_]; strftime("%F %T", @_>1? localtime @_[1..$#_]: localtime) }


# оборачивает в `` если нужно
sub word {
	my ($self, $col) = @_;
	exists $self->{sql_word}{uc $col}? "`$col`": $col;
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

# квотирование
sub quote {
	my ($self, $s) = @_;
	!defined($s)? "NULL":
	ref($s)? do {
		ref $s eq "ARRAY"? do {
			my %x = map { ($_=>$_) } @$s;
			"(".join(",", map{$self->quote($x{$_})} keys %x).")"
		}:
		Utils::isa($s, "R::Model::Row")? $s->id:
		die("не могу приобразовать ссылку в quote: `$s`");
	}:
	$s =~ /^-?(?:[1-9]\d*|0)(?:\.\d+)?$/? $s:
	$self->{dbh}->quote($s)
}

# формирует ключ=значение через запятую, для UPDATE SET или REPLACE SET
sub DO_SET {
	my ($self, $p, $as) = @_;
	my @set = ();
	while(my($a, $b) = each %$p) {
		push @set, join("",
			$self->SQL_COL($a, $as), "=", (
				ref $b eq 'HASH'? scalar($self->replace($self->TAB_ref($a), $b)):
				ref $b eq "SCALAR"? (ref $$b eq "SCALAR"? $$$b: $self->SQL_COL($$b, $as)):
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
	my $sql = join "", "SELECT ", join(", ", @view), "${sep}FROM ", $tab, $self->query_add($sep, \@args);
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
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute;
	my $rows = [];
	while(my $row = $sth->fetchrow_arrayref) {
		$self->pack_rows($fields, $rows, $row);
	}
	$sth->finish;
	
	return {
		fields => $real_fields,
		rows => $rows
	};
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

# запрашивает строку
sub query {
	my ($self) = @_;
	$CURR_SQL = sel(@_);
	my @row = $self->{dbh}->selectrow_array($CURR_SQL);
	$self->log(wantarray? \@row: $row[0]);
	$CURR_SQL = undef;
	return wantarray? @row: $row[0];
}

# запрашивает строки
sub query_all {
	my ($self) = @_;
	$CURR_SQL = sel @_;
	my $row = $self->{dbh}->selectall_arrayref($CURR_SQL, {Slice=>{}});
	$self->log($row);
	$CURR_SQL = undef;
	$row
}

# массив значений
sub query_col {
	my ($self) = @_;
	$CURR_SQL = sel @_;
	my $row = $self->{dbh}->selectcol_arrayref($CURR_SQL);
	$self->log($row);
	$CURR_SQL = undef;
	$row
}

# строка в виде хеша
sub query_ref {
	my $x = query_all(@_);
	$x->[0];
}

# логирует, если нужно
sub log {
	my ($self, @args) = @_;
	main::msg ":inline", ":empty", $self->syntax($CURR_SQL), (@args? (":red", " -> ", ":reset", ":sep", @args): ()) if $self->{app}->ini->{site}{'log-level'} >= 1;
}

our $COLOR_NUM = ":cyan";
our $COLOR_WORD = ":magenta";
our $COLOR_STR = ":green";
our $COLOR_DO = ":yellow";

# подсветка синтаксиса
sub syntax {
	my ($self, $sql) = @_;
	#my $words = $self->{sql_word}; $words->{uc $_}
	map { ((/^\d+$/? $COLOR_NUM: /^['"]/? $COLOR_STR: /^[A-Z\d_]+$/? $COLOR_WORD: ":reset"), $_) } split /(\w+|'(?:\\'|[^'])*'|"(?:\\"|[^"])*")/, $sql;
}

# id последней добавленной записи
sub last_id {
	my ($self) = @_;
	return $self->{last_id} // $self->{dbh}->selectrow_array("SELECT LAST_INSERT_ID()");
}

# количество изменённых строк последней операцией редактирования
sub last_count { $_[0]->{last_count} }

# выполняет sql-запрос
sub do {
	my ($self, $sql) = @_;
	$CURR_SQL = $sql;
	my $ret = $self->{dbh}->do($CURR_SQL);
	my $cw = $COLOR_WORD;
	$COLOR_WORD = $COLOR_DO;
	$self->log($COLOR_NUM, ($ret == 1? (): $ret), ($CURR_SQL =~ /^\s*INSERT\b/i? $self->last_id: ()));
	$COLOR_WORD = $cw;
	$CURR_SQL = undef;
	$ret
}

# удаляет записи из таблицы
sub erase {
	my ($self, $tab, $where) = @_;
	my $cond = $self->DO_WHERE($where);
	$CURR_SQL = join "", "DELETE FROM ", $self->word($tab), " WHERE ", $cond;
	$self->{last_count} = $self->do($CURR_SQL) + 0;
	$self
}

# добавляет одну запись в таблицу
sub add {
	my ($self, $tab, $param) = @_;
	if(defined($param) and 0!=keys %$param) {	
		my $SET = $self->DO_SET($param);
		$CURR_SQL = join "", "INSERT INTO ", $self->word($tab), " SET ", $SET;
	} else {
		$CURR_SQL = join "", "INSERT INTO ", $self->word($tab), " () VALUES ()";
	}
	$self->{last_id} = undef;
	$self->{last_count} = $self->do($CURR_SQL) + 0;
	$self
}

# добавляет одну запись в таблицу и возвращает её id
sub append {
	my ($self, $tab, $param) = @_;
	$self->add($tab, $param)->last_id;
}


# добавляет много записей в таблицу
sub insert {
	my ($self, $tab, $fields, $matrix) = @_;
	my $SET = $self->INS_SET($matrix);
	$CURR_SQL = join "", "INSERT INTO ", $self->word($tab), " (", join(", ", $self->FIELDS($fields)), ") VALUES ", $SET;
	$self->{last_id} = undef;
	$self->{last_count} = $self->do($CURR_SQL)+0;
	$self
}

# изменяет запись
sub update {
	my ($self, $tab, $param, $where, $opt) = @_;
	my $SET = $self->DO_SET($param);
	my $COND = $self->DO_WHERE($where);
	my $from;
	if(ref $tab) {
		if(@$tab == 1) { $tab = $tab->[0]; }
		else {
			$from = $tab;
			($tab) = $from->[0] =~ /As\s+(.+?)$/;
		}
	}
	$CURR_SQL = join "", "UPDATE ", $self->word($tab), " SET ", $SET, ($from? join("\n", @$from) . "\n": " "), "WHERE ", $COND, (defined($opt)? " $opt": ());
	$self->{last_count} = $self->do($CURR_SQL)+0;
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
	my $SET = $self->DO_SET($param);
	$CURR_SQL = join "", "REPLACE ", $self->word($tab), " SET ", $SET;
	$self->{last_id} = $param->{id};
	$self->{last_count} = $self->do($CURR_SQL)+0;
	$self
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


# поиск
our $ABC = {qw(а А б Б в В г Г д Д е Е ё Е Ё Е ж Ж з З и И й Й к К л Л м М н Н о О п П р Р с С т Т у У ф Ф х Х ц Ц ч Ч ш Ш щ Щ ъ Ъ ы Ы ь Ь э Э ю Ю я Я)};
our $ABCx = join "|", %$ABC;

# фразу разбивает на слова для поиска
sub build_words {
	my ($u) = @_;
	local ($`, $', $&);

	my @z = ();
	while($u =~ /(\d+|($ABCx)+|[A-Za-z]+)/go) {
		my $z = $1;
		$z =~ tr/a-z/A-Z/;
		$z =~ s/а|б|в|г|д|е|ё|Ё|ж|з|и|й|к|л|м|н|о|п|р|с|т|у|ф|х|ц|ч|ш|щ|ъ|ы|ь|э|ю|я/$ABC->{$&}/g;
		if($z =~ s/^([\x80-\xFF]{4,})(АМИ|ЯМИ|УМЯ|ЕГО|ОГО|ОМУ|ЕМУ|ЫМИ|ИМИ|ЕШЬ|ИШЬ|ЕТЕ|ИТЕ|ЕТЬ|ИТЬ|АТЬ|ЯТЬ|ОСЬ|ОСЯ|ЕТЕ|ИТЕ)$/$1/){}
		elsif($z =~ s/^([\x80-\xFF]{4,})(ЕМ|ОМ|ОЮ|ОВ|ЕЮ|ОЙ|ЕЙ|ЬЮ|ЬИ|ИЙ|ЫЙ|ИИ|ИЯ|ЫЯ|АМ|ЯМ|АХ|ЯХ|ЯЯ|АЯ|ОЕ|ЕЕ|ОМ|ЕМ|ЮЮ|ЮУ|ЫМ|ИМ|ЕЙ|ЫЕ|ИЕ|ЫХ|ИХ|СЯ|СЬ|ТЕ|АЮ|УЮ|ЕТ|ИТ|ЕМ|ИМ|УТ|ЮТ|АТ|ЯТ|ИТ|ШЬ|СТ)$/$1/){}
		elsif($z =~ s/^([\x80-\xFF]{4,})(А|Я|О|У|Ю|Е|И|Ы|Ь)$/$1/){}
		elsif($z =~ s/^([A-Z]{2,})(ES|S|E|ED|ING|ER)$/$1/){}
		push @z, $z;
	}
	return @z;
}

# добавляет слова в таблицу words, если их там нет и возвращает их идентификаторы
sub set_words {
	my $self = shift;
	my $dbh = $self->{dbh};
	
	
	my @words = build_words(@_);

	my %word_id;
	for my $word (@words) {
		my $word_id = $dbh->selectrow_array("SELECT word_id FROM words WHERE word=?", undef, $word);
		add("word", {word=>$word}), $word_id = $dbh->selectrow_array("SELECT last_insert_id()") unless $word_id;
		$word_id{$word_id} = 1;
	}
	return keys %word_id;
}

# возвращает word_id для тех слов в фразе, которые есть в words
sub get_words {
	my ($self, $phrase) = @_;
	my $dbh = $self->{dbh};
	
	my @words = build_words($phrase);
	my @word_id;
	for my $word (@words) {
		my $word_id = $dbh->selectrow_array("SELECT word_id FROM words WHERE word=?", undef, $word);
		push @word_id, $word_id if $word_id;
	}
	return @word_id;
}


1;