use AnyEvent;

my $done = AnyEvent->condvar;

my ($w, $t);



$w = AnyEvent->io (
    fh => \*STDIN,
    poll => 'r',
    cb => sub {
        chomp (my $input = <STDIN>);
        warn "read: $input\n";
        undef $w;
        undef $t;
        $done->send($input);
    });

$t = AnyEvent->timer (
    after => 2,
    cb => sub {
        if (defined $w) {
            warn "no input for a 4.2 sec\n";
            undef $w;
            undef $t;
        }
        $done->send();
    });

warn $done->recv()
