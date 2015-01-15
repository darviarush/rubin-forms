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
	my $request = $app->request;
	my $response = $app->response;

	$app->session->reset;
	
	my $_info = $app->{connect}{info};
	my $action = $app->action;
	#my $_action_act = $action->{act};
	my $_action_htm = $action->{htm};
	my $_HEAD = $request->{head};
	my $_action = $request->{action};
	
	eval {
		#my $action = $_action_act->{$_action};
		my $action_htm = $_action_htm->{$_action};
		my $ajax = $_HEAD->{"Ajax"};
		my @ret;
		
		main::msg $_action, $action->{act}{$_action}, $action_htm, $ajax;
		
		if(defined $action_htm and defined $ajax and $ajax =~ /^(submit|load)$/) {
			@ret = $self->submit;
		}
		elsif(defined $action_htm and !$ajax) {
			@ret = $self->wrap;
		} elsif(defined(my $act = $action->{act}{$_action})) {
			@ret = $act->($app, $request, $response);
		} elsif(exists $_info->{$_action}) {
			#main::msg "update";
			@ret = $self->update;
		} else {
			return $response->error(404);
		}
	
		$response->{body} = \@ret unless defined $response->{body};
		
		return $self->ajax_redirect if $response->{status} == 307;
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

	$app->{stash} = {};
	
}


# ajax-редирект
sub ajax_redirect {
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	
	my @location = $response->{head}{"Location"} =~ m!^$R::Request::RE_LOCATION$!o;
	main::msg $response->{head}{"Location"}, $R::Request::RE_LOCATION, \@location;
	return unless @location;
	
	$request->reset( 'GET', @location, 'HTTP/1.1', $request->{head} );
	
	my $cookie = $response->{cookie};
	$response->reset->{cookie} = $cookie;
	
	$self->{ritter}->($self);
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

	}
	@ret
}


# фреймы - механизм лайоутов и таргетов форм
sub submit {
	my ($self, $ajax) = @_;
	my $app = $self->{app};
	my $request = $app->{request};
	my $response = $app->{response};
	my $action = $app->{action};
	my $actions = $action->{act};
	my $templates = $action->{htm};
	my $pages = $action->{page};
	my $param = $request->param;
	my $layout = $app->action->{layout};
	
	my $result = {};
	my $act;
	my ($id, $url);
	
	$response->type("text/json");
	
	my $add_res = sub {
		
		die "Нет экшена `$act`" if not exists $actions->{$act} and not exists $templates->{$act};
		
		my $page = $pages->{$act};
		
		my $data = exists $actions->{$act}? $actions->{$act}->($app, $request, $response): $param;
		$page->{code}->($app, $data, $act) if exists $page->{code};
		
		$result->{$act} = {
			#act => $act,
			($id ? (id => $id): ()),
			#(exists $main::_forms{$act} && exists $main::_info->{$act}? (data => action_view($main::_action, $main::param)): ()),
			(defined($data)? (data => $data): ()),
			(exists $page->{template}? (template => $page->{template}): ()),
			(exists $page->{layout_id}? (layout_id => $page->{layout_id}): ()),
			#(exists $layout->{$act}? (layout => $layout->{$act}): ())
		};
		
	};

	if($ajax) {
		$act = $request->{action};
		$add_res->();
		return $result->{$act};
	}
	
	my $layout_id = $param->{_a} // "main";
	my @layout = $response->layout;
	my $layouts = [];
	for (@layout) {
		$act = $_;
		if($layout_id eq ($pages->{$act}{layout_id} // "")) { last; } else { $add_res->($act); }
		unshift @$layouts, $act;
	}

	my $frames = $param->{_f};
	if($frames) {
		$frames = Utils::param($frames, qr/,/);

		while(($id, $url) = each %$frames) {
			if($url =~ /\?/) { $act = $`; $request->{param} = Utils::param($'); } else { $act = $url; $request->{param} = {} }
			$add_res->($act);
		}
	}
	
	#$result->{$layouts->[0]}{layout_id} = $layout_id if @$layouts;
	
	return {
		stash => $app->{stash},
		url => $request->{url},
		(@$layouts? (layout => $layouts): ()),
		($layout_id? (layout_id => $layout_id): ()),
		body => $result,
	};
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