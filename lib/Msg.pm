use Data::Dumper;
use Utils;
require Cwd;

sub msg (@) {
	print STDERR join(", ", map { ref $_? Utils::Dump($_): $_ } @_)."\n";
	return $_[$#_];
}

sub msg1 (@) {
	print STDERR join(", ", map { ref $_? do { my($x)=Utils::Dump($_); $x=~s/\s+//g; $x}: $_ } @_)."\n";
	return $_[$#_];
}

sub mtime {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $_[0];
	$mtime
}

sub files ($) { if(Cwd::abs_path(".") =~ /\/rubin\/?$/) { <$_[0]> } else { <../rubin/$_[0]> } }
sub dirs ($) { if(Cwd::abs_path(".") =~ /\/rubin\/?$/) { $_[0] } else { ("../rubin/$_[0]", $_[0]) } }


1;
