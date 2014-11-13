package R::Server::Fcgi;

use FCGI;

# создаёт подключение
sub new {
	my ($cls, $_port) = @_;
	my $socket = FCGI::OpenSocket(":$_port", 5);
	bless {	socket => $socket }, $cls;
}

# инициализация в новом треде
sub accept {
	my ($self, $ritter) = @_;
	
	my ($env, $in, $out, $x, $y) = {};
	my $request = FCGI::Request($in, $out, $out, $env, $self->{socket});
	open $in, "<", \$x;
	open $out, ">", \$y;
	%$self = (%$self, 
		request => $request,
		stdin => $in,
		stdout => $out,
		env => $env
	);
	
	
	for(;;) {
		last if $self->{request}->Accept() < 0;
	
		main::stat_start() if $::_test;
		
		my $env = $self->{env};
		
		$main::_METHOD = $self->{env}{REQUEST_METHOD};
		#$main::_LOCATION = $self->{env}{DOCUMENT_URI};
		#$main::_URL = $self->{env}{REQUEST_URI};
		$main::_VERSION = $self->{env}{SERVER_PROTOCOL};
		
		main::parse_location(($self->{env}{DOCUMENT_URI} =~ /^$::_RE_LOCATION$/), $env->{'QUERY_STRING'});
		
		$main::_HEAD = { map { my $val = $self->{env}{$_}; s/^HTTP_//; $_=lc $_; s/_(.)/"-".uc $1/ge; ($_ => $val) } grep { /^HTTP_/ } keys %$env };
		
		my $f;
		$::_POST = $env->{CONTENT_LENGTH}? Utils::param_from_post($env->{'REQUEST_BODY_FILE'}? do { open $f, $env->{'REQUEST_BODY_FILE'} or die "NOT OPEN REQUEST_BODY_FILE=".$env->{'REQUEST_BODY_FILE'}." $!"; $f }: $self->{stdin}, $env->{'CONTENT_TYPE'}, $env->{'CONTENT_LENGTH'}): {};
		close $f if defined $f;
		if(0 != keys %$::_POST) { $::param = { %$::POST, %$::param }; }
		
		$::_COOKIE = Utils::param($env->{'HTTP_COOKIE'}, qr/;\s*/);

		my $ret = $ritter->();
		my ($status, $head, $out) = @$ret;
		my $stdout = $self->{stdout};
		push @$head, "Status: $status $main::_STATUS{$status}\r\n";
		print($stdout $_), print $stdout "\r\n" for @$head;
		print $stdout "\r\n";
		print $stdout $_ for @$out;
		
		$main::_action = $main::_VERSION = $main::_METHOD = $main::_LOCATION = $main::_URL = $main::_HEAD = $main::_COOKIE = $main::_GET = $main::_POST = $main::param = $main::_user_id = undef;
		
		main::stat_end("", $head, $out) if $::_test;
		
		@main::_HEAD = %main::_HEAD = @main::_COOKIE = ();
		@$out = ();
	}
}

sub close { my ($self) = @_; FCGI::CloseSocket($self->{socket}); }

1;