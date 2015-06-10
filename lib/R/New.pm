package R::New;
# создаёт новый экземпляр указанного класса

use strict;
use warnings;

#use common::sense;
use R::App;
use vars '$AUTOLOAD';


# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}


sub AUTOLOAD {
	my ($self) = @_;
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	my $base = $self->{base} // "R";
	my $new = $prop; $new =~ s![A-Z]!::$&!g; $new = $base."::".ucfirst $new;
	
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