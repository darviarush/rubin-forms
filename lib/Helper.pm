package Helper;

use warnings;
use strict;

use JSON::XS;
use Data::Dumper;
use Utils;

our %_NO_ESCAPE_HTML = Utils::set(qw(raw html json dump style hidden show));

sub json { JSON::XS->new->encode($_[0]) }

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
my $_FLOAT = qr/^-?\d+(?:\.\d+)?(?:E[+-]\d+)?$/i;
my $_is_float = sub { my ($x) = @_; defined($x) && !ref($x) && $x =~ $_FLOAT };

sub or { $_[0] or $_[1] }
sub and { $_[0] and $_[1] }
sub not { not $_[0] }
sub lt { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] < $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] lt $_[1] } }
sub gt { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] > $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] gt $_[1] } }
sub le { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] <= $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] le $_[1] } }
sub ge { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] >= $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] ge $_[1] } }
sub eq { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] == $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] eq $_[1] } }
sub ne { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] != $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] ne $_[1] } }


# атрибуты, классы, стили
sub visible { $_[0]? "": "display: none" }
sub style { $_[0]? "style=\"$_[0]\"": "" }
sub hidden { $_[0]? "style='display:none'": "" }
sub show { $_[0]? "": "style='display:none'" }
sub img { return "/img/" unless $_[0]; "/images/" . Utils::img_path($_[0]) }

# запуск функции
sub run { my $f = shift; $f->(@_) }

1;