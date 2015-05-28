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
	$url = $self->{app}->request->referer("/") unless $url;
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

# возвращает дефолтные параметры страницы: $request->param + $errors + $info
sub param {
	my ($self) = @_;
	my $param = $self->{app}{request}->param;
	return {%$param, %{$self->{param}}} if $self->{param};
	return $param;
}

# возвращает ошибки
sub errors { $_[0]->{errors} }

# добавляет ошибки на форму
sub addErrors {
	my ($self, $form, @errors) = @_;
	@errors = map { { error => $_ } } @errors;
	push @{ $self->{param}{$form}{errors} }, @errors;
	push @{ $self->{errors}{$form}{errors} }, @errors;
	$self
}

# добавляет ошибку для элемента формы
sub addError {
	my ($self, $form, $element, $error) = @_;
	$self->{errors}{$form}{"${element}_error"} = $self->{param}{$form}{"${element}_error"} = $error;
	$self
}

# добавляет информацию на форму
sub addInfo {
	my ($self, $form, @info) = @_;
	push @{ $self->{param}{$form}{info} }, map { { info => $_ } } @info;
	$self
}

# отображает в body страницу
sub render {
	my ($self, $_action, $data) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $self;
	
	my $action = $app->action;
	my $_action_htm = $action->{htm};
	#my $_HEAD = $request->{head};
	
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
	my @ret;

	if(defined $action_htm) {
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
	
	$self->{redirect} //= 0;
	die "Глубина редиректа больше 5. Зацикливание" if $self->{redirect}++ > 5;
	
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $self;
	my $location = $response->{head}{"Location"};

	my @location = $location =~ m!^$R::Request::RE_LOCATION$!o;
	return unless @location;
	
	my $cookie = $request->cookie;
	$request->reset( 'GET', @location, 'HTTP/1.1', $request->{head} );
	$request->{cookie} = $cookie;
	
	$cookie = $response->{cookie};
	$response->reset->{cookie} = $cookie;
	
	# рендерим и добавляем переход
	$self->render->append("<script><!--\nCRoot.navigate('" . Utils::escapejs($location) . "', '" . Utils::escapejs($self->{stash}{title}) . "')\n--></script>");
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
	my $_action_htm = $action->{htm};
	my $action_act = $_action_act->{$act};
	
	my @ret;
	my $form_action = $request->param("action");
	$_action_act->{$form_action}->($app, $request, $response) if $form_action;
	
	::msg $response->errors, 'x', $response->param;
	
	for my $layout ($response->layout) {
		$action_act = $_action_act->{$layout};
		my $arg = $action_act? $action_act->($app, $request, $response): (ref $ret[0]? $ret[0]: $response->param);
		@ret = $_action_htm->{$layout}->($app, $arg, $layout, \@ret);
	}

	@ret
}

1;