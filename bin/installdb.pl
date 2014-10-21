#> заливает базу в mysql

use ModelEdit;

#$packages = $ini->{package};
#$install = get_install_info(files "install.sql");


print "install ";
($database) = $ini->{mysql}{DNS} =~ /\bdatabase=(\w+)/;
@query = ({ file=> "@", q=>["DROP DATABASE `$database`", "CREATE DATABASE `$database` CHARACTER SET utf8 COLLATE utf8_unicode_ci", "USE `$database`"]},
map {
	$_ = Utils::read($file = $_);
	s!#[^\n]*|/\*.*?\*/?! !gms;
	{file=>$file, q=>[split /;/]};
} files "install.sql");

for $q (@query) {
	$ln = 0;
	for (@{$q->{q}}) {
		$ln ++ while /\n/g;
		next if /^\s*$/;
		eval { $dbh->do($_); };
		print("\n\n$q->{file}:$ln:$_\n\nError: $@$!\n"), goto _END_ if $@ || $!;
		print ".";
	}
}
print " done\n";


_END_:

1;