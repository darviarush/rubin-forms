# тестирование Msg.pm
use strict;
use warnings;
use Test::More tests => 7;

use Msg;

our $_FRAMEWORK;
chdir $_FRAMEWORK if $_FRAMEWORK;

$_FRAMEWORK = "t";

#like file("t/msg.t"), qr!t/msg\.t$!;
is file("t/msg.t"), "t/msg.t";
is file("msg.t"), "t/msg.t";
is file("msg.tttt"), undef;

is_deeply [files("msg.t")], ["t/msg.t"];
is_deeply [files("t/ms*.t")], ["t/msg.t"];
is_deeply [files("*.ttt")], [];


is_deeply [dirs("msg.t")], ["t/msg.t", "msg.t"];