package ex {
	use common::sense;
	require R::App;
	our @ISA = R::App::app->syntaxAg->include(qw/Nil/);
	sub piramid { my $DATA = { me => shift }; ($DATA->{'k'}) = @_;  join("\n", do { my $ref2 = [do { 0 .. (( ($DATA->{k}) //= (6) ))-1 }]; my $ref3 = []; for(my $ref1=0; $ref1<@$ref2; $ref1+=1) { @$DATA{qw/a/} = map { $ref2->[$_] } $ref1..$ref1+0; push @$ref3, do { (((scalar(" ") x scalar(($DATA->{k}) - ($DATA->{a}))) . ("/")) . (scalar(" ") x scalar(($DATA->{a}) * (2)))) . ("\\") } } @$ref3 }) }
sub fish { my $DATA = { me => shift }; ($DATA->{'k'}) = @_;  ($DATA->{k}) //= (6); join("\n", do { my $ref5 = [do { (0 .. ($DATA->{k})-1), (( reverse( 0 .. ($DATA->{k})-1 ) )) }]; my $ref6 = []; for(my $ref4=0; $ref4<@$ref5; $ref4+=1) { @$DATA{qw/a/} = map { $ref5->[$_] } $ref4..$ref4+0; push @$ref6, do { (((scalar(" ") x scalar(($DATA->{k}) - ($DATA->{a}))) . ("/")) . (scalar(" ") x scalar(($DATA->{a}) * (2)))) . ("\\") } } @$ref6 }) }
sub romb { my $DATA = { me => shift }; ($DATA->{'k'}) = @_;  ($DATA->{k}) //= (6); join("\n", (( do { my $ref8 = [do { 0 .. ($DATA->{k})-1 }]; my $ref9 = []; for(my $ref7=0; $ref7<@$ref8; $ref7+=1) { @$DATA{qw/a/} = map { $ref8->[$_] } $ref7..$ref7+0; push @$ref9, do { (((scalar(" ") x scalar(($DATA->{k}) - ($DATA->{a}))) . ("/")) . (scalar(" ") x scalar(($DATA->{a}) * (2)))) . ("\\") } } @$ref9 } )), (( do { my $ref11 = [do { ( reverse( 0 .. ($DATA->{k})-1 ) ) }]; my $ref12 = []; for(my $ref10=0; $ref10<@$ref11; $ref10+=1) { @$DATA{qw/a/} = map { $ref11->[$_] } $ref10..$ref10+0; push @$ref12, do { (((scalar(" ") x scalar(($DATA->{k}) - ($DATA->{a}))) . ("\\")) . (scalar(" ") x scalar(($DATA->{a}) * (2)))) . ("/") } } @$ref12 } ))) }
	sub void { my $DATA = { me => shift }; 
#  класс для примеров


;

;




 }
}
"ex"
