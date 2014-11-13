use strict;
use warnings;

use Msg;
use JSON;
use Test::More tests => 1;

our $app;

END {
$app->server->close;
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
	$app->server->accept(*ritter);
}

sub ritter {
	$app->response->body($app->request->param);
}

my $text = Utils::post("http://localhost:8999/id10_12?x=1", { y=>2 });

is_deeply from_json($text), { id=>10, id2=>12, x=>1, y=>2 };

