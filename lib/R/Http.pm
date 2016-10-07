package R::Http;
# протокол http

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# возвращает клиента http (LWP) с куками
sub ua {
	my $self = shift;
	require LWP::UserAgent;
	require LWP::ConnCache;
	my $ua = LWP::UserAgent->new(agent => 'RubinForms-Agent', conn_cache => 1, @_);
	$ua->conn_cache(LWP::ConnCache->new);
	$ua->conn_cache->total_capacity(undef);
	$ua->cookie_jar({});
	$ua
}

# возвращает клиента websocket
sub ws {
	my ($self, $url) = @_;
	$app->httpWs->new($url);
}

1;