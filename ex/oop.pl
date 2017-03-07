use common::sense;

my $A = "-A-";

*{"${A}::name"} = sub { $A };

my $B = "-B-";

@{"${B}::ISA"} = qw/A/;
*{"${B}::name"} = sub { $B };
*{"${B}::test"} = sub { my $self=shift; my $x=delete ${"${B}::"}{CODE}; my $res=$self->name; *{"${B}::name"} = $x; $res };


my $n = bless {}, $B;

print $n->test;