
use Data::Dumper;
require Cwd;

use Utils;

my $_LOG = 1;
my $_MSG_INLINE = 0;

sub msg (@) {
	if($_LOG == 1) {
		require Term::ANSIColor;
		my ($sep, $next, $reset) = ", ";
		my $msg = join($sep, map {
			my @ret = !defined($_)? Term::ANSIColor::RED."undef".Term::ANSIColor::RESET:
			ref $_? do { my($x)=Utils::Dump($_); $x=~s/\s+//g if $_MSG_INLINE; $x}:
			$_ eq ":space"? do { $sep = " "; () }:
			$_ eq ":empty"? do { $sep = ""; () }:
			/^:([\w ]+)$/? do { $reset = 1; $next = Term::ANSIColor::color($1); () }:
			$_;
			if(defined $next and @ret) { $ret[0] = "$next$ret[0]"; $next = undef }
			@ret
		} @_).($reset? Term::ANSIColor::color('reset'): "")."\n";
		print STDERR $msg;
	}
	return $_[$#_];
}

sub msg1 (@) {
	my ($app) = @_;
	$_MSG_INLINE = 1;
	msg(@_);
	$_MSG_INLINE = 0;
	return $_[$#_];
}

sub mtime {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $_[0];
	$mtime
}

sub dirs ($) { my ($path) = @_; ((-e $path? $path: ()), ($::framework && (-e ($path="$::framework/$path"))? $path: ())) }
sub files ($) { dirs($_[0]); }

sub run_bin ($$) {
	my ($run, $our) = @_;
	
	while(my ($key, $val) = each %$our) {
		${"R::BIN::${run}::$key"} = $val;
	}
	
	my $code = Utils::read(files("bin/$run.pl"));
	eval "package R::BIN::$run;\n$code";
	die $@ // $! if $@ // $!;
}

1;
