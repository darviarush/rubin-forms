#= [sec1::...]key1=val1 ...
#> устанавливает параметры инициализации и запускает сервер

for($i=1; $i < @ARGV; $i++) {
	die "ошибка в параметре `$ARGV[$i]` - нет `=`" unless $ARGV[$i] =~ /=/;
	($key, $val) = ($`, $');
	@sec = split /::/, $key;
	$key = pop @sec;
	$in = $ini;
	$in = $in->{$_} for @sec;
	$ini->{$key} = $val;
}

require "$framework_dir/bin/qq.pl";