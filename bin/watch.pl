#> следит за изменением файлов и перекомпилирует их
#> а именно, применяет команды: stylus, coffee, sprite, action

use IPC::Open3;
use R::Watch;

my @pid = ();
END { kill KILL, @pid; }

mkdir "watch";

die "Нет конфигурации watch в ini-файле. Смотрите пример в main.sample.ini" unless $ini->{watch};

print BOLD.BLACK."starting...".RESET."\n";

my $watching = R::Watch->new;

while(my ($key, $watch) = each %{$ini->{watch}}) {
	
	next if !$watch->{enable} or $watch->{enable} !~ /^yes$/i;
	
	my @in = split /\s*,\s*/, $watch->{in};
	my ($ext) = split /\|/, $watch->{ext};
	
	Utils::write("watch/watch.$ext", "");
	
	my ($in, $out) = ();
	$pid = open3($in, $out, $out, $watch->{hang}) or die $!;
	push @pid, $pid;
	
	if($watch->{start}) {
		out(scalar <$out>);
		out($_) for read_nonblock($out, 0.25);
	}
	
	$watching->on(qr/\.(?:$watch->{ext})$/, [map { dirs($_) } @in], (sub { my @args = @_; sub { inset($_[0], @args) }})->($watch, $ext, $out));
}

print BOLD.BLACK."\ncompiling...".RESET."\n";
$watching->fire();
print BOLD.BLACK."\nwatching...".RESET."\n";
$watching->loop();

sub inset {
	my ($path, $watch, $ext, $out) = @_;
	my $map = "watch/watch.".($watch->{map} || "map");
	unlink $map;
	#msg 'cp', $path, "watch/watch.$ext";
	Utils::cp($path, "watch/watch.$ext");
	local $_ = scalar <$out>;
	my $p = $path;
	$p =~ s!/cygdrive/(\w)/!$1:/!, $p =~ s!/!\\!g if $watch->{win};
	s!(- compiled ).*!$1$p!;
	s!^.*?(:\d+:\d+: error:)!$p$1!;
	s!^TypeError: .*(:\d+:\d+)!$p$1: error:!;
	out($_);
	out(read_nonblock($out, 0.25));
	my $to = $watch->{out};
	for my $from (split /\s*,\s*/, $watch->{in}) {
		last if $path =~ s!(^|/)$from!$1$to!;
	}
	my $new_ext = $watch->{outext};
	$path =~ s!\.\w+$!.$new_ext!;
	#msg 'cp', "watch/watch.$new_ext", $path;
	Utils::cp("watch/watch.$new_ext", $path);
	$path =~ s!\.$new_ext!.map!, Utils::cp($map, $path) if -e $map;
}

sub out {
	for(@_) {
		s/(compiled|watching|generated|\bat\b)/BOLD . BLACK . $1 . RESET/ge;
		if(/error/i) { print RED . $_ . RESET } else { print; }
		#s/(error)/RED . $1 . RESET/e;
		#if() { print BOLD . BLACK . $_ . RESET; print STDERR RESET; } elsif(/error/) { print RED . $_ . RESET } else { print; }
		#print;
	}
}

sub read_nonblock {
	my ($out, $sleep) = @_;
	my @out;
	#my $old = select $out; $| = 1; select $old;
	Utils::nonblock($out);
	for(;;) {
		my $vec = '';
		vec($vec, fileno($out), 1) = 1;
		my ($nfound, $rtime) = select undef, $vec, undef, $sleep;
		my $o = scalar <$out>;
		last unless defined $o;
		push @out, $o;
	}
	Utils::block($out);
	return @out;
}

1;