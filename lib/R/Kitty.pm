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

sub new {
	my ($cls, $app, $wrapper, $wrapper_path) = @_;
	my ($in, $out) = (gensym, gensym);
	
	my $cmd = $app->ini->{kitty}{$wrapper} // $wrapper;
	
	main::msg "start kitty", $cmd, $wrapper_path;
	#require AnyEvent;
	
	my $pid = open3($in, $out, $out, "$cmd $wrapper_path") or die "Не запустился процесс `$wrapper_path`. $!";
	my $old = select $out; $|=1; select $in; $|=1; select $old;
	
	#Utils::nonblock($err);
	#Utils::nonblock($out);
	
	my $self = bless {
		app =>$app,
		pid=>$pid,
		in=>$in,
		out=>$out,
		#err=>$err,
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
	while(<$out>) {
		
		push(@$body, $_), next unless /\x6/;	# не команда, а вывод
		
		push @$body, $` if length $`;
		$_ = $';
		
		if(/^end(?:\s+(.+?))?\s*$/) { return $1? $json->decode($1): undef; } # может вернуть json
		elsif(/^head(?:er)?(?:\s+(.+?))?(?::\s+(.*?)\s*)?$/) {
			if(defined $2) { $response->{head}{$1} = $2	}
			elsif(defined $1) { print $in $response->{head}{$1} . "\n" }
			else { print $in $json->encode($response->{head}) }
		}
		elsif(/^write\s+(\d+)\s*$/) {
			my $size = $1;
			my $bsize = $app->ini->{site}{"buf-size"} // 1024*1024;
			my $n = int($size / $bsize);
			my $last = $size % $bsize;
			my $buf;
			for(my $i=0; $i<$n; $i++) {
				read $out, $buf, $bsize;
				push @$body, $buf;
			}
			my $i=read $out, $buf, $last;
			push @$body, $buf;
			$buf = undef;
		}
		elsif(/^([\w\.]+)(?:\s+(.+?))?\s*$/) {
			my ($path, $param) = ($1, $2);
			my $app_ = $app;
			my @path = split /\./, $path;
			my $cmd = pop @path;
			for $path (@path) { $app_ = $app_->$path }
			$param = [ $app_->$cmd( @{ $json->decode($param) } ) ];
			print $in $json->encode($param) . "\n";
			($app_, $path, $param, @path, $cmd) = ();
		}
		else { die "kitty: Неизвестная команда `$_`"; }
	}
	#main::msg 'экстренное завершение', $., $response->body();
}

# деструктор
sub DESTROY {
	my ($self) = @_;
	kill 9, $self->{pid};
}

1;