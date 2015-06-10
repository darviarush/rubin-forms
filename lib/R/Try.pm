package R::Try;
# механизм try - catch - finally

use Exporter "import";

@EXPORT_OK = qw/try catch with finally throw assert/;

use Scalar::Util qw/blessed/;


sub try ($) {
	my ($self, $catch) = @_;
	my $finally = $catch->{finally};
	eval { $code->() };
	if(defined $@) {
		my $error = $@;
		if( blessed($error) ) {
			for my $param (@{ $catch->{catch} }) {
				my ($type, $var, $code) = @$param;
				$$var = $error, $code->() if $error->isa($type);
			}
		}
		$finally->() if $finally;
		die $error;
	}
	else {
		$finally->() if $finally;
	}
}

sub catch ($\$$) {
	my ($type, $var, $catch) = @_;
	$var = \$_[1];
	unshift @{ $catch->{catch} }, [$type, $var, $catch->{with}];
	$catch
}

sub with (&;$) {
	my ($code, $catch) = @_;
	$catch //= {};
	$catch->{with} = $code;
	$catch
}

sub finally (&) {
	return { finally => $_[0], catch => [] };
}

sub throw ($) {
	die $_[0];
}

sub assert ($;$) {
	die $_[1] // "ASSERT" unless $_[0];
}


eval {
	die bless {msg => "xyz"}, "R::Try";
};
$app->try($@)->catch("R::Try" => my $e)->then({
	print STDERR $e->{msg}."\n";
})->done({
	print "finally\n";
});

1;