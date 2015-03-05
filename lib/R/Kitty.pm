package R::Kitty;
# содержит все kitty-cgi процессы

use strict;
use warnings;

use POSIX ":sys_wait_h";

# конструктор
sub new {
	my ($cls, $app) = @_;
	bless {app=>$app, wrapper=>{}}, $cls;
}

# выполняет запрос к файлу kitten-cgi. Если wrapper не указан, то берётся расширение имени реквестера
sub request {
	my ($self, $requester, $wrapper, $wrapper_path) = @_;
	my $ext;
	($wrapper)=$requester=~/\.(\w+)$/ unless defined $wrapper;
	
	my $ps = $self->{wrapper}{$wrapper};
	$self->{wrapper}{$wrapper} = $ps = R::Kitty::Process->new($self->{app}, $wrapper, $wrapper_path // "$::_FRAMEWORK/lib/KittyCGI/kitty.$wrapper") if !$ps or 0 > waitpid $ps->{pid}, WNOHANG or 0 == kill 0, $ps->{pid};
	
	$ps->request($requester);
}

# останавливает все процессы или указанный
sub shutdown {
	my ($self, $wrapper) = @_;
	my @pid = $wrapper? $self->{wrapper}{$wrapper}->{pid}: map { $_->{pid} } values $self->{wrapper};
	kill 9, @pid;
}

# следит и перезагружает обёртки изменившихся запросников
sub watch {
	my ($self, $dir, $re, $watch, $act) = @_;
	$re //= join "|", map {/\/kitty\.(\w+)$/; $1} <$::_FRAMEWORK/lib/KittyCGI/kitty.*>;
	$dir //= [main::dirs("action")];
	($watch // $self->{app}->watch)->on(qr/\.($re)$/, $dir, $act // Utils::closure($self, sub {
		my ($self, $path) = @_;
		my ($wrapper)=$path=~/\.(\w+)$/;
		$wrapper = $self->{wrapper}{$wrapper};
		if($wrapper) {
			$wrapper->DESTROY;
			delete $self->{wrapper}{$wrapper};
			main::msg ":empty", "kitty ", ":red", $wrapper, ":reset", " reload";
		}
	}));
}

# расширяет пути для action
sub route {
	my ($self, $route, $dir) = @_;
	
	my $watch = R::Watch->new;
	
	$self->watch($dir, undef, $watch, sub {
		my ($path) = @_;
		$path =~ m!^.*\baction/(.*)\.\w+!;
		$route->{$1} = Utils::closure($self->{app}, $path, sub { my($app, $path) = @_; $app->kitty->request($path) });
	});
	
	$watch->fire;
	
	$self
}

package R::Kitty::Process;
# процесс обёртки

use Symbol;
use IPC::Open3;
use Time::HiRes qw//;
use Socket;


sub new {
	my ($cls, $app, $wrapper, $wrapper_path) = @_;
	my ($in, $out, $err) = (gensym, gensym, gensym);
	
	my $cmd = $app->ini->{kitty}{$wrapper} // $wrapper;
	
	my $pid;
	
	$cmd .= " $wrapper_path" unless $cmd =~ s/%s/$wrapper_path/;
	main::msg "start kitty", $cmd;

	eval {
		$pid = open3($in, $out, $err, $cmd) or die "Не запустился процесс `$wrapper_path`. $!";
	};
	$wrapper_path =~ /\.(\w+)$/, die "Не запускается команда `$cmd` или обёртка `$wrapper_path`: `$!`. Попробуйте указать main.ini:[kitty]:$1" if $@ // $!;
	
	my $old = select $out; $|=1; select $err; $|=1; select $in; $|=1; select $old;
	
	Utils::nonblock($err);
	Utils::nonblock($out);
	
	my $self = bless {
		app =>$app,
		pid=>$pid,
		in=>$in,
		out=>$out,
		err=>$err,
		wrapper=>$wrapper,
		path=>$wrapper_path
	}, $cls;
	
	#$self->{ev_out} = AnyEvent->io(fh=>$out, poll=> 'r', cb=> Utils::closure($self, $self->can("out")));
	#$self->{ev_err} = AnyEvent->io(fh=>$err, poll=> 'r', cb=> Utils::closure($self, $self->can("control")));
	#$self->{wait} = AnyEvent->condvar;
	
	main::msg ":space", "Запустился процесс", ":green", "kitty", ":red", $pid, ":bold black", $wrapper_path;
	
	$self
}

# отправляет запрос
sub request {
	my ($self, $path) = @_;
	my $in = $self->{in};
	print $in "$path\n";

	my $app = $self->{app};
	my $response = $app->response;
	my $json = $app->json;
	my $body = $response->{body} = [];
	
	my $out = $self->{out};
	my $err = $self->{err};
	my $ktimeout = $app->ini->{site}{'kitty-timeout'} // 1;
	my $timeout = $ktimeout;
	my $test = $app->ini->{site}{'test'};
	
	my $bsize = $app->ini->{site}{"buf-size"} // 1024*1024;
	my $size;
	
	my ($ein, $rin, $win) = '';
	
	for(;;) {
	
		main::msg("kitty: ошибка потока при запросе `$path`"), return if vec($ein, fileno($out), 1) or vec($ein, fileno($err), 1);
	
		my $vec = '';
		vec($vec, fileno($out), 1) = 1;
		vec($vec, fileno($err), 1) = 1;
		
		my $time = Time::HiRes::time();
		
		my $nfound = select $rin=$vec, undef, $ein=$vec, $timeout;
		
		$self->close, main::msg("kitty: превышен интервал запроса $ktimeout сек для `$path`"), return unless $nfound;
		#main::msg("kitty: ошибка в потоках `$path`. $!", vec($ein, fileno($out), 1), vec($ein, fileno($err), 1), vec($rin, fileno($out), 1), vec($rin, fileno($err), 1)) if $!;
		
		$timeout -= Time::HiRes::time() - $time;
		$self->close, main::msg("kitty: превышен интервал запроса $ktimeout сек для `$path`"), return if $timeout<=0;
		
		if( vec($rin, fileno($err), 1) ) {
			my @e = map { chomp $_; $_ } <$err>;
			main::msg $_ for @e;
			#if($test) {
				push @$body, map({ $_ = Utils::escapeHTML($_)."<br>\n"; s/\t/'&nbsp;' x 8/ge; s/ {2,}/ ' ' . ('&nbsp;' x (length($&)-1)) /ge; $_ } @e);
			#}
		}
		next unless vec($rin, fileno($out), 1);
	
		if($size) {
			my $i = read $out, my $buf, $size > $bsize? $bsize: $size;
			$size -= $i;		
			push @$body, $buf;
			$buf = undef;
			next;
		}
	
		while(<$out>) {
			
			push(@$body, $_), next unless /\x06/;	# не команда, а вывод
			
			push @$body, $` if length $`;
			$_ = $';
			
			my $isout = s/^\x06//;
			
			if(/^end(?:\s+(.+?))?\s*$/) { # может вернуть json
				main::msg 'end', $1;
				return $1? $json->decode($1): undef;
			}
			elsif(/^head(?:er)?(?:\s+(.+?))?(?::\s+(.*?)\s*)?$/) {
				if(defined $2) { $response->{head}{$1} = $2; print $in "\n" if $isout }
				elsif(defined $1) { print $in $response->{head}{$1} . "\n" if $isout }
				else { print $in $json->encode($response->{head}) if $isout }
			}
			elsif(/^write\s+(\d+)\s*$/) {
				$size = $1;
				print $in "\n" if $isout;
			}
			elsif(/^([\w\.]+)(?:\s+(.+?))?\s*$/) {	# команда от app
				my ($path, $param) = ($1, $2);
				my $app_ = $app;
				my @path = split /\./, $path;
				my $cmd = pop @path;
				eval {
					#main::msg ':space', 'kitty-cmd:', "`$path`", ($param? "`$param`": ());
					for $path (@path) { $app_ = $app_->$path }
					$param = $json->decode($param) if defined $param;
					my @param = $app_->$cmd( ref($param) eq 'ARRAY'? @$param: (defined($param)? $param: ()) );
					if($isout) {
						$param = @param==1? $param[0]: \@param;
						#main::msg 'kitty-out:', \@param;
						$param = eval { $json->encode($param) };
						print $in $param, "\n";
					}
				};
				main::msg $@ if $@;
				#main::msg "kitty ошибка ввода-вывода: $!" if $!;
				($app_, $path, $param, @path, $cmd) = ();
			}
			else { $self->close; main::msg ":red", "kitty: Неизвестная команда `$_` `$isout`"; print $in "\n" if $isout; }
		}
	}
	#main::msg 'экстренное завершение', $., $response->body();
}

# ликвидирует поток
sub close {
	my ($self) = @_;
	kill 9, $self->{pid};
}

# деструктор
sub DESTROY { $_[0]->close }

1;