#= [sec1::...]key1=val1 ...
#> устанавливает параметры инициализации и запускает сервер

my $ini = $app->ini;

for(my $i=1; $i < @ARGV; $i++) {
	die "ошибка в параметре `$ARGV[$i]` - нет `=`" unless $ARGV[$i] =~ /=/;
	my ($key, $val) = ($`, $');
	my @sec = split /::/, $key;
	$key = pop @sec;
	my $in = $ini;
	$in = $in->{$_} for @sec;
	$ini->{$key} = $val;
}


my $req = $_FRAMEWORK? "$_FRAMEWORK/bin/qq.pl": "bin/qq.pl";
require $req;