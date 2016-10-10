package R::Model::Extend::Sphinx::Metafieldset;
# 

use common::sense;
use R::App;

use base "R::Model::Metafieldset";

# конструктор
sub new {
	my ($cls) = @_;
	
	my $self = $cls->SUPER::new("Sphinx", $app->sphinx, $app->ini->{sphinx}{model});
	
	$self
}

1;