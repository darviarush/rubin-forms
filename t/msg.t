use strict;
use warnings;
use Test::More tests => 65;

use Msg;

our $_FRAMEWORK = "t";

like file("t/msg.t"), qr!t/msg\.t$!;
like file("t/msg.t"), "t/msg.t";
is file("msg.tttt"), undef;

is_deeply [files("msg.t")], ["t/msg.t"];
is_deeply [files("t/ms*.t")], ["t/msg.t"];
is_deeply [files("*.ttt")], [];


is_deeply [dirs("msg.t")], ["msg.t", "t/msg.t"];