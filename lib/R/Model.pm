package R::Model;

sub new {
	my ($cls, $app) = @_;
	bless {app=>$app, models=>{}}, $cls;
}

sub query {
	my ($self, $model, @args) = @_;
	$self->models
}

1;