use Data::Dumper;

sub msg (@) {
	print STDERR join(", ", map { ref $_? Dumper($_): $_ } @_)."\n";
	return $_[$#_];
}

sub msg1 (@) {
	print STDERR join(", ", map { ref $_? do { my($x)=Dumper($_); $x=~s/\s+//g; $x=~s/^\$VAR1=(.*);$/$1/; $x}: $_ } @_)."\n";
	return $_[$#_];
}

sub mtime {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $_[0];
	$mtime
}


1;
