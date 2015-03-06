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
	
	my $self = bless {app => $app, pid => []}, $cls;
	
	#mkdir "watch";
	
	die "Нет конфигурации watch в ini-файле. Смотрите пример в main.sample.ini" unless exists $app->ini->{watch};

	main::msg(":BOLD BLACK", "starting...");

	my $watching = $app->watch;
	
	while(my ($key, $watch) = each %{$app->ini->{watch}}) {
		
		next if !$watch->{enable} or $watch->{enable} !~ /^yes$/i;
		
		my @in = split /\s*,\s*/, $watch->{in};
		my ($ext) = split /\|/, $watch->{ext};
		
		Utils::write("watch/watch.$ext", "");
		
		$watching->on(qr/\.(?:$watch->{ext})$/, [main::files(@in)],
			$watch->{kitty}? Utils::closure($key, sub {
				my ($key, $path, $app) = @_;
				my $watch = $app->ini->{watch}{$key};
				
				$path =~ m!/([^/]+)\.\w+$!;
				my $to = "$watch->{out}/$1.$watch->{outext}";
				my $map = "$watch->{out}/$1.map";
				
				$app->request->{get} = {
					from => $path,
					to => $to,
					map => $map,
					root => '..',
				};
				$app->kitty->timeout(10)->run(main::file($watch->{kitty}));
				#my $body = [@{ $app->response->{errors} }];
				#$body = $app->kitty->reg_compile($body, $path, $key);
				main::msg ":empty", $app->response->arr_body;
			}):
			$watch->{run} || $watch->{hung}? do {
				my $process = R::Hung::Process->new($key, $app);
				push @{$self->{pid}}, $process->{pid} if defined $process->{pid};
				Utils::closure($process, $process->can("inset"));
			}:
			die("Нет ни hung, ни run, ни kitty в main.ini:[watch::$key]")
		);
		
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
	my ($cls, $key, $app) = @_;
	my ($in, $out, $pid, $old);
	
	my $watch = $app->ini->{watch}{$key};
	
	if($watch->{hung}) {
		($in, $out) = (gensym, gensym);
		$pid = open3($in, $out, $out, $watch->{hung}) or die "Не запустился процесс `$watch->{hung}`. $!";
		$old = select $out; $|=1; select $old;
		main::msg ":space", "Запустился процесс", ":red", $pid, ":bold black", $watch->{hung};
	}
	
	my ($ext) = split /\|/, $watch->{ext};
	
	my $self = bless {app=>$app, key=>$key, watch => $watch, ext => $ext, in => $in, out => $out, pid => $pid}, $cls;
	
	#$app->select->on($out, 're', Utils::closure($self, $self->can("")));
	
	if($watch->{start} && $watch->{hung}) {
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

# обрабатывает изменение файла - записывает в watch/watch.ext и ожидает изменения watch/watch.out
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

	$self->wait($path);
	
	Utils::cp($path, $watch_path);
	
	if($watch->{run}) {
		my ($in, $out) = (gensym, gensym);
		my $pid = open3($in, $out, $out, $watch->{run}) or die "Не запустился процесс `$watch->{run}`. $!";
		my $old = select $out; $|=1; select $old;
		$_ = join "", <$out>;
		$_ = strftime("%T", localtime) . " - compiled $path to $js_path\n" if $_ eq "";
	} else {
		$self->wait($path);
		until($_ = join "", $self->read_bk) {
			main::msg("Компиллятор `$watch->{hung}` приказал долго жить"), return if kill 0, $self->{pid};
			main::msg ":red", "Нет ответа компиллятора `$watch->{hung}` на cp $path $watch_path";
			#Utils::cp($path, $watch_path);
		}
	}
	
	my $is_err;
	($_, $is_err) = $app->kitty->reg_error($_, $path);
	
	$_ = $app->kitty->reg_compile($_, $path, $watch->{reg_compile});
	
	my @out = split /\n/, $_;
	
	unless($is_err) {
	
		Time::HiRes::usleep($self->{watch}{sleep} * 1000) if exists $self->{watch}{sleep};
		
		$self->wait($watch_out_path);
		
		if(-e $map) {
			my $p = $js_path;
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