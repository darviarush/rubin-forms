package R::New;
# 

use common::sense;
use R::App;
use vars '$AUTOLOAD';


# конструктор
sub new {
	my ($cls) = @_;
	bless {base => "R"}, $cls;
}


sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	my $base = $self->{base};
	my $new = $prop; $new =~ s![A-Z]!::$&!g; $new = $base."::".ucfirst $new;
	my ($self) = @_;
	
	eval "sub $AUTOLOAD { my (\$self, \@args) = \@_; ${new}->new(\@args) }";
	die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	my $sub;
	{no strict "refs"; $sub = *{$AUTOLOAD}{CODE} };

	my $load = $prop; $load =~ s![A-Z]!/$&!g;
	$load = $base."/".ucfirst($load).".pm";
	require $load;
	#{no strict "refs"; ${"${new}::app"} = $app; ${"${new}::new"} = $self };
		
	goto &$sub;
}

sub DESTROY {}

1;