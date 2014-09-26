#= пакет файлы...
#> добавляет файлы в пакет

($cmd, $package, @file) = @ARGV;

for $file (@file) {
	print("Нет файла `$file`"), exit unless -e $file;
}

#for () {
#	split /,\s*/, $ini->{package}{$package}{files}
#}

Utils::replace("main.ini", sub {
	my %set = Utils::set(@file, split /,\s*/, $ini->{package}{$package}{files});
	Utils::inject_ini($_[0], "package::$package", "files", join ", ", sort {$a cmp $b} keys %set);
});