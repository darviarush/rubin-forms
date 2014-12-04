# создаёт $app, добавляет пути, обрабатывает ошибки (в лог, цвет)
BEGIN {
	#use Carp 'verbose';
	use Term::ANSIColor qw//;
	#$SIG{ __DIE__ } = \&Carp::confess;

	sub R::color_error {
		my ($action, $error, $color_error, $color_words) = @_;
		$color_error //= 'red';
		$color_words //= 'cyan';
		#my $e = Carp::longmess(Term::ANSIColor::colored($error, $color_error));
		##$e =~ s!^ at .*$!!m;
		#$e =~ s!\b(require|called at|at|line|thread)\b!Term::ANSIColor::colored($1, $color_words)!ge;
		#print STDERR $e;
		
		my ($efile, $eline);
		
		if(ref $error) { $error = Utils::Dump($error); }
		else { $error =~ s! at (\S+) line (\d+)(?:, <GEN\d+> line \d+)\.$!!; $efile = $1; $eline = $2; }
		
		for(my $i=1; my @param = caller($i); $i++) {
			my ($package, $file, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @param;
			$subroutine =~ s!^main::(\w+)$!$1!;
			push @trace, "$file:$line: $subroutine\n" if $subroutine !~ /^(?:__ANON__|\(eval\))$/;
		}
		
		print STDERR  "$efile:$eline: " . Term::ANSIColor::colored($action.": ", $color_error) . Term::ANSIColor::colored($error, $color_words);
		print STDERR $_ for @trace;
	}
	
	$SIG{ __DIE__ } = sub { die @_ if $^S; R::color_error("error", $_[0]); exit };
	$SIG{ __WARN__ } = sub { R::color_error("warning", $_[0], 'yellow', 'green') };
	
	use Cwd;
	use File::Basename qw/dirname/;
	chdir dirname($0);
	
	our $_FRAMEWORK;
	
	my $root = "."; #getcwd();
	#chdir $root;
	my @frame = split /\//, __FILE__;
	my $frame = join("/", @frame[0..@frame-3]) || ".";
	if($frame ne $root) { $_FRAMEWORK = $frame; unshift @INC, "$root/lib"; }
}
our $_FRAMEWORK;

use R::App;
our $app = R::App->new;

use Utils;
use POSIX qw//;
use Term::ANSIColor qw//;

my $_LOG = 1;
my $_COLOR = $ENV{TERM} eq "cygwin";

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
