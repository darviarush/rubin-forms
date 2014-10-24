#> следит за изменением файлов и перекомпилирует их
#> а именно, применяет команды: stylus, coffee, sprite, action

use R::Watch;
use R::Cron;
use R::Select;

mkdir "watch";

Utils::write("watch/watch.coffee", "");
$pid = open $coffee, "coffee -bw watch/watch.coffee |" or die $!;

END { kill KILL, $pid }


$watch = R::Watch->new;

# $watch->on(qr/\.sty$/, ['css'], sub {
	# my ($path) = @_;
# });

%TRANS = ('html/coffee/' => 'html/js/', 'html/' => 'html/js/');
%path = ();
$PATH = undef;

sub inset {
	my ($path) = @_;
	msg 'inset', $path;
	$path =~ /(\.\w+)$/; $ext = $1;
	$path{$path} = 1, return if %path;
	$path{$PATH = $path} = 1;
	msg 'inset in';
	$path =~ /\.(\w+)$/;
	Utils::cp($path, "watch/watch.$1");
}

sub outset {
	my ($path) = @_;
	msg 'outset', $path;
	delete $path{$PATH};
	while(($from, $to) = each %TRANS) {
		last if $PATH =~ s!(^|/)$from!$1$to!;
	}
	$path =~ /(\.\w+)$/; $ext = $1;
	$PATH =~ s!\.(\w+)!$ext!;
	Utils::cp($path, $PATH);
	if(%path) {
		($PATH) = each %path;
		delete $path{$PATH};
		$PATH =~ /\.(\w+)$/;
		Utils::cp($PATH, "watch/watch.$1");
	}
}


$watch->on(qr/\.coffee$/, [dirs('html/coffee'), dirs('html')], \&inset);

$watch->on(qr/\.js$/, 'watch', \&outset);

$select = R::Select->new->on($coffee, "rn", sub {
	while(<$coffee>) {
		last unless length $_;
		if(/compile/) {	print BOLD . BLACK } else { print RED }
		print;
		print RESET;
	}
});

#$select->nonblock($coffee);

$select->loop(1, sub { $watch->run() });

1;