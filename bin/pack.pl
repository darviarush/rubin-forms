#= пакет файлы...
#> добавляет файлы в пакет

($cmd, $package, @file) = @ARGV;

for $file (@file) {
	print("Нет файла `$file`"), exit unless -e $file;
}

# проверить - не содержиться ли этот файл в другом пакете и сообщить об этом
#for () {
#	split /,\s*/, $ini->{package}{$package}{files}
#}

Utils::replace("main.ini", sub {
	Utils::inject_ini($_[0], "package::$package", "enable", "no") if !exists $ini->{package}{$package};
	my %set = Utils::set(@file, split /,\s*/, $ini->{package}{$package}{files});
	Utils::inject_ini($_[0], "package::$package", "files", join ", ", sort {$a cmp $b} keys %set);
});