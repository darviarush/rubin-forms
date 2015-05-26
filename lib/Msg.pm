# создаёт $app, добавляет пути, обрабатывает ошибки (в лог, цвет)

# 1. кэш для orm: R::Cache
# 2. лог для записи msg. msg пишет в $app->log->info. Предусмотреть в msg стандартные уровни логирования
# 3. темплейт в R::Jig или R::Template. 
#	а) предусмотреть виджеты
#	б) хелперы встраивать в шаблон
#	в) компилировать и в js



BEGIN {
	#use open qw/:utf8 :std/;
	#use Carp 'verbose';
	use Term::ANSIColor qw//;
	#use Fcntl ':flock';
	#$SIG{ __DIE__ } = \&Carp::confess;
	
	our $_UNIX = !!$ENV{SHLVL}; #not $ENV{TERM} eq "dumb";
	
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
	$SIG{ __WARN__ } = sub {
		print STDERR $raise->trace($_[0])->color("warning", 'yellow', 'green');
		exit;
		exit if $_[0]=~/^Deep recursion on subroutine/;
	};

}
our $_FRAMEWORK;

use R::App;
our $app = R::App->new("R");

use JSON::XS;
$app->json(JSON::XS->new->allow_nonref);

use Utils;
use POSIX qw//;
use Term::ANSIColor qw//;

my $old = select STDOUT;
$| = 1;
select STDERR;
$| = 1;
select $old;


my $_LOG = 1;


sub msg (@) {
	if($_LOG == 1) {
		my ($sep, $next, $reset, $inline) = ", ";
		my $newline = 1;
		my $i = 0;
		my $msg = join("", map {
			my @ret = !defined($_)? ($_UNIX? Term::ANSIColor::colored("undef", "red"): "undef"):
			ref $_? do { my($x)=Utils::Dump($_); $x=~s/\s+/ /g if $inline; $x}:
			$_ eq ":space"? do { $sep = " "; () }:
			$_ eq ":empty"? do { $sep = ""; () }:
			$_ eq ":sep"? do { $sep = ", "; () }:
			$_ eq ":nonewline"? do { $newline = undef; () }:
			$_ eq ":inline"? do { $inline = 1; () }:
			$_ eq ":inline_end"? do { $inline = 0; () }:
			$_ eq ":time"? do { POSIX::strftime("%T", localtime) }:
			/^:([\w ]+)$/? do { if($_UNIX) { $reset = 1; $next = Term::ANSIColor::color($1); } () }:
			$_;
			if(@ret) {
				unshift @ret, $sep if $i++ != 0;
				unshift(@ret, $next), $next = undef if defined $next;
			}
			
			@ret
		} @_);
		$msg .= Term::ANSIColor::color('reset') if $reset;
		$msg .= "\n" if $newline;
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
sub dirs (@) { map { (($_FRAMEWORK? glob("$_FRAMEWORK/$_") : ()), glob($_)) } @_ }
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
