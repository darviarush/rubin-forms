package R::Response;
# содержит параметры, необходимые для ответа

use base R::Utils::Object;

use HTTP::Date;

sub header {
	my ($self, $k, $v) = @_;
	if($k =~ /^Content-Type$/i) { $self->type($v) }
	else {
		$self->{head}{$k} = $v = Utils::uri_escape($v, qr/[^ -\xFF]/);
		push @::_HEAD, $k.": ".$v;
	}
}

sub type {
	my ($self, $v) = @_;
	if(@_>1) {
		$v .= "; charset=utf-8" if $v =~ /^text\// && $v !~ /;\s*charset=/;
		$self->{head}{"Content-Type"} = $v;
		$self
	} else {
		$self->{head}{"Content-Type"} //= "text/plain; charset=utf-8";
	}
}

sub cookie {
	my ($self, $name, $value, %param) = @_;
	my $val = join "", $name, "=", $value,
		(exists $param->{expire}? ("; Expires=" , time2str($param->{expire})): ()),
		(exists $param->{path}? "; Path=$param->{path}": ()),
		(exists $param->{domain}? "; Domain=$param->{domain}": ()),
		(exists $param->{secure}? "; Secure": ()),
		(exists $param->{httponly}? "; HttpOnly": ());
	header "Set-Cookie", $val;
	push @::_COOKIE, $val;
	
}

sub redirect {
	my ($self, $url, $text) = @_
	$self->{status} = 307;
	$self->header("Location" => $url);
	$self->body("Redirect to <a href='$_[0]'>".Utils::escapeHTML($text // $url)."</a>");
}

sub status { 
	my($self, $status) = @_;
	if(@_ > 1) { $self->{status} = $status; $self } else { $self->{status} // 200 }
}

sub body { 
	my($self, $body) = @_;
	if(@_ > 1) {
		push @{$self->{body}}, ref $body? @$body: $body;
		$self
	}
	else { my $status; $self->{body} //= ($status = $self->status)." ".$self->{app}->serverHttpStatus->{$status} }
}

1;