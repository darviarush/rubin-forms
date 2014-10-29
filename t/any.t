use Test::More tests => 1;

use IPC::Open3;
use AnyEvent;

use Msg;
use Utils;
use R::Select;

$pid = open3($in, $out, $out, "perl -e 'print \"hi1\n\"; print STDERR \"hi!\\n\"'") or die $!;

while(<$out>) { print ":$_" }

#Utils::nonblock($in, $out, $err);

#my $done = AnyEvent->condvar;

#AnyEvent->io(fh => $out, poll => "r", cb => sub { msg "io!"; $done->send(scalar <$out>); });

#@res = $done->recv();

#msg "ppppppppppppppppppppppp";

#is "hi!\n", "@res";