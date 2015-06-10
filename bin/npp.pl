#==
#= [[место] файл]
#> открывает notepad++ в другом окне
#> если указаны параметры, то открывает в npp файл
#> место: t - тест, act - экшн, не указано - шаблон, lib - модуль в lib, 

die "Нет файла rubin.session. Смените директорию" if @ARGV==1 and not file("rubin.session");

$framework = 1, splice @ARGV, 1, 1 if $ARGV[1] eq "-";

$path = @ARGV>1? $app->path->to(@ARGV): " -multiInst -nosession -openSession rubin.session";
$path = $app->path->framework($path) if $framework;

if(@ARGV>2) {
	die "не найдена функция $ARGV[2] в $path" unless Utils::read($path) =~ /.*\bsub $ARGV[2]/s;
	$_ = $&;
	$i = 1;
	$i++ while /\n/g;
	$path = "-n$i -c5 $path";
}

return if fork;
$ENV{"QQ_NO_COLOR"} = 1;

$npp = "/cygdrive/c/sbin/notepad++/notepad++";

open $f, "|-", "$npp $path";
close $f;