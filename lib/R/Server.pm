package R::Server;
# базовый класс для серверов
# распечатывают статистику. Используются в драйверах

use strict;
use warnings;


use R::Request;

use Time::HiRes qw//;
use POSIX qw//;

Utils::has("R::Server", "app");

sub new {
	my ($cls, $app) = @_;
	local $_ = $app->ini->{site}{server} // "http";
	/^fcgi$/i? $app->serverFcgi: /^psgi$/i? $app->serverPsgi: /^http$/? $app->serverHttp: die "main.ini [site] server=$_ - такого сервера нет";
}

sub stat_start {
	my ($self) = @_;
	$self->{_STAT}{time} = Time::HiRes::time();
}

sub stat_begin {
	require threads;
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $_req = $app->ini->{req} // $app->ini->{site}{"log-level"};
	if($_req) { main::msg ":empty", "\n", ":red", $request->method, ":reset", " ", $request->url, " ", ":red", $request->version, " ", ":cyan", "tid", ":reset", ":", " ", threads->tid(), ":cyan", " from ", ":reset", join(", ", threads->list());
	}
	if($_req > 1) { main::msg ":empty", ":magenta", $_, ":reset", ":", " ", ":cyan", $request->{head}{$_} for keys %{$request->{head}} };
	if($_req > 2) { my $post = $request->post; my $v; $v=$post->{$_}, main::msg ":empty", ":CYAN", $_, ":RESET", ":", " ", (ref $v eq "JSON::XS::Boolean"? (":RED", "$v", ":RESET"): ref $v? Utils::Dump($v): $v) for keys %$post };
}

sub stat_end {
	my ($self, $RESPONSE) = @_;
	$RESPONSE =~ s/\s*$//;
	main::msg $RESPONSE;
	my $app = $self->app;
	my $_req = $app->ini->{req} // $app->ini->{site}{"log-level"};
	my $head = $app->response->head;
	if($_req) { main::msg ":empty", ":GREEN", $_, ":RESET", ":", " ", ":YELLOW", $head->{$_} for keys %$head; }
	if($_req > 2) { main::msg $_ for @{$self->app->response->body} }
	if($_req) {
		my $time = Time::HiRes::time() - $self->{_STAT}{time};
		main::msg ":empty", ":MAGENTA", "sec", ":RESET", " $time";
	}
}

# выдаёт файл
sub file {
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	eval {
		my $root = abs_path(".");
		if($root ne substr abs_path($request->html), 0, length $root) {
			$response->error(403, "403 ".$app->serverHttpStatus->{403});
		} else {
			my $path = $request->html;
			$response->type( $app->serverHttpMime->{$request->ext} );
			$response->head( "Content-Length" => -s $path );
			$response->body( Utils::file2array($path, $app->ini->{site}{buf_size} // 1024*1024) );
		}
	};
	$response->error(404, $! // $@) if $! // $@;
}

# Обработчик с файлами
sub tan {
	my ($self) = @_;
	if($self->{app}->request->{ext}) { $self->file } else { $self->ritter }
}

# Подчинённый обработчик запросов
sub ritter {
	my ($self) = @_;
	my $app = $self->{app};
	my $response = $app->response;
	#$app->session->reset;
	
	eval {
		$response->render;
		return $response->ajax_redirect if exists $response->{head}{Location} and $app->{request}{head}{Ajax};
	};

	if(my $error = $@ || $!) {
		my $is_io = $!;
		$@ = $! = undef;
		
		if(ref $error eq "R::Response::Raise") {
			$response->body($error);
		} else {

			$error = ref $error eq "R::Raise::Trace" ? $error: $app->raise->set($error);
			main::msg "$error";
			
			$error = $app->ini->{site}{test} ? $error: $app->raise->set("Внутренняя ошибка");
			
			eval {
				$response->error(500, join "", $error->html);
			};
			if($@) {
				$response->status(500);
				if($app->{request}{head}{Accept} =~ /^text\/json\b/) {
					$response->type("text/plain");
					$response->body({error=> $error});
				} else {
					$response->type("text/html");
					$response->body($error->html);
				}
			}
			$app->connect->reconnect;
		}
	}

	$app->{stash} = {};
	
}



# фреймы - механизм лайоутов и таргетов форм
# sub submit {
	# my ($self) = @_;
	# my $app = $self->{app};
	# my ($ret) = $self->wrap(1);
	# $app->response->type("text/plain");
	# return {
		# head => {
			# stash => $app,
			# url => $app->{request}{url},
		# },
		# body => $ret
	# }
# }


1;