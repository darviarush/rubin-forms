package R::Http;
# реализует всё связанное с проколом http

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

# коннектится к сайту и возвращает страницу
sub connect {
	my ($self, ) = @_;
	#use AnyEvent::HTTP;
	todo;
}


# создаёт сервер
sub listen {
	my ($self, $port) = @_;
	$app->httpServer($port);
}



1;
