use Data::Dumper;
use Term::ANSIColor qw(:constants);
require Cwd;

use Utils;


sub msg (@) {
	print STDERR join(", ", map { !defined($_)? RED."undef".RESET: ref $_? Utils::Dump($_): $_ } @_)."\n";
	return $_[$#_];
}

sub msg1 (@) {
	print STDERR join(", ", map { !defined($_)? RED."undef".RESET: ref $_? do { my($x)=Utils::Dump($_); $x=~s/\s+//g; $x}: $_ } @_)."\n";
	return $_[$#_];
}

sub mtime {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $_[0];
	$mtime
}

our $framework;
sub dirs ($) { my $path = $_[0]; ((-e $path? abs_path($path): ()), ($framework && -e ($path="$framework/$path")? $path: ())) }
sub files ($) { dirs(@_); }

1;
