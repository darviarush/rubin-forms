package R::Server::Psgi;


sub new {
	my ($cls, $_port) = @_;
	bless {port => $_port}, $cls;
}

sub bind {
	my ($self) = @_;
}

# http://perl5doc.ru/cpan/PSGI
sub accept {
	my ($self, $app) = @_;
	$main::app = (sub {
		return sub {
			my $env = shift;
			
			main::stat_start() if $::_test;
			
			main::parse_location(($env->{REQUEST_URI} =~ /^$::_RE_LOCATION$/), $env->{QUERY_STRING});
			
			$main::_METHOD = $env->{REQUEST_METHOD};
			$main::_VERSION = $env->{SERVER_PROTOCOL};
			
			# считываем заголовки
			while(my($key, $val) = each %$env) {
				if($key =~ s/^HTTP_//) {
					$key = lc $key;
					$key =~ s/_(\w)/"-".ucFirst $1/ge;
					$main::_HEAD->{ucFirst $key} = $val;
				}
			}
			
			$main::_HEAD->{"Content-Length"} = my $CONTENT_LENGTH = $env->{CONTENT_LENGTH};
			$main::_HEAD->{"Content-Type"} = $env->{CONTENT_TYPE};
			
			# считываем данные
			if($CONTENT_LENGTH) {
				my $f;
				my $body = $main::_HEAD->{'Request-Body-File'};
				$main::_POST = Utils::param_from_post($body? do {
					open $f, $body or die "NOT OPEN REQUEST_BODY_FILE=$body $!"; $f
				}: $env->{"psgi.input"}, $main::_HEAD->{'Content-Type'}, $CONTENT_LENGTH);
				close $f if defined $f;
				$main::param = { %$main::_POST, %$main::_GET };
			}
			$main::_COOKIE = Utils::param($main::_HEAD->{"Cookie"}, qr/;\s*/);
			
			my $ret = $app->();
			my ($status, $head, $out) = @$ret;
			$head = [map { /:\s*/; ($`, $') } @$head];
			
			$main::_action = $main::_VERSION = $main::_METHOD = $main::_LOCATION = $main::_URL = $main::_HEAD = $main::_COOKIE = $main::_GET = $main::_POST = $main::param = $main::_user_id = undef;

			main::stat_end("", $head, $out) if $::_test;

			@main::_HEAD = %main::_HEAD = @main::_COOKIE = ();
			#@$out = ();
			
			[$status, $head, $out]
		}
	})->($app);
}



sub close { my ($self) = @_; }


1