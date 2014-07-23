#> заливает базу в mysql


$ln = 0;

eval {
	print "install ";
	($database) = $ini->{mysql}{DNS} =~ /\bdatabase=(\w+)/;
	@query = ("DROP DATABASE `$database`", "CREATE DATABASE `$database` CHARACTER SET utf8 COLLATE utf8_unicode_ci", "USE `$database`", map {
		s!#[^\n]*|/\*.*?\*/?! !gms;
		split /;/;
	} (Utils::read("../rubin/install.sql"), Utils::read("install.sql")));
	
	for (@query) {
		$ln ++ while /\n/g;
		$dbh->do($_), print "." if !/^\s*$/;
	}
	print " done\n";
};
print "\n$ln) Error: $@$!\n" if $@ || $!;