BEGIN { use common::sense; my ($class, $file, $lineno) = ("Nil", '/cygdrive/c/__/rubin-forms/ag/Nil.ag', 1); my $c = $Nil::CLASSES{$class}; die "класс $class встречается в $file:$lineno и в $c->{file}:$c->{lineno}" if $c; $Nil::CLASSES{$class} = { file => $file, lineno => $lineno };  } (do { package Nil; use common::sense; use R::App; sub void { my $DATA = { me => shift }; 
#  корневой класс

#  конструктор корневого класса
sub new { my $DATA = { me => bless({}, do { my $cls=shift; ref $cls || $cls }) };  
(%{$DATA->{me}}) = (@{(\@_)})
; $DATA->{me} }






 } __PACKAGE__ })
