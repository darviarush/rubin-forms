#> Синхронизирует структуру базы

use ModelEdit;

$packages = $ini->{package};
$install = get_install_info(files "install.sql");

@tabs = Utils::order_by("order", $install);

$dbh->do("START TRANSACTION");
eval {

for $info (@tabs) {
	@cols = Utils::order_by("order", $info->{cols});
	$tab = $info->{name};
	for $inf (@cols) {
		$package = $inf->{package};
		$col = $inf->{name};
		if(!$package or $ini->{package}{$package}{enable} =~ /^yes$/i) {
			if(!exists $_info->{$tab}) {
				
			} elsif(!exists $_info->{$tab}{$col}) {
				$sql = "alter table ".SQL_WORD($tab)." add column ".SQL_WORD($col)." ".$inf->{install};
				msg "$sql;";
				$dbh->do($sql);
			} elsif(sql_from_info($_info->{$tab}{$col}) ne $inf->{install}) {
				$sql = "alter table ".SQL_WORD($tab)." modify column ".SQL_WORD($col)." ".$inf->{install};
				msg "$sql;";
				$dbh->do($sql);
			}
		}
	}
}

};
if($error = $@ // $!) {
	$dbh->do("ROLLBACK");
	die $error;
} else {
	$dbh->do("COMMIT");
}