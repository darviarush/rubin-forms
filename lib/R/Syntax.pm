package R::Syntax;
# синтаксический анализатор
# просматривает на один оператор вперёд, благодаря чему может определить арность оператора

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		
		PREFIX => {},			# префикс-операторы
		INFIX => {},			# инфикс-операторы 
		POSTFIX => {},			# постфикс-операторы
		
		BR => {},				# скобки
		CR => {},				# закрывающие скобки (для формирования лексики)
		X => {},				# терминалы
		
		PRIO => 0,				# инкремент приоритета
		
		LEXX => undef,			# лексический анализатор
		
		trace => "EXAMPLE",		# файл трейс которого показать
		file => "",				# путь к текущему файлу
		lineno => 1,			# номер строки в текущем файле
		
		stack => undef,			# стек операторов
		terms => undef,			# стек операндов
		space => undef,			# дополнительный стек скобок
		
		op => "",				# запомненный оператор
		front => 1,				# обозначает границу операторов (порядок их выборки)
		
		error => {				# ошибки
			sym => "неизвестный символ `%s`",
		},
		
	}, ref $cls || $cls;
}

###############################  формирование таблицы ###############################

# термы
# скобки
# операторы

our $nonassoc = 0b000001;				# неассоциативность
our $leftassoc = 0b000010;				# левосторонняя ассоциативность
our $rightassoc = 0b000100;				# правосторонняя ассоциативность

our $infix = 0b001000;					# инфиксный оператор
our $prefix = 0b010000;					# префиксный оператор
our $postfix = 0b100000;				# постфиксный оператор

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
		prio=>$_PRIO,
		fix=>$fix,
		type=>$type,
	);
	
	my $key = $fix & $infix? "INFIX": $fix & $prefix? "PREFIX": "POSTFIX";
	for my $x (@_) {
		die "оператор $type `$x` уже объявлен" if exists $self->{$key}{$x};
		$self->{$key}{$x} = {%p, name=>"$type $x"};
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
	
	my $br = $self->{BR};
	my $closest = $self->{CR};
	my $open;			# открывающая скобка
	my $close = 1;		# закрывающая скобка
	
	for(my $i=0; $i<@_; $i++) {
		my $a = $_[$i];
		if(ref $a eq "Regexp") {
			my $r = $close? $close: $open;
			die "регулярка уже есть у скобки $r->{name}" if exists $r->{re};
			$r->{re} = $a;
		}
		elsif(ref $a eq "CODE") {
			my $r = $close? $close: $open;
			die "код уже есть у скобки $r->{name}" if exists $r->{sub};
			$r->{sub} = $a;
		}
		elsif($close) {	# открывающая скобка
			die "скобка `$a` уже есть" if exists $br->{ $a };
			$br->{ $a } = $open = { name => "br $a" };
		}
		else {	# закрывающая скобка
			if(exists $closest->{ $a }) {
				$close = $closest->{ $a };
			} else {
				$closest->{ $a } = $close = { name => "cr $a" };
			}
			$open->{tag} = $a;
		}
	}
	
	$self
}

# операнды (терминалы)
sub x {
	my $self = shift;
	
	#die "формирование таблицы символов уже завершено" if $self->{LEXX};
	
	my $x = $self->{X};
	my $prev;
	
	for(my $i=0; $i<@_; $i++) {
		my $a = $_[$i];
		if(ref $a eq "Regexp") {
			die "регулярка уже есть у терминала $prev->{name}" if exists $prev->{re};
			$prev->{re} = $a;
		}
		elsif(ref $a eq "CODE") {
			die "код уже есть у терминала $prev->{name}" if exists $prev->{sub};
			$prev->{sub} = $a;
		}
		else {
			die "терминал `$a` уже есть" if exists $x->{ $a };
			$x->{ $a } = $prev = { name => "x $a" };
		}
	}
	
	$self
}

###############################  лексический анализатор ###############################

# формирует список имён операторов
sub operators {
	my ($self) = @_;
	keys %{ +{ keys %{$self->{INFIX}}, keys %{$self->{PREFIX}}, keys %{$self->{POSTFIX}} } };
}

# формирует лексемы
sub _lex {
	my $self = shift;
	join "|", map {
		$_->{re} // do { 
			my $x = quotemeta($_->{name} =~ /^\w+ /? $`: die("странное name"))
			$x = "\\b$x" if $x =~ /^\w/;
			$x = "$x\\b" if $x =~ /\w$/;
		}
	} @_
}

# формирует лексический анализатор из таблиц операторов, скобок и операндов
sub lexx {
	my ($self) = @_;
	
	return $self->{LEXX} if defined $self->{LEXX};
	
	my $re_op = $self->_lex( values %{ +{ %{$self->{INFIX}}, %{$self->{PREFIX}}, %{$self->{POSTFIX}} } } );
	
	my $open_brakets = $self->_lex( values %{$self->{BR}} );
	my $close_brakets = $self->_lex( values %{$self->{CR}} );
	my $terms = $self->_lex( values %{$self->{X}} );	
	
	$self->{LEXX} = qr{
		(?<op> $re_op )				(?{ $self->op($+{op}) }) |
		(?<br> $open_brakets )		(?{ $self->push($+{br}) }) |
		(?<cr> $close_brakets )		(?{ $self->pop($+{cr}) }) |
		(?<x>  $terms )				(?{ $self->atom($+{x}) }) |
		\s+							|	# пропускаем пробелы
		(?<sym> . )					(?{ $self->error(sprintf($self->{error}{sym}, $+{sym})) })
	}sxo
}

###############################  синтаксический разбор  ###############################

=pod таблица приведения



=cut



# выбрасывает оператор
sub popop {
	my ($self) = @_;
	
	my $front = $self->{front};
	my $op = $self->{OP};
	my $stmt = $push->{stmt};
	#my $OP = $self->top->{OP};		# 1-после операнда или постфиксного оператора
	
	# a++ b - gosub			после a уст. 1
	# a b - gosub
	# a +b = a + b
	# a + -b
	
	
	
	# if(!$operator && $OP) {			# обнаружен gosub
		# # преобразуем переменную или незакончившийся вызов метода в gosub
		# if(exists $OP->{tag} or exists $OP->{gosub}) {
			# push @$code, $prev = {stmt => 'gosub', var => 1, endline => 1, gosub => 1};
		# }
		# else {
			# $prev->{gosub} = 1;
			# $prev->{endline} = 1;
			# $prev->{stmt} .= "_go";
		# }
		# push @{$self->{stack}}, $prev;
		# $self->trace("^", $prev);


	#push @$T, $operator;
	#$self->trace("?", $operator);
	
	$self
}


# пришёл оператор
sub op {
	my $self = shift;
	my $push = {%+, 'stmt', @_};
	
	$self->popop($push) if $self->{op};
	
	$self->{op} = $push;
	
	#my $stmt = $_[0];
	
	# вначале и после инфиксного оператора и открывающей скобки = 1
	# после терма, закрывающей скобки и постфиксного оператора = 0
	# ^ ( +				=1
	# a ) a++ -a		=0
	
	# 0 + 1
	# 0 -a 1
	
	# my $front = $self->{front};
	
	# my $op = $front? $PREFIX{ $stmt }: $INFIX{ $stmt } // $POSTFIX{ $stmt };
	
	# $self->error("не объявлен ".($front? "префиксный": "инфиксный или постфиксный")." оператор $stmt") unless $op;
	
	# my $fix = $op->{fix};
	# $self->{front} = !($fix & $postfix);
	
	# my $S = $self->{stack};
	
	# # выбрасываем все операторы с меньшим приоритетом		
	# my $prio = $op->{prio};
	# my $x; my $s;
	# while(@$S && defined($x = ($s = $S->[-1])->{prio}) && (
			# $x < $prio || $x==$prio && $s->{fix} & $leftassoc
		# )) {
		# $self->popop;
	# }
	
	# $self->error("оператор $s->{stmt} неассоциативен") if $s && $s->{fix} & $nonassoc && $prio == $x;
	
	
	# my $name = $op->{stmt};
	# $push->{stmt} = $name if defined $name;
	# $push->{prio} = $prio;
	# $push->{fix} = $fix;
	# push @$S, $push;
	# $self->trace("?", $push);
	
	$self
}


# добавляет терм
sub atom {
	my $self = shift;
	my $push = {%+, 'stmt', @_};
	
	if(my $op = $self->{op}) {
		if($op->{FIX} & $postfix)
	}
	
	$self->{front} = 0;
	my $terms = $self->{terms};
	push @$terms, $push;
	$self->trace("¤", $push);
	$self
}



# добавляет открывающую скобку
sub push {
	my $self = shift; 
	my $push = {%+, 'stmt', @_, 'T+' => 1 + @{$self->{terms}} };
	
	$self->{front} = 1;
	
	push @{$self->{stack}}, $push;
	push @{$self->{space}}, $push;
	
	$self->trace("+", $push);
	
	$self
}

# закрывающая скобка
sub pop {
	my ($self, $stag) = @_;
	
	$self->{front} = 0;
	
	my $S = $self->{stack};
	my $T = $self->{terms};
	my $C = $self->{space};
	
	# ошибка
	$self->error("нет открывающей скобки" . (defined($stag)? "к $stag": "")) if !@$S;
	
	# выбрасываем все операторы до скобки
	while(@$S && defined $S->[-1]{prio}) {
		$self->popop;
	}
	
	$self->error("нет открывающей скобки ".(defined($stag)? "к $stag ": "")."- стек S пуст") if !@$S;
	$self->error("нет открывающей скобки ".(defined($stag)? "к $stag ": "")."- стек С пуст") if !@$C;
	
	my $sk = pop @$S;
	my $Sk = pop @$C;
	
	
	$self->error("скобка $Sk->{stmt} не смогла закрыться. Проверьте скобки между открывающейся и закрывающейся этими скобками") if $sk != $Sk;
	
	$self->error("при закрытии скобки $stag выброшено ".(@$T < $sk->{'T+'}? 'больше': 'меньше')." терминалов чем нужно") if $sk->{'T+'} != @$T;
	
	my $tag;
	$self->error("закрывающая скобка $stag конфликтует со скобкой $tag") if defined $stag and ($tag = $sk->{tag} // $sk->{stmt}) ne $stag;
	
	#$self->error("стек T пуст: невозможно достать операнд для скобки") if !@$T;
	
	$sk->{right} = pop @$T;
	push @$T, $sk;
	
	$self->trace("-", $sk);

	$self
}

# возвращает колоризированный массив стеков для trace и error
sub color_stacks {
	my ($self) = @_;
	local $_;
	return ":space",
		":dark white", "\tC:", ":reset", map({ $_->{stmt} } @{$self->{space}}),
		":dark white", "\tT:", ":reset", map({ $_->{stmt} } @{$self->{terms}}),
		":dark white", "\tS:", ":reset", map({ defined($_->{prio})? (":bold blue", $_->{stmt}, ":reset"): $_->{stmt} } @{$self->{stack}})
}

# отображает операции со стеком в лог
sub trace {
	my ($self, $op, $top) = @_;
	
	my $trace = $self->{trace};
	if( defined($trace) && $self->{file} eq $trace ) {
	
		local($+, $`, $', $&, $_, $a, $b);
	
		my $stmt = $top->{stmt};
	
		my @after;
		if(0) {
			my $after = {%$top};
			delete @$after{qw/stmt e left right/};
			@after = pairmap { "$a=$b" } %$after;
		}
		
		if(1) {
			push @after, $self->color_stacks;
		}
		
		$app->log->info( ":space", "$self->{lineno}:", ($op eq "+" || $op eq "^"? ":red": $op eq "-"? ":bold blue": $op eq "?"? ":red": $op eq "?"? ":bold blue": ":dark white"), $op, $stmt, ":reset", @after );
	}
	
	$self
}

# выбрасывает ошибку
sub error {
	my ($self, $msg) = @_;
	local ($_, $`, $', $&);
	
	my $color_msg = $app->log->colorized( "$self->{file}:$self->{lineno}: $msg", $self->color_stacks );
	
	die "$self->{file}:$self->{lineno}: $color_msg";
}

# формирует дерево
sub masking {
	my ($self, $s) = @_;
	
	my $lex = $self->lexx;
	
	while($s =~ /$lex/g) {}			# формируем дерево
	
	$self
}

# устанавливает шаблоны языка
sub templates {
	my $self = shift;
	
	my $c = $self->{lang}{templates} //= {};

	for(my $i=0; $i<@_; $i+=2) {
		my ($k, $v) = @_[$i, $i+1];
		
		$v =~ s/'/\\'/g;
		$v =~ s/\{\{\s*(\w+)\s*\}\}/', \$_->{$1} ,'/g;
		
		$c->{$k} = eval "sub { join '', '$v' }";
	}
	
	$self
}



# осуществляет два прохода по дереву кода и формирует код
sub expirience {
	my ($self) = @_;
	
	my $S = $self->{stack};
	my $T = $self->{terms};
	
	$self->error("expirience: стек S не пуст") if @$S != 0;
	$self->error("expirience: в стеке T должен быть 1-н элемент") if @$T != 1;
	

	#msg1 ":size10000", $self->top;
	
	# обход в глубину - модификации дерева
	if(defined(my $modifiers = $self->{lang}{modifiers})) {
		my @path = $T->[0];
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
	my $templates = $self->{lang}{templates};
	my $out;
	my @path = $T->[0];
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
			$_ = pop @path;		# удаляем элемент
			
			#$_->{code} = join "", @$code if $code;
			
			my $template = $templates->{ $_->{stmt} };
			die "нет шаблона $_->{stmt} в языке $self->{lang}" if !$template;
			
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



# морфирует в другой язык
sub morf {
	my ($self, $s) = @_;
	$self->masking($s)->expirience;
}

# вычисляет выражение
sub eval {
	my ($self, $code) = @_;
	my $ret = eval $self->morf($code);
	die $@ if $@;
	$ret
}

1;