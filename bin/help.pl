#= [name]
#> возвращает список команд

use Term::ANSIColor qw(:constants);

$name = $ARGV[1];
if($name) {
	for $path (dirs("bin")) {
		$f="$path/$name.pl";
		if(-e $f) {
			$_ = Utils::read($f);
			($args) = /#= (.*)/;
			print "$name $args\n\n";
			print "$1\n" while /^#> (.*)/gm;
		}
	}
	exit;
}

for $path (dirs("bin")) {
	opendir dir, $path;
	while( $file = readdir dir ) {
		if(not exists $files{$file} and $file =~ /\.pl$/) {
			$name = $`;
			$_ = Utils::read("$path/$file");
			($args) = /^#= (.*)/m;
			($help) = /^#> (.*)/m;
			$name .= MAGENTA." $args" if defined $args;
			utf8::encode($name);
			$len = length $name;
			utf8::decode($name);
			#print "$file `$name`\n";
			print CYAN.$name .RESET. (" " x  (20 - $len)) ." ". $help . "\n";
			$files{$file} = 1;
		}
	}
}