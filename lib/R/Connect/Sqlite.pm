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


# возвращает sql для get_tab_info
sub sql_tab_info {
	my ($self) = @_;
	"select table_name as name, engine, table_collation as charset, table_comment as remark, create_options as options, table_type as type
		from information_schema.tables
		where table_schema=".$self->quote($self->basename);
}

# возвращает sql для get_info
sub sql_info {
	my ($self) = @_;
	"select table_name, column_name, data_type, column_type, column_default, is_nullable, character_maximum_length, extra, column_key, ordinal_position, column_comment, character_set_name, collation_name
		from information_schema.columns
		where table_schema=".$self->quote($self->basename);
}

# возвращает sql для get_index_info. Если пусто - то используется mysql схема
sub sql_index_info {
    my ($self) = @_;
    ""
}


# sql для get_fk_info
sub sql_fk_info {
	my ($self) = @_;
	"SELECT table_name as tab,column_name as col,constraint_name as name,
referenced_table_name as ref_tab,referenced_column_name as ref_col,
ordinal_position as pos, position_in_unique_constraint as ref_pos
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA=" . $self->quote($self->basename) . "
AND referenced_column_name IS not null"
}

1;