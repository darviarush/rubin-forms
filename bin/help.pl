#= [name]
#> возвращает список команд

use Msg;
#use Term::ANSIColor qw(:constants);
use File::Find;
use utf8;
use Cwd qw/cwd/;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $name = $ARGV[1];
if($name) {
	my ($path) = dirs("bin/$name.pl");
	$_ = Utils::read($path, 'utf-8');
	$name .= " $1" if /^#= ([^\r\n]+)/m;
	main::msg ":bold black", "$name\n";
	main::msg $1 while /^#> ([^\r\n]+)/gm;
	exit;
}

my %CAT;

find({ no_chdir=>1, wanted=> sub {
	return unless $File::Find::name =~ /([^\/]+)\.pl$/;
	my $name = $1;
	$_ = Utils::read($File::Find::name, 'UTF-8');
	my ($cat) = /^#== (.*?)\s*$/m;
	my ($args) = /^#= ([^\r\n]+)/m;
	my ($help) = /^#> ([^\r\n]+)/m;
	
	$CAT{$cat || ""}{$name} = {args=>$args, help=>$help};
}}, dirs "bin");


for my $cat (sort keys %CAT) {

	main::msg ":empty", ":bold", "\n+ ", ":bold black", $cat if $cat ne "";

	my $category = $CAT{$cat};
	
	for my $name (sort keys %$category) {
		my $args = $category->{$name}{args};
		my $help = $category->{$name}{help};
		$name .= " $args" if defined $args;
		my $len = length $name;
		main::msg ":empty", ":bold black", $name, ":reset", (" " x  (20 - $len)) . ($help? " ".$help: "");
	}
}

1;