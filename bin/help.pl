#= [name]
#> возвращает список команд

use Term::ANSIColor qw(:constants);
use File::Find;
use utf8;
use Cwd qw/cwd/;

binmode STDOUT, ":utf8";

$name = $ARGV[1];
if($name) {
	($path) = dirs("bin/$name.pl");
	$_ = Utils::read($path, 'utf-8');
	$name .= " $1" if /^#= ([^\r\n]+)/m;
	print BOLD . BLACK . "$name\n\n" . RESET;
	print "$1\n" while /^#> ([^\r\n]+)/gm;
	exit;
}

find({ no_chdir=>1, wanted=> sub {
	return unless $File::Find::name =~ /([^\/]+)\.pl$/;
	$name = $1;
	$_ = Utils::read($File::Find::name, 'UTF-8');
	($args) = /^#= ([^\r\n]+)/m;
	($help) = /^#> ([^\r\n]+)/m;
	$name .= " $args" if defined $args;
	$len = length $name;
	print BOLD . BLACK . $name . RESET . (" " x  (20 - $len)) . ($help? " ".$help: "") . "\n";
	
}}, dirs "bin");

1;