use common::sense; use R::App; R::App::app->syntaxAg->include(qw/R::File/);
; (do { package String::Fix::f; use common::sense; use R::App; BEGIN { @String::Fix::f::ISA = qw/R::File/ } sub void { my $DATA = { me => shift }; 
 } __PACKAGE__ })
