(do { package Nil; BEGIN { $Nil::CLASSES{"Nil"}++ } sub render { my $DATA = { me => shift }; 



sub new { my $DATA = { me => bless({}, do { my $cls=shift; ref $cls || $cls }) };  
$DATA->{me}}






 } __PACKAGE__ })