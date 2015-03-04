package ex;

sub main {
	my ($app, $id) = @_;
	$app->auth->query('tab', {id=>$id});
}


1;