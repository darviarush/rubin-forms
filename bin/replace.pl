#== ‘айлы проекта
#= маска что на_что
#> замен€ет текст
#> маска - маска файлов в которых производитс€ замена
#> что - регул€рное выражение
#> на_что - текст дл€ замены


($, $from, $to) = @ARGV;

for my $name (split /\n/, `find . -name '*.htm'`) {
	open f, $name or next;
	print "$name\n";
	
	read f, $_, -s f;
	close f;
	open f, ">", $name or die $!;
	
	s{$from}{$to}o;
	
	print f $_;
	close f;
}