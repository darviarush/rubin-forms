package R::Response;
# содержит параметры, необходимые для ответа

use strict;
use warnings;

use HTTP::Date qw//;

Utils::has("app", "stash");

# конструктор
sub new {
	my ($cls, $app) = @_;
	bless {app=>$app}, $cls;
}

# сбрасывает объект в начальное состояние
sub reset {
	my ($self) = @_;
	my $app = $self->{app};
	%$self = (app => $app, stash => {}, status => 200, head=>{'Content-Type' => 'text/html; charset=utf-8'}, body=>undef, layout => [] );
	$self
}


# устанавливает и возвращает заголовки
sub head {
	my ($self, $k, $v) = @_;
	if(@_ == 1) { $self->{head} }
	elsif(@_==2) { $self->{head}{$k} }
	else {
		if($k =~ /^Content-Type$/i) { $self->type($v) }
		else {
			$self->{head}{$k} = $v = Utils::uri_escape($v, qr/[^ -\xFF]/);
			#push @{$self->{HEAD}}, [$k, $v];
		}
		$self
	}
}


# устанавливает и возвращает content-type
sub type {
	my ($self, $v) = @_;
	if(@_>1) {
		$v .= "; charset=utf-8" if $v =~ /^text\// && $v !~ /;\s*charset=/;
		$self->{head}{"Content-Type"} = $v;
		$self
	} else {
		$self->{head}{"Content-Type"}
	}
}

# устанавливает куки
sub cookie {
	my ($self, $name, $value, %param) = @_;
	my $val = join "", $name, "=", $value,
		(exists $param{expires}? ("; Expires=" , HTTP::Date::time2str($param{expires})): ()),
		(exists $param{path}? "; Path=$param{path}": ()),
		(exists $param{domain}? "; Domain=$param{domain}": ()),
		(exists $param{secure}? "; Secure": ()),
		(exists $param{httponly}? "; HttpOnly": ());
	#$self->head("Set-Cookie", $val);
	push @{$self->{cookie}}, $val;
	$self
}

# перенаправление на другой url. В ajax перенаправление происходит на сервере, а иначе - на клиенте
sub redirect {
	my ($self, $url, $text) = @_;
	$self->{status} = 307;
	$self->head("Location" => $url);
	$self->body("Redirect to <a href='$url'>".Utils::escapeHTML($text // $url)."</a>");
}

# status - 404
sub not_found {
	my($self) = @_;
	$self->error(404);
}

# устанавливает/возвращает статус
sub status {
	my($self, $status) = @_;
	if(@_ > 1) { $self->{status} = $status; $self } else { $self->{status} }
}

# устанавливает ошибку - меняет body
sub error {
	my($self, $status, $error) = @_;
	
	my $recursive_error = $self->{is_error};
	
	$self->{status} = $status;
	$self->{is_error} = [$status, $error];
	
	my $action = "error/$status";
	
	return $self->render($action, {error=>$error}) if !$recursive_error and exists $self->{app}->action->{htm}{$action};
	
	$self->type('text/plain');
	my $httpStatus = $self->{app}->serverHttpStatus;
	my $msg = "$status " . $httpStatus->{$status} . "\n" . ($error // "");
	$msg .= "\n\nRecursive error from $recursive_error->[0] " . $httpStatus->{$recursive_error->[0]} . "\n" . ($recursive_error->[1] // "") if $recursive_error;
	$self->body($msg);
}

# устанавливает/возвращает body
sub body { 
	my $self = shift;
	if(@_ > 0) {
		$self->{body} = [@_];
		$self
	}
	else { $self->{body} }
}

# добавляет к body массив спереди
sub prepend {
	my $self = shift;
	unshift @{$self->{body}}, @_;
	$self
}

# добавляет к body массив позади
sub append {
	my $self = shift;
	push @{$self->{body}}, @_;
	$self
}

# возвращает body в виде массива
sub arr_body { @{$_[0]->{body}} }

# возвращает body в виде строки
sub str_body { join "", @{$_[0]->{body}} }


# устанавливает/возвращает лайоуты для текущей акции
sub layout {
	my $self = shift;
	if(@_ > 0) {
		$self->{layout} = [@_];
		$self
	}
	else { @{$self->{layout}} or @{$self->{app}{action}->layout($self->{app}{request}{action})} }
}

# отображает в body страницу
sub render {
	my ($self, $_action, $data) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $self;
	
	my $action = $app->action;
	my $_action_htm = $action->{htm};
	my $_HEAD = $request->{head};
	
	if(defined $_action) {
		$request->{action} = $_action;
	} else {
		$_action = $request->{action};
	}
	
	if(defined $data) {
		$request->{ids} = {%{$request->{ids}}, %$data};
		$request->{param} = {%{$request->{param}}, %$data} if defined $request->{param};
	}
	
	my $action_htm = $_action_htm->{$_action};
	my $ajax = $_HEAD->{"Ajax"};
	my @ret;
	
	#main::msg $_action, $action->{act}{$_action}, $action_htm, $ajax;
	
	if(defined $action_htm and defined $ajax and $ajax =~ /^(submit|load)$/) {
		@ret = $self->submit;
	}
	elsif(defined $action_htm and !$ajax) {
		@ret = $self->wrap;
	} elsif(defined(my $act = $action->{act}{$_action})) {
		$response->type('application/json; charset=utf-8');
		@ret = $act->($app, $request, $response);
	} elsif(exists $app->{modelMetafieldset}{$_action}) {	
		my $bean = $app->model->$_action($request->param);
		@ret = {id=>$bean->{id}};
	} else {
		$response->error(404);
	}

	$response->{body} = \@ret unless defined $response->{body};
	
	$self
}

# ajax-редирект
sub ajax_redirect {
	my ($self) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $self;

	my @location = $response->{head}{"Location"} =~ m!^$R::Request::RE_LOCATION$!o;
	return unless @location;
	
	$request->reset( 'GET', @location, 'HTTP/1.1', $request->{head} );
	
	my $cookie = $response->{cookie};
	$response->reset->{cookie} = $cookie;
	
	$self->render;
}

# выполняет и оборачивает в лайоуты экшн
sub wrap {
	my ($self, $ajax) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $self;
	my $act = $request->{action};
	my $action = $app->action;
	my $_action_act = $action->{act};
	my $_action_htm = $ajax? $action->{ajax_htm}: $action->{htm};
	my $action_act = $_action_act->{$act};
	
	my @ret;
	for my $layout ($response->layout) {
		$action_act = $_action_act->{$layout};
		my $arg = $action_act? $action_act->($app, $request, $response): (ref $ret[0]? $ret[0]: $request->param);
		@ret = $_action_htm->{$layout}->($app, $arg, $layout, \@ret);
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
	$self->{stash}{user_id} = $request->user->id;
	return {
		stash => $self->{stash},
		url => $request->{original} // $request->{url},
		(@$layouts? (layout => $layouts): ()),
		($layout_id? (layout_id => $layout_id): ()),
		body => $result,
	};
}

1;