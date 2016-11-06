package R::Syntax;
# синтаксический анализатор
# просматривает на один оператор вперёд, благодаря чему может определить арность оператора

use common::sense;
use R::App;

# конструктор
sub new {
	my $cls = shift;
	bless {
		
		PREFIX => {},			# префикс-операторы
		INFIX => {},			# инфикс-операторы 
		POSTFIX => {},			# постфикс-операторы
		
		BR => {},				# скобки
		CR => {},				# закрывающие скобки (для формирования лексики)
		X => {},				# терминалы
		
		PRIO => 0,				# инкремент приоритета
		
		LEX => undef,			# лексический анализатор
		
		show_morf => 0,			# отражать ли преобразование в лог
		#trace => "«eval»",		# файл трейс которого показать
		file => "",				# путь к текущему файлу
		lineno => 1,			# номер строки в текущем файле
		
		stack => undef,			# стек скобок
		lex => undef,			# кэш - лексический анализатор
		
		error => {				# ошибки
			nosym => "неизвестный науке символ `%s`",
		},
		
		@_
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
		prio=>$self->{PRIO},
		fix=>$fix,
		type=>$type,
	);
	my $op;
	
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
			$op = $self->{$key}{$x} = {%p, name=>"$type $x"};
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
	
	my $br = $self->{BR};
	my $closest = $self->{CR};
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
			die "скобка `$a` уже есть" if exists $br->{ $a };
			$br->{ $a } = $open = { name => "br $a" };
			undef $close;
		}
		else {	# закрывающая скобка
			if(exists $closest->{ $a }) {
				$close = $closest->{ $a };
			} else {
				$closest->{ $a } = $close = { name => "cr $a", cr=>1 };
			}
			$open->{tag} = $a;
		}
	}
	
	$self
}

# операнды (терминалы)
sub x {
	my $self = shift;
	
	#die "формирование таблицы символов уже завершено" if $self->{LEX};
	
	my $x = $self->{X};
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
			die "терминал `$a` уже есть" if exists $x->{ $a };
			$x->{ $a } = $prev = { name => $a };
			push @term, $prev;
		}
	}
	
	for my $a (@term) {
		#$a->{re} = quotemeta $a->{name} if !exists $a->{re};
		#my $name = quotemeta $a->{name};
		#use charnames;
		#$name =~ s/\W/charnames::viacode(ord $&)/ge;
		if($a->{re}) {
			$a->{re} = "(?<$a->{name}>$a->{re})";
		}
		else {
			$a->{re} = quotemeta $a->{name};
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
	join "", map {
	
		my $name = $_->{name};
		$name =~ s/^\w+\s+// if $_->{fix} || $_->{cr} || exists $_->{tag};
		$name = quotemeta $name;
		
		my $ret = exists $_->{tag}? "\$self->push(\"$name\", tag=>\"".quotemeta($_->{tag})."\")":
		$_->{cr}? "\$self->pop(\"$name\")":
		"\$self->op(\"$name\")";
		
		"\t\t$_->{re}		(?{ $ret }) |\n"
	
	} nsort { -length $_->{re} } map {
		$_->{re} //= do {
			my $x = quotemeta($_->{fix} && $_->{name} =~ /^\w+\s+/? $': $_->{name});
			$x = "\\b$x" if $x =~ /^\w/;
			$x = "$x\\b" if $x =~ /\w$/;
			$x
		};
		$_
	} @_
}

# формирует лексический анализатор из таблиц операторов, скобок и операндов
sub lex {
	my ($self) = @_;
	
	return $self->{lex} if defined $self->{lex};
	
	my $BR = $self->{BR};
	
	my $re = $self->_lex( values %{$self->{INFIX}}, values %{$self->{PREFIX}}, values %{$self->{POSTFIX}}, values %$BR, values %{$self->{CR}}, values %{$self->{X}} );
		
	$re = "\n$re" if $re ne "";
		
	my $lex = "qr{$re
		\\n		(?{ \$self->{lineno}++; \$self->{charlineno}=length \$` })  |
		\\s+		|	# пропускаем пробелы
		(?<nosym> . )	(?{ \$self->error(sprintf(\$self->{error}{nosym}, \$+{nosym})) })
	}sx";
	
	my $lexx = eval $lex;
	die $@ if $@;
	
	$self->{lex} = $lexx;
	
	$lexx
}

###############################  синтаксический разбор  ###############################



# пришёл оператор
sub op {
	my $self = shift;
	my $push = {%+, 'stmt', @_};
	
	push @{$self->{stack}[-1]{'A+'}}, $push;
	#$self->trace("_", $push);
	$self
}


# пришёл терм
sub atom {
	my $self = shift;
	my $push = {%+, 'stmt', @_};
	
	push @{$self->{stack}[-1]{'A+'}}, $push;
	#$self->trace(",", $push);
	$self
}



# добавляет открывающую скобку
# все операторы и атомы добавляются в неё
sub push {
	my $self = shift; 
	my $push = {%+, 'stmt', @_};
	
	push @{$self->{stack}}, $push;
	$self->trace("+", $push);
	$self
}

# закрывающая скобка
# происходит разбор операторов и термов, попавших меж скобок
sub pop {
	my ($self, $stag) = @_;
	
	$self->{front} = 0;
	
	my $stack = $self->{stack};		# стек скобок
	
	# выбрасываем скобки
	$self->error("нет открывающей скобки ".(defined($stag)? "к $stag ": "")."- стек S пуст") if !@$stack;
	
	my $sk = pop @$stack;

	my $tag;
	$self->error("закрывающая скобка $stag конфликтует со скобкой $tag") if defined $stag and ($tag = $sk->{tag} // $sk->{stmt}) ne $stag;
	
	my $A = $sk->{'A+'};
	$self->error("скобки ".($stag eq $tag? $tag: $tag." ".$stag)." не могут быть пусты") if !$A;
	
	my $PREFIX =  $self->{PREFIX};
	my $INFIX =  $self->{INFIX};
	my $POSTFIX =  $self->{POSTFIX};
	
	my @T;
	my @S;
	my $front = 1;
	my $meta;
	
	my $popop = sub {
		my $prio = $meta->{prio};
		my $s;
		my $x;

		while(@S &&
			(($x = ($s = $S[-1])->{prio}) < $prio || 
			$x==$prio && $s->{fix} & $leftassoc)
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
				$self->error("нет операнда для оператора $r->{stmt}") if !defined( $r->{left} = pop @T );
				$self->trace("<", $r);
			}
			push @T, $r;
		}
		
		if(my $op = $_[0]) {
			@$op{qw/stmt fix prio/} = @$meta{qw/name fix prio/};
			push @S, $op;
			$self->trace("^", $op);
		}
	};
	
	# определяем с конца сколько постфиксных операторов
	my $n;
	for($n=@$A; $n>0; $n--) {
		last if !exists $POSTFIX->{$A->[$n-1]{stmt}};
	}
	
	# определяем операторы
	my $i = 0;
	for my $op (@$A) {
	
		my $stmt = $op->{stmt};
	
		if($front and $meta = $PREFIX->{$stmt}) {
			$popop->($op);
		}
		elsif(!$front and $meta = $INFIX->{$stmt} and $i<$n) {
			$popop->($op);
			$front = 1;
		}
		elsif(!$front and $meta = $POSTFIX->{$stmt}) {
			$popop->($op);
		}
		else {	# терминал
			$front = 0;
			push @T, $op;
			$self->trace("¤", $op);
		}
	}
	continue {
		$i++;
	}
	
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

my %COLOR = (
	"+" => ":red",
	"-" => ":bold blue",
	"<" => ":cyan",
	">" => ":cyan",
	"%" => ":cyan",
	"^" => ":magenta",
);

# возвращает колоризированный массив стеков для trace и error
sub color_stacks {
	my ($self) = @_;
	local $_;
	return ":space",
		":dark white", "\tS:", ":reset", map({ $_->{stmt} } @{$self->{stack}})
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
		
		$app->log->info( ":space", "$self->{lineno}:", $COLOR{$op} // ":dark white", $op, $stmt . (exists $top->{$stmt}? "<$top->{$stmt}>": ""), ":reset", @after );
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

# формирует дерево
sub masking {
	my ($self, $s) = @_;
	
	my $lex = $self->lex;
	
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
		$k =~ s/\s+/ /g;
		
		$c->{$k} = eval "sub { join '', '$v' }";
	}
	
	$self
}



# осуществляет два прохода по дереву кода и формирует код
sub expirience {
	my ($self, $root) = @_;
	

	#msg1 ":size10000", $self->top;
	
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
			
			# $_ используется в функциях-шаблонах. Так передаётся параметр
			$_ = pop @path;		# удаляем элемент
			
			#$_->{code} = join "", @$code if $code;
			
			my $template = $templates->{ $_->{stmt} };
			die "нет шаблона `$_->{stmt}` в языке " . ($self->{lang}{name} // "«язык Батькович»") . " для " . $app->perl->dump($_) . " со стеком " . $app->perl->inline_dump(\@path) if !$template;
			
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
	my ($self, $s, $file) = @_;
	$self->{file} = $file // "«eval»";
	$self->{lineno} = 1;
	$self->{charlineno} = 0;
	
	my $S = $self->{stack} = [my $root = {stmt=>$app->perl->mq("root")}];
	
	$self->push("¥")->masking($s)->pop("¥");
	
	$self->error("конец: стек должен содержать 1-н элемент") if @$S != 1;
	
	my $A = $root->{"A+"};
	$self->error("конец: пустой код") if !defined $A;
	
	$self->error("конец: рут должен содержать 1-н элемент") if @$A != 1;
	
	my $ret = $self->expirience($A->[0]{right});
	msg1 ":space cyan", "code:", $s, ":reset", , ":red", "->", ":reset", $ret if $self->{show_morf};
	$ret
}

# вычисляет выражение
sub eval {
	my ($self, $code) = @_;
	my $morf = $self->morf($code);
	my @ret = wantarray? eval $morf: scalar eval $morf;
	die $@ if $@;
	wantarray? @ret: $ret[0]
}

# проверяет параметры на верхушке стека скобок и выбрасывает ошибку, если они не совпадают
sub check {
	my $self = shift;
	for(my $i=0; $i<@_; $i+=2) {
		my ($k, $v) = @_[$i, $i+1];
		next if $k == 1;
		if( $_->{$k} ne $v ) {
			my %check = @_;
			$self->error(exists($check{1})? $check{1}: "$check{stmt}: не совпадает $k в стеке. Оно $_->{$k}, а должно быть $v");
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