#= [name]
#> возвращает список команд

$name = $ARGV[1];
if($name) {
	#if(-e "bin/$name.pl") {	
	#} elsif() {
	#}
	#while/#> (.*)/g;
	exit;
}

for $path ("bin", "../rubin/bin") {
	opendir dir, $path;
	while( $file = readdir dir ) {
		if($file =~ /\.pl$/ and not exists $files{$file}) {
			$name = $`;
			$_ = Utils::read("$path/$file");
			($args) = /#= (.*)/;
			($help) = /#> (.*)/;
			print "$name $args\t\t$help\n";
			$files{$file} = 1;
		}
	}
}