package R::Hung;
# управляет "висящими заданиями" прописанными в main.ini вроде coffee -w

use IPC::Open3;
use POSIX qw/strftime/;


my @pid = ();
END { kill KILL, @pid; }

sub new {
	my ($cls, $app) = @_;
	
	my $self = bless {app => $app}, $cls;
	
	mkdir "watch";
	
	die "Нет конфигурации watch в ini-файле. Смотрите пример в main.sample.ini" unless exists $app->ini->{watch};

	$app->log(":BOLD BLACK", "starting...");

	my $watching = $app->watch;
	
	while(my ($key, $watch) = each %{$app->ini->watch}) {
		
		next if !$watch->{enable} or $watch->{enable} !~ /^yes$/i;
		
		my @in = split /\s*,\s*/, $watch->{in};
		my ($ext) = split /\|/, $watch->{ext};
		
		Utils::write("watch/watch.$ext", "");
		
		my ($in, $out) = ();
		my $pid = open3($in, $out, $out, $watch->{hang}) or die $!;
		push @pid, $pid;
		
		if($watch->{start}) {
			#out(scalar <$out>);
			out($_) for read_bk($out);
		}
		
		$watching->on(qr/\.(?:$watch->{ext})$/, [main::files(@in)], (sub { my @args = @_; sub { inset($_[0], @args) }})->($watch, $ext, $out));
		
	}

	$app->log(":BOLD BLACK", "\ncompiling...");
	$watching->fire();
	$app->log(":BOLD BLACK", "\nwatching...");
	$self;
}

sub loop {
	my ($self, @any) = @_;
	$self->{app}->watch->loop(@any);
}

sub inset {
	my ($path, $watch, $ext, $out) = @_;
	my $map = "watch/watch.".($watch->{map} || "map");
	unlink $map;
	#msg 'cp', $path, "watch/watch.$ext";
	Utils::cp($path, "watch/watch.$ext");
	my $p = $path;
	$p =~ s!/cygdrive/(\w)/!$1:/!, $p =~ s!/!\\!g if $watch->{win};
	for(read_bk($out)) {
		s!$watch->{reg_compile}!($1 // strftime("%T", localtime))." - compiled $p"!e;
		s!$watch->{reg_error}!"$p:$1:".($2 // 1).": error: $3"!e;
		out($_);
	}
	
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
		chomp $_;
		main::msg ":empty", map { /^(compiled|watching|generated|at)$/? (":bold black", $_, ":reset"): /error/? (':red', $_, ':reset'): $_ } split /(compiled|watching|generated|\bat\b)/;
	}
}

sub read_bk {
	my ($out) = @_;
	my @out;
	until(@out = read_nonblock($out, 0.25)) {}
	@out
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