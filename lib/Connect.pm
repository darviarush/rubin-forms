
use DBI;

our $dbh;

# коннект
sub dbh_connect {
	$dbh->disconnect if $dbh;
	my $myini = $ini->{mysql};
	$dbh = DBI->connect($myini->{DNS}, $myini->{user}, $myini->{password},
		{RaiseError => 1, PrintError => 0, PrintWarn => 0});
	$dbh->do("SET NAMES utf8");
}

# коннектится и считывает в $_info
sub dbh_connect_full {
	dbh_connect();
	our $_info = get_info();
}

dbh_connect_full() if $ini->{mysql}{DNS};


# зарезервированные слова sql
%SQL_WORD = Utils::set(qw/ACCESSIBLE ADD ALL ALTER ANALYZE AND AS ASC ASENSITIVE BEFORE BETWEEN BIGINT BINARY BLOB BOTH BY CALL CASCADE CASE CHANGE CHAR CHARACTER CHECK COLLATE COLUMN CONDITION CONSTRAINT CONTINUE CONVERT CREATE CROSS CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER CURSOR DATABASE DATABASES DAY_HOUR DAY_MICROSECOND DAY_MINUTE DAY_SECOND DEC DECIMAL DECLARE DEFAULT DELAYED DELETE DESC DESCRIBE DETERMINISTIC DISTINCT DISTINCTROW DIV DOUBLE DROP DUAL EACH ELSE ELSEIF ENCLOSED ESCAPED EXISTS EXIT EXPLAIN FALSE FETCH FLOAT FLOAT4 FLOAT8 FOR FORCE FOREIGN FROM FULLTEXT GET GRANT GROUP HAVING HIGH_PRIORITY HOUR_MICROSECOND HOUR_MINUTE HOUR_SECOND IF IGNORE IN INDEX INFILE INNER INOUT INSENSITIVE INSERT INT INT1 INT2 INT3 INT4 INT8 INTEGER INTERVAL INTO IO_AFTER_GTIDS IO_BEFORE_GTIDS IS ITERATE JOIN KEY KEYS KILL LEADING LEAVE LEFT LIKE LIMIT LINEAR LINES LOAD LOCALTIME LOCALTIMESTAMP LOCK LONG LONGBLOB LONGTEXT LOOP LOW_PRIORITY MASTER_BIND MASTER_SSL_VERIFY_SERVER_CERT MATCH MAXVALUE MEDIUMBLOB MEDIUMINT MEDIUMTEXT MIDDLEINT MINUTE_MICROSECOND MINUTE_SECOND MOD MODIFIES NATURAL NONBLOCKING NOT NO_WRITE_TO_BINLOG NULL NUMERIC ON OPTIMIZE OPTION OPTIONALLY OR ORDER OUT OUTER OUTFILE PARTITION PRECISION PRIMARY PROCEDURE PURGE RANGE READ READS READ_WRITE REAL REFERENCES REGEXP RELEASE RENAME REPEAT REPLACE REQUIRE RESIGNAL RESTRICT RETURN REVOKE RIGHT RLIKE SCHEMA SCHEMAS SECOND_MICROSECOND SELECT SENSITIVE SEPARATOR SET SHOW SIGNAL SMALLINT SPATIAL SPECIFIC SQL SQLEXCEPTION SQLSTATE SQLWARNING SQL_BIG_RESULT SQL_CALC_FOUND_ROWS SQL_SMALL_RESULT SSL STARTING STRAIGHT_JOIN TABLE TERMINATED THEN TINYBLOB TINYINT TINYTEXT TO TRAILING TRIGGER TRUE UNDO UNION UNIQUE UNLOCK UNSIGNED UPDATE USAGE USE USING UTC_DATE UTC_TIME UTC_TIMESTAMP VALUES VARBINARY VARCHAR VARCHARACTER VARYING WHEN WHERE WHILE WITH WRITE XOR YEAR_MONTH ZEROFILL/);

sub SQL_WORD(@) {
	my ($col) = @_;
	exists $SQL_WORD{uc $col}? "`$col`": $col;
}

# формирует колумн
sub SQL_COL (@) {
	my ($col, $as) = @_;
	join "", ($as? (SQL_WORD($as), "."): ()), SQL_WORD($col);
}

sub TAB_ref (@) {
	my ($col) = @_;
	$col =~ s/_id$//;
	$_alias_tab{$col} || $col;
}

# формирует ключ=значение через запятую, для UPDATE SET или REPLACE SET
sub DO_SET (@) {
	my ($p, $as) = @_;
	my ($a, $b, @set) = ();
	push @set, join("", SQL_COL($a, $as), "=", (ref $b eq 'HASH'? scalar(replace(TAB_ref($a), $b)): ref $b eq "SCALAR"? (ref $$b eq "SCALAR"? $$$b: SQL_COL($$b, $as)): $dbh->quote($b))) while ($a, $b) = each %$p;
	return wantarray? @set: join(",", @set);
}

# формирует where
sub DO_WHERE {
	my ($where, $as) = @_;

	if(ref $where) {
		my @SET = DO_SET($where, $as);
		return join(" AND ", @SET);
	}

	return $where =~ /^\d+$/? SQL_COL('id', $as).'='.$dbh->quote($where): $where;
}

# формирует матрицу значений для INSERT
sub INS_SET {
	my ($m) = @_;
	my $set = join ",", map {join "", "(", join(",", map {$dbh->quote($_)} @$_), ")"} @$m;
	return $set;
}

# формирует столбцы
sub FIELDS ($) {
	my ($fields) = @_;
	return map { SQL_WORD($_) } @$fields if ref $fields eq "ARRAY";
	return map { ($fields->{$_}, ' as ', SQL_WORD($_)) } keys %$fields if ref $fields eq "HASH";
	return $fields;
}

# возвращает массив названий столбцов
sub FIELDS_NAMES ($) {
	my ($fields) = @_;
	return @$fields if ref $fields eq "ARRAY";
	return keys %$fields if ref $fields eq "HASH";
	return split /,\s*/, $fields;
}

# формирует столбцы с таблицей
sub FOR_TAB_FIELDS ($$) {
	my ($fields, $as) = @_;
	$as = SQL_WORD($as);
	return map { ($as.".".SQL_WORD($_)) } @$fields if ref $fields eq "ARRAY";
	return map { ($as.".".$fields->{$_}, ' as ', SQL_WORD($_)) } keys %$fields if ref $fields eq "HASH";
	return map { $as.".".SQL_WORD($_) } split /,\s*/, $fields;
}

# возвращает таблицу и её алиас, если он указан
sub TAB {
	return ($2, $1) if $_[0] =~ /^\s*(\w+)\s+(?:as\s+)?(\w+)\s*$/i;
	($_[0], $_[0]);
}

# выборки
sub sel (@) {
	my ($tab, $view, @args) = @_;
	join "", "SELECT ", FIELDS($view), " FROM ", SQL_WORD($tab), CONS::add(\@args, " ");
}

package JOIN;
sub new { my ($cls, $join, @args) = @_; my ($tab) = @args; my ($as, $tab) = main::TAB($tab); bless {tab => main::SQL_WORD($tab), as => main::SQL_WORD($as), args=>[@args], join=>$join}, $cls; }

package CONS;
sub new { my ($cls, $op, $val) = @_; bless {op=>$op, val=>$val}, $cls }

sub compile {
	my ($self, $push, $as) = @_;
	my $op = $self->{op};
	my $val = $self->{val};
	if($op==1) {	# GROUP
		push @{$push->{group}}, main::FOR_TAB_FIELDS($val, $as);
	} elsif($op==2) { # HAVING
		push @{$push->{having}}, main::DO_WHERE($val, $as);
	} elsif($op==3) { # ORDER
		push @{$push->{order}}, main::FOR_TAB_FIELDS($val, $as);
	} elsif($op==4) { # LIMIT
		die "Один LIMIT уже есть в SQL-запросе" if $push->{limit};
		$push->{limit} = $val->[0].', '.$val->[1];
	} else {
		die "Что-то неясное попало в выражение для select";
	}
}

sub add {
	my ($sep, $args) = @_;
	my $push;
	for my $arg (@$args) {
		if(ref $arg eq 'CONS') { $arg->compile($push) }
		else { push @{$push->{where}}, main::DO_WHERE($arg) }
	}
	CONS::join($push, $sep);
}

sub join {
	my ($self, $sep) = @_;
	(@{$self->{where}}? ("${sep}WHERE ", join " AND ", map { join "", "(", $_, ")" } @{$self->{where}}): ()), 
	(@{$self->{group}}? ("${sep}GROUP BY ", join ", ", @{$self->{group}}): ()), 
	(@{$self->{having}}? ("${sep}HAVING ", join " AND ", map { join "", "(", $_, ")" } @{$self->{having}}): ()),
	(@{$self->{order}}? ("${sep}ORDER BY ", join ", ", @{$self->{order}}): ()), 
	($self->{limit}? ("${sep}LIMIT ", $self->{limit}): ())
}

package main;

# возвращает объект для джойнов SQL
sub LEFT_JOIN (@) {	JOIN->new('LEFT', @_) }
sub INNER_JOIN (@) { JOIN->new('INNER', @_) }

# понятно
sub GROUP (@) { JOIN->new(1, @_) }
sub HAVING (@) { CONS->new(2, @_) }
sub ORDER (@) { CONS->new(3, @_) }
sub LIMIT (@) { CONS->new(4, @_) }


# выборки
sub sel_join (@) {
	my (@st, @where, @view, @join, $push);
	my ($as_table, $table) = TAB($_[0]);
	my ($fields, $real_fields, $real_new, @cols) = ([], []);
	@st = [[], \@_, $real_fields];
	
	while(@st) {
		my ($path, $args, $real) = @{ pop @st };
		my ($tab, $view, @args) = @$args;
		my ($as, $tab) = TAB($tab);
		push @view, FOR_TAB_FIELDS($view, $as);
		push @$fields, [$path, [ @cols = FIELDS_NAMES($view) ] ];
		push @$real, @cols;
		my @real = ();
		for my $arg (@args) {
			if(ref $arg eq "JOIN") {
				my ($as1, $tab1) = ($arg->{as}, $arg->{tab});
				my $is1 = $as1 eq $tab1;
				unshift @real, $real_new = [$as1];
				push @st, [[@$path, $as1], $arg->{args}, $real_new];
				push @join, join "", "\n", $arg->{join}, " JOIN ", $tab1, (!$is1? (' as ', $as1): ()), " ON ", $as1, '.', ($is1? $as: $as1), "_id=", $as, ".id";
			} elsif(ref $arg eq "CONS") {
				$arg->compile($push, $as);
			} else {
				push @{$push->{where}}, DO_WHERE($arg, $as);
			}
		}
		push @$real, @real;
	}
	my $sql = join "", "SELECT ", join(", ", @view), "\nFROM ", SQL_WORD($table), ($table ne $as_table? (' as ', $as_table): ()), @join, CONS::join($push, "\n");
	
	wantarray? ($sql, $fields, $real_fields): $sql;
}

# пакует строки для передачи клиенту
sub pack_rows (@) {
	my ($fld, $rows_start, $add_row) = @_;
	
	my (@st, $row, $i, $rows);
	my $old_path = -1;
	
	for my $field (@$fld) {
		my ($path, $cols) = @$field;
		
		splice(@st, scalar(@$path)), $st[$#$path] ++ if $old_path == @$path;
		
		$rows = $rows_start;
		$row = $rows->[$#$rows], $rows = ($row->[$_] ||= [[]]) for @st[0..$#$path];
		if( $#$rows == -1 ) { push @$rows, $row = [] } else { $row = $rows->[$#$rows] }
		
		if(not defined $add_row->[$i]) { $i += @$cols; pop @$rows if @$row == 0; msg1 $rows_start if $msg;}
		elsif(@$row == 0) { push @$row, $add_row->[$i++] for @$cols; }
		elsif($add_row->[$i] == $row->[0]) {	# сравниваем id
			$i += @$cols;
		} else {
			push @$rows, $row = [];
			push @$row, $add_row->[$i++] for @$cols;
		}
		
		$st[$old_path = scalar @$path] += scalar @$cols;
	}
}


# запрашивает строки и пакует их в формат для передачи
sub query_rows (@) {
	my ($tab, $view, @args) = @_;
	my ($sql, $fields, $real_fields) = sel_join(@_);
	my $sth = $dbh->prepare($sql);
	$sth->execute;
	my $rows = [];
	while(my $row = $sth->fetchrow_arrayref) {
		pack_rows $fields, $rows, $row;
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
sub quick_rows (@) {
	my ($tab, $view, @args) = @_;
	
	my @join = grep { ref $_ eq 'JOIN' } @args;
	@args = grep { ref $_ ne 'JOIN' } @args;
	
	my ($tab, $view, @a);
	($tab, $view, @a) = @{$_->{args}}, $_->{a} = [@a], $_->{view} = $view for @join;
	
	my $rows = query_all $tab, $view, @args;
	
	for my $row (@$rows) {
		$row->{$_->{as}} = quick_rows($_->{tab}, $_->{view}, $row->{id}, @{$_->{a}}) for @join;
	}
	
	return $rows;
}

# запрашивает строку
sub query (@) {
	my $sql = sel @_;
	$dbh->selectrow_array($sql);
	#msg $sql." val=".join(", ", @x);
	#wantarray? @x: $x[0];
}

# запрашивает строки
sub query_all (@) {
	my $sql = sel @_;
	$dbh->selectall_arrayref($sql, {Slice=>{}});
}

# строка в виде хеша
sub query_ref (@) {
	my $x = query_all(@_);
	$x->[0];
}

# id последней добавленной записи
sub last_id {
	return $dbh->selectrow_array("SELECT LAST_INSERT_ID()");
}

# удаляет записи из таблицы
sub erase ($$) {
	my ($tab, $where) = @_;
	my $cond = DO_WHERE($where);
	my $sql = join "", "DELETE FROM ", SQL_WORD($tab), " WHERE ", $cond;
	$dbh->do($sql) + 0;
}

# добавляет одну запись в таблицу
sub add_only ($;$) {
	my ($tab, $param) = @_;
	my $sql;
	if(%$param) {	
		my $SET = DO_SET($param);
		$sql = join "", "INSERT INTO ", SQL_WORD($tab), " SET ", $SET;
	} else {
		$sql = join "", "INSERT INTO ", SQL_WORD($tab), " () VALUES ()";
	}
	$dbh->do($sql) + 0
}

# добавляет одну запись в таблицу и возвращает её id или 0 в случае неудачи
sub add ($;$) {
	add_only($_[0], $_[1])? last_id(): 0;
}


# добавляет много записей в таблицу
sub insert ($$$) {
	my ($tab, $fields, $matrix) = @_;
	my $SET = INS_SET($matrix);
	my $sql = join "", "INSERT INTO ", SQL_WORD($tab), " (", FIELDS($fields), ") VALUES ", $SET;
	$dbh->do($sql) + 0;
}

# изменяет запись
sub update ($$$) {
	my ($tab, $param, $where) = @_;
	my $SET = DO_SET($param);
	my $COND = DO_WHERE($where);
	my $sql = join "", "UPDATE ", SQL_WORD($tab), " SET ", $SET, " WHERE ", $COND;
	$dbh->do($sql) + 0;
}

# добавляет или изменяет запись
sub replace ($$) {
	my ($tab, $param) = @_;
	if($id = $param->{id}) {
		delete $param->{id};
		$count = update $tab, $param, $id;
	} else {
		$count = add_only $tab, $param;
		$id = last_id();
	}
	return wantarray? ($id, $count): $id;
}


# возвращает информацию о таблицах
sub get_info {
	my $sql = "select table_name, column_name, data_type, column_type, column_default, is_nullable, character_maximum_length, extra, column_key, ordinal_position
		from information_schema.columns
		where table_schema=".$dbh->quote($ini->{mysql}{DNS} =~ /database=(\w+)/ and $1);
	my $rows = $dbh->selectall_arrayref($sql, {Slice=>{}});
	my $info = {};
	
	for my $row (@$rows) {	# создаём info
		$info->{$row->{table_name}}{$row->{column_name}} = $row;
	}
	return $info;
}


$ABC = {qw(а А б Б в В г Г д Д е Е ё Е Ё Е ж Ж з З и И й Й к К л Л м М н Н о О п П р Р с С т Т у У ф Ф х Х ц Ц ч Ч ш Ш щ Щ ъ Ъ ы Ы ь Ь э Э ю Ю я Я)};
$ABCx = join "|", %$ABC;

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
	my ($phrase) = @_;
	my @words = build_words($phrase);
	for my $word (@words) {
		my $word_id = $dbh->selectrow_array("SELECT word_id FROM words WHERE word=?", undef, $word);
		push @word_id, $word_id if $word_id;
	}
	return @word_id;
}


1;