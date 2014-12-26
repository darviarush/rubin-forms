# создаёт $app, добавляет пути, обрабатывает ошибки (в лог, цвет)
BEGIN {
	#use Carp 'verbose';
	use Term::ANSIColor qw//;
	#use Fcntl ':flock';
	#$SIG{ __DIE__ } = \&Carp::confess;
	
	our $_FRAMEWORK;
	
	my $root = ".";
	#chdir $root;
	my @frame = split /\//, __FILE__;
	my $frame = join("/", @frame[0..@frame-3]) || ".";
	if($frame ne $root) { $_FRAMEWORK = $frame; unshift @INC, "$root/lib"; }
	
	use R::Raise;
	my $raise = R::Raise->new;
	
	$SIG{ __DIE__ } = sub {
		my ($msg) = @_;
		eval {
			$msg = $raise->trace($msg) if ref $msg ne 'R::Raise::Trace';
		};
		die $msg if $^S;
		print STDERR $msg;
		exit
	};
	$SIG{ __WARN__ } = sub { print STDERR $raise->trace($_[0])->color("warning", 'yellow', 'green') };

}
our $_FRAMEWORK;

use R::App;
our $app = R::App->new;

use Utils;
use POSIX qw//;
use Term::ANSIColor qw//;

my $old = select STDOUT;
$| = 1;
select STDERR;
$| = 1;
select $old;

my $_LOG = 1;
my $_COLOR = not $ENV{TERM} eq "dumb";

sub msg (@) {
	if($_LOG == 1) {
		my ($sep, $next, $reset, $inline) = ", ";
		my $msg = join($sep, map {
			my @ret = !defined($_)? ($_COLOR? Term::ANSIColor::colored("undef", "red"): "undef"):
			ref $_? do { my($x)=Utils::Dump($_); $x=~s/\s+//g if $inline; $x}:
			$_ eq ":space"? do { $sep = " "; () }:
			$_ eq ":empty"? do { $sep = ""; () }:
			$_ eq ":inline"? do { $inline = 1; () }:
			$_ eq ":inline_end"? do { $inline = 0; () }:
			$_ eq ":time"? do { POSIX::strftime("%T", localtime) }:
			/^:([\w ]+)$/? do { if($_COLOR) { $reset = 1; $next = Term::ANSIColor::color($1); } () }:
			$_;
			if(defined $next and @ret) { $ret[0] = "$next$ret[0]"; $next = undef }
			@ret
		} @_).($reset? Term::ANSIColor::color('reset'): "")."\n";
		print STDERR $msg;
	}
	return $_[$#_];
}

sub mtime {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $_[0];
	$! = undef;
	$mtime
}

sub file ($) { my ($path) = @_; -e $path? $path: ($_FRAMEWORK && -e ($path="$_FRAMEWORK/$path"))? $path: undef }
sub dirs (@) { map { (glob($_), ($_FRAMEWORK? glob("$_FRAMEWORK/$_") : ())) } @_ }
sub files (@) { map { -e $_? $_: () } dirs(@_) }

sub run_bin ($$) {
	my ($run, $our) = @_;
	
	while(my ($key, $val) = each %$our) {
		${"R::BIN::${run}::$key"} = $val;
	}
	
	my $code = Utils::read(file("bin/$run.pl"));
	eval "package R::BIN::$run;\n$code";
	die $@ // $! if $@ // $!;
}

1;
