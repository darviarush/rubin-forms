#> заливает базу в mysql

use ModelEdit;

$packages = $ini->{package};
$install = get_install_info(files "install.sql");

$ln = 0;

eval {
	print "install ";
	($database) = $ini->{mysql}{DNS} =~ /\bdatabase=(\w+)/;
	@query = ("DROP DATABASE `$database`", "CREATE DATABASE `$database` CHARACTER SET utf8 COLLATE utf8_unicode_ci", "USE `$database`", map {
		$_ = Utils::read($_)
		s!#[^\n]*|/\*.*?\*/?! !gms;
		split /;/;
	} files "install.sql");
	
	for (@query) {
		$ln ++ while /\n/g;
		$dbh->do($_), print "." if !/^\s*$/;
	}
	print " done\n";
};
print "\n$ln) Error: $@$!\n" if $@ || $!;