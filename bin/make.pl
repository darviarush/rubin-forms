#== Файлы проекта
#= имя
#> создаёт файл

if(@ARGV == 3) {
	$def = $ARGV[1];
	$name = $ARGV[2];
} else {
	$def = "r";
	$name = $ARGV[1];
}

%def = qw();

$name = ucfirst $name;
$def = "lib/R/";
$ext = ".pm";


$path = "$def$name$ext";

die "Файл $path уже существует" if -e $path;

$pack = "R::$name";

$body = "package $pack;
# 

use common::sense;
use R::App;

# конструктор
sub new {
	my (\$cls) = \@_;
	bless {}, \$cls;
}

1;
";

Utils::write($path, $body);

$npp = $ENV{"notepad++"};

system "$npp $path" if $npp;