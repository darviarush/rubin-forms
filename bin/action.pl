#= [clean]
#> управляет экшенами
#> без параметров - удалить и перекомпилить экшены
#> clean - удалить скомпилленные экшены

require "../rubin/bin/clean.pl";

if($ARGS[1] ne "clean") {
	require Watch;
	require Action;
	for_action(\&load_action);
}

1;