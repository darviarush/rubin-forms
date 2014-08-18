#= [name]
#> возвращает список команд

use Term::AnsiColor qw/:constants/;

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
			($args) = /#= (.*)/;
			($help) = /#> (.*)/;
			$name .= " $args" if defined $args;
			print "$file `$name`\n";
			print $name . (" " x  (20 - length $name)) . $help . "\n";
			$files{$file} = 1;
		}
	}
}