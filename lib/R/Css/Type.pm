package R::Css::Type;
# типизирует ключи css

# см. 
# префиксы по движкам: http://peter.sh/experiments/vendor-prefixed-css-property-overview/
# какие бывают префиксы: http://stackoverflow.com/questions/5411026/list-of-css-vendor-prefixes

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

our %Sep = (transform => " ");
our %KeyVal;
our %Type;
our %Key;
our $k;

# типизирует ключи
sub type(@) {
	my $code = shift;
	$code = \&$code;
	$Type{$_} = $code for @_;
}

# вендоризирует ключи
sub vendor(@) {
	my $code = shift;
	$code = \&$code;
	$Key{$_} = $code for @_;
}

# на ключи и значение
sub xak($$$) {
	my ($key, $val, $code) = @_;
	$code = \&$code;
	$KeyVal{$key}{$val} = $code;
}



type "size", qw/fontSize width height maxWidth maxHeight minWidth minHeight marginLeft marginTop marginRight marginBottom paddingLeft paddingTop paddingRight paddingBottom left top right bottom/;

type "size4", qw/margin padding borderRadius/;

type "string", qw/content/;

vendor "mini", qw/borderRadius opacity/;

vendor "maxi", qw/filter transition transitionProperty transitionDuration transitionTimingFunction transitionDelay transform transformOrigin perspective perspectiveOrigin/;

vendor "opera", qw/textOverflow/;

xak "display" => "inline-block" => "iblock";
#xak "position", "fixed", "fixed";

#################### типы

my $RE_NUM = qr/^-?(?:\d*\.\d+|\d+)$/;

sub size {
	if(Num($_) && $_ != 0) { ($_ * 100) . "%" }
	elsif(ref $_ eq "SCALAR") { $$_ . "em" }
	else { $_ }
}

sub deg {
	if(Num $_) { $_ * 360 . "deg" }
	elsif(ref $_ eq "SCALAR") { $$_ . "deg" }
	else { $_ }
}

# несколько значений size
sub size4 {
	join " ", map { &size } split /\s+/, $_;
}

sub string {
	ref $_? $$_: do { my $x=$_; $x=~s/"/\"/g; "\"$x\"" }
}


#################### вендоры

# минимальный набор вендорных префиксов
sub mini {
	return "-moz-$k", "-webkit-$k", $k;
}

# максимальный набор вендорных префиксов
sub maxi {
	return "-khtml-$k", "-o-$k", "-ms-$k", "-moz-$k", "-webkit-$k", $k;
}

# только для оперы
sub opera {
	return "-o-$k"
}

#################### хаки

# инлайн-блок
sub iblock {
	"display: -moz-inline-stack; display: inline-block; *zoom:1; *display:inline"
}



1;