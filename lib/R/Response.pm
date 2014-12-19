package R::Response;
# содержит параметры, необходимые для ответа

use base R::Utils::Object;

use HTTP::Date qw//;
use JSON qw//;

sub reset {
	my ($self) = @_;
	my $app = $self->{app};
	%$self = (app => $app, status => 200, head=>{'Content-Type' => 'text/html; charset=utf-8'}, body=>undef, layout => [] );
	$self
}

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

sub cookie {
	my ($self, $name, $value, %param) = @_;
	my $val = join "", $name, "=", $value,
		(exists $param->{expire}? ("; Expires=" , HTTP::Date::time2str($param->{expire})): ()),
		(exists $param->{path}? "; Path=$param->{path}": ()),
		(exists $param->{domain}? "; Domain=$param->{domain}": ()),
		(exists $param->{secure}? "; Secure": ()),
		(exists $param->{httponly}? "; HttpOnly": ());
	#$self->head("Set-Cookie", $val);
	push @{$self->{cookie}}, $val;
	$self
}

sub redirect {
	my ($self, $url, $text) = @_;
	$self->{status} = 307;
	$self->head("Location" => $url);
	$self->body("Redirect to <a href='$url'>".Utils::escapeHTML($text // $url)."</a>");
}

# устанавливает/возвращает статус
sub status { 
	my($self, $status) = @_;
	if(@_ > 1) { $self->{status} = $status; $self } else { $self->{status} }
}

# устанавливает ошибку - меняет body
sub error {
	my($self, $status, $error) = @_;
	$self->{status} = $status;
	$self->type('text/plain');
	my $msg = $error // "$status " . $self->{app}->serverHttpStatus->{$status};
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

# устанавливает/возвращает лайоуты для текущей акции
sub layout {
	my $self = shift;
	if(@_ > 0) {
		$self->{layout} = [@_];
		$self
	}
	else { @{$self->{layout}} or @{$self->{app}{action}->layout($self->{app}{request}{action})} }
}

1;