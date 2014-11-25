# тестирует perl и его библиотеки

use Test::More tests => 2;

use IPC::Open3;
use AnyEvent;

use Msg;

#use R::Select;

$pid = open3($in, $out, $out, "perl -e 'print \"hi1\n\"; print STDERR \"hi!\\n\"'") or die $!;

is "hi!\n", scalar <$out>;
is "hi1\n", scalar <$out>;

#while(<$out>) { print ":$_" }

#Utils::nonblock($in, $out, $err);

#my $done = AnyEvent->condvar;

#AnyEvent->io(fh => $out, poll => "r", cb => sub { msg "io!"; $done->send(scalar <$out>); });

#@res = $done->recv();

#msg "ppppppppppppppppppppppp";

#is "hi!\n", "@res";


use AnyEvent;

my $done = AnyEvent->condvar;

my ($w, $t);



# $w = AnyEvent->io (
    # fh => \*STDIN,
    # poll => 'r',
    # cb => sub {
        # chomp (my $input = <STDIN>);
        # warn "read: $input\n";
        # undef $w;
        # undef $t;
        # $done->send($input);
    # });

# $t = AnyEvent->timer (
    # after => 2,
    # cb => sub {
        # if (defined $w) {
            # warn "no input for a 4.2 sec\n";
            # undef $w;
            # undef $t;
        # }
        # $done->send();
    # });

# warn $done->recv()