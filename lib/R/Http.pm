package R::Http;
# всё, что относится к протоколу http - сервер и клиент

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

# создаёт http-сервер на указанном порту
sub makeServer {
	my ($self, $port) = @_;
	my $server = $app->new->serverHttp;
	$server
}

# коннектится к чему-то по протоколу http
sub connect {
	$app->new->connectHttp;
}





1;