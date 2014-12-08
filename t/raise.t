use strict;
use warnings;

use Test::More tests => 2;
use Msg;

sub A {
	die "ex - error";
}

eval { A() };

like $@, qr/ex - error/;
like $@, qr/: A\n/;