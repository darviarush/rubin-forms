package R::Response;
# �������� ���������, ����������� ��� ������

use strict;
use warnings;

use HTTP::Date qw//;

Utils::has("app", "stash");

# �����������
sub new {
	my ($cls, $app) = @_;
	bless {app=>$app}, $cls;
}

# ���������� ������ � ��������� ���������
sub reset {
	my ($self) = @_;
	my $app = $self->{app};
	%$self = (app => $app, stash => {}, status => 200, head=>{'Content-Type' => 'text/html; charset=utf-8'}, body=>undef );
	$self
}


# ������������� � ���������� ���������
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


# ������������� � ���������� content-type
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

# ������������� ����
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

# ��������������� �� ������ url. � ajax ��������������� ���������� �� �������, � ����� - �� �������
sub redirect {
	my ($self, $url, $text) = @_;
	$url = $self->{app}->request->referer("/") unless $url;
	$self->{status} = 303;	# 307 - �������������� � POST, � 303 - GET
	$self->head("Location" => $url);
	$self->body("Redirect to <a href='$url'>".Utils::escapeHTML($text // $url)."</a>");
}

# ���� ���������������?
sub be_redirect {
	my ($self) = @_;
	$self->{status} == 303;
}

# status - 404
sub not_found {
	my($self) = @_;
	$self->error(404);
}

# �������������/���������� ������
sub status {
	my($self, $status) = @_;
	if(@_ > 1) { $self->{status} = $status; $self } else { $self->{status} }
}

# ������������� ������ - ������ body
sub error {
	my($self, $status, $error) = @_;
	
	my $recursive_error = $self->{is_error};
	
	$self->{status} = $status;
	$self->{is_error} = [$status, $error];
	
	my $action = "error/$status";
	
	return $self->render($action, {error=>$error}) if !$recursive_error and exists $self->{app}->action->{htm}{$action};
	
	$self->type('text/html');
	my $httpStatus = $self->{app}->serverHttpStatus;
	my $msg = "$status " . $httpStatus->{$status} . "<br>" . Utils::escapeHTML($error // "") . "<br>";
	$msg .= "\n\nRecursive error from " . Utils::escapeHTML($recursive_error->[0]) . " " . Utils::escapeHTML($httpStatus->{$recursive_error->[0]}) . "\n" . Utils::escapeHTML($recursive_error->[1] // "") if $recursive_error;
	$self->body($msg);
}

# �������������/���������� body
sub body { 
	my $self = shift;
	if(@_ > 0) {
		$self->{body} = [@_];
		$self
	}
	else { $self->{body} }
}

# ��������� � body ������ �������
sub prepend {
	my $self = shift;
	unshift @{$self->{body}}, @_;
	$self
}

# ��������� � body ������ ������
sub append {
	my $self = shift;
	push @{$self->{body}}, @_;
	$self
}

# ��������� � body ������ ������
sub echo {
	my $self = shift;
	push @{$self->{body}}, @_;
	$self
}

# ���������� body � ���� �������
sub arr_body { @{$_[0]->{body}} }

# ���������� body � ���� ������
sub str_body { join "", @{$_[0]->{body}} }


# �������������/���������� ������� ��� ������� �����
sub layout {
	my $self = shift;
	if(@_ > 0) {
		$self->{layout} = [@_];
		$self
	}
	else { $self->{layout}? @{$self->{layout}}: @{$self->{app}{action}->layout($self->{app}{request}{action})} }
}

# ���������� ��������� ��������� ��������: $request->param + $errors + $info
sub default_param {
	my ($self) = @_;
	my $param = $self->{app}{request}->ids;
	return {%$param, %{$self->{default_param}}} if $self->{default_param};
	return $param;
}

# ���������� ��������� ��� �����
sub form {
	my ($self) = @_;
	$self->{form} //= do {
		my $form = $self->{app}{request}->param('@form');
		die "�� ������ �������� form" unless defined $form;
		$form =~ s/^[^-]+-//;
		my $param = $self->{default_param} //= {};
		$param = $param->{$_} //= {} for split /-/, $form;
		$param
	};
}

# ���������� ���������� ������
sub errors { $_[0]->{errors} }

# ��������� ������ �� �����
sub addErrors {
	my ($self, @errors) = @_;
	my $form = $self->form;
	@errors = map { { error => $_ } } @errors;
	push @{ $form->{errors} }, @errors;
	$self->{errors} //= 0;
	$self->{errors} += @errors;
	$self
}

# ��������� ������ ��� �������� �����
sub addError {
	my ($self, $element, $error) = @_;
	my $form = $self->form;
	$form->{"${element}_error"} = $error;
	$self->{errors} //= 0;
	$self->{errors} ++;
	$self
}

# ��������� �������� �� �����
sub addValue {
	my ($self, $name, $value) = @_;
	$self->form->{$name} = $value;
	$self
}

# ��������� ���������� �� �����
sub addInfo {
	my ($self, @info) = @_;
	push @{ $self->form->{info} }, map { { info => $_ } } @info;
	$self
}

# ���������� � body ��������
sub render {
	my ($self, $_action, $data) = @_;
	my $app = $self->{app};
	my $request = $app->request;
	my $response = $self;
	
	my $action = $app->action;
	
	if(defined $_action) {
		$request->{action} = $_action;
	} else {
		$_action = $request->{action};
	}
	
	if(defined $data) {
		$request->{ids} = {%{$request->{ids}}, %$data};
		$request->{param} = {%{$request->{param}}, %$data} if defined $request->{param};
	}
	
	my $_action_act = $action->{act};
	if(my $form_action = $request->param('@action')) {
		$_action_act->{$form_action}->($app, $request, $response);
		return $self if $response->be_redirect;
	}
	
	my @ret;
	my $action_htm = $action->{htm}{$_action};
	if(defined $action_htm) {
		@ret = $self->wrap;
	} elsif(defined(my $act = $_action_act->{$_action})) {
		$response->type('application/json; charset=utf-8');
		@ret = $act->($app, $request, $response);
	# } elsif(exists $app->{modelMetafieldset}{$_action}) {	
		# my $bean = $app->model->$_action($request->param);
		# @ret = {id=>$bean->{id}};
	} else {
		$response->error(404);
	}

	$response->{body} = \@ret unless defined $response->{body};
	
	$self
}

# ajax-��������
sub ajax_redirect {
	my ($self) = @_;
	
	$self->{redirect} //= 0;
	die "������� ��������� ������ 5. ������������" if $self->{redirect}++ > 5;
	
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
	
	# �������� � ��������� �������
	$self->render->append("<script><!--\nCRoot.navigate('" . Utils::escapejs($location) . "', '" . Utils::escapejs($self->{stash}{title}) . "')\n--></script>");
}

# ��������� � ����������� � ������� ����
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
	
	#::msg 'lay:', $response->layout;
	
	my @ret;
	for my $layout ($response->layout) {
		$action_act = $_action_act->{$layout};
		my $arg = $action_act? $action_act->($app, $request, $response): (ref $ret[0]? $ret[0]: $response->default_param);
		@ret = $_action_htm->{$layout}->($app, $arg, $layout, \@ret);
	}

	@ret
}

1;