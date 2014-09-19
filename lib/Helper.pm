use strict;
use warnings;

package Helper;

use JSON;
use Data::Dumper;
use Utils;

our %_NO_ESCAPE_HTML = Utils::set(qw(raw json dump));

sub json { JSON::to_json($_[0]) }

sub raw { $_[0] }

sub html { defined($_[0])? Utils::escapeHTML($_[0]): "" }

sub nbsp { $_[0] eq ""? "&nbsp;": $_[0] }

sub bool { $_[0]? ($_[1] // '+'): $_[2] }

sub dump { "<pre>".Utils::escapeHTML(Dumper($_[0]))."</pre>" }

sub join { defined($_[0])? Utils::escapeHTML(join(($_[1] // ", "), @{$_[0]}, @_[2..$#_])): "" }

sub at { $_[0]->{ $_[1] } }

# нечётный
sub odd { $_[0] % 2? ($_[1] // "odd"): $_[2] }

# чётный
sub even { $_[0] % 2 == 0? ($_[1] // "even"): $_[2] }

# или или
sub oddeven { $_[0] % 2? ($_[1] // "odd"): ($_[2] // "even") }

# логические операции
my $_FLOAT = qr/-?\d+(?:\.\d+)?(?:E[+-]\d+)?/i;

sub or { $_[0] or $_[1] }
sub and { $_[0] and $_[1] }
sub not { not $_[0] }
sub lt { if($_[0]=~$_FLOAT and $_[1]=~$_FLOAT) { $_[0] < $_[1] } else { $_[0] lt $_[1] } }
sub gt { if($_[0]=~$_FLOAT and $_[1]=~$_FLOAT) { $_[0] > $_[1] } else { $_[0] gt $_[1] } }
sub le { if($_[0]=~$_FLOAT and $_[1]=~$_FLOAT) { $_[0] <= $_[1] } else { $_[0] le $_[1] } }
sub ge { if($_[0]=~$_FLOAT and $_[1]=~$_FLOAT) { $_[0] >= $_[1] } else { $_[0] ge $_[1] } }
sub eq { if($_[0]=~$_FLOAT and $_[1]=~$_FLOAT) { $_[0] == $_[1] } else { $_[0] eq $_[1] } }
sub ne { if($_[0]=~$_FLOAT and $_[1]=~$_FLOAT) { $_[0] != $_[1] } else { $_[0] ne $_[1] } }

# 

1;