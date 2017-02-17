use common::sense; use R::App; R::App::app->syntaxAg->include(qw/Nil/);
; (do { package Decorator::make; use common::sense; use R::App; BEGIN { @Decorator::make::ISA = qw/Nil/ } sub void { my $DATA = { me => shift }; 
#  make desc
#  make args, desc
#  make args, desc, spec

sub init { my $DATA = { me => shift }; ($DATA->{'args'}, $DATA->{'desc'}, $DATA->{'spec'}) = @_;  
(((@{(\@_)}) == (0))? do {
$R::App::app->make->add(($DATA->{me}->{class}), ($DATA->{me}->{name}))
 }: ((@{(\@_)}) == (1))? do {
$R::App::app->make->add(((($DATA->{me}->{class}), ($DATA->{me}->{name})), ("")), ($DATA->{args}))
 }: do { 
$R::App::app->make->add((((($DATA->{me}->{class}), ($DATA->{me}->{name})), ($DATA->{args})), ($DATA->{desc})), ($DATA->{spec}))
 })
 }
;
(do { package Decorator::make::category; use common::sense; use R::App; BEGIN { @Decorator::make::category::ISA = qw/Nil/ } sub void { my $DATA = { me => shift }; 
sub init { my $DATA = { me => shift }; ($DATA->{'category'}) = @_;  $R::App::app->make->category($DATA->{category}) }
 } __PACKAGE__ })
 } __PACKAGE__ })
