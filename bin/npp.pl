#==
#= [[место] файл [функция]]
#> открывает notepad++ в другом окне
#> если указаны параметры, то открывает в npp файл
#> место: t - тест, act - экшн, не указано - шаблон, lib - модуль в lib, 

if(@ARGV > 1) {

	#die "Нет файла rubin.session. Смените директорию" if @ARGV==1 and not $app->path->file("rubin.session");

	$framework = 1, splice @ARGV, 1, 1 if ($ARGV[1] // "") eq "-";
	$path = $app->path->to(@ARGV);
	$path = $app->path->framework($path) if $framework;

	msg(":space", "нет файла", ":red", $path), exit unless -e $path;

	if(@ARGV>2) {
		die "не найдена функция $ARGV[2] в $path" unless Utils::read($path) =~ /.*\bsub $ARGV[2]/s;
		$_ = $&;
		$i = 1;
		$i++ while /\n/g;
		$path = "-n$i -c5 $path";
	}

} else {
	$path = " -multiInst -nosession";
}

return if fork;
$ENV{"QQ_NO_COLOR"} = 1;

$npp = $app->ini->{site}{npp} // "/cygdrive/c/sbin/notepad++/notepad++";

open $f, "|-", "$npp $path";
close $f;