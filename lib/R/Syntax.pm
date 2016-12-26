package R::Syntax;
# синтаксический анализатор
# просматривает на один оператор вперёд, благодаря чему может определить арность оператора

use common::sense;
use R::App qw/msg msg1 $app todo nsort qsort pairmap has Can Isa/;

has qw/addspacelex/;

# конструктор
sub new {
	my $cls = shift;
	bless {
		
		name => (ref $cls || $cls),	# имя языка
		
		# больше не используются
		PREFIX => "no!",			# префикс-операторы
		INFIX => "no!",			# инфикс-операторы 
		POSTFIX => "no!",			# постфикс-операторы
		
		OP => "no!",				# лексемы операторов
		
		BR => "no!",				# скобки
		CR => "no!",				# закрывающие скобки (для формирования лексики)
		X => "no!",				# терминалы
		
		LEX => {},				# все лекемы
		
		PRIO => 0,				# инкремент приоритета
		ORDER => 1000,			# позиция в лексическом анализаторе
		
		POP_A => {},			# обработчики соытий при выбрасывании закрывающей скобки из стека
		
		show_morf => 0,			# отражать ли преобразование в лог
		#trace => "«eval»",		# файл трейс которого показать
		trace => undef,			# показывать трейс
		show => undef,			# показывать текст в eval
		file => "",				# путь к текущему файлу
		lineno => 1,			# номер строки в текущем файле
		
		stack => undef,			# стек скобок
		lex => undef,			# кэш - лексический анализатор
		
		addspacelex => 1,		# добавляет обязательные лекемы
		
		error => {				# ошибки
			nosym => "неизвестный науке символ `%s`",
		},
		
		LA => {},				# лексические анализаторы встроенных языков
		
		lang => undef,			# язык в который морфировать
		langs => {},			# кэш языков
		
		@_
	}, ref $cls || $cls;
}


# переключает на другой лексический анализатор
# чтобы вернуться - без параметров
sub checkout {
	my ($self, $LA) = @_;
	
	local $_;
	
	my $fields = [qw/ name LEX POP_A lex addspacelex trace show /];
	
	# сохраняем текущий в LA_MASTER
	my $name = $self->{name};
	if(!$self->{LA}{$name}) {
		$self->{LA}{$name}{$_} = $self->{$_} for @$fields;
	}
	
	# переходим
	$LA = $self->{LA}{$LA};
	$self->{$_} = $LA->{$_} for @$fields;
	
	$self
}

# добавляет ветку
sub bar {
	my ($self, $syntax) = @_;
	
	$self->{LA}{$syntax->{name}} = $syntax;
	
	$self
}

# устанавливает язык
sub lang {
	if(@_ == 1) {
		my $self = shift;
		$self->{lang} // $self->lang("perl")->{lang}
	} else {
		my ($self, $lang) = @_;
	
		$self->{lang} = $self->{langs}{$lang} //= do {
			require "R/Syntax/Morf/" . ucfirst($lang) . ".pm";
			my $class = "R::Syntax::Morf::" . ucfirst($lang);
			$self->{lang} = bless { name => $lang }, $class;
			$self->modifiers( %{"${class}::modifiers"} );
			$self->templates( %{"${class}::templates"} );
			$self->{lang}
		};

		$self
	}
}

###############################  формирование таблицы ###############################

# термы
# скобки
# операторы

our $nonassoc   = 0b000_001;				# неассоциативность
our $leftassoc  = 0b000_010;				# левосторонняя ассоциативность
our $rightassoc = 0b000_100;				# правосторонняя ассоциативность

our $infix      = 0b001_000;				# инфиксный оператор
our $prefix     = 0b010_000;				# префиксный оператор
our $postfix    = 0b100_000;				# постфиксный оператор

our $terminal = 0b001_000_000;				# терминал
our $bracket  = 0b010_000_000;				# скобка
our $atom	  = 0b100_000_000;				# или терминал или скобка
our $crbracket= 0b001_000_000_000;			# закрывающая скобка

our $xfy=$infix | $leftassoc;			# левоассоциативный инфиксный
our $yfx=$infix | $rightassoc;			# правоассоциативный инфиксный
our $xfx=$infix | $nonassoc;			# неассоциативный инфиксный

our $yf=$postfix | $leftassoc;			# правоассоциативный префиксный
our $xf=$postfix | $nonassoc;			# неассоциативный префиксный

our $fy=$prefix | $rightassoc;			# левоассоциативный постфиксный
our $fx=$prefix | $nonassoc;			# неассоциативный постфиксный

our %FIX = (
	xfy => $xfy,
	yfx => $yfx,
	xfx => $xfx,
	xf => $xf,
	yf => $yf,
	fx => $fx,
	fy => $fy,
);


# ячейка таблицы операторов
sub td {
	my $self = shift;
	my $type = shift;
	
	my $fix = $FIX{$type};
	die "нет $type фикса" if !defined $fix;

	my %p = (
		prio=>$self->{PRIO},
		fix=>$fix,
		type=>$type,
	);
	my $op = "no val!";
	
	my $key = $fix & $infix? "INFIX": $fix & $prefix? "PREFIX": "POSTFIX";
	for my $x (@_) {
		if(ref $x eq "Regexp") {
			die "не указан оператор" if !$op;
			die "регулярка уже есть у оператора $op->{name}" if exists $op->{re};
			$op->{re} = $x;
		}
		elsif(ref $x eq "CODE") {
			die "не указан оператор" if !$op;
			die "подпрограмма уже есть у оператора $op->{name}" if exists $op->{sub};
			$op->{sub} = $x;
		}
		else {
			die "оператор `$type $x` уже объявлен" if exists $self->{$key}{$x};
			$op = $self->newlex($key => {%p, name=>"$type $x", alias=>$x, fix => $fix, order => -length $x});
		}
	}

	$self
}

# строка таблицы операторов
sub tr {
	my $self = shift;
	$self->{PRIO}++;
	$self->td(@_) if @_;
	$self
}

# скобки
sub br {
	my $self = shift;
	
	my $open;				# открывающая скобка
	my $close = 1;		# закрывающая скобка
	
	for my $a (@_) {

		if(ref $a eq "Regexp") {
			my $r = $close // $open;
			die "не указана скобка" if !$r;
			die "регулярка уже есть у скобки $r->{name}" if exists $r->{re};
			$r->{re} = $a;
		}
		elsif(ref $a eq "CODE") {
			my $r = $close // $open;
			die "не указана скобка" if !$r;
			die "код уже есть у скобки $r->{name}" if exists $r->{sub};
			$r->{sub} = $a;
		}
		elsif($close) {	# открывающая скобка, т.к. предыдущая - закрывающая
			die "скобка `$a` уже есть" if exists $self->{LEX}{ $a } and exists $self->{LEX}{ $a }{BR};
			$open = $self->newlex(BR => { name => "br $a", alias => $a, order=>$self->{ORDER}++, fix => $bracket | $atom });
			undef $close;
		}
		else {	# закрывающая скобка
			if(exists $self->{LEX}{ $a } and exists $self->{LEX}{ $a }{CR}) {
				$close = $self->{LEX}{ $a };
			} else {
				$close = $self->newlex(CR => { name => "cr $a", alias => $a, order=>$self->{ORDER}++, fix => $crbracket });
			}
			$open->{tag} = $a;
		}
	}
	
	$self
}

# операнды (терминалы)
# @return добавленные терминалы
sub x {
	my $self = shift;
	
	my $prev;
	my @term;
	
	for my $a (@_) {
		if(ref $a eq "Regexp") {
			die "не указан терминал" if !$prev;
			die "регулярка уже есть у терминала $prev->{name}" if exists $prev->{re};
			$prev->{re} = $a;
		}
		elsif(ref $a eq "CODE") {
			die "не указан терминал" if !$prev;
			die "код уже есть у терминала $prev->{name}" if exists $prev->{sub};
			$prev->{sub} = $a;
		}
		else {
			die "терминал `$a` уже есть" if exists $self->{LEX}{ $a } and exists $self->{LEX}{ $a }{X};
			$prev = $self->newlex(X => { name => $a, alias => $a, order=>$self->{ORDER}++, fix => $atom | $terminal });
		}
	}
	
	$self
}

# добавляет к сущности свойства
sub opt {
	my ($self, $stmt) = splice @_, 0, 2;
	
	my $x;
	
	die "нет opt($stmt)" unless $x = $self->{LEX}{$stmt};
	
	pairmap {
		die "свойство $a в $stmt уже есть" if exists $x->{$a};
		die "можно добавлять только re, sub, order, или nolex в $stmt" if $a !~ /^(?:re|sub|order|nolex)$/;
		$x->{$a} = $b;
	} @_;
	
	$self
}

# указывает, что операторы могут быть только в указанной скобке
sub in {
	my $self = shift;
	my $br = shift;
	
	for my $x (@_) {
		$self->{IN}{$x} = $br;
	}
	
	$self
}

# устанавливат обработчик на разбор лексем в pop
sub pull {
	my $self = shift;
	
	pairmap { $self->{POP_A}{$_} = $b for split /\s+/, $a  } @_;
	
	$self
}

###############################  лексический анализатор ###############################

# добавляет лексему
sub newlex {
	my $self = shift;
	my ($key, $val) = @_;
	
	my $alias = $val->{alias};
	my $LEX = $self->{LEX};
	my $op = $LEX->{$alias};
	
	if($op) {
		die "лексема $key:$alias уже есть в лексемах" if exists $op->{$key};
		die "скобка $alias не может сочетаться с $key:$alias" if exists $op->{BR} || exists $op->{CR};
		%$op = (%$op, @_, count => $op->{count} + 1, $key => $val, fix => $op->{fix} | $val->{fix});
	}
	else {
		$op = $LEX->{$alias} = { @_, name => $alias, alias => $alias, count => 1, $key => $val, order => $val->{order}, fix => $val->{fix}, VAL => $val };
	}
	
	$op
}

# формирует функцию лексического разбора
sub lex {
	my ($self) = @_;
	
	#use re 'eval';
	
	my $lex = join " |\n", map {
		my $alias = quotemeta $_->{alias};
		
		if($_->{fix} & $terminal && $_->{re} && $_->{name} =~ /^[a-z_]\w*$/i) {
			$_->{re} = "(?<$_->{name}>$_->{re})" if "$_->{re}" !~ /\(\?P?</;
		}
		
		$_->{re} //= do {
			my $x = $alias;
			$x = "\\b$x" if $x =~ /^\w/;
			$x = "$x\\b" if $x =~ /\w$/;
			$x
		};
	
		"$_->{re}		(?{ \"$alias\" })";
	}
	nsort { $_->{order} }
	grep { !$_->{nolex} }
	values %{$self->{LEX}};
	
	if($self->{addspacelex}) {
		$lex .= ($lex ne ""? " |\n": "") . "
		(?<newline> \\n	)						|
		(?<spacer>[^\\S\\n]+ )					|
		(?<error_nosym> . )	"
	}
	
	#$app->file("var/lex.pl")->write("qr{$lex}xni");
	
	#msg1 $lex;
	
	my $re = eval "qr{$lex}xni";
	die $@ if $@;
	$re
}

# формирует дерево
sub masking {
	my ($self, $s) = @_;
	
	my $lex = $self->{lex} //= $self->lex;
	my $LEX = $self->{LEX};
	my $trace = $self->{trace};
	my $endline;

	while($s =~ /$lex/g) {			# формируем дерево
	
		if($trace) {
			$endline = index($&, "\n")!=-1;
			$app->log->info(":nonewline", "$&") if !$endline;
			$endline = $& if $endline;
		}
	
		exists $+{newline}? $self->{lineno}++:
		exists $+{error_nosym}? $self->error(sprintf($self->{error}{nosym}, $+{error_nosym})):
		exists $+{spacer}? ():
		do { if(defined $^R) {
			my $lex = $LEX->{$^R};
		
			$self->error("лексема ". $app->perl->q("$^R") ." не существует в языке " . $self->{name}) if !defined $lex;
		
			my $fix = $lex->{fix};
		
			$fix & $bracket? do {
				my $tag = $lex->{tag};
				$self->push($^R, defined($tag)? (tag=>$tag): ());
			}:
			$fix & $crbracket? $self->pop($^R):
			$fix & $infix | $fix & $prefix | $fix & $postfix | $fix & $terminal? $self->op($^R):
			$self->error("лексема ". $app->perl->q("$^R") ." не опознана в языке " . $self->{name})
			
			
		}};
		
		if($endline) {
			$app->log->info(":nonewline empty", $endline);
			#":cyan", $self->{lineno} . ": "
		}
	}
	
	$self
}

###############################  синтаксический разбор  ###############################



# пришёл оператор
sub op {
	my $self = shift;
	my $push = {%+, 'stmt', @_};
	
	my $stmt = $_[0];

	# выполняем подпрограмму
	if(my $x = $self->{LEX}{$stmt}) {
		$x->{sub}->($self, $push) if exists $x->{sub};
	}
	# проверяем скобки
	my $br = $self->{IN}{$stmt};
	$self->check($push->{stmt}, stmt => $br) if $br;
	
	push @{ $self->{stack}[-1]{'A+'} }, $push;
	#$self->trace("_", $push);
	$self
}


# пришёл терм
sub atom {
	my $self = shift;
	$self->op(@_);
	#$self->trace(",", $push);
	$self
}



# добавляет открывающую скобку
# все операторы и атомы добавляются в неё
sub push {
	my $self = shift;
	my $push = {%+, 'stmt', @_};
	
	# выполняем подпрограмму
	if(my $x = $self->{LEX}{$_[0]}) {
		$x->{sub}->($self, $push) if exists $x->{sub};
	}
	
	push @{$self->{stack}}, $push;
	$self->trace("+", $push);
	$self
}

# закрывающая скобка
# происходит разбор операторов и термов, попавших меж скобок
sub pop {
	my ($self, $stag) = @_;
	
	# выполняем подпрограмму
	my $x = $self->{LEX}{$stag};
	if($x && exists $x->{sub}) {
		my $push = {%+, stmt => $stag};
		$x->{sub}->($self, $push);
	}
	
	$self->{front} = 0;
	
	my $stack = $self->{stack};		# стек скобок
	
	# выбрасываем скобки
	$self->error("нет открывающей скобки ".(defined($stag)? "к $stag ": "")."- стек S пуст") if !@$stack;
	
	my $sk = $stack->[-1];

	my $tag = $sk->{tag} // $sk->{stmt};
	$self->error("закрывающая скобка $stag конфликтует со скобкой $tag") if defined $stag and $tag ne $stag;
	
	my $A = $sk->{'A+'};
	$self->error("скобки ".($stag eq $sk->{stmt}? $stag: $sk->{stmt}." ".$stag)." не могут быть пусты") if !$A;

	# лексемы
	my $LEX = $self->{LEX};

	my @T;
	my @S;
	my $front = 1;	# после открывающей скобки - только префиксный оператор или терминал
	my $meta;
	
	# входит оператор и выбрасывает c более низким приоритетом из стека @S (если такие есть)
	# выброшенные попадают в @T
	# новый в @S
	my $popop = sub {
		my $prio = $meta->{prio};
		my $s;
		my $x;

		while(@S &&
			(($x = ($s = $S[-1])->{prio}) < $prio || 
			$x==$prio && ($s->{fix} & $nonassoc || $meta->{fix} & $nonassoc? 
				$self->error("неассоциативный оператор " . ($s->{fix} & $nonassoc? $s->{name}: $meta->{name})):
			$s->{fix} & $leftassoc))
		) {
			my $r = pop @S;
			
			if($r->{fix} & $infix) {
				$self->error("нет операндов для оператора $r->{stmt}") if !defined( $r->{right} = pop @T );
				$self->error("нет левого операнда для оператора $r->{stmt}") if !defined( $r->{left} = pop @T );
				$self->trace("%", $r);
			}
			elsif($r->{fix} & $prefix) {	# -x
				$self->error("нет операнда для оператора $r->{stmt}") if !defined( $r->{right} = pop @T );
				$self->trace(">", $r);
			}
			else {	# x--
				$self->error("нет операнда для оператора $r->{stmt}") if !defined( my $prev = pop @T );

				if( $prev->{fix} & $postfix && $prev->{prio} < $r->{prio} ) {
					$r->{left} = $prev->{left};
					$prev->{left} = $r;
					$r = $prev;
					$self->trace("<", $prev);
				}
				else {
					$r->{left} = $prev;
					$self->trace("<", $r);
				}
			}
			
			
			push @T, $r;			
		}
		
		# входящий оператор
		if(my $op = $_[0]) {
			@$op{qw/stmt fix prio/} = @$meta{qw/name fix prio/};
			push @S, $op;
			$self->trace("^", $op);
		}
	};
	
	# срабатывают обработчики для грамматического разбора
	if(my $POP_A = $self->{POP_A}) {
		for(my $i=0; $i<@$A; $i++) {
			my $op = $A->[$i];
			my $sub = $POP_A->{$op};
			$sub->($self, $i) if defined $sub;
		}
	}
	
	pop @$stack;	# сбрасываем скобку с вершины стека
	
	# ( \n \n ) - обычная ситуация prefix prefix
	# есть "xfy \n", "fy \n", "yf \n"
	# последний становится терминалом
	
	# определяем операторы
	# 1-й проход - выделяем неоднозначные операторы (X, INFIX, POSTFIX, PREFIX)
	# 2-й проход по последовательностям неоднозначных операторов: с начала и конца такой последовательности
	# 3-й - делаем popop на операторах, а в @T забрасываем терминалы и вложенные скобки
	
	# prefix <, infix <>, postfix >, x
	
	# после (	<, x
	# после x	<>, >, )
	# после <>	<, x
	# после <	<, x
	# после >	<>, >, )
	
	# >, x			перед )
	# <>, <, (		перед x
	# >, x			перед <>
	# <>, <, x, (	перед <
	# >, x			перед >
	
	# там где сравниваются операторы, нужно сравнивать и их приоритет, а именно:
	# 	a? \n
	#	? - infix и postfix. \n - infix, postfix, prefix, x
	#	приоритет \n больше ? - знак вопроса не может быть infix
	
	my $check = sub {
		my ($x, $y) = @_;

		my $fix = $x->{fix};
		my $next = $y->{fix};
		
		msg1($x), die "--x!--" if !defined $x->{prio} and ($fix & $infix || $fix & $prefix || $fix & $postfix);
		msg1($y), die "--y!--" if !defined $y->{prio} and ($fix & $infix || $fix & $prefix || $fix & $postfix);
		
		return 1 if !defined($fix) && $next & $prefix;
		return 1 if !defined($fix) && $next & $atom;
		
		return 1 if $fix & $atom && $next & $infix;
		return 1 if $fix & $atom && $next & $postfix;
		return 1 if $fix & $atom && !defined $next;
		
		return 1 if $fix & $infix && $next & $prefix && $x->{prio} => $y->{prio};
		return 1 if $fix & $infix && $next & $atom;
		
		return 1 if $fix & $prefix && $next & $prefix;
		return 1 if $fix & $prefix && $next & $atom;
		
		return 1 if $fix & $postfix && $next & $infix && $x->{prio} <= $y->{prio};
		return 1 if $fix & $postfix && $next & $postfix;
		return 1 if $fix & $postfix && !defined $next;
		
		return "";
	};
	
	
	
	# 1-й проход
	my $i = 0;
	my $begin = undef;	# начало последовательности неоднозначных операторов
	my @meta;
	my $resolve = sub {	# 2-й проход по последовательности
		# определяем направленность операторов:
		# должны ли все быть постфиксными, префиксными или начинаться на префиксные и заканчиваться постфиксными или наоборот?
		
		
		# проходимся по возможным комбинациям и выбираем 1-ю подходящую: которая начинается и заканчивается на требуемые операции
		my @fix = ();			# комбинации fix-ов
		my @comb = ();		# текущая комбинация, которая будет подставлена в @meta[$begin..$i-1]
		my $super_prev = $begin==0? undef: $meta[$begin-1];

		#msg1 @meta[$begin, $i-1];
		
		my $k = $begin;
		FOR: for(; $k<$i; $k++) {
			$meta = $meta[$k];
			my $n = $k-$begin;
			
			my $prev = $n==0? $super_prev: $comb[$n-1];		# предыдущий fix
			
			my $fix = $meta->{fix};
			my $fixk = $fix[$n];
			
			#msg1 $n, $meta->{name}, $self->namefix($fix), $self->namefix($fixk);
			
			if($fix & $infix && !($fixk & $infix) && $check->($prev, $meta->{INFIX})) {
				$fix[$n] |= $infix;
				$comb[$n] = $meta->{INFIX};
			}
			elsif($fix & $prefix && !($fixk & $prefix) && $check->($prev, $meta->{PREFIX})) {
				$fix[$n] |= $prefix;
				$comb[$n] = $meta->{PREFIX};
			}
			elsif($fix & $postfix && !($fixk & $postfix) && $check->($prev, $meta->{POSTFIX})) {
				$fix[$n] |= $postfix;
				$comb[$n] = $meta->{POSTFIX};
			}
			elsif($fix & $terminal && !($fixk & $terminal) && $check->($prev, $meta->{X})) {
				$fix[$n] |= $terminal;
				$comb[$n] = $meta->{X};
			}
			elsif($n == 0) {
				$self->error("нет больше комбинаций для $meta->{alias}. " . join " ", map { $_->{stmt} } @$A);
			}
			else {
				$k -= 2;
				$fix[$n] = 0;
			}
		}
		
		# если $meta соответствует следующему операнду - выходим, а нет - откатываемся
		my $next = $i==@meta? undef: $meta[$i];				# следующий операнд
		
		@meta[$begin..$i-1] = @comb, return if $check->($comb[-1], $next);
		
		$k--;
		goto FOR;
	
	};
	
	for my $op (@$A) {
		my $stmt = $op->{stmt};
		my $lex = $LEX->{$stmt};
		my $count = $lex->{count};
		if($count > 1) { 
			push @meta, $lex;
			$begin = $i if !defined $begin;
		} else {
			push @meta, $lex->{VAL};
			$resolve->(), $begin = undef if defined $begin;
		}
	}
	continue {
		$i++
	}
	
	$resolve->() if defined $begin;
	
	#msg1 \@meta;
	#msg1 map { $_->{name} } @meta;
	
	# третий проход - проверка правильности лексем: кто за кем стоит и 
	$i = 0;
	my $prev;
	my $op;
	
	for my $meta1 (@meta) {
		$meta = $meta1;
		$op = $A->[$i];
		my $fix = $meta->{fix};
		
		$self->error($app->perl->qq($op->{stmt}) . " не может стоять после " . $self->namefix($prev, 1) . ": " . join " ", map { $_->{stmt} } @$A) if !$check->($prev, $meta);
		
		if($fix & $prefix | $fix & $postfix | $fix & $infix) {
			$popop->($op);
		}
		elsif($fix & $atom) {	# терминал
			push @T, $op;
			$self->trace("¤", $op);
		}
		else {
			$self->error("неопознанная лексема " . $app->perl->qq($op->{stmt}));
		}
	
		$prev = $meta;
	}
	continue {
		$i++;
	}
	
	$self->error($app->perl->qq($op->{stmt}) . " не может стоять перед " . $self->namefix($prev, 0) . ": " . join " ", map { $_->{stmt} . ($_->{$_->{stmt}}? ":$_->{$_->{stmt}}": "") } @$A) if !$check->($prev);
	
	
	
	# выбрасываем всё
	$meta = {prio => 1_000_000};
	$popop->();
	
	$self->error("стек T пуст: невозможно достать операнд для скобки") if !@T;
	$self->error("стек T содержит больше одного операнда") if @T>1;
	$self->error("стек S содержит операторы") if @S;
	
	$sk->{right} = pop @T;
	push @{$stack->[-1]{'A+'}}, $sk;
	
	$self->trace("-", $sk);

	$self
}


# снимает последний элемент стека и заменяет $push
sub assign {
	my ($self, $push) = @_;
	
	%$push = (%$push, %{ pop @{$self->{stack}[-1]{"A+"}} });
	
	$self
}

# превращает в удобочитаемый fix
sub namefix {
	my ($self, $fix, $open) = @_;
	
	$fix = $fix->{fix} if ref $fix;
	
	my $s = "";
	$s .= ($open? "открывающей": "закрывающей") . " скобки " if !defined $fix;
	$s .= "инфикс " if $fix & $infix;
	$s .= "постфикс " if $fix & $postfix;
	$s .= "префикс " if $fix & $prefix;
	if($fix & $atom) {
		if($fix & $terminal && $fix & $bracket) { $s .= "терминал+скобка " }
		elsif($fix & $terminal) { $s .= "терминал " }
		elsif($fix & $bracket) { $s .= "скобка " }
		else { $s .= "атом " }
	}
	$s = "неизвестно" if $s eq "";
	$s;

}

my %COLOR = (
	"+" => ":red",
	"-" => ":bold blue",
	"<" => ":cyan",
	">" => ":cyan",
	"%" => ":cyan",
	"^" => ":magenta",
	"¤" => ":dark white",
);

# выводит помощь по обозначениям trace
sub trace_help {
	my ($self) = @_;
	
	msg ":space", $self->{name},
	"\n", $COLOR{"+"}, "+", ":reset", "открывающая скобка",
	"\n", $COLOR{"-"}, "-", ":reset", "закрывающая скобка",
	"\n", $COLOR{"<"}, "<", ":reset", "левосторонний оператор - связывает одно значение",
	"\n", $COLOR{">"}, ">", ":reset", "правосторонний оператор - связывает одно значение",
	"\n", $COLOR{"%"}, "%", ":reset", "бинарный оператор - связывает два занчения",
	"\n", $COLOR{"^"}, "^", ":reset", "оператор, выбросивший из стека предыдущие",
	"\n", $COLOR{"¤"}, "¤", ":reset", "терминал";
	
	$self
}

# возвращает колоризированный массив стеков для trace и error
sub color_stacks {
	my $self = shift;
	local($a, $b);
	return ":space",
		pairmap { ":dark white", "\t$a:", ":reset", map({ $_->{stmt} } @$b) } @_
}

# # отображает операции со стеком в лог
# sub trace {
	# my ($self, $op, $top, $stacks) = @_;
	
	# my $trace = $self->{trace};
	# if( defined($trace) && $self->{file} eq $trace ) {
	
		# local($+, $`, $', $&, $_, $a, $b);

		# my $stmt = $top->{stmt};
	
		# my @after;
		# if(0) {
			# my $after = {%$top};
			# delete @$after{qw/stmt e left right/};
			# @after = pairmap { "$a=$b" } %$after;
		# }

		# #push @after, $self->color_stacks(@$stacks) if $stacks;
		
		# # if($op eq "+" || $op eq "-") {
			# # push @after, $self->color_stacks("S", $self->{stack});
		# # }
		
		# $app->log->info( ":space", "$self->{lineno}:", $COLOR{$op} // ":dark white", $op, $stmt . (exists $top->{$stmt}? "<$top->{$stmt}>": ""), ":reset", @after );
	# }
	
	# $self
# }

# отображает операции со стеком в лог
sub trace {
	my ($self, $op, $top) = @_;
	
	my $trace = $self->{trace};
	# && $self->{file} eq $trace
	if( $trace ) {
	
		my $stmt = $top->{stmt};
		$app->log->info(":space nonewline", $COLOR{$op} // ":dark white", " $op", $stmt . (exists $top->{$stmt}? "<$top->{$stmt}> ": " "));
		
	}
	
	$self
}

# выбрасывает ошибку
sub error {
	my ($self, $msg) = @_;
	local ($_, $`, $', $&);
	
	my $color_msg = $app->log->colorized( "$self->{file}:$self->{lineno}: $msg", $self->color_stacks );
	
	die $color_msg;
}

# устанавливает модификаторы языка
sub modifiers {
	my $self = shift;
	
	%{ $self->{lang}{modifiers} } = ( %{$self->{lang}{modifiers}}, @_ );
	
	$self
}

# устанавливает шаблоны языка
sub templates {
	my $self = shift;
	
	my $c = $self->{lang}{templates} //= {};
	
	for(my $i=0; $i<@_; $i+=2) {
		my ($k, $v) = @_[$i, $i+1];
		
		$c->{$k} = $v, next if ref $v eq "CODE";
		
		$v =~ s/'/\\'/g;
		$v =~ s/\{\{\s*(\w+)\s*\}\}/', \$b->{$1} ,'/g;
		$v =~ s/\{\{\s*(?<id>\w+)\s+(?<args>\w+(\s*,\s*\w+)*)\s*\}\}/
			my $args = $+{args};
			my $id = $+{id};
			$args =~ s!\w+!\$b->{$&}!g; 
			"', \$a->{lang}->$id($args) ,'"
		/gen;
		
		$k =~ s/\s+/ /g;
		$c->{$k} = eval "sub { join '', '$v' }";
		die $@ if $@;
	}
	
	$self
}



# осуществляет два прохода по дереву кода и формирует код
sub expirience {
	my ($self, $root) = @_;
	
	# обход в глубину - модификации дерева
	if(defined(my $modifiers = $self->{lang}{modifiers})) {
		my @path = $root;
		while(@path) {
			my $node = $path[-1];
			
			# вызываем модификатор, если мы на элементе впервые
			if(!exists $node->{"&"}) {
				my $fn = $modifiers->{$node->{stmt}};
				$fn->($self, $node, \@path) if $fn;
			}
			
			if(exists $node->{left} && $node->{"&"} < 1) {	# на подэлемент
				$node->{"&"}=1;
				push @path, $node->{left};
			}
			elsif(exists $node->{right} && $node->{"&"} < 2) {	# на подэлемент
				$node->{"&"}=2;
				push @path, $node->{right};
			}
			else {
				pop @path;		# удаляем элемент
			}
		}
	}
	
	# формирование кода из шаблонов
	$a = $self;	# используется в функциях-шаблонах
	my $templates = $self->{lang}{templates};
	my $out;
	my @path = $root;
	while(@path) {
		my $node = $path[-1];
		
		if(exists $node->{left} && $node->{"&"} < 3) {	# на подэлемент
			$node->{"&"}=3;
			push @path, $node->{left};
		}
		elsif(exists $node->{right} && $node->{"&"} < 4) {	# на подэлемент
			$node->{"&"}=4;
			push @path, $node->{right};
		}
		else {
			
			# $b используется в функциях-шаблонах. Так передаётся параметр
			$b = pop @path;		# удаляем элемент
			
			#$_->{code} = join "", @$code if $code;
			my $template = $templates->{ $b->{stmt} };
			die "нет шаблона `$b->{stmt}` в языке " . ($self->{lang}{name} // "«язык Батькович»") if !$template;
			
			if(@path) {
				my $parent = $path[-1];
				if($parent->{"&"} == 3) {
					$parent->{left} = $template->();
				} else {
					$parent->{right} = $template->();
				}
			}
			else {
				$out = $template->();
			}
		}
	}
	
	$out
}

my $rootsk = $app->perl->qq("¥");

# приготовления для трансляции в другой язык
sub premorf {
	my ($self, $file) = @_;
	$self->{file} = $file // $self->{file} // "«eval»";
	$self->{lineno} = 1;
	$self->{charlineno} = 0;
	
	$self->{stack} = [{stmt=>$app->perl->qq("root")}];
	
	$self->push($rootsk);
	
	$self
}

# разбор дерева и трансляция по нему в другой язык
sub postmorf {
	my ($self) = @_;

	$self->pop($rootsk);
	
	my $S = $self->{stack};
	
	$self->error("конец: стек должен содержать 1-н элемент") if @$S != 1;
	my $root = pop @$S;
	
	my $A = $root->{"A+"};
	$self->error("конец: пустой код") if !defined $A;
	
	$self->error("конец: рут должен содержать 1-н элемент") if @$A != 1;

	my $ret = $self->expirience($A->[0]{right});
	
	$ret = $self->{lang}->end($ret, $self) if Can $self->{lang}, "end";
	#msg1 ":space cyan", "code:", $s, ":reset", , ":red", "->", ":reset", $ret if $self->{show_morf};
	$ret
}

# морфирует в другой язык
sub morf {
	my ($self, $s, $file) = @_;
	
	$app->log->info("") if $self->{trace};
	
	$self->premorf($file)->masking($s)->postmorf;
}

# вычисляет выражение
sub eval {
	my ($self, $code) = @_;
	
	$app->log->info($code) if $self->{show};
	
	my $morf = $self->morf($code);
	my @ret;
	my $lang = $self->{lang};
	if(Can $lang, "eval") {
		@ret = wantarray? $lang->eval($morf): scalar $lang->eval($morf);
	}
	else {
		@ret = wantarray? eval $morf: scalar eval $morf;
	}
	msg(":empty black on_cyan", "eval morf", ":reset", "\n", $morf), die $@ if $@;
	wantarray? @ret: $ret[0]
}

# проверяет параметры на верхушке стека скобок и выбрасывает ошибку, если они не совпадают
sub check {
	my $self = shift;
	my $e = shift;
	my $s = $self->{stack}[-1];
	for(my $i=0; $i<@_; $i+=2) {
		my ($k, $v) = @_[$i, $i+1];
		if( $s->{$k} ne $v ) {
			$self->error("проверка $e: не совпадает $k в стеке. Оно $s->{$k}, а должно быть $v");
		}
	}
	$self
}

# просматривает вершину стека
sub top {
	my ($self) = @_;
	my $stack = $self->{stack};
	$self->error("нет элементов в стеке скобок") if @$stack == 0;
	$stack->[-1]
}


1;