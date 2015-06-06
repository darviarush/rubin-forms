
$app->http->makeServer("unix-socket-500")->then({
	my () = @_;
	msg "hi! server 500";
})->route("/")->then({
	
})->error(400 => 499)->then({
	my ($error) = @_;
	msg $error->code . ": " . $error->message;
});

$app->http->makeServer("unix-socket-600")->then({

});


$app->http->connect("unix-socket-500")->then({

});