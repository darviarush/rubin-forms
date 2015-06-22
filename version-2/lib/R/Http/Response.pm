package R::Response;
# ответ на запрос

use common::sense;
use R::App;

use HTTP::Date qw//;

# конструктор
sub new {
	my ($cls, $request) = @_;
	bless {
		echo => [],
		head => {'Content-Type' => 'text/html; charset=utf-8'},
		public
			status => 200,
			stash => {},
			request => $request,
	}, $cls;
}

# добавляет к ответу данные
sub echo (@) {
	my $self = shift;
	push @{$self->{echo}}, @_;
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
	$url = $self->request->referer("/") unless $url;
	$self->{status} = 303;	# 307 - перенаправляет и POST, а 303 - GET
	$self->head("Location" => $url);
	$self->echo("Redirect to <a href='$url'>", $app->html->to($text // $url), "</a>");
}

# есть перенаправление?
sub be_redirect {
	my ($self) = @_;
	$self->{status} == 303;
}

# status - 404
sub not_found {
	my($self) = @_;
	$self->status(404);
}

# отправляет ответ
sub send {
	my ($self) = @_;
	
	my $socket = $self->request->socket;
	
	
}



1;
