package R::Data;
# функции для управления данными

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		starset_base => 0,
	}, $cls;
}

# создаёт множество-хэш
sub set { shift; map { $_=>1 } @_ }

# создаёт множество-хэш с порядковым номером
sub starset { my $i=shift->{starset_base}; map { $_=>$i++ } @_ }

# удаляет дубликаты
sub unique { shift; my %x; map { if(exists $x{$_}) { () } else { $x{$_} = 1; $_ } } @_ }

# проверяет на соответствие isa
use Scalar::Util qw/blessed/;
sub isa {
	my ($self, $val, $cls) = @_;
	return unless blessed $val;
	$val->isa($cls);
}

# сортирует по свойству
sub order_by {
	my ($self, $sort, $arr, $desc) = @_;
	if($desc) {	sort { $b->{$sort} <=> $a->{$sort} } values %$arr }
	else { sort { $a->{$sort} <=> $b->{$sort} } values %$arr }
}

use Data::Dumper::AutoEncode qw/eDumper/;
# возвращает дамп данных
sub dump { substr(eDumper($_[1]), 8, -2) }

# возвращает дамп данных в одну линию
sub inline_dump { my $x = $_[0]->dump($_[1]); $x=~s/\s+/ /g; $x }

1;
