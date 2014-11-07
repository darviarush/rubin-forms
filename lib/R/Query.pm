package R::Query;
# 

use R::Utils::Connect;

sub new { my ($cls, $app) = @_; bless { app => $app }, $cls }


sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	my $sub = (sub {
		my ($tab) = @_;
		sub {
			my ($self) = @_;
		}
	})->($prop);
	#no strict 'refs';
	*{$AUTOLOAD} = $sub;
	#use strict 'refs';


	my $cls = "${AUTOLOAD}::$prop";
	my $load = $prop; $load =~ s![A-Z]!/$&!g;
	$load = main::file "lib/R/Query/".ucfirst($load).".pm";
	require $load if -e $load;
	#$_[0]->{$prop} = $new->new($_[0]);
		
	goto &$sub;
}

sub DESTROY {}

1;