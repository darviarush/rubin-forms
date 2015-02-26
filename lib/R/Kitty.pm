package R::Kitty;
# содержит все kitty-cgi процессы

use strict;
use warnings;

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
	$ps = R::Kitty::Process->new($self->{app}, $wrapper, $wrapper_path // "$::_FRAMEWORK/lib/KittyCGI/kitty.$wrapper") unless $ps;
	
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
	
	main::msg "start kitty", `pwd`, $cmd, $wrapper_path;
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

	my $out = $self->{out};
	while(<$out>) {
		$self->{app}->response->append($_), next unless s/^\x6//;	# не команда, а вывод
		if(/^end\s+(.+)?/) { main::msg 'end'; last; } # может вернуть json
		else { die "Неизвестная команда `$_`"; }
	}
	
}

sub DESTROY {
	my ($self) = @_;
	kill 9, $self->{pid};
}

1;