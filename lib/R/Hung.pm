package R::Hung;
# управляет "висящими заданиями" прописанными в main.ini вроде coffee -w
#use POSIX qw/:HUP/;

use strict;
use warnings;

sub close {
	my ($self) = @_;
	kill 'HUP', @{$self->{pid}};
}

sub DESTROY { $_[0]->close }

sub new {
	my ($cls, $app) = @_;
	
	my $self = bless {app => $app}, $cls;
	
	#mkdir "watch";
	
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

		$watching->on(qr/\.(?:$watch->{ext})$/, [main::files(@in)], Utils::closure($process, $process->can("inset")));
		
	}

	if($app->ini->{hung}{compiling} =~ /^yes$/i) {
		main::msg(":BOLD BLACK", "\ncompiling...");
		$watching->fire;
	}
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
	my ($in, $out, $pid, $old);
	if($watch->{hang}) {
		($in, $out) = (gensym, gensym);
		$pid = open3($in, $out, $out, $watch->{hang}) or die "Не запустился процесс `$watch->{hang}`. $!";
		$old = select $out; $|=1; select $old;
		main::msg ":space", "Запустился процесс", ":red", $pid, ":bold black", $watch->{hang};
	} elsif(!$watch->{run}) {
		die "Нет ни main.ini:watch:hung, ни main.ini:watch:run";
	}
	
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
		if($main::_UNIX) {
			main::msg ":empty", map { /^(compiled|watching|generated|at)$/? (":bold black", $_, ":reset"): /^error/? (':red', $_, ':reset'): $_ } split /(\b(?:compiled|watching|generated|at|error)\b:?)/;
		} else {
			s!\e\[\d+m!!g;
			main::msg $_;
		}
	}
}

# ожидает изменения файла
sub wait {
	my ($self, $file) = @_;
	
	my $prev_size = $self->{'prev_size' . $file};
	my $wait = ($self->{watch}{wait} // 100) * 1000;
	
	Time::HiRes::usleep($wait) unless -s $file;
	Time::HiRes::usleep($wait) if !-e $file or defined $prev_size and $prev_size == -s $file;
	
	main::msg ":red", "Файл `$file` имеет нулевой размер" unless -s $file;
	main::msg ":red", "Размер файла `$file` равен предыдущему размеру" if !-e $file or defined $prev_size and $prev_size == -s $file;
	
	$self->{'prev_size' . $file} = -s $file;
}

sub inset {
	my ($self, $path, $app) = @_;
	my $time = Time::HiRes::time;
	my $watch = $self->{watch};
	my $ext = $self->{ext};
	my $watch_path = "watch/watch.$ext";
	my $new_ext = $watch->{outext};
	my $watch_out_path = "watch/watch.$new_ext";
	my $map = "watch/watch.".($watch->{map} || "map");

	my $js_path = $path;
	my $to = $watch->{out};
	for my $from (split /\s*,\s*/, $watch->{in}) {
		last if $js_path =~ s!(^|/)$from!$1$to!;
	}
	$js_path =~ s!\.\w+$!.$new_ext!;
	
	unlink $map;
	#main::msg ":green", "cp $path";

	$self->wait($path);
	
	Utils::cp($path, $watch_path);
	
	my $p = $path;
	my $winpath = $app->ini->{hung}{winpath};
	$p = Utils::winpath($p) if defined $winpath and $winpath =~ /^yes$/i;
	until($_ = join "", $self->read_bk) {
		main::msg ":red", "Нет ответа компиллятора `$watch->{hung}` на cp $path $watch_path";
		#Utils::cp($path, $watch_path);
	}
	
	s!\e\[\d+m!!g unless $main::_UNIX;
	
	s!$watch->{reg_compile}!($+{time} // strftime("%T", localtime))." ".(-s $watch_path)." - compiled $p"!ge;
	my $is_err = s!$watch->{reg_error}!"$p:$+{line}:".($+{char} || 1).": error: ".($+{msg2}? "$+{msg2}: ": "").($+{msg}? $+{msg}:"")!ge;
	
	my @out = split /\n/, $_;
	
	unless($is_err) {
	
		Time::HiRes::usleep($self->{watch}{sleep} * 1000) if exists $self->{watch}{sleep};
		
		$self->wait($watch_out_path);
		
		if(-e $map) {
			$p = $js_path;
			$p =~ s!\.$new_ext$!.map!;

			my $json;
			eval {
				$json = $app->json->decode(Utils::read($map));
			};
			
			if($@ // $!) {
				main::msg ":red", ":space", "Файл `$map` не был сформирован:\n", "$@$!";
			} else {
				($json->{file}) = $js_path =~ m!(?:^|/)html/(.*)!;
				($json->{sources}->[0]) = $path =~ m!(?:^|/)html/(.*)!;
				Utils::write($p, $app->json->encode($json));
			}
			
			$p =~ m!([^/]+)$! and $p = $1;
			$_ = Utils::read($watch_out_path);
			main::msg ":red", "Файл тождественен предыдущему!" if defined $self->{prev} and $self->{prev} eq $_;
			$self->{prev} = $_;
			s!(?:^|\n)/([/\*])[#@] sourceMappingURL=.*\s*$!"/$1# sourceMappingURL=$p".($1 eq "*"? " */": "")."\n"!e;
			Utils::write($js_path, $_);
		}
		else {
			Utils::mv($watch_out_path, $js_path);
		}
	}
	#$out[0] = sprintf "%.4f %s", Time::HiRes::time - $time, $out[0];
	out(@out);
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