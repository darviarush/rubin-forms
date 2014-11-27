package R::Hung;
# управляет "висящими заданиями" прописанными в main.ini вроде coffee -w



my %pid;
END { kill KILL, keys %pid; #main::msg "END";
}

sub DESTROY { my ($self) = @_; kill KILL, @{$self->{pid}}; delete $pid{$_} for @{$self->{pid}}; #main::msg "DESTROY", $self->{pid};
}

sub new {
	my ($cls, $app) = @_;
	
	my $self = bless {app => $app}, $cls;
	
	mkdir "watch";
	
	die "Нет конфигурации watch в ini-файле. Смотрите пример в main.sample.ini" unless exists $app->ini->{watch};

	main::msg(":BOLD BLACK", "starting...");

	my $watching = $app->watch;
	
	while(my ($key, $watch) = each %{$app->ini->{watch}}) {
		
		next if !$watch->{enable} or $watch->{enable} !~ /^yes$/i;
		
		my @in = split /\s*,\s*/, $watch->{in};
		my ($ext) = split /\|/, $watch->{ext};
		
		Utils::write("watch/watch.$ext", "");
		
		my $process = R::Hung::Process->new($watch);
		push @{$self->{pid}}, $process->{pid};
		$pid{$process->{pid}} = 1;

		$watching->on(qr/\.(?:$watch->{ext})$/, [main::files(@in)], (sub { my ($p) = @_; sub { $p->inset(@_) }})->($process));
		
	}

	main::msg(":BOLD BLACK", "\ncompiling...");
	$watching->fire();
	main::msg(":BOLD BLACK", "\nwatching...");
	$self;
}

sub loop {
	my ($self, @any) = @_;
	$self->{app}->watch->loop(@any);
}



package R::Hung::Process;

use IPC::Open3;
use POSIX qw/strftime/;
use Cwd qw/abs_path/;
use Symbol;

sub new {
	my ($cls, $watch) = @_;
	my ($in, $out) = (gensym, gensym);
	my $pid = open3($in, $out, $out, $watch->{hang}) or die "Не запустился процесс `$watch->{hang}`. $!";
	
	#Utils::nonblock($in);
	#Utils::nonblock($out);
	#my $old = select $out; $| = 1; select $old;
	my ($ext) = split /\|/, $watch->{ext};
	
	my $self = bless {watch => $watch, ext => $ext, in => $in, out => $out, pid => $pid}, $cls;
	
	if($watch->{start}) {
		#out(scalar <$out>);
		out( $self->read_bk );
	}
	$self
}

sub out {
	for(@_) {
		chomp $_;
		main::msg ":empty", map { /^(compiled|watching|generated|at)$/? (":bold black", $_, ":reset"): /error/? (':red', $_, ':reset'): $_ } split /(compiled|watching|generated|\bat\b)/;
	}
}

sub inset {
	my ($self, $path) = @_;
	my $watch = $self->{watch};
	my $ext = $self->{ext};
	my $out = $self->{out};
	my $map = "watch/watch.".($watch->{map} || "map");
	unlink $map;
	#main::msg 'cp', $path, "watch/watch.$ext";
	Utils::cp($path, "watch/watch.$ext");
	my $p = abs_path($path);
	$p =~ s!/cygdrive/(\w)/!$1:/!, $p =~ s!/!\\!g if $watch->{win};
	unless($_ = join "", $self->read_bk) {
		kill KILL, $self->{pid};
		%$self = %{R::Hung::Process->new($watch)};
		$_ = join "", $self->read_bk;
	}
	
	s!$watch->{reg_compile}!($+{time} // strftime("%T", localtime))." - compiled $p"!ge;
	s!$watch->{reg_error}!"$p:$+{line}:".($+{char} || 1).": error: ".($+{msg2}? "$+{msg2}: ": "")."$+{msg}"!ge;
	out(split /\n/, $_);
	
	my $to = $watch->{out};
	for my $from (split /\s*,\s*/, $watch->{in}) {
		last if $path =~ s!(^|/)$from!$1$to!;
	}
	
	my $new_ext = $watch->{outext};
	$path =~ s!\.\w+$!.$new_ext!;
	#main::msg 'cp', "watch/watch.$new_ext", $path;
	Utils::cp("watch/watch.$new_ext", $path);
	$path =~ s!\.$new_ext!.map!, Utils::cp($map, $path) if -e $map;
}

sub read_bk {
	my ($self) = @_;
	my @out;
	#main::msg ":green", "read_bk";
	my $i = 0;
	while(not @out = $self->read_nonblock(0.25) and $i++ > 10) {}
	#main::msg ":red", "read_bk out", \@out;
	@out
}

use Time::HiRes qw//;
sub read_nonblock {
	my ($self, $sleep) = @_;
	my $out = $self->{out};
	my @out;
	Utils::nonblock($out);
	my $f = fileno($out);
	my $vec = '';
	my ($rin, $ein);
	vec($vec, $f, 1) = 1;
	for(;;) {
		my $time = Time::HiRes::time();
		my ($nfound, $rtime) = select $rin=$vec, $win=$vec, $ein=$vec, $sleep;
		my $o = <$out>;
		#main::msg kill(0, $self->{pid}), vec($vec, $f, 1), vec($rin, $f, 1), vec($win, $f, 1), vec($ein, $f, 1), $nfound, $rtime, Time::HiRes::time() - $time;
		last unless defined $o;
		push @out, $o;
	}
	Utils::block($out);
	return @out;
}

1;