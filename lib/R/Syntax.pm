package R::Syntax;
# синтаксический анализатор
# просматривает на один оператор вперёд, благодаря чему может определить арность оператора

use common::sense;
use R::App qw/msg msg1 $app todo nsort qsort pairmap has Can Isa closure/;

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
		
		text => "",				# текущий код
		
		file => undef,			# путь к текущему файлу
		lineno => 1,			# номер строки в текущем файле
		charno => 1,			# номер текущего символа
		startline => 0,			# сколько символов до начала текущей строки
		
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
			$self->templates( @{"${class}::templates"} );
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

our $terminal	= 0b001_000_000;				# терминал
our $bracket	= 0b010_000_000;				# скобка
our $atom		= 0b100_000_000;				# или терминал или скобка

our $crbracket	= 0b001_000_000_000;			# закрывающая скобка
our $void		= 0b010_000_000_000;			# скобки могут быть пустыми

our $xfy=$infix | $leftassoc;			# левоассоциативный инфиксный
our $yfx=$infix | $rightassoc;			# правоассоциативный инфиксный
our $xfx=$infix | $nonassoc;			# неассоциативный инфиксный

our $yf=$postfix | $leftassoc;			# правоассоциативный префиксный
our $xf=$postfix | $nonassoc;			# неассоциативный префиксный

our $fy=$prefix | $rightassoc;			# левоассоциативный постфиксный
our $fx=$prefix | $nonassoc;			# неассоциативный постфиксный

our $yF=$postfix | $leftassoc  | $bracket;		# левоассоциативная скобка (postcircumfix)
our $xF=$postfix | $nonassoc   | $bracket;		# неассоциативная скобка (postcircumfix)
our $Fy=$prefix  | $leftassoc  | $bracket;		# правоассоциативная скобка (precircumfix)
our $Fx=$prefix  | $nonassoc   | $bracket;		# неассоциативная скобка (precircumfix)
our $yFx=$infix  | $rightassoc | $bracket;		# левоассоциативная инфиксная скобка (incircumfix)
our $xFy=$infix  | $leftassoc  | $bracket;		# правоассоциативная инфиксная скобка (incircumfix)
our $xFx=$infix  | $nonassoc   | $bracket;		# неассоциативная инфиксная скобка (incircumfix)

our $yS=$postfix | $leftassoc  | $bracket | $void;		# левоассоциативная скобка (postcircumfix)
our $xS=$postfix | $nonassoc   | $bracket | $void;		# неассоциативная скобка (postcircumfix)
our $Sy=$prefix  | $leftassoc  | $bracket | $void;		# правоассоциативная скобка (precircumfix)
our $Sx=$prefix  | $nonassoc   | $bracket | $void;		# неассоциативная скобка (precircumfix)
our $ySx=$infix  | $rightassoc | $bracket | $void;		# левоассоциативная инфиксная скобка (incircumfix)
our $xSy=$infix  | $leftassoc  | $bracket | $void;		# правоассоциативная инфиксная скобка (incircumfix)
our $xSx=$infix  | $nonassoc   | $bracket | $void;		# неассоциативная инфиксная скобка (incircumfix)


our %FIX = (
	xfy => $xfy,
	yfx => $yfx,
	xfx => $xfx,
	xf => $xf,
	yf => $yf,
	fx => $fx,
	fy => $fy,
	yF => $yF,
	xF => $xF,
	Fy => $Fy,
	Fx => $Fx,
	yS => $yS,
	xS => $xS,
	Sy => $Sy,
	Sx => $Sx,
	yFx => $yFx,
	xFy => $xFy,
	xFx => $xFx,
	ySx => $ySx,
	xSy => $xSy,
	xSx => $xSx,
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
	my $step = $fix & $bracket? 2: 1;
	
	for(my $i=0; $i<@_; $i+=$step) {
		my $x = $_[$i];
		if(ref $x) { die "имена операторов должны быть строками: `$x`" }
		else {
			die "оператор `$type $x` уже объявлен" if exists $self->{$key}{$x};
			$op = $self->newlex($key => {%p, name=>"$type $x", alias=>$x, fix => $fix, order => -length $x});
			
			if($fix & $bracket) {
				$op->{tag} = $_[$i+1];
				$self->newlex(CR => { name => "cr $op->{tag}", alias => $op->{tag}, order=>$self->{ORDER}++, fix => $crbracket }) if !exists $self->{LEX}{ $_[$i+1] } || !exists $self->{LEX}{ $_[$i+1] }{CR};
			}
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
sub _br {
	my $self = shift;
	my $VOID = shift;
	
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
			$open = $self->newlex(BR => { name => "br $a", alias => $a, order=>$self->{ORDER}++, fix => $bracket | $atom | $VOID });
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

# не пустые скобки
sub br {
	splice @_, 1, 0, 0;
	goto &_br;
}

# скобки могущие быть пустыми
sub sr {
	splice @_, 1, 0, $void;
	goto &_br;
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
		die "свойство $a в $stmt уже есть" if exists $x->{$a} and $a ne "order";
		die "можно добавлять только re, sub, sur, order, или nolex в $stmt" if $a !~ /^(?:re|sub|sur|order|nolex)$/;
		$x->{$a} = $b;
	} @_;
	
	$self
}

# возвращает приоритет оператора (для тестов)
sub prio {
	my ($self, $op) = @_;
	
	die "не оператор `$op`" unless $op =~ /\s+/;
	die "не распознана лексема `$'` из `$op`" unless my $lex = $self->{LEX}{$'};
	my $fix = $FIX{$`};
	my $key = $fix & $infix? "INFIX": $fix & $prefix? "PREFIX": "POSTFIX";
	
	$lex->{$key}{prio}
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
		
		#my $fix = $val->{fix};
		#my $ofix = $op->{fix};
		
		die "скобка $alias не может сочетаться с $key:$alias" if $op->{BR} || $op->{CR};
		#die "$alias не может сочетаться со скобкой $key:$alias" if $val->{fix} & ($bracket | $crbracket);
		
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
		die "формирование lex: нет alias" if $_->{alias} eq "";
		my $alias = quotemeta $_->{alias};
		
		if($_->{fix} & $terminal && $_->{re} && $_->{name} =~ /^[a-z_]\w*$/i) {
			$_->{re} = "(?<$_->{name}>$_->{re})" if "$_->{re}" !~ /\(\?P?</;
		}
		
		$_->{re} //= do {
			$_->{_lex_re} = 1;
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
	
	#$app->file("var/lex-$self->{name}.pl")->write("my \$a = qr{$lex}xni;\n");
	
	#msg1 $lex;
	
	my $re = eval "qr{$lex}xni";
	die $@ if $@;
	$re
}

# формирует дерево
sub masking {
	my ($self, $s) = @_;
	
	my $re_lex = $self->{lex} //= $self->lex;
	my $LEX = $self->{LEX};
	my $trace = $self->{trace};
	my $endline;

	while($s =~ /$re_lex/g) {			# формируем дерево
	
		$self->{charno} = length($`) - length($&) - $self->{startline} + 1;
	
		if($trace) {
			local ($`);
			$endline = index($&, "\n")!=-1;
			$app->log->info(":nonewline", "$&") if !$endline;
			$endline = $& if $endline;
			
			$app->log->info(":nonewline on_cyan black", "$^R") if defined $^R and !exists $+{newline} and !exists $+{error_nosym} and !exists $+{spacer};
		}
	
		exists $+{newline}? $self->newline:
		exists $+{error_nosym}? $self->error(sprintf($self->{error}{nosym}, $+{error_nosym})):
		exists $+{spacer}? do {
			my $stack = $self->{stack};
			my $e = @$stack? $stack->[-1]: undef;
			my $A = $e->{'A+'};
			my $s = @$A? $A->[-1]: $e;
			$s->{spacer} = 1;
		}:
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

# инкрементирует строку
sub newline {
	my ($self) = @_;
	
	$self->{lineno}++;
	$self->{startline} = length $`;
	
	$self
}

# возвращает все ключевые слова
sub keywords {
	my ($self) = @_;
	my $prev = "";
	sort { length($a) == length($b)? $a cmp $b: length($a) <=> length($b) }
	map { $prev eq $_? (): ($prev=$_) }
	sort { $a cmp $b } 
	map {  $_->{re}? do {
		my @r = ();
		
		while( $_->{re} =~ /\\.|\(\?\^?\w+:|\/uix$|\(\?P?<\w+>|\[[^\[\]]+\]|([a-zA-Z_]\w*)/g ) {
			push @r, lc $1 if defined $1;
		}
		@r
	}: lc $_->{alias} } grep { !$_->{nolex} } nsort { $_->{order} } values %{$self->{LEX}};
}

###############################  синтаксический разбор  ###############################



# пришёл оператор
sub op {
	my $self = shift;
	my $push = {%+, 'stmt', @_, lineno => $self->{lineno}, charno => $self->{charno}};
	
	my $stmt = $_[0];
	my $lex = $self->{LEX}{$stmt};

	# выполняем подпрограмму
	$lex->{sub}->($self, $push) if $lex && exists $lex->{sub};
	
	# проверяем скобки
	my $br = $self->{IN}{$stmt};
	$self->check($push->{stmt}, stmt => $br) if $br;
	
	push @{ $self->{stack}[-1]{'A+'} }, $push;
	
	# выполняем подпрограмму
	$lex->{sur}->($self, $push) if $lex && exists $lex->{sur};
	
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
	my $push = {%+, 'stmt', @_, lineno => $self->{lineno}, charno => $self->{charno}};
	
	my $lex = $self->{LEX}{$_[0]};
	
	# выполняем подпрограмму
	$lex->{sub}->($self, $push) if $lex && exists $lex->{sub};
	
	push @{$self->{stack}}, $push;
	$self->trace("+", $push);
	
	# выполняем подпрограмму
	$lex->{sur}->($self, $push) if $lex && exists $lex->{sur};
	
	$self
}

# закрывающая скобка
# происходит разбор операторов и термов, попавших меж скобок
sub pop {
	my ($self, $stag) = @_;
	
	# лексемы
	my $LEX = $self->{LEX};
	
	# подготовка к выполнению обработчика
	my $lex = $LEX->{$stag};
	my $push;
	$push = {%+, stmt => $stag} if $lex and exists $lex->{sub} || exists $lex->{sur};

	# выполняем подпрограмму
	$lex->{sub}->($self, $push) if $lex && exists $lex->{sub};
	
	my $stack = $self->{stack};		# стек скобок
	
	# выбрасываем скобки
	$self->error("нет открывающей скобки ".(defined($stag)? "к $stag ": "")."- стек S пуст") if !@$stack;
	
	my $sk = $stack->[-1];

	my $tag = $sk->{tag} // $sk->{stmt};
	$self->error("закрывающая скобка $stag конфликтует со скобкой ".($sk->{stmt} ne $tag? "$sk->{stmt} … $tag": $tag)) if defined $stag and $tag ne $stag;
	
	my $A = $sk->{'A+'};
	$self->error("скобки ".($stag eq $sk->{stmt}? $stag: $sk->{stmt}." ".$stag)." не могут быть пусты") if !$A && $sk->{fix} & $void == 0;

	
	# срабатывают обработчики для грамматического разбора
	if(my $POP_A = $self->{POP_A}) {
		for(my $i=0; $i<@$A; $i++) {
			my $op = $A->[$i]{stmt};
			my $sub = $POP_A->{$op};
			$sub->($self, $i) if defined $sub;
		}
	}
	
	pop @$stack;	# сбрасываем скобку с вершины стека
	
	$self->_pop($stag, $sk, $A) if $A;
	
	push @{$stack->[-1]{'A+'}}, $sk;
	
	$self->trace("-", $sk);
	
	
	# выполняем подпрограмму
	$lex->{sur}->($self, $push) if $lex && exists $lex->{sur};
	

	$self
}

# разбор операторов в скобках
sub _pop {
	my ($self, $stag, $sk, $A) = @_;

	my @T;
	my @S;
	
	my $meta;
	
	# входит оператор и выбрасывает c более низким приоритетом из стека @S (если такие есть)
	# выброшенные попадают в @T
	# новый в @S
	my $popop = sub {
		my $prio = $meta->{prio};
		my $fix = $meta->{fix};
		my $s;
		my $x;

		unless($fix & $prefix) {	# prefix не выбрасывает операторы
			while(@S) {			
				my $s = $S[-1];
				
				last unless $fix & $postfix && $s->{fix} & $postfix ||	# postfix выбрасывает другие постфиксы
				($x = $s->{prio}) < $prio || 	# приоритет оператора больше чем у того, что из стека
				$x==$prio && ( ($fix | $s->{fix}) & $nonassoc?	# приоритет равен
					$self->error("неассоциативный оператор " . ($s->{fix} & $nonassoc? $s->{name}: $meta->{name})):
				$s->{fix} & $leftassoc);	# и он левоасоциативен
			
				my $r = pop @S;
				
				if($r->{fix} & $infix) {
					my $right;
					$self->error("нет операндов для оператора $r->{stmt}", $r) if !defined( $right = pop @T );
					$self->error("нет левого операнда для оператора $r->{stmt}", $r) if !defined( $r->{left} = pop @T );
					
					if(exists $r->{right}) {
						$r->{right} = { stmt => $r->{F_stmt} // 'F', left => $r->{right}, right => $right };
					}
					else {
						$r->{right} = $right;
					}
					
					$self->trace("%", $r);
				}
				elsif($r->{fix} & $prefix) {	# -x
					$r->{left} = $r->{right} if exists $r->{right};		# для префиксных скобок
					$self->error("нет операнда для оператора $r->{stmt}", $r) if !defined( $r->{right} = pop @T );
					$self->trace(">", $r);
				}
				else {	# x--
					$self->error("нет операнда для оператора $r->{stmt}", $r) if !defined( $r->{left} = pop @T );
					$self->trace("<", $r);			
				}
				
				
				push @T, $r;			
			}
		}
		
		# входящий оператор
		if(my $op = $_[0]) {
			@$op{qw/stmt fix prio/} = @$meta{qw/name fix prio/};
			push @S, $op;
			$self->trace("^", $op);
		}
	};
	
	
	
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
	
	
	my $check = sub {
		my ($fix, $next) = @_;

		return 1 if !defined($fix) && $next & $prefix;
		return 1 if !defined($fix) && $next & $atom;
		
		return 1 if $fix & $atom && $next & $infix;
		return 1 if $fix & $atom && $next & $postfix;
		return 1 if $fix & $atom && !defined $next;
		
		return 1 if $fix & $infix && $next & $prefix;
		return 1 if $fix & $infix && $next & $atom;
		
		return 1 if $fix & $prefix && $next & $prefix;
		return 1 if $fix & $prefix && $next & $atom;
		
		return 1 if $fix & $postfix && $next & $infix;
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
		my $super_prev = $begin==0? undef: $meta[$begin-1]{fix};
		my $next = $i==@meta? undef: $meta[$i]{fix};	# следующий операнд

		#msg1 @meta[$begin, $i-1];
		
		my $k = $begin;
		FOR: for(; $k<$i; $k++) {
			$meta = $meta[$k];
			my $n = $k-$begin;
			
			my $prev = $n==0? $super_prev: $comb[$n-1]{fix};		# предыдущий fix

			my $fix = $meta->{fix};
			my $fixk = $fix[$n];	# проверяем, что ещё не проходили
			
			#msg1 $n, $meta->{name}, $self->namefix($fix), $self->namefix($fixk);
			
			if($fix & $prefix && !($fixk & $prefix) && $check->($prev, $prefix)) {
				$fix[$n] |= $prefix;
				$comb[$n] = $meta->{PREFIX};
			}
			elsif($fix & $postfix && !($fixk & $postfix) && $check->($prev, $postfix)) {
				$fix[$n] |= $postfix;
				$comb[$n] = $meta->{POSTFIX};
			}
			elsif($fix & $infix && !($fixk & $infix) && $check->($prev, $infix)) {
				$fix[$n] |= $infix;
				$comb[$n] = $meta->{INFIX};
			}
			elsif($fix & $atom && !($fixk & $atom) && $check->($prev, $atom)) {
				$fix[$n] |= $atom;
				$comb[$n] = $meta->{X} // $meta->{BR};
			}
			elsif($n == 0) {
				$self->error("нет больше комбинаций для $meta->{alias} ( как: " . $self->namefix($fix) . ") ");
			}
			else {
				$k -= 2;
				$fix[$n] = 0;
			}
		}
		
		# если $meta соответствует следующему операнду - выходим, а нет - откатываемся
		my $fix = $comb[-1]{fix};
		
		@meta[$begin..$i-1] = @comb, return if $check->($fix, $next);
		
		$k--;
		goto FOR;
	
	};
	
	my $LEX = $self->{LEX};
	
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
		
		if(!$check->($prev, $fix)) {
			my $msg = $app->perl->qq($op->{stmt}) . " не может стоять после " . $self->namefix($prev, 1) . ": " . join "   ", map { $_->{stmt} } @$A;
			$self->error($msg, $op);
		}
		
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
	
		$prev = $fix;
	}
	continue {
		$i++;
	}
	
	$self->error($app->perl->qq($op->{stmt}) . " не может стоять перед " . $self->namefix($prev, 0) . ": " . join " ", map { $_->{stmt} . ($_->{$_->{stmt}}? ":$_->{$_->{stmt}}": "") } @$A) if !$check->($prev);
	
	
	
	# выбрасываем всё
	$meta = {prio => 1_000_000, fix => $infix};
	$popop->();
	
	$self->error("стек T пуст: невозможно достать операнд для скобки") if !@T;
	$self->error("стек T содержит больше одного операнда") if @T>1;
	$self->error("стек S содержит операторы") if @S;
	
	$sk->{right} = pop @T;
	
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
	#local($a, $b);
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
	my ($self, $msg, $simbol) = @_;
	local ($_, $`, $', $&);
	
	my $file = $self->{file};
	my $lineno = $simbol? $simbol->{lineno}: $self->{lineno};
	my $charno = $simbol? $simbol->{charno}: $self->{charno};
	
	my @lines = split /\r\n|[\r\n]/, $self->{text};
	
	my $line = $lines[$lineno-1];
	
	my ($line1, $line2) = $line =~ /(.{$charno})(.*)/;
	$line1 =~ s/\t/ $charno+=3; "    "/ge;
	$line1 =~ s/\t/    /g;
	$line = "$line1$line2";
	
	#my $color_msg = $app->log->colorized( "$file:$lineno: $msg", $self->color_stacks );
	
	$msg = "$msg\n$file:$lineno:$charno:\n$line\n" . ('_' x ($charno-1)) . "^\n";
	
	die R::Raise->new($msg, "error")->clear;
}

# устанавливает модификаторы синтаксиса
sub fixes {
	my $self = shift;
	my $modifiers = $self->{fixes} //= {};
	for(my $i=0; $i<@_; $i+=2) {
		my ($key, $val) = @_[$i..$i+1];
		die "синтаксический модификатор `$key` встречается дважды" if exists $modifiers->{$key};
		$modifiers->{$key} = $val;
	}
	
	$self
}

# устанавливает шаблоны языка
# принимает ключ=>шаблон или ключ=>функция=>шаблон
sub templates {
	my $self = shift;
	
	my $templates = $self->{lang}{templates} //= {};
	my $modifiers = $self->{lang}{modifiers} //= {};
	my $re_arg = "(\\*|\\w+)";
	
	for(my $i=0; $i<@_; $i+=2) {
		my ($k, $v) = @_[$i, $i+1];
		
		die "шаблон `$k` в языке ".($self->{lang}{name} // "«язык Батькович»")." встречается дважды" if exists $templates->{$k};
		
		$modifiers->{$k} = $v, $v = $_[$i+2], $i++ if ref $v eq "CODE";
		
		my $orig = $v;
		
		$v =~ s/'/\\'/g;
		$v =~ s/\{\{\s*(\w+)\s*\}\}/', \$b->{$1} ,'/g;	# переменные
		$v =~ s/\{\{\s*(?<id>\w+)\s+(?<args>$re_arg(\s*,\s*$re_arg)*)\s*\}\}/	# вызовы методов класса темплейта
			my $args = $+{args};
			my $id = $+{id};
			$args =~ s!$re_arg! $& eq "*"? "\$b": "\$b->{$&}"!ge;
			"', \$a->{lang}->$id($args) ,'"
		/gen;
		
		# всплывающие переменные
		$v =~ s{	\{\{  \s* (?<key> \w+:\w+ ) (\s* ("(?<sep>[^"]+)"|'(?<sep>[^']+)'))? \s* \}\}	}{
			"', join(\"" . ($+{sep} // "''") . "\", \@{delete(\$b->{'UP+'}{'$+{key}'})}) ,'"
		}xgen;
		
		my $begin = '';
		$v =~ s{	\{% \s* (?<key> \w+:\w+) \s* \|	(?<val> .*? ) %\} }{
			$begin .= "push \@{\$b->{'UP+'}{'$+{key}'}}, join '', '$+{val}'; ";
			''
		}sxgen;
		
		
		
		# # проверяем, что не осталось конструкций
		# die "осталось `{{` в шаблоне: $k -> $orig -> $v" if $v =~ /\{\{/;
		# die "осталось `}}` в шаблоне: $k -> $orig -> $v" if $v =~ /\}\}/;
		# die "осталось `{%` в шаблоне: $k -> $orig -> $v" if $v =~ /\{%/;
		# die "осталось `%}` в шаблоне: $k -> $orig -> $v" if $v =~ /%\}/;
		
		
		
		$k =~ s/\s+/ /g;
		my $code = $begin? "sub { my \$ret = join '', '$v'; $begin\$ret }": "sub { join '', '$v' }";
		
		#msg1 $k, $code;
		
		$templates->{$k} = eval $code;
		die "синтаксическая ошибка в шаблоне кода $k: $@\n$code\n\n$orig" if $@;
	}
	
	$self
}

# модифицирует дерево
sub modify {
	my ($self, $idx, $root, $modifiers) = @_;
	
	my $one = $idx+1;
	my $two = $idx+2;
	
	my $path = bless [$root], "R::SyntaxBinary";
	while(@$path) {
		my $node = $path->[-1];
		
		# # вызываем модификатор, если мы на элементе впервые
		# if(!exists $node->{"&"}) {
			# my $fn = $modifiers->{$node->{stmt}};
			# $fn->($self, $node, \@path) if $fn;
		# }
		
		if(exists $node->{left} && $node->{"&"} < $one) {	# на подэлемент
			$node->{"&"}=$one;
			push @$path, $node->{left};
		}
		elsif(exists $node->{right} && $node->{"&"} < $two) {	# на подэлемент
			$node->{"&"}=$two;
			push @$path, $node->{right};
		}
		else {
			
			# просматриваем снизу-вверх
			my $fn = $modifiers->{$node->{stmt}};
			$fn->($self, $node, $path) if $fn;
			
			pop @$path;		# удаляем элемент
		}
	}
	
	$self
}

# осуществляет два прохода по дереву кода и формирует код
sub expirience {
	my ($self, $root) = @_;
	
	# обход в глубину - модификации дерева
	$self->modify(0, $root, $self->{fixes}) if $self->{fixes};
	
	# обход в глубину - модификации дерева
	$self->modify(2, $root, $self->{lang}{modifiers}) if $self->{lang}{modifiers};
	
	my $one = 4+1;
	my $two = 4+2;
	
	# формирование кода из шаблонов
	$a = $self;	# используется в функциях-шаблонах
	my $templates = $self->{lang}{templates};
	my $out;
	my @path = $root;
	my $node;
	while(@path) {
		$node = $path[-1];
		
		if(exists $node->{left} && $node->{"&"} < $one) {	# на подэлемент
			$node->{"&"}=$one;
			push @path, $node->{left};
		}
		elsif(exists $node->{right} && $node->{"&"} < $two) {	# на подэлемент
			$node->{"&"}=$two;
			push @path, $node->{right};
		}
		else {
			
			# $b используется в функциях-шаблонах. Так передаётся параметр
			$b = pop @path;		# удаляем элемент
			
			#$_->{code} = join "", @$code if $code;
			my $tmpl = $b->{tmpl} // $b->{stmt};
			my $template = $templates->{ $tmpl };
			die "нет шаблона `$tmpl` в языке " . ($self->{lang}{name} // "«язык Батькович»") if !$template;
			
			if(@path) {
				my $parent = $path[-1];		# есть родитель
				if($parent->{"&"} == $one) {
					$parent->{left} = $template->();
				} else {
					$parent->{right} = $template->();
				}
				
				# поднятие всплывающих переменных
				if(exists $b->{'UP+'}) {
					if(exists $parent->{'UP+'}) {
						my $up = $b->{'UP+'};
						my $pup = $parent->{'UP+'};
						while(my ($key, $val) = each %$up) {
							push @{$pup->{$key}}, @$val;
						}
					}
					else {
						$parent->{'UP+'} = $b->{'UP+'}; 
					}
				}
			}
			else {
				$out = $template->();
			}
		}
	}
	
	$self->error("остались всплывающие переменные: " . join ", ", keys %{$node->{'UP+'}}) if %{$node->{'UP+'}};
	
	$out
}




my $rootsk = $app->perl->qq("¥");

# приготовления для трансляции в другой язык
sub premorf {
	my ($self, $file) = @_;
	$self->{file} = $file // $self->{file} // "«eval»";
	$self->{lineno} = 1;
	$self->{charno} = 0;
	$self->{startline} = 0;
	
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
	
	msg1 ":cyan", "morf:", ":reset", $ret if $self->{show_morf};
	
	$ret
}

# морфирует в другой язык
sub morf {
	my ($self, $s, $file) = @_;
	
	$self->{text} = $s;
	
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
		@ret = wantarray? $lang->eval($morf): $lang->eval($morf);
	}
	else {
		@ret = wantarray? eval $morf: scalar eval $morf;
	}
	if($@) {
		{
			local $@;
			msg(":empty black on_cyan", "eval morf", ":reset", "\n", $code, "\n\n", $morf);
		}
		die $@;
	}
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




########################## манипулятор бинарного дерева
package R::SyntaxBinary;
use common::sense;
use R::App;


# !!! Важно !!!
# в пройденных node будет установлен ключ &

# создаёт очередь
sub new {
	my $cls = shift;
	bless [grep { defined $_ } @_], ref $cls || $cls;
}

# заменяет ноду
sub replace {
	my $self = shift;
	if(@_ == 1) {
		my $node = shift;
		%{$self->[-1]} = ref $node eq ref $self? %{$_[0]->node}: ref $node? %{$_[0]}: (stmt => $_[0]);
	}
	else {
		unshift @_, 'stmt' if @_ % 2 == 1;
		%{$self->[-1]} = pairmap { ref $_ eq ref $self? $_->node: $_ } @_;
	}
		
	$self
}

# возвращает парента с указанным stmt
sub up {
	my ($self, $up) = @_;
	for(my $i=$#$self; $i>=0; $i--) {
		return $self->new($self->[$i]) if $self->[$i]{stmt} eq $up;
	}
	return $self->new;
}

# возвращает левую ветвь
sub left {
	my $self = shift;
	$self->new($self->[-1]{left})
}

# возвращает правую ветвь
sub right {
	my $self = shift;
	$self->new($self->[-1]{right})
}

# тестирует stmt
sub is {
	my ($self, $stmt) = @_;
	if(ref $stmt) {
		my $ret = 1;
		my $node = $self->[-1];
		while(my ($k, $v) = each %$stmt) {
			return "" if !exists $node->{$k};
			return "" if $node->{$k} ne $v;
		}
		$ret
	}
	else { $self->[-1]{stmt} eq $stmt }
}

# возвращает последнюю ноду
sub node {
	my ($self) = @_;
	+{ @$self? %{$self->[-1]}: () }
}

1;