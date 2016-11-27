package R::View::Morf::Perl;
# драйвер для перевода языка Argentum в язык perl

use common::sense;
use R::App;

# не имеет конструктора - не может использоваться как тип

my $in = "'; "; my $_in = "; push \@{\$R::App::app->{q}{echo}}, '";
my $raw = "', (scalar do { "; my $_raw = " }), '";
my $esc = "', R::View::Views::escapeHTML(scalar do { "; my $_esc = " }), '";

### шаблоны
our %templates = (



"\n" => ";\n",

'yf .$word' => '{{ left }}->${$DATA->{{{ var }}}}',
'yf .word' => '{{ left }}->{{ var }}',
'yf :word' => '{{ left }}->{{{ var }}}',

'xfy .$word()' => '{{ left }}->${$DATA->{{{ var }}}}({{ right }})',
'xfy .$word{}' => '{{ left }}->${$DATA->{{{ var }}}}{{{ right }}}',
'xfy .$word[]' => '{{ left }}->${$DATA->{{{ var }}}}[{{ right }}]',

'xfy .word()' => '{{ left }}->{{ var }}({{ right }})',
'xfy .word{}' => '{{ left }}->{{ var }}{{{ right }}}',
'xfy .word[]' => '{{ left }}->{{ var }}[{{ right }}]',

'xfy :word()' => '{{ left }}->{{{ var }}}({{ right }})',
'xfy :word{}' => '{{ left }}->{{{ var }}}{{{ right }}}',
'xfy :word[]' => '{{ left }}->{{{ var }}}[{{ right }}]',

'.word.br' => '{{ right }}',

# строки
string => '"{{ right }}"',
str => '{{ str }}',
kav => '{{ str }}\"',
interpolation => '{{ str }}${\( {{ right }} )}',

# атомы
var => '$DATA->{{{ var }}}',
num => '{{ num }}',
regexp => 'qr({{ QR }}){{ qr_args }}',
'[]' => '[]',
'()' => '()',
'{}' => '{}',
app => '$app',

# массивы
'[' => '[ {{ right }} ]',
'{' => '{ {{ right }} }',
'(' => '( {{ right }} )',

'xf @' => '@{{{ left }}}',
'xf %' => '%{{{ left }}}',


# операторы 
'[]=' => 'push(@{{{ left }}}, {{ right }})',
gosub => '->( {{ right }} )',

# арифметические операторы
"xfy +" => '({{ left }}) + ({{ right }})',
"xfy -" => '({{ left }}) - ({{ right }})',
"xfy *" => '({{ left }}) * ({{ right }})',
"xfy /" => '({{ left }}) / ({{ right }})',

"fy +" => '0+({{ right }})',
"fy -" => '-({{ right }})',


# операторы распределения данных
'xfy \n' => "{{ left }};\n{{ right }}",
'fy \n' => "\n{{ right }}",
'yf \n' => "{{ left }}\n",

"xfy ;" => '{{ left }}; {{ right }}',
"xfy ," => '{{ left }}, {{ right }}',
"yf ," => '{{ left }}',
"xfy =>" => '{{ left }} => {{ right }}',

# операторы присваивания
"yfx =" => '({{ left }}) = ({{ right }})',
"yfx as" => '({{ right }}) = ({{ left }})',

# операторы смысловых конструкций
"xfy then" => sub {
	given($b->{then}) {
		#when ("") {}
		default { die "нет такого THEN: $_" }
	}
	
},

HTML => "{{ html }}",
'xfy CAT' => "{{ left }}{{ right }}",
GET => "{{ html }}" . $esc . '{{ right }}' . $_esc,
RAW => "{{ html }}" . $raw . '{{ right }}' . $_raw,
LET => "{{ html }}" . $in . '{{ right }}' . $_in,
COMMENT => "{{ html }}" . $in . '{{ lines }}' . $_in,
TEMPLATE => 'package {{ class }};{{ extends }} use common::sense; use R::App; use List::Util;{{ begin }} sub {{ block }} { my $DATA = shift; '.$_in.'{{ right }}'.$in.' return; } 1;',
INHERITS => '',

);


### модификаторы
our %modifiers = (

# наследование шаблона
INHERITS => sub  {
	my ($self, $node, $path) = @_;
	$node->{block} = "__UNUSED__";
	my $inherits = map { $self->get_name($_) } split /\s*,\s*/, $node->{inherits};	
	my $mro = @$inherits>1? " use mro 'c3';": "";
	$inherits = join " ", @$inherits;
	$node->{extends} = $inherits? " use parent -norequire, qw/$inherits/;$mro": "";
	$self
},

### конец модификаторов
);

# заменяет спецсимволы в строке
sub escape_string {
	my ($self, $string, $kav) = @_;
	if($kav eq "'") {
		$string =~ s/'/\\'/g;
	} else {
		$string =~ s/[\$\@]/\\$&/g;
	}
	$string
}

# # заменяет выражение в строке
# sub replace_dollar {
	# my ($self, $masking, $kav) = @_;
	# "$kav . $masking . $kav"
# }

# # конец строки, возможно с комментарием
# sub endline {
	# my ($self, $rem, $endline) = @_;
	# (defined($rem)? "#$rem": "") . $endline
# }

# # конец выражения
# sub sepexpression {
	# ";"
# }

# # конец выражения после then
# sub sepexpression_after_then {
	# return;
# }

# # встретилась регулярка
# sub regexp {
	# my ($self, $regexp, $args) = @_;
	# "qr{$regexp}$args"
# }

# # вспомогательный метод для скобок
# sub _sk {
	# my ($name, $sk) = @_;
	# return $name if !defined $sk;
	# return "$name(", ")" if $sk eq "(";
	# return "$name->\[", "]" if $sk eq "[";
	# return "$name->\{", "}";
# }

# # встретилось имя класса
# sub classname {
	# my ($self, $name, $sk) = @_;
	# _sk($name, $sk);
# }

# # встретилась переменная
# sub var {
	# my ($self, $name, $sk) = @_;
	# _sk("\$DATA->{'$name'}", $sk);
# }

# # вызов метода по ссылке
# sub dotref {
	# my ($self, $name, $sk) = @_;
	# _sk("->\${\\\$DATA->{'$name'}}", $sk)
# }

# # вызов метода
# sub dot {
	# my ($self, $name, $sk) = @_;
	# _sk("->$name", $sk)
# }

# # по ключу хеша
# sub colon {
	# my ($self, $name, $sk) = @_;
	# _sk("->{'$name'}", $sk)
# }

# # разыменование класса
# sub twocolon {
	# my ($self, $name, $sk) = @_;
	# _sk("::$name", $sk)
# }

# # доступ к реальной переменной
# my %CloseTag = qw/ ( ) { } [ ] /;
# sub dollar {
	# my ($self, $name, $sk) = @_;
	# "\$$name$sk", ($sk? $CloseTag{$sk}: ())
# }

# # встретился ключ
# sub key {
	# my ($self, $key) = @_;
	# "$key => scalar "
# }

# # встретилась долгая запятая
# sub fat_comma {
	# "=> scalar "
# }

# # встретилось ключевое слово
# sub word {
	# my ($self, $word) = @_;
	# lc $word
# }

# # встретился указатель на себя
# sub self {
	# '$self'
# }

# # встретилась специальная переменная app
# sub appvar {
	# '$R::App::app'
# }

# # встретилась специальная переменная q
# sub q {
	# '$R::App::app->{q}'
# }

# # встретилась специальная переменная user
# sub user {
	# '$R::App::app->{q}->user'
# }

# # встретился цикл while
# sub while {
	# return "while(", ") {", "}";
# }

# # встретился цикл repeat
# sub repeat {
	# "do {"
# }

# # встретился until
# sub until {
	# return "} while(!(", "));";
# }

# # встретился if
# sub if {
	# return "((", ")? do {", "}: ())";
# }

# # встретился elseif
# sub elseif {
	# return "}: (", ")? do {";
# }

# # встретился else
# sub else {
	# return "}: do {", "})";
# }

# # встретился try
# sub try {
	# "do { eval {"
# }

# # встретился catch
# sub catch {
	# my ($self, $isa, $var, $is_end) = @_;
	# $var = $var? " \$DATA->{'$var'}=\$@;": "";
	# $isa = defined($isa)? do { $isa =~ s/,/ /g; "Isa(\$@, qw/$isa/)"}: "defined \$@";
	# my $pre = $is_end? "}:": "};";
	# return "$pre $isa? do {$var ", "}: () }";
# }

# # открывающая скобка 
# sub group {
	# return "(", ")";
# }

# # открывающая скобка массива
# sub array {
	# return "[", "]";
# }

# # открывающая скобка хэша
# sub hash {
	# return "+{", "}";
# }

# # конвеер
# sub pairmapconv {
	# "pairmap { \$DATA->{a} = \$a; \$DATA->{b} = \$b; "
# }

# # конвеер
# sub map {
	# "map { \$DATA->{a} = \$_; "
# }

# # конвеер
# sub grep {
	# "grep { \$DATA->{a} = \$_; "
# }

# # конвеер
# sub reduceconv {
	# "reduce { \$DATA->{a} = \$a; \$DATA->{b} = \$b; "
# }

# # конвеер
# sub sort {
	# "sort { \$DATA->{a} = \$a; \$DATA->{b} = \$b; "
# }

# # from после конвеера
# sub from {
	# " } ", ""
# }

# # блок begin
# sub begin {
	# return "BEGIN { my \$DATA; ", "}";
# }

# # роутер on
# sub route {
	# my ($self, $route) = @_;
	
	# my $actionName = $route;
	
	# $route =~ s!^/?!/!;
	# $actionName =~ s!/([a-z])!ucfirst $1!ige;
	# $actionName =~ s!-!__!g;
	# $actionName = "on__$actionName";
	
	# my $path = $app->view->{file};
	
	# return "BEGIN { \$R::App::app->view->route_on('$route', \\&{'$actionName'}, '$path') } sub $actionName { my \$DATA={};", "}";
# }

# # addhandler в роутере on
# sub addhandler {
	# "return if \$app->{q}->isErrors"
# }

# # массив параметров функции
# sub paramarray {
	# "\@_"
# }

# # супервызов блока
# sub template_super {
	# my ($self, $block, $sk) = @_;
	# "\$DATA->SUPER::$block$sk"
# }

# # супервызов метода
# sub super {
	# my ($self, $method, $sk, $is_method) = @_;
	# ($method eq "new"? '$self=': "") . "\$self->SUPER::$method" . (!$is_method && !$sk? '(@_)': $sk)
# }

# # вызов метода
# sub gosub {
	# my ($self, $name) = @_;
	# return "$name(", ")";
# }

# # оператор присваивания
# sub assign {
	# "="
# }

# # new Class
# sub newstmt {
	# my ($self, $name) = @_;
	# "$name->new"
# }

# # разыменивание ссылки на массив
# sub unarray {
	# my ($self) = @_;
	# return "\@{", "}"
# }

# # разыменивание ссылки на хэш
# sub unhash {
	# my ($self, $code) = @_;
	# return "%{", "}"
# }

# # ничего
# sub nothing {
	# "undef"
# }

# # константа true
# sub true {
	# "\$app->json->true"
# }

# # константа false
# sub false {
	# "\$app->json->false"
# }

# # выброс исключения
# sub throw {
	# "die"
# }

# # числовая константа
# sub number {
	# my ($self, $num) = @_;
	# $num
# }

# # оператор
# my %replace_op = qw/^ ** mod % xor ^/;
# sub operator {
	# my ($self, $operator) = @_;
	# $replace_op{$operator} // $operator
# }

# # пробелы
# sub space {
	# my ($self, $space) = @_;
	# $space
# }

# # ,
# sub comma {
	# ","
# }

# # формирует аргументы функции
# sub _args {
	# my ($args) = @_;
	# local $_;
	# my $AST=0;
	# $args = join ", ", map { $_ eq "*"? do { $AST++; "my \$_AST$AST"}: "\$DATA->{'$_'}"} @$args;
	# $args = "($args) = \@_; " if $args;
	# $args .= "%\$DATA = (".join(", ", map { "\%\$_AST$_" } 1..$AST).", %\$DATA); " if $AST;
	# $args
# }

# # формирует заголовок функции
# sub _sub {
	# my ($name, $args, $class) = @_;
	# my $sub = $class? "my \$self=shift; ": "";
	# $sub .= _args($args);
	# $sub .= "\$self = bless {}, ref \$self || \$self; " if $name eq "new";
	# $sub
# }


# # объявление функции
# sub sub {
	# my ($self, $name, $args, $class_in, $class, $endline) = @_;
	
	# my $sub = _sub($name, $args, $class);
	
	# return ($class_in? "package $class_in {": "") . "sub $name { my \$DATA = {}; $sub$endline(); ", ($class_in? "}}": "}");
# }


# # перегрузка оператора
# sub overload {
	# my ($self, $name, $args, $class_in, $class, $endline) = @_;
	
	# my $sub = _sub($name, $args, $class);
	
	# return ($class_in? "package $class_in {": "") . "use overload '$name' => sub { my \$DATA = {}; $sub$endline(); ", ($class_in? "}}": "};");
# }


# # блок do
# sub do {
	# my ($self, $prevop, $args, $endline) = @_;
	# my $args = _args($args);
	# #$endline не выводим - если там then... а у perl нет конца комментария
	# ($prevop? "": ", ") . "sub { $args", "}"
# }

# # самый обычный for =
# sub for {
	# my ($self, $k, $i) = @_;
	# my $begin = $i? "\$DATA->{'$i'}=0; ": "";
	# my $end = $i? "; \$DATA->{'$i'}++; ": "";
	# return "${begin}for my \$I_$k (", ") { \$DATA->{'$k'}=\$I_$k;", "$end}";
# }

# # for с разыменованием параметра
# sub for_in {
	# my ($self, $k, $i) = @_;
	# my ($begin, $then, $end) = $self->for($k, $i);
	# return "$begin\@{", "}$then", $end;
# }

# # for по хэшу
# sub for_of {
	# my ($self, $k, $v, $i) = @_;
	# my $begin = $i? "\$DATA->{'$i'}=0; ": "";
	# my $end = $i? "; \$DATA->{'$i'}++; ": "";
	# my $then = $v? " \$DATA->{'$v'}=\$H_${k}->{\$I_$k};": "";
	# return "${begin}my \$H_$k = ", "; for my \$I_$k (keys %\$H_$k) { \$DATA->{'$k'}=\$I_$k;$then", "$end}";
# }

# # хелпер для расширения класса
# sub _extends {
	# my ($extends) = @_;
	# if(defined $extends) {
		# my $x = $extends =~ s/,/ /g;
		# $extends = " use parent -norequire, qw/$extends/;";
		# $extends .= " use mro 'c3';" if $x;
	# }
	# $extends
# }

# # декларация модуля
# sub module {
	# my ($self, $name, $extends) = @_;
	# $extends = _extends($extends);
	# return "(do { BEGIN { \$R::View::Perl::Classes{'$name'}++; push \@R::View::Perl::Classes, '$name'; } package $name; $extends use common::sense; use R::App; sub __INIT__CLASS__ { my \$DATA; my \$self = shift; ", "} __PACKAGE__ })";
# }

# # декларация класса
# sub class {
	# my ($self, $name, $extends) = @_;
	# $extends = _extends($extends);
	# return "(do { BEGIN { \$R::View::Perl::Classes{'$name'}++; push \@R::View::Perl::Classes, '$name'; } package $name; $extends use common::sense; use R::App; sub __INIT__CLASS__ { my \$DATA; my \$self = shift; ", "} __PACKAGE__ })";
# }

# # функция для вставки в модуль
# sub modulesub {
	# my ($self, $module, $sub, $cls) = @_;
	# " sub ${module}::$sub { '$cls' }"
# }

# # добавляет new и аргументы
# sub object {
	# my ($self, $cls) = @_;
	# return "->new(" , ")"
# }

# # вставка кода в темплейт
# sub v_in {
	# return "'; ", "; push \@{\$R::App::app->{q}{echo}}, '"
# }

# # вставка выражения в темплейт
# sub v_raw {
	# return "', (scalar do { ", " }), '"
# }

# # вставка выражения с экранированием
# sub v_escape {
	# return "', R::View::Views::escapeHTML(scalar do { ",  " }), '";
# }

# # запоминание позиции кода
# my $SETPOS = 0;
# sub v_setpos {
	# join "", 'my $SETPOS', ++$SETPOS, '=@{$R::App::app->{q}{echo}};';
# }

# # возвращение позиции кода
# sub v_getpos {
	# "splice \@{\$R::App::app->{q}{echo}}, \$SETPOS$SETPOS"
	
# }


# # сценарий
# sub scenario {
	# my ($self, $name, $masking) = @_;
	# return "package R::View::Views; use common::sense; use R::App; sub __sc__$name { my \$DATA = {}; $masking;
# }

# 1;"
# }

# # возвращает шаблон
# sub template {
	# my ($self, $class, $inherits, $begin) = @_;
	
	# my $block = @$inherits? "__UNUSED__": "__RENDER__";
	
	# my $mro = @$inherits>1? " use mro 'c3';": "";
	# $inherits = join " ", @$inherits;
	# my $extends = $inherits? " use parent -norequire, qw/$inherits/;$mro": "";
	# return "package $class;$extends use common::sense; use R::App; use List::Util;$begin sub $block { my \$DATA = shift; ", " return; } 1;"
# }

# # блок
# sub block {
	# my ($self, $name) = @_;
	# return "sub $name { my \$DATA=shift;", " return; } \$DATA->$name;"
# }

# # блок вывода джаваскрипта в app.js
# sub js {
	# return v_setpos(), join "", "\$R::App::app->js->append( ", v_getpos(), " );"
# }

# # блок filter
# sub filter {
	# my ($self, $var) = @_;
	# return v_setpos(), join "", "push \@{\$R::App::app->{q}{echo}}, R::View::Filter->", $var, "(join '', ", v_getpos(), ")"
# }

# # часть шаблона в переменную
# sub set {
	# my ($self, $var) = @_;
	# return v_setpos(), join "", "\$DATA->{", $var, "} = bless [join '', ", v_getpos(), "], 'R::Html';";
# }

# # включение блока или шаблона
# sub include {
	# my ($self, $name, $block) = @_;
	# $block //= "__RENDER__";
	# return "my \$_DATA=\$DATA; \$DATA=bless {%\$DATA}, '$name';", "; \$DATA->$block; \$DATA=\$_DATA;"
# }

# # включение блока или шаблона без сохранения переменных
# sub process {
	# my ($self, $name, $block) = @_;
	# $block //= "__RENDER__";
	# return "", " my \$BLESS=ref \$DATA; bless \$DATA, '$name'; \$DATA->$block; bless \$DATA, \$BLESS;"
# }

# # экшн
# sub action {
	# my ($self, $key, $route, $view) = @_;
	# "BEGIN { \$R::App::app->view->action('$key', '$route', '$view') }"
# }

# # блок функции в темплейте
# sub subinblock {
	# return " my \$IDX = \@{\$R::App::app->{q}{echo}};", "return bless [splice \@{\$R::App::app->{q}{echo}}, \$IDX], 'R::Html' ";
# }

# # вызывается в masking для второго прохода по свормированному коду в этом языке
# # должен модифицировать $_[1]
# sub expirience {
	# #my ($self, $expirience) = @_;
	# #$_[1] = $expirience
	# $_[1]
# }

# рендерит
sub render {
	my ($self, $name, $data, $output) = @_;
	
	my $class = $self->get_name($name);
	
	$data //= {};
	bless $data, $class;
	
	push @{$app->{q}{VIEW_FRAME}}, $app->{q}{echo};
	
	$app->{q}{echo} = $output;
	
	$data->__RENDER__;
	
	$app->{q}{echo} = pop $app->{q}{VIEW_FRAME};
	
	$self
}

# добавляет данные для вычисления
sub foreval {
	my ($self, $code) = @_;
	"my \$DATA={}; $code"
}

# вычисляет выражение на perl
sub eval {
	my ($self, $eval) = @_;
	eval $eval;
}

our %Classes;
our @Classes;

# очищает классы
sub clear_classes {
	my ($self) = @_;
	
	%Classes = ();
	@Classes = ();
	
	$self
}

# позиция в классах
sub len_classes {
	int @Classes
}

# инициализирует классы
sub init_classes {
	my ($self, $from) = @_;
	
	return $self if $from == @Classes;
	
	my @cls = @Classes[$from .. $#Classes];
	
	# проверка на вшивость
	for my $class (@cls) {
		die "дважды объявлен класс $class" if $Classes{$class} > 1;
		$Classes{$class} = 1;
	}
	
	# запускаем тело класса
	for my $class (@cls) {
		$class->__INIT__CLASS__;
	}
	
	# инициализируем инпуты
	for my $class (@cls) {
		$class->create_meta if $class->isa("R::Form::Input");
	}
	
	# инициализируем формы
	for my $class (@cls) {
		$class->create_meta if $class->isa("R::Form::Form");
	}	
		
	# запускаем конструктор класса
	for my $class (@cls) {
		$class->CLASS_INIT if $class->can("CLASS_INIT");
	}
	
	$self
}

1;