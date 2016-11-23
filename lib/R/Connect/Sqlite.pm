package R::Connect::Sqlite;
# драйвер для СУБД скулат

use base R::Connect;

use common::sense;
use R::App;

# конструктор
sub new {
	my $cls = shift;
	bless {}, ref $cls || $cls;
}

# зарезервированные слова sql
my $SQL_WORD = $app->perl->setref(qw/ABORT ACTION ADD AFTER ALL ALTER ANALYZE AND AS ASC ATTACH AUTOINCREMENT BEFORE BEGIN BETWEEN BY CASCADE CASE CAST CHECK COLLATE COLUMN COMMIT CONFLICT CONSTRAINT CREATE CROSS CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP DATABASE DEFAULT DEFERRABLE DEFERRED DELETE DESC DETACH DISTINCT DROP EACH ELSE END ESCAPE EXCEPT EXCLUSIVE EXISTS EXPLAIN FAIL FOR FOREIGN FROM FULL GLOB GROUP HAVING IF IGNORE IMMEDIATE IN INDEX INDEXED INITIALLY INNER INSERT INSTEAD INTERSECT INTO IS ISNULL JOIN KEY LEFT LIKE LIMIT MATCH NATURAL NO NOT NOTNULL NULL OF OFFSET ON OR ORDER OUTER PLAN PRAGMA PRIMARY QUERY RAISE RECURSIVE REFERENCES REGEXP REINDEX RELEASE RENAME REPLACE RESTRICT RIGHT ROLLBACK ROW SAVEPOINT SELECT SET TABLE TEMP TEMPORARY THEN TO TRANSACTION TRIGGER UNION UNIQUE UPDATE USING VACUUM VALUES VIEW VIRTUAL WHEN WHERE WITH WITHOUT/);

sub SQL_WORD {
    $SQL_WORD
}



# # типы столбцов для alter table
# $COLUMN_TYPE = {
    # "int(11)" => "int",
    # "int(10) unsigned" => "int unsigned",
    # "tinyint(4)" => "tinyint",
    # "tinyint(3) unsigned" => "tinyint unsigned",
    # "bigint(21)" => "bigint",
    # "bigint(20) unsigned" => "bigint unsigned",
    # "smallint(5) unsigned" => "smallint unsigned",
    # "smallint(6)" => "smallint",
# };

# sub COLUMN_TYPE {
    # $COLUMN_TYPE
# }


#pragma table_info(\"B\")
# [
          # {
            # 'notnull' => 0,
            # 'type' => 'integer',
            # 'name' => 'i',
            # 'pk' => 1,
            # 'dflt_value' => undef,
            # 'cid' => 0
          # },
          # {
            # 'pk' => 0,
            # 'cid' => 1,
            # 'dflt_value' => '"xyz"',
            # 'name' => 'b',
            # 'type' => 'varchar(600)',
            # 'notnull' => 0
          # }
        # ]

        
# [
          # {
            # 'tbl_name' => 'A',
            # 'type' => 'table',
            # 'sql' => 'CREATE TABLE A(i int, b int not null)',
            # 'rootpage' => 2,
            # 'name' => 'A'
          # },
          # {
            # 'tbl_name' => 'B',
            # 'type' => 'table',
            # 'sql' => 'CREATE TABLE B(i integer primary key autoincrement, b varc
# har(600) default "xyz")',
            # 'rootpage' => 3,
            # 'name' => 'B'
          # },
          # {
            # 'name' => 'sqlite_sequence',
            # 'rootpage' => 4,
            # 'sql' => 'CREATE TABLE sqlite_sequence(name,seq)',
            # 'tbl_name' => 'sqlite_sequence',
            # 'type' => 'table'
          # }
        # ]

# возвращает информацию о таблицах
sub get_tab_info {
	my ($self) = @_;
	
    #name, engine, charset, remark, options, type
	my $sql = "select *	from sqlite_master where type='table'";
	my $rows = $self->nolog(sub { $self->query_all($sql); });
	
	my $info = {};
	for my $row (@$rows) {	# создаём info
		$info->{$row->{name}} = $row;
	}
	return $info;
}


# PRAGMA foreign_key_list('table')

1;