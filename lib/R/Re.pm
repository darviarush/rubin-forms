package R::Re;
# словарь регулярных выражений

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# строки
our $string = qr/(?:"(?:\\["\\]|[^"])*")|(?:'(?:\\['\\]|[^'])*')/;
our $number = qr/-?(?:0b\d[\d_]*|0x\d[\d_]*|\d[\d_]*(?:\.[\d_]+)?(?:e[+-]?[\d_]+)?|(?:\d[\d_]*)?\.\d[\d_]*)/i;

# идентификаторы
our $id = qr/(?:[a-z_]\w*)/i;
our $css_id = qr/(?:[a-z_\-][\w\-]*)/i;

# переводы строк
our $endline = qr/(?<re_newline>\r\n|\r|\n)/;

# пробелы
our $space = qr{ [\t\ ]+ }x;
our $space_ask = qr{ [\t\ ]* }x;

# вложенные скобки
our $inbrackets = qr{
	(?<R1> \(  ( [^\(\)]+ | (?&R1) )* \) ) |
	(?<R2> \{  ( [^\{\}]+ | (?&R2) )* \} ) |
	(?<R3> \[  ( [^\[\]]+ | (?&R3) )* \] )
}xn;



# если функция не найдена
use vars '$AUTOLOAD';

sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	die "нет такой регулярки: $prop" if !defined $$prop;
	
	eval "sub $AUTOLOAD { \$$prop }";
	die "not make $AUTOLOAD: ".($@ // $!) if $@ // $!;
	
	$$prop
}

sub DESTROY {}


1;