package R::Server;
# базовый класс для серверов
# распечатывают статистику. Используются в драйверах

use base R::Utils::Main;

use R::Request;

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

# выдаёт файл
sub file {
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	my $mime = $app->serverHttpMime;
	eval {
		my $root = abs_path(".");
		if($root ne substr abs_path($request->html), 0, length $root) {
			$response->error(403, "403 $http->{403}");
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
	
	my $action = $app->action;
	#my $_action_act = $action->{act};
	my $_action_htm = $action->{htm};
	my $_HEAD = $request->head;
	my $_action = $request->{action};
	
	eval {
		#my $action = $_action_act->{$_action};
		my $action_htm = $_action_htm->{$_action};
		my $ajax = $_HEAD->{"Ajax"} // "";
		my @ret;
		
		if(defined $action_htm and $ajax eq "submit") {
			
			#$_user_id = $_COOKIE->{sess}? auth(): undef;
			#%_STASH = (user_id => $_user_id);
			$app->stash({});
			
			$self->submit($ajax eq "submit");
			return $self->ajax_redirect if $response->{status} == 307;
		}
		elsif(defined $action_htm and $ajax eq "") {
			$app->stash({});
			@ret = $self->wrap;
		} elsif(defined $action) {
			@ret = $action->($app, $request, $response);
		} elsif(exists $_info->{$_action}) {
			@ret = $self->update;
		} else {
			@ret = $response->error(404);
		}
		
		
		$response->body( @ret==1 && ref $ret[0]? JSON::to_json($ret[0]): @ret );
	};

	if(my $error = $@ || $!) {
		my $is_io = $!;
		$@ = $! = undef;
		
		if(ref $error eq "R::Response::Raise") {
			$response->body($error);
		} else {

			$error = ref $error eq "R::Raise::Trace"? $error: $app->raise->set($error);
			$error = $app->ini->{site}{test} ? $error: "Внутренняя ошибка";
			
			$response->status(500);
			if($_HEAD->{Accept} =~ /^text\/json\b/) {
				$response->type("text/plain");
				$response->body({error=> $error});
			} else {
				$response->type("text/html");
				$response->body($error->html);
			}
			$app->connect->reconnect;
		}
	}
	
	$app->{stash} = undef;
	
}


# ajax-редирект
sub ajax_redirect {
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	
	$request->reset( $response->{head}{"Location"} =~ $R::Request::RE_LOCATION );
	
	my $cookie = $response->{cookie};
	$response->reset->{cookie} = $cookie;
	
	$self->{ritter}->();
}

# выполняет и оборачивает в лайоуты экшн
sub wrap {
	my ($self, $ajax) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	my $act = $request->{action};
	my $action = $app->action;
	my $_action_act = $action->{act};
	my $_action_htm = $ajax? $action->{ajax_htm}: $action->{htm};
	my $action_act = $_action_act->{$act};

	my @ret = $action_act? $action_act->($app, $request, $response): $request->param;
	if(!$action_act || $action_act && !defined $response->{body}) {
		@ret = $_action_htm->{$act}->($app, $ret[0], $act);
		for my $layout ($response->layout) {
			$action_act = $_action_act->{$layout};
			my $arg = $action_act? $action_act->($app, $request, $response): (ref $ret[0]? $ret[0]: {});
			@ret = $_action_htm->{$layout}->($app, $arg, $layout, \@ret);
		}
		
		# for(; my $_layout = $_layout{$_action}; $_action = $_layout) {
			# my $arg = ($action = $_action_act->{$_layout})? $action->($app, $request, $response): {};
			# @ret = $_action_htm->{$_layout}->($app, $arg, $_layout, @ret);
		# }
	}
	@ret
}


# фреймы - механизм лайоутов и таргетов форм
sub submit {
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->{request};
	my $response = $app->{response};
	
	my $result = {};
	my ($id, $url, $act);
	
	$act = $request->{action};
	
	$self->type("text/json");
	
	my $add_res = sub {

		die "Нет экшена `$act`" if not exists $main::_action{$act} and not $main::_action_htm{$act};
		
		my $data = exists $main::_action{$act}? $main::_action{$act}->(): $::param;
		$main::_pages{$act}{code}->($data, $act) if exists $main::_pages{$act}{code};
		
		$result->{$act} = {
			act => $act,
			($id ? (id => $id): ()),
			#(exists $main::_forms{$act} && exists $main::_info->{$act}? (data => action_view($main::_action, $main::param)): ()),
			(defined($data)? (data => $data): ()),
			(exists $main::_pages{$act}{template}? (template => $main::_pages{$act}{template}): ()),
			(exists $main::_pages{$act}{layout_id}? (layout_id => $main::_pages{$act}{layout_id}): ()),
			(exists $main::_layout{$act}? (layout => $main::_layout{$act}): ())
		};
	};

	if($_[0]) {
		$add_res->();
		return $result->{$act};
	}
	
	unless($::param->{_noact_}) {
		#$act = 'index' if $act eq "/";
		my $layout_id = $::param->{_layout_id_};
		my $layout = [];
		for(; $act; $act = $main::_layout{$act}) {
			last if defined($layout_id) and $main::_pages{$act}{layout_id} eq $layout_id;
			$add_res->();
			unshift @$layout, $act;
		}
		$result->{"\@layout"} = $layout;
		if(defined $layout_id and exists $main::_layout{$act}) {
			$result->{$act=$main::_layout{$act}} = { act => $act, layout_id => $result->{$act}{layout_id} };
			unshift @$layout, $act;
		}
	}

	my $frames = Utils::param($::param->{_frames_}, qr/,/);

	while(($id, $url) = each %$frames) {
		if($url =~ /\?/) { ($act, $::param) = ($`, Utils::param($')) } else { $act = $url; $::param = {} }
		$add_res->();
	}

	$result->{'@stash'} = \%::_STASH;
	$result->{'@url'} = $::_URL;

	return $result;
}


1;