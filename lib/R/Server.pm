package R::Server;
# базовый класс для серверов
# распечатывают статистику. Используются в драйверах

use base R::Utils::Main;

use Time::HiRes qw//;
use POSIX qw//;


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

sub file {
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	my $mime = $app->serverHttpMime;
	eval {
		my $root = abs_path(".");
		if($root ne substr abs_path($request->html), 0, length $root) {
			$response->error(403);
		} else {
			my $path = $request->html;
			$response->type( $mime->{$ext} );
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
	my $request = $app->request;
	my $response = $app->response;

	$app->session->reset;
	
	my $act = $app->action;
	my $_action = $act->{act};
	my $_action_htm = $act->{htm};
	my $_HEAD = $request->head;
	
	eval {
		my $action = $_action{$_action};
		my $action_htm = $_action_htm{$_action};
		my $ajax = $_HEAD->{"Ajax"};
		
		if(defined $action_htm and $ajax eq "reload") {
			
			#$_user_id = $_COOKIE->{sess}? auth(): undef;
			#%_STASH = (user_id => $_user_id);
			
			@ret = $act->action_submit($ajax eq "submit");
			my @loc;
			return $act->ajax_redirect(\@ret, \@loc) if $_STATUS == 307 and @loc = $_HEAD->{'Location'} =~ /^$_RE_LOCATION$/o;
		}
		elsif(defined $action_htm and $ajax eq "") {
			$_STATUS = 200;
			$_user_id = $_COOKIE->{sess}? auth(): undef;
			%_STASH = (user_id => $_user_id);
						
			@ret = $action? $action->($app, $request, $response): $param;
			if($action_htm and $_STATUS == 200) {
				@ret = $_action_htm{$_action}->($app, $ret[0], $_action);
				for(; my $_layout = $_layout{$_action}; $_action = $_layout) {
					my $arg = ($action = $_action{$_layout})? $action->($app, $request, $response): {};
					@ret = $_action_htm{$_layout}->($app, $arg, $_layout, @ret);
				}
			}
		} elsif(defined $action) {
			@ret = $action->($app, $request, $response);
		} elsif(exists $_info->{$_action}) {
			@ret = $act->action_main($_action);
		} else {
			$response->error(404);
		}
		@ret = map { ref($_)? to_json($_): $_ } @ret;
	};

	if(my $error = $@ || $!) {
		my $is_io = $!;
		$@ = $! = undef;
		if(ref $error eq "Rubin::Raise") {
			@ret = $error;
		} else {
			if(ref $error eq "Rubin::Exception") { $_STATUS = $error->{error}; $error = join "", $error->{error}, " ", $error->{message}, "\n\n", $error->{trace} }
			else { $_STATUS = 500; }
			
			$error = ($is_io? "io: ": "").$error;
			
			my $e = $error;
			$e =~ s!\b((?:called )?at|line|thread)\b!CYAN.$1.RESET!ge;
			main::msg ":empty", ":red", "action-error `$_action".($param->{id} // "")."`:", ":reset", " $e\n";
			$error = $_test ? $error: "Внутренняя ошибка";
			
			if($_HEAD->{Accept} =~ /^text\/json\b/) {
				@_HEAD = "Content-Type: text/plain; charset=utf-8";
				@ret = to_json({error=> $error});
			} else {
				@_HEAD = "Content-Type: text/html; charset=utf-8";
				my ($i, $x) = 0;
				$error =~ s!\b((?:called )?at|line|thread)\b!<font color=LightSlateGray>$1</font>!g;
				$error =~ s/^(.*)/$x = $1; ""/e;
				$error =~ s!\n(\s*)!"</div>\n<div class='".($i++ % 2 == 0? 'e-odd': 'e-even')."'>"!ge;
				$error =~ s!^</div>\n!!;
				$error =~ s!<div class='[^']+'>$!!;
				@ret = ("<style><!--
.e-even {background: lavender}
.e-odd {background: AliceBlue}
.e-even, .e-odd { padding: 4pt 4pt 4pt 20pt }
--></style>
$x
", $error);
			}
			$conn->reconnect;
		}
	}
	
	%_STASH = ();
	
	return [$_STATUS, \@_HEAD, \@ret];
}


1;