package R::Hung;
# управляет "висящими заданиями" прописанными в main.ini вроде coffee -w


my %pid;
sub close {
	kill KILL, keys %pid;
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
		
		my $process = R::Hung::Process->new($watch, $app);
		push @{$self->{pid}}, $process->{pid};
		$pid{$process->{pid}} = 1;

		$watching->on(qr/\.(?:$watch->{ext})$/, [main::files(@in)], Utils::closure($process, $process->can("inset")));
		
	}

	main::msg(":BOLD BLACK", "\ncompiling...");
	$watching->fire;
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
use Time::HiRes qw//;
use Symbol;

sub new {
	my ($cls, $watch, $app) = @_;
	my ($in, $out) = (gensym, gensym);
	my $pid = open3($in, $out, $out, $watch->{hang}) or die "Не запустился процесс `$watch->{hang}`. $!";
	
	my $old = select $out; $|=1; select $old;
	
	main::msg "Запустился процесс $$ $pid $watch->{hang}";
	
	my ($ext) = split /\|/, $watch->{ext};
	
	my $self = bless {app=>$app, watch => $watch, ext => $ext, in => $in, out => $out, pid => $pid}, $cls;
	
	#$app->select->on($out, 're', Utils::closure($self, $self->can("")));
	
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
	my ($self, $path, $app) = @_;
	#main::msg $self, $path, !!$app;
	my $time = Time::HiRes::time;
	my $watch = $self->{watch};
	my $ext = $self->{ext};
	my $out = $self->{out};
	my $map = "watch/watch.".($watch->{map} || "map");
	unlink $map;
	#main::msg ":green", "cp $path";
	Utils::cp($path, "watch/watch.$ext");
	my $p = $path;
	$p = Utils::winpath($p) if $watch->{win};
	until($_ = join "", $self->read_bk) {
		main::msg ":red", "cp -x $path watch/watch.$ext";
		Utils::cp($path, "watch/watch.$ext");
		#main::msg 'kill $self->{pid}';
		#kill KILL, $self->{pid};
		#$watch->{start} = 0;
		#%$self = %{R::Hung::Process->new($watch)};
		#$_ = join "", $self->read_bk;
	}
	
	s!$watch->{reg_compile}!($+{time} // strftime("%T", localtime))." - compiled $p"!ge;
	s!$watch->{reg_error}!"$p:$+{line}:".($+{char} || 1).": error: ".($+{msg2}? "$+{msg2}: ": "")."$+{msg}"!ge;
	my @out = split /\n/, $_;
	
	my $to = $watch->{out};
	for my $from (split /\s*,\s*/, $watch->{in}) {
		last if $path =~ s!(^|/)$from!$1$to!;
	}
	
	my $new_ext = $watch->{outext};
	$path =~ s!\.\w+$!.$new_ext!;
	#main::msg 'cp', "watch/watch.$new_ext", $path;
	Utils::cp("watch/watch.$new_ext", $path);
	$path =~ s!\.$new_ext!.map!, Utils::cp($map, $path) if -e $map;
	
	$out[0] = sprintf "%.4f %s", Time::HiRes::time - $time, $out[0];
	out(@out);
	#main::msg sprintf "%.4f - %s", Time::HiRes::time - $time, $path;
}

sub read_bk {
	my ($self) = @_;
	$self->read_nonblock(3);
}

sub read_nonblock {
	my ($self, $sleep) = @_;
	my $out = $self->{out};
	my @out;
	Utils::nonblock($out);
	my $vec = '';
	my ($rin, $win, $ein);
	vec($vec, fileno($out), 1) = 1;
	my $nfound = select $rin=$vec, $win=$vec, $ein=$vec, $sleep;
	if($nfound) {
		push @out, <$out>;
	}
	Utils::block($out);
	return @out;
}

1;