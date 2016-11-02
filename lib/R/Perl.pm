package R::Perl;
# функции для управления данными

use common::sense;
use R::App;

use List::Util qw/reduce/;
use Scalar::Util qw/reftype/;
use Devel::Peek qw/SvREFCNT/;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		starset_base => 0,
	}, $cls;
}

# проверяет - существует ли указанный класс
sub exists {
	my ($self, $class) = @_;
	
	my $path = \%{"main::"};
	for my $x (split /::/, $class) {
		my $key = "${x}::";
		return if !exists $path->{$key};
		$path = $path->{$key};
	}
	
	# если в классе есть хоть одна переменная или функция, то он - существует
	while(my($k, $v) = each %$path) {
		return 1 if $k !~ /::$/;
	}
	
	return;
}

# возвращает количество ссылок на значение. Разыменовывает ссылку
sub refcnt {
	my $ref = reftype($_[1]);
	if($ref eq "HASH") { SvREFCNT(%{$_[1]}) }
	elsif($ref eq "ARRAY") { SvREFCNT(@{$_[1]}) }
	elsif($ref eq "SCALAR") { SvREFCNT(${$_[1]}) }
	elsif($ref eq "CODE") { SvREFCNT(&{$_[1]}) }
	elsif($ref eq "GLOB") { SvREFCNT(*{$_[1]}) }
	else { shift; goto &SvREFCNT }
}

# расписывает внутреннюю структуру переменной
sub dumpsv { shift; goto &Devel::Peek::Dump }

# # заглушка, когда происходит чтение или запись в хэш - распечатывается количество ссылок на него
# package R::Perl::LeakHash {
	# require Tie::Hash;
	# our @ISA = qw/Tie::ExtraHash/;
	# use Devel::Peek qw/SvREFCNT/;
	# sub TIEHASH {
		# my ($cls, $name) = @_;
		# bless [{}, $name], $cls;
	# }
	# sub STORE {
		# my($self, $key, $val) = @_;
		# $self->SUPER::STORE($key, $val);
		# print "$self->[1] REFCNT=" . SvREFCNT($self->[0]) . " ". SvREFCNT(%{$self->[0]}) . " $key=$val\n";
	# }
	# sub FETCH {
		# my($self, $key) = @_;
		# my $rel = $self->SUPER::FETCH($key);
		# print "$self->[1] REFCNT=" . SvREFCNT($self->[0]) . " ". SvREFCNT(%{$self->[0]}) . " $key->$rel\n";
		# $rel
	# }
# };

# # получает ссылку на хэш и оборачивает её tie leack
# sub leak { tie %{$_[1]}, "R::Perl::LeakHash", $_[2] // "$_[1]" }

# создаёт множество-хэш
sub set { shift; map { $_=>1 } @_ }

# создаёт множество-хэш
sub setref { shift; return { map { $_=>1 } @_ } }

# создаёт множество-хэш с порядковым номером
sub starset { my $i = shift->{starset_base}; map { $_=>$i++ } @_ }

# создаёт множество-хэш с порядковым номером
sub starsetref { my $i = shift->{starset_base}; { map { $_=>$i++ } @_ } }

# удаляет дубликаты
sub unique { shift; my %x; map { if(exists $x{$_}) { () } else { $x{$_} = 1; $_ } } @_ }

# переводит в массив строку, возвращает ключи хэш и пропускает ссылку на массив
sub array {
	my ($self, $ref, $re) = @_;
	reftype($ref) eq "ARRAY"? @$ref: reftype($ref) eq "HASH"? values %$ref: split($re // qr/\s*,\s*|\s+/, $ref);
}

# объединяет хеши рекурсивно
sub union {
	my $self = shift;
	
	my $a = {};
	
	for my $b (@_) {
	
		while(my ($key, $val) = each %$b) {
			my $v = $a->{$key};
			if(reftype( $v ) eq "HASH" && reftype($val) eq "HASH") {
				$a->{$key} = $self->union($v, $val);
			} else {
				$a->{$key} = $val;
			}
		}
		
	};
	
	$a
}

# возвращает имена на все методы в иерархии
# порядок: с наиболее удалённых к наиболее приближённым
# из ISA c конца смотрим
sub canallnames {
	my ($self, $cls, $name) = @_;
	
	$cls = ref $cls || $cls;
	
	my %cls;			# уже были тут
	my @st = ($cls);	# стек для обхода
	my @can;			# выходной
	
	while(@st) {
		$cls = shift @st;
		my $class = "${cls}::";
		if(defined $name) {
			my $name = "$class$name";
			my $code = *{$name}{CODE};
			unshift @can, $name if $code;
		} else {
			while(my ($key, $val) = each %$class) {
				my $code = *$val{CODE};
				unshift @can, $name if $code;
			}
		}
		
		$cls{$cls} = 1;
		push @st, grep { !exists $cls{$_} } @{"${cls}::ISA"};
	}
	
	@can
}

#  возвращает ссылки на все методы в иерархии
sub canall {
	my $self = shift;
	map { *{$_}{CODE} } $self->canallnames(@_);
}

# вызывает метод суперкласса
# sub Super {
	# my $self = shift;
	# my $method = shift;
	# my $cls = ref $self || $self;
	# for my $isa (@{"${cls}::ISA"}) {
		# if( $isa->can($method) ) {
			# $self = ref $self? bless($self, $isa): $isa;
			# return $self->$method(@_);
		# }
	# }
	# die "суперклассы класса $cls не имеют метода $method";
# }

# сортирует по свойству
sub order_by {
	my ($self, $sort, $arr, $desc) = @_;
	local ($a, $b);
	if($desc) {	sort { $b->{$sort} <=> $a->{$sort} } values %$arr }
	else { sort { $a->{$sort} <=> $b->{$sort} } values %$arr }
}

#use Data::Dumper::AutoEncode qw/eDumper/;
# возвращает дамп данных
#sub dump { substr(eDumper($_[1]), 8, -2) }

use Data::Dumper;
sub dump {
	my ($self, $val, $maxlength) = @_;
	local($_, $`, $', $1);
	$val = Dumper($val);
	if( defined($maxlength) && $maxlength<length($val)-10 ) {
		my $half = $maxlength / 2;
		$_ = join "<...>", substr($val, 8, $half), substr($val, length($val)-$half-2, -2);
	}
	else {
		$_ = substr $val, 8, -2;
	}
	
	s/\\x\{(\w+)\}/ chr hex $1 /ge;
	
	$_
}

# возвращает дамп данных в одну линию
sub inline_dump { my $x = shift->dump(@_); $x=~s/\s+/ /g; $x }

# превращает в camelcase через сепаратор, по умолчанию: "-"
sub camelcase {
	my ($self, $who, $sep) = @_;
	$sep //= "-";
	$who =~ s/$sep(\w)/ucfirst $1/ge;
	$who
}

# декамелизирует через указанный разделитель. По умолчанию: "-"
sub decamelcase {
	my ($self, $who, $sep) = @_;
	
	$sep //= "-";
	
	$who =~ s/[A-Z]/$sep . lcfirst $&/ge;
	
	$who
}

# создаёт уникальный идентификатор
my @abc = ('A'..'Z', 'a'..'z', '0'..'9', '/', '$', '.');

sub unic_id {
	my $self = shift;
	my $size = shift || 16;
	my @unic_id;

	for(my $i=0; $i<$size; $i++) {
		my $j = int rand scalar @abc;
		push @unic_id, $abc[$j];
	}

	return join "", @unic_id;
}

# переводит натуральное число в заданную систему счисления
sub to_radix {
	my ($self, $n, $radix) = @_;
	my ($x, $y) = "";
	for(;;) {
		$y = $n % $radix;
		$x = ($y < 10? $y:  chr($y + ($y<36? ord("A") - 10: $y<62? ord("a")-36 : 128-62))).$x;
		last unless $n = int $n / $radix;
	}
	return $x;
}

# парсит число в указанной системе счисления
sub from_radix {
	my ($self, $s, $radix) = @_;
	my $x = 0;
	my $a;
	for my $ch (split "", $s) {
		$a = ord $ch;
		$x = $x*$radix + $a - ($a <= ord("9")? ord("0"): $a <= ord("Z")? ord('A')-10: $a <= ord('z')? ord('a')-36: 128-62);
	}
	return $x;
}

# переворачивает хэш
sub reverse {
	my ($self, $hash) = @_;
	map { $hash->{$_} => $_ } keys %$hash
}

# парсит из строки
sub unstring { my $x = $_[1] // ""; if($x=~/^["']/) { $x = substr $x, 1, -1; $x=~s/\\([\\'"nrt])/my $x=$1; $x=~tr!nrtv!\n\r\t!; $x/ge; } $x }

# обрезает пробелы с двух сторон
sub trim {
	my ($self, $s) = @_;
	local ($`, $', $&, $1);
	$s =~ s/^\s*(.*?)\s*$/$1/s;
	$s
}

# обрезает пробелы справа
sub rtrim {
	my ($self, $s) = @_;
	local ($`, $', $&, $1);
	$s =~ s/^(.*?)\s*$/$1/s;
	$s
}

# обрезает пробелы слева
sub ltrim {
	my ($self, $s) = @_;
	local ($`, $', $&, $1);
	$s =~ s/^\s*(.*)$/$1/s;
	$s
}

# 'laquo' => '«',
# 'raquo' => '»',
# 'prime' => '′',
# 'Prime' => '″',
# 'lsquo' => '‘',
# 'rsquo' => '’',
# 'sbquo' => '‚',
# 'ldquo' => '“',
# 'rdquo' => '”',
# 'bdquo' => '„',

# оборачивает текст в кавычки «...»
sub q {
	my ($self, $text) = @_;
	"«$text»"
}

# оборачивает текст в кавычки “...”
sub qq {
	my ($self, $text) = @_;
	"“$text”"
}

# оборачивает текст в кавычки ‘...’
sub mq {
	my ($self, $text) = @_;
	"‘$text’"
}

# замена для шаблонов
sub replace {
	my ($self, $subject, $from, $to) = @_;
	if(ref $to) {
		$subject =~ s/$from/$to->()/ge;
	} else {
		$subject =~ s/$from/$to/g;
	}
	$subject
}

# замена для шаблонов
sub replaceonce {
	my ($self, $subject, $from, $to) = @_;
	if(ref $to) {
		$subject =~ s/$from/$to->()/e;
	} else {
		$subject =~ s/$from/$to/;
	}
	$subject
}

# posix strftime
use POSIX qw//;
sub strftime {
	my $self = shift;
	if(@_ == 1) { POSIX::strftime($_[0], localtime) }
	elsif(@_ == 2) { POSIX::strftime($_[0], localtime($_[1])) }
	else { POSIX::strftime(@_) };
}

# возвращает магический шифр (хэш), который расшифровывается множеством разных способов.
# Используется в паролях.
# Если к паролю применены определённые правила для пользователя, создающего пароль, то к нему не подойдут многие расшифровки
sub cipher {
	require Digest::MD5;
	require Crypt::Eksblowfish::Bcrypt;
	*cipher = \&_cipher;
	goto &_cipher;
}
sub _cipher {
	my ($self, $password) = @_;
	
	my $salt = $self->{bfsalt} //= $app->ini->{cipher}{salt} // "&U9i*0Vv^";
	my $key = $self->{bfkey} //= substr Digest::MD5::md5_hex($app->ini->{cipher}{key} // "&U S[\\M\@Plc+!\t\n"), 0, 16;
	my $cost = $self->{bfcost} //= $app->ini->{cipher}{cost} // 8;
	
	utf8::encode($password);
	utf8::encode($key);
	utf8::encode($salt);
	
	my $hash = Crypt::Eksblowfish::Bcrypt::bcrypt_hash({
		key_nul => 1,
		cost => $cost,
		salt => $key,
	}, $password . $salt);

	Crypt::Eksblowfish::Bcrypt::en_base64($hash);
}

# переводит из одной кодировки в другую
use Encode qw//;
sub iconv {
	my ($self, $from, $to, $text) = @_;
	Encode::from_to($text, $from, $to, Encode::FB_CROAK);
	$text
}

# кодирует в base64
sub base64 {
	my ($self, $bytes) = @_;
	utf8::encode($bytes);
	en_base64($bytes);
}

# подпись sha1
sub sha1 {
	require Digest::SHA1;
	*sha1 = \&_sha1;
	goto &_sha1;
}
sub _sha1 {
	my ($self, $bytes) = @_;
	utf8::encode($bytes);
	Digest::SHA1::sha1($bytes);
}

# подпись md5
sub md5 {
	require Digest::MD5;
	*md5 = \&_md5;
	goto &_md5;
}
sub _md5 {
	my ($self, $bytes) = @_;
	utf8::encode($bytes);
	Digest::MD5::md5($bytes);
}

# подсчитывает строки
sub lines {
	my ($self, $x) = @_;
	local ($`, $', $&, %+, %-);
	my $i = 0;
	my $endline = $app->re->endline;
	while($x =~ /$endline/go) { $i++ }
	$i
}

# парсит значение и выдаёт в байтах
sub size { shift; goto &_size }
sub _size {
	my ($v) = @_;
	
	if(Num $v) {	# без изменений
	}
	elsif($v =~ /[\+\-\*\/]/) {	# выражение
		my ($a, $op);
		for my $x (split /([\+\-\*\/])/, $v) {
			if( $x=~/^[\+\-\*\/]/ ) {
				$op = $x;
			}
			elsif($op eq "+") { $a += $x }
			elsif($op eq "-") { $a -= $x }
			elsif($op eq "*") { $a *= $x }
			elsif($op eq "/") { $a /= $x }
		}
		$a
	}
	elsif($v =~ s/g$//i) {	# гигабайты
		$v *= 1024*1024*1024;
	}
	elsif($v =~ s/m$//i) {	# мегабайты
		$v *= 1024*1024;
	}
	elsif($v =~ s/k$//i) {	# килобайты
		$v *= 1024;
	}
	elsif($v =~ s/b$//i) {	# байты
	}
	else {
		die "распознать размер не удалось"
	}
	
	$v
}

my $len_year = 365.2425;	# по григорианскому календарю
my $len_month = $len_year / 12;
*sec = *seconds;
# парсит значение и выдаёт в секундах
sub seconds {
	my ($self, $v) = @_;
	
	if(Num $v) {	# без изменений
	}
	elsif($v =~ s/mi(lleniums?)?$//i) {	# тысячи лет
		$v *= 60*60*24*$len_year*1000;
	}
	elsif($v =~ s/c(entur(y|ies))?$//i) {	# века
		$v *= 60*60*24*$len_year*100;
	}
	elsif($v =~ s/y(ears?)?$//i) {	# годы
		$v *= 60*60*24*$len_year;
	}
	elsif($v =~ s/mo(n(ths?)?)?$//i) {	# месяцы
		$v *= 60*60*24*$len_month;
	}
	elsif($v =~ s/d(ays?)?$//i) {	# дни
		$v *= 60*60*24;
	}
	elsif($v =~ s/h(ours?)?$//i) {	# часы
		$v *= 60*60;
	}
	elsif($v =~ s/m(inutes?)$//i) {	# минуты
		$v *= 60;
	}
	elsif($v =~ s/s(econds?)?$//i) {	# секунды
	}
	elsif($v =~ s/ms$//i) {	# милисекунды
		$v /= 1000;
	}
	elsif($v =~ s/us$//i) {	# уносекунды
		$v /= 1000000;
	}
	elsif($v =~ s/ns$//i) {	# наносекунды
		$v /= 1000000000;
	}
	else {
		die "распознать время не удалось: `$v`"
	}
	
	$v
}


1;
