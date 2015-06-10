#== Редактор
#= [-] модуль [функция [аргументы...]]
#> создаёт файл модуля
#> тип модуля берётся из названия:
#>	make - шаблон html
#>	make:act - шаблон ModelView
#>	make:r - шаблон библиотеки в lib/R
#>	make:t - тест
#>	make:bin - команда
#> например:
#> 

$framework = 1, splice @ARGV, 1, 1 if $ARGV[1] eq "-";

my ($make, $name, $func) = @ARGV;

$make =~ s/^[^:]+:?//;
$path = $app->path->to($make, $name);
$path = $app->path->framework($path) if $framework;

if($func) {

	die "Создайте вначале файл $path" if !-e $path;

	$args = join ", ", map { "\$$_" } "self", @ARGV[3..$#ARGV];

	Utils::replace($path, sub {
		$_[0] =~ s!(\s1;\s*)$!

# функция $func
sub $func {
	my ($args) = \@_;
	\$self
}

$1!;
	});
	
	exit;
}


if($make eq "") {

$skel = '{% layout "menu" %}
{% title =%}' . $name . '{% end %}

';

} elsif($make eq "act") {

$skel = '
$ = $request->param("");

return {}
';
	
} elsif($make eq "r") {

$pack = ucfirst $name;
$pack =~ s![A-Z]!::$&!g;
$skel = 'package R' . $pack . ';
# 

use common::sense;
use R::App;

# конструктор
sub new {
	my (\$cls) = \@_;
	bless {}, \$cls;
}

1;
'

}
elsif($make eq "t") {

$skel = '# тестирует lib/R/'.ucfirst($name).'

use common::sense;
use Test::More tests => 1;
use App;

ok 1;
';

}
elsif($make eq "bin") {

$skel = '#== СЕКЦИЯ
#=
#> команда ' . $name . '

($name,) = @ARGV;

$app->;
';
}
else {
	die "Неизвестная команда `make:$make`";
}


die "Файл $path уже существует" if -e $path;

Utils::mkpath($path);
Utils::write($path, $skel);

# $npp = $ENV{"notepad++"};

# system "$npp $path" if $npp;
