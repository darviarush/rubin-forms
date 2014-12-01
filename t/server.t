# тестирование сервера

use strict;
use warnings;

use Msg;
use JSON;
use Test::More tests => 4;

our $app;

END {
$app->process->close;
}

$app->ini({
	site => {
		server => 'http',
		port => 8999,
		lords => 1,
		test => 1,
		"log-level" => 0
	}
})->server;

$app->process->fork(*lord);

sub lord {
	$app->server->loop(*ritter);
}

sub ritter {
	$app->response->body($app->request->param);
}

my $text = Utils::post("http://localhost:8999/id10_12?x=1", { y=>2 });

is_deeply from_json($text), { id=>10, id2=>12, x=>1, y=>2 };

$text = Utils::post("http://localhost:8999/id10_12?x=5", { y=>2 });
is_deeply from_json($text), { id=>10, id2=>12, x=>5, y=>2 };


my $ua;
($ua, $text) = Utils::post("http://localhost:8999/", { i=>6 }, \"keepAlive");
is_deeply from_json($text), { i=>6 };

my $r = $ua->get("http://localhost:8999/x_7");
is_deeply from_json($r->content), { id=>7 };
