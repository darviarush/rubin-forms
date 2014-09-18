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

sub oddeven { $_[0] % 2? ($_[1] // "odd"): ($_[2] // "even") }

1;