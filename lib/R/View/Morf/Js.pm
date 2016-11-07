package R::View::Javascript;
# транслятор на js c языка программиррвания lukull

use common::sense;
use R::App;

has qw/name view/;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		name => "javascript",
		view => undef,			# устанавливается в view->parse
		tree => 0,				# построить дерево кода
		#ref => [],				# массив замен
	}, ref $cls || $cls;
}


# добавляет весь необходимый javascript
sub vitaland {
	my ($self) = @_;
	return if $self->{vitaland};
	$self->{vitaland} = 1;
q{
var $app = {}

var _Arr = Array.prototype
var _Obj = Object.prototype
var _own = _Obj.hasOwnProperty

function _extend(child, parent, methods) {
	function ctor() { this.constructor = child }
	ctor.prototype = parent.prototype
	var pro = child.prototype = new ctor()
	child.SUPER = parent.prototype
	if(methods)
		for(var i in methods) pro[i] = methods[i]
	return child
}


function _Html() { this.push.apply(this, arguments) }
_extend(_Html, Array, {
	render: function() { return this.join("") }
})

_Obj._apply = function(name, args) {
	return this[name].apply(this, args)
}

_Obj._assign = function() {
	for(var i in this) if(_own.call(this, i)) delete this[i]
	for(var i=0, n=arguments.length; i<n; i+=2) this[arguments[i]] = arguments[i+1]
	this
}

function keys(a) {
	var r=[]
	for(var i in a) if(_own.call(a, i)) r.push(i)
	return r
}

function values(a) {
	var r=[]
	for(var i in a) if(_own.call(a, i)) r.push(a[i])
	return r
}

function _esc(s) { 
	if(typeof s == 'object' && 'render' in s) return s.render();
	return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\"/g, '&quot;').replace(/\'/g, '&#39;');
}

function _range(a, b) { var A=new Array(b-a); for(var i=0,n=b-a; i<n; i++) A[i]=a+i; return A }

function _hash2array(h) { var a=[], i; for(i in h) a.push(i, h[i]); return a }

function _pairmap(self, data, cb, from) {
	var A=[], a=data.a, b=data.b
	for(var i=0, n=from.length; i<n; i+=2) { data.a=from[i]; data.b=from[i+1]; A.push(cb.call(self)) }
	data.a=a
	return A
}

function _map(self, data, cb, from) {
	var A=[], a=data.a
	for(var i=0, n=from.length; i<n; i++) { data.a=from[i]; A.push(cb.call(self)) }
	data.a=a
	return A
}

function _grep(self, data, cb, from) {
	var A=[], a=data.a
	for(var i=0, n=from.length; i<n; i++) { data.a=from[i]; if(cb.call(self)) A.push(from[i]) }
	data.a=a
	return A
}

function _reduce(self, data, cb, from) {
	var a=data.a, b=data.b
	data.a = from[0]
	for(var i=1, n=from.length; i<n; i++) { data.b=from[i]; data.a=cb.call(self) }
	var A=data.a
	data.a=a; data.b=b
	return A
}

function _sort(self, data, cb, from) {
	var a = data.a, b = data.b
	from.sort(function(a,b) { data.a=a; data.b=b; return cb.call(self) })
	data.a = a; data.b = b
	return from
}

function join() { var a=_Arr.slice.call(arguments); return a.join(a.shift()) }
function split(a, s) { return s.split(a) }

function _push() { var a=_Arr.slice.call(arguments); return a.push.apply(a.shift(), a) }
function _unshift() { var a=_Arr.slice.call(arguments); return a.unshift.apply(a.shift(), a) }
function _splice() { var a=_Arr.slice.call(arguments); return a.splice.apply(a.shift(), a) }
function _pop(a) { return a.pop() }
function _shift(a) { return a.shift() }


var $app_OUTPUT = [];

}
}

require R::Html;
sub _esc($) { goto &R::Html::_escape }
sub esc ($) { \R::Html::_escape(@_) }

# заменяет спецсимволы в строке
sub escape_string {
	my ($self, $string, $kav) = @_;
	if($kav eq "'") {
		$string =~ s/['\\]/\\$&/g;
	} else {
		$string =~ s/"/\\$&/g;
	}
	$string
}

# заменяет выражение в строке
sub replace_dollar {
	my ($self, $masking, $kav) = @_;
	"$kav+ $masking +$kav"
}

# конец строки, возможно с комментарием
sub endline {
	my ($self, $rem, $endline) = @_;
	#(defined($rem)? "//${esc $rem}": "") . 
	$endline
}

# конец выражения
sub sepexpression {
	my ($self) = @_;
	"<exp>;</exp>"
}

# конец выражения после then
sub sepexpression_after_then {
	''
}


# встретилась регулярка
sub regexp {
	my ($self, $regexp, $args) = @_;
	$regexp =~ s!/!\\/!g;
	"<regexp>/${esc $regexp}/$args</regexp>"
}

# встретилось имя класса
sub classname {
	my ($self, $name, $sk) = @_;
	$self->_sk(_class_name($name), $sk)
}

# вспомогательный метод для скобок
sub _sk {
	my ($self, $name, $sk) = @_;
	return $name if !defined $sk;
	return "$name(", ")" if $sk eq "(";
	return "$name->\[", "]" if $sk eq "[";
	return "$name->\{", "}";
}

# вспомогательный метод для вызова метода
sub _call_sk {
	my ($self, $name, $sk) = @_;
	return "$name()" if !defined $sk;
	return "$name(", ")" if $sk eq "(";
	$self->_sk("$name()", $sk);
}

# встретилась переменная
sub var {
	my ($self, $name, $sk) = @_;
	$self->_sk("\$DATA.$name", $sk)
}

# вызов метода по ссылке .$name
sub dotref {
	my ($self, $name, $sk) = @_;
	$self->_call_sk("\$DATA['$name']", $sk)
}

# вызов метода
sub dot {
	my ($self, $name, $sk) = @_;
	$self->_call_sk(".$name", $sk);
}

# по ключу хеша
sub colon {
	my ($self, $name, $sk) = @_;
	$self->_sk(".$name", $sk)
}

# разыменование класса
sub twocolon {
	my ($self, $name, $sk) = @_;
	$self->_call_sk(".prototype.$name", $sk)
}

# доступ к реальной переменной
sub dollar {
	my ($self, $name, $sk) = @_;
	$self->_sk($name, $sk)
}

# встретился ключ key =>
sub key {
	my ($self, $key) = @_;
	"<key>$key:</key>"
}

# встретилась долгая запятая =>
sub fat_comma {
	"<fat_comma>: </fat_comma>"
}

# встретилось ключевое слово
sub word {
	my ($self, $word) = @_;
	$word = lc $word;
	#$word eq "ucfirst"? "":
	#$word eq "lcfirst"? "":
	#$word eq "uc"? "":
	#$word eq "lc"? "":
	$word eq "ref"? "typeof":
	#$word eq "cmp"? "":
	#$word eq "push"? "":
	#$word eq "pop"? "":
	$word eq "undef"? "void(0)":
	$word eq "next"? "continue":
	$word eq "last"? "break":
	#$word eq "redo"? "":
	$word eq "return"? "return":
	#$word eq "pairs"? "":
	$word eq "or"? "||":
	$word eq "and"? "&&":
	$word eq "not"? "!":
	$word eq "eq"? " +''==''+ ":
	$word eq "ne"? " +''!=''+ ":
	$word eq "le"? " +''<=''+ ":
	$word eq "ge"? " +''>=''+ ":
	$word eq "lt"? " +''<''+ ":
	$word eq "gt"? " +''>''+ ":
	#$word eq "msg"? "":
	#$word eq "msg1"? "":
	#$word eq "exists"? "":
	#$word eq "use"? "":
	$word =~ /^(?:push|pop|splice|shift|unshift|keys|values|scalar)/? do { $self->top->{word} = $word; "" }:
	#$word eq "delete"? "":
	#$word eq "defined"? "":
	#$word eq "wantarray"? "":
	$self->view->error("ключевое слово $word в $self->{name} не используется")
}

# встретился указатель на себя
sub self {
	'this'
}

# встретилась специальная переменная app
sub appvar {
	'$app'
}

# встретилась специальная переменная q
sub q {
	'$app.q'
}

# встретилась специальная переменная user
sub user {
	'$app.q.user'
}

# встретился цикл while
sub while {
	return "<while>while(<cond>", "</cond>) {<code>", "</code>}</while>";
	#return "while(", ") {", "}"
}

# встретился цикл repeat
sub repeat {
	#"do {"
	"<repeat>do {<code>"
}

# встретился until
sub until {
	#return "} while(!(", "));";
	return "</code>} while(!(<until>", "</until>));</repeat>"
}

# встретился if
sub if {
	#return "if(", ") {", "}";
	return "<if>if(<cond>", "</cond>) {<then>", "</then>}</if>"
}

# встретился elseif
sub elseif {
	#return "} else if(", ") {";
	return "</then>} else if(<cond>", "</cond>) {<then>"
}

# встретился else
sub else {
	#return "} else {", "}";
	return "</then>} else {<else>", "</else>}</if>"
}

# встретился try
sub try {
	#"try {"
	"<try>try {<code>"
}

# встретился catch
sub catch {
	my ($self, $isa, $var, $is_end) = @_;
	$var //= "e";
	#$isa = defined($isa)? do { $isa =~ s/,/ /g; "Isa(\$@, qw/$isa/)"}: "defined \$@";
	#my $pre = $is_end? "}: ": "}; ";
	
	# my $end = "}";
	# if($isa) {
		# $end = "}";
		# $isa = "if(" . (join " || ", map { "$var instanceof $_" } split /\s*,\s*/, $isa) . ") {";
	# }
	
	#return "} catch($var) {", $isa, "</try>";
	return( ($is_end? "</catch>": "") . "<catch isa='$isa' var='$var'>", "</catch></try>" )
}

# открывающая скобка 
sub group {
	#return "(", ")";
	return "<group>(<code>", "</code>)</group>"
}

# открывающая скобка массива
sub array {
	#return "[", "]";
	return "<array>[<code>", "</code>]</array>"
}

# открывающая скобка хэша
sub hash {
	#return "{", "}";
	return "<hash>{<code>", "</code>}</hash>";
}

# конвеер
sub pairmapconv {
	"<conveer>_pairmap(this, \$DATA, function() { <code>"
}

# конвеер
sub map {
	"<conveer>_map(this, \$DATA, function() { <code>"
}

# конвеер
sub grep {
	"<conveer>_grep(this, \$DATA, function() { <code>"
}

# конвеер
sub reduceconv {
	"<conveer>_reduce(this, \$DATA, function() { <code>"
}

# конвеер
sub sort {
	"<conveer>_sort(this, \$DATA, function() { <code>"
}

# from после конвеера
sub from {
	#" }, ([", "]) )"
	return "</code> }, ([<from>", "</from>]) )</conveer>"
}

# блок begin
sub begin {
	#return "\$(function() {", "})";
	return "<begin>\$(function() { <code>", "</code>})</begin>"
}

# роутер on
sub route {
	my ($self, $route) = @_;
	
	$self->view->error("on $route - не используется в $self->{name}");
	
	# my $actionName = $route;
	
	# $route =~ s!^/?!/!;
	# $actionName =~ s!/([a-z])!ucfirst $1!ige;
	# $actionName =~ s!-!__!g;
	# $actionName = "on__$actionName";
	
	# my $path = $app->view->{file};
	
	# return "BEGIN { \$R::App::app->view->route_on('$route', \\&{'$actionName'}, '$path') } sub $actionName { my \$DATA={};", "}";
}

# addhandler в роутере on
sub addhandler {
	my ($self) = @_;
	$self->view->error("addhandler - не используется в $self->{name}");
	#"return if \$app->{q}->isErrors"
}

# массив параметров функции
sub paramarray {
	"<arguments>arguments</arguments>"
}

# супервызов блока
sub template_super {
	my ($self, $block, $sk) = @_;
	"\$DATA.SUPER.$block$sk"
}

# супервызов метода
sub super {
	my ($self, $method, $sk, $is_method) = @_;
	#($method eq "new"? '$self=': "") . 
	"this.SUPER.$method" . (!$is_method && !$sk? '.apply(this, arguments)': $sk)
}

# вызов функции
sub gosub {
	my ($self, $name) = @_;
	#return "$name(", ")";
	return "<gosub name='$name'>$name(<code>", "</code>)</gosub>"
}

# оператор присваивания
sub assign {
	"<assign>=</assign>"
}

# new Class
sub newstmt {
	my ($self, $name) = @_;
	"new $name"
}

# разыменивание ссылки на массив
sub unarray {
	my ($self) = @_;
	#return "]).concat(", ", [";
	return "<unarray>]).concat(<code>", "</code>, [</unarray>"
}

# разыменивание ссылки на хэш
sub unhash {
	my ($self) = @_;	
	#return "]).concat(_hash2array(", "), [";
	return "<unhash>]).concat(_hash2array(</code>", "</code>), [</unhash>"
}

# ничего
sub nothing {
	"null"
}

# константа true
sub true {
	"true"
}

# константа false
sub false {
	"false"
}

# выброс исключения
sub throw {
	"throw"
}

# числовая константа
sub number {
	my ($self, $num) = @_;
	$num =~ tr/_//;
	$num
}

# оператор
my %replace_op = qw/^ ** mod % xor ^ <=> -/;
my %op_logic = $app->perl->set(qw/== != <= >= < > + %/);
my %op_any = $app->perl->set(qw/ - * \/ << >>  += -= *= \/= ++ -- /);
my %op_replace = ( "." => " +''+ ", ".=" => " += ''+ ", "+=" => "+= + ");
sub operator {
	my ($self, $operator) = @_;
	
	$operator = $replace_op{$operator} // $operator;
	
	if(exists $op_logic{$operator}) { _esc " -0 $operator + " }
	elsif(exists $op_any{$operator}) { _esc $operator }
	elsif(exists $op_replace{$operator}) { _esc $op_replace{$operator} }
	elsif($operator eq "..") {
		"<optwodot>..</optwodot>"
	}
	else {
		die "неизвестный науке оператор `$operator`"
	}
	
}

# пробелы
sub space {
	my ($self, $space) = @_;
	$space;
}

# ,
sub comma {
	","
}

# блок do
sub do {
	my ($self, $prevop, $args, $endline) = @_;
	$args = _args($args);
	#$endline не выводим - если там then... а у perl нет конца комментария
	($prevop? "": ", ") . "<do>(function() {$args<code>", "</code>})</do>"
}

# самый обычный for =
sub for {
	my ($self, $k, $i) = @_;
	my $I = "I_$k";
	my $K = "\$DATA.$k";
	my $N = "N_$k";
	my $A = "A_$k";
	return "<for><code>var $A=<array>[<code>", "</code>]</array></code>; for(var $I=0, $N=$A.length; $I&lt;$N; $I++) { $K=${A}[$I]; " . ($i?"\$DATA.$i=$I; ":"") . "<infor>", "</infor>}</for>";
}

# for с разыменованием параметра
sub for_in {
	my ($self, $k, $i) = @_;
	my $I = "I_$k";
	my $K = "\$DATA.$k";
	my $N = "N_$k";
	my $A = "A_$k";
	return "<for><code>var $A=", "</code>; for(var $I=0, $N=$A.length; $I<$N; $I++) { $K=${A}[$I]; " . ($i?"\$DATA.$i=$I; ":"") . "<infor>", "</infor>}</for>";
}

# for по хэшу
sub for_of {
	my ($self, $k, $v, $i) = @_;
	$i = $i? "\$DATA.$i": undef;
	my $K = "K_$k";
	my $V = "V_$k";
	my $A = "A_$k";
	return "<for>".($i? "$i=0; ": "")."<code>var $A=", "</code>; for(var $K in $A) { if(_own.call($A, $K)) { \$DATA.$k=$K; ".($v? "var $V=${A}[$K]; ": "") . "<infor>",  "</infor>" . ($i? "; $i++; ": "")."}}</for>";
}

# формирует аргументы функции
sub _args {
	my ($args) = @_;
	local $_;
	my $i = -1;
	
	join "", map { $i++; $_ eq "*"? "\$.extends(\$DATA, arguments[$i]); ": "\$DATA.$_ = arguments[$i]; "} @$args;
}

# объявление функции
sub sub {
	my ($self, $name, $args, $class_in, $class, $endline) = @_;
	
	$args = _args($args);
	
	my $cls = _cls($class);
	$class_in = _class_name($class_in);
	
	return "<sub name='$name' class='$cls' in_class='$class_in'>"._esc($name eq "new" && !$class_in && $class? "function $cls": $class_in? "$class_in.prototype.$name = function": $class? "$cls.prototype.$name = function": "function $name") . _esc("() { var \$DATA = {}; $args$endline")."<code>", "</code>}</sub>";
}


# перегрузка оператора
sub overload {
	my ($self, $name, $args, $class_in, $class, $endline) = @_;
	
	$self->view->error("перегрузка операторов не реализована в $self->{name}");
}

# декларация модуля
sub module {
	my ($self, $name, $extends) = @_;
	my $cls = _cls($name);
	$extends = $self->_extends($cls, $extends);
	
	return "<module name='$name'>" . _esc("($name = (function() {$extends function $cls() {}") . "<code>", "</code>" . _esc("return $cls }).call(this))") . "</module>";
}

# декларация класса
sub class {
	my ($self, $name, $extends) = @_;
	
	my $cls = _cls($name);
	$extends = $self->_extends($cls, $extends);
	
	return "<class name='$name'>" . _esc("($name = (function() {$extends function $cls() {}") . "<code>", "</code>". _esc("return $cls }).call(this))") . "</class>";
}

# возвращает шаблон
sub template {
	my ($self, $class, $inherits, $begin) = @_;
	
	$class = _class_name($class);
	
	my $block = @$inherits? "__UNUSED__": "__RENDER__";
	
	$self->view->error("множественное наследование в $self->{name} не реализовано") if @$inherits>1;
	
	my $cls = _cls($class);
	my $extends = $self->_extends("window.$class", $inherits->[0]);
	
	return "<template>" . _esc("$class = (function(){ function $cls() {} $begin $extends $cls.prototype.$block=function(\$DATA) { ") . "<code>", "</code>" . _esc(" }; return $cls })();") . "</template>"
}

# блок
sub block {
	my ($self, $name) = @_;
	return "<block>this.prototype.$name = function(\$DATA) {<code>", "</code>} this.$name(\$DATA);</block>"
}

# возвращает имя класса
sub _class_name {
	my ($name) = @_;
	$name =~ s/::/\$/g;
	$name
}

# превращает в нормальное имя
sub _cls {
	my ($cls) = @_;
	($cls) = $cls =~ m!(\w+)$!;
	$cls
}

# добавляет функцию для расширения
sub _extends {
	my ($self, $child, $parent) = @_;
	return "" if !$parent;
	"_extend($child, $parent); ";
}

# функция для вставки в модуль
sub modulesub {
	my ($self, $module, $sub, $cls) = @_;
	" ${module}.$sub = function() { return '$cls' }"
}

# добавляет new и аргументы
sub object {
	my ($self, $with_args, $begin, $end) = @_;
	#$end = join "", $end, "->new(", $with_args , ")";
	return "new $begin($with_args)", $end;
}


# вставка кода в темплейт
sub v_in {
	return "');", "\$app_OUTPUT.push('";
}

# вставка выражения в темплейт
sub v_raw {
	"', <get>", "</get>, '"
}

# вставка выражения с экранированием
sub v_escape {
	return "', _esc(<get>", "</get>), '";
}

# запоминание позиции кода
my $SETPOS = 0;
sub v_setpos {
	join "", 'var $SETPOS', ++$SETPOS, '=\$app_OUTPUT.length;';
}

# возвращение позиции кода
sub v_getpos {
	"\$app_OUTPUT.splice($SETPOS)"
	
}


# сценарий
sub scenario {
	my ($self, $name, $masking) = @_;
	return "\$app.scenario.$name = function() { var \$DATA = {}; $masking;
}

1;"
}

# блок вывода джаваскрипта в app.js - на самом деле - вставка js
sub js {
	todo;
	return v_setpos(), join "", "\$R::App::app->js->append( ", v_getpos(), " );"
}

# блок filter
sub filter {
	my ($self, $var) = @_;
	todo;
	return v_setpos(), join "", "push \@\$R::View::Views::OUTPUT, R::View::Filter->", $var, "(join '', ", v_getpos(), ")"
}

# часть шаблона в переменную
sub set {
	my ($self, $var) = @_;
	return v_setpos(), join "", "\$DATA.", $var, " = new \$app.html(", v_getpos(), ");";
}

# включение блока или шаблона
sub include {
	my ($self, $name, $masking, $block) = @_;
	$name = _class_name($name);
	
	$block //= "__RENDER__";
	"var data=\$DATA; \$DATA={}; $masking new $name().$block(\$DATA); \$DATA=data "
}

# включение блока или шаблона без сохранения переменных
sub process {
	my ($self, $name, $masking, $block) = @_;
	
	$name = _class_name($name);
	
	$block //= "__RENDER__";
	"$masking new $name().$block(\$DATA); "
}

# инициализатор экшена
sub init {
	my ($self, $masking) = @_;
	" sub init { my \$DATA=shift; $masking; return} \$DATA->init;"
}

# экшн
sub action {
	my ($self, $key, $route, $view, $masking) = @_;
	todo;
	"BEGIN { \$R::App::app->view->action('$key', '$route', '$view') } $masking"
}

# блок функции в темплейте
sub subinblock {
	return " my \$IDX = \@\$R::View::Views::OUTPUT;", "return bless [splice \@\$R::View::Views::OUTPUT, \$IDX], 'R::Html' ";
}


# добавляет return, если его нет в метод или функцию
sub _addreturn {
	my ($self, $code, $who) = @_;

	return if !@$code;

	my($i, $k);
	# идём по коду, пока ; или пробелы или комментарии
	for($i=@$code-1; $i>=0; $i--) {
		last if ref $code->[$i];
		last if $code->[$i] !~ m!^(?:;|\s*|//.*)$!;
	}

	$i = 0 if $i<0;
	
	# на начало выражения
	for(; $i>=0; $i--) {
		last if $i-1>=0 && !ref($code->[$i-1]) && $code->[$i-1] eq ";";
	}
	
	$i = 0 if $i<0;
	
	# пропускаем пробелы
	for(; $i<@$code; $i++) {
		last if $code->[$i] !~ m!^(?:\s*|//.*)$!;
	}

	$i = 0 if $i<0;
	
	return if !ref($code->[$i]) && $code->[$i] =~ /^(?:return|break|continue)$/;
	splice @$code, $i, 0, $who // " return "; # вставляем
	return;
}

# вставляет who перед экспрешином
sub _beforeexp {
	my ($self, $code, $i) = @_;

	# на начало выражения
	for(; $i>=0; $i--) {
		last if $i-1>=0 && !ref($code->[$i-1]) && $code->[$i-1] eq ";";
	}
	
	$i = 0 if $i<0;

	splice @$code, $i, 0, @_[3..$#_];

	$_[2] += @_ - 3;	# меняем $i

	$self
}

# возвращает следующий индекс, пропуская пробелы
sub _next_i {
	my ($code, $i) = @_;
	for(; $i<@$code; $i++) {
		last if ref($code->[$i]) || $code->[$i] !~ /^\s*$/;
	}
	$i
}

# возвращает след. элемент и переставляет $i
sub _next {
	my ($code, $i) = @_;
	$code->[ $_[2] = _next_i($code, $i) ]
}

# возвращает индекс ; или конец code
sub _next_exp {
	my ($code, $i) = @_;
	my $j;
	while(_next($code, $i, $j) ne ";" && $j!=$i) { $i = $j }
	$i
}

# проверяет что в параметрах функции или метода есть аррай-параметры
sub _isarrayparam {
	my ($line) = @_;
	return if $line->{check_isarrayparam};
	$line->{check_isarrayparam} = 1;
	my $code = $line->{code};
	my($flag, $idx);
	for(my $i=0; $i<@$code; $i++) {
		my $k = $code->[$i];
		$flag = 1, last if ref $k and $k->{stmt} =~ /^(?:unarray|unhash)$/;
		$idx = $i if $k eq ",";
	}
	
	$code->[$idx] = "" if $flag && defined $idx;
	$flag
}

# вызывается в masking для второго прохода по свормированному коду в этом языке
# должен модифицировать $_[1]
sub expirience {
	my ($self, $TOP) = @_;
	
	msg1 $TOP;
	
	my $q = $app->htmlquery->new($TOP);
	
	# расширим exp-ы
	$q->find("exp")->each(sub {
		$_->prevUntil("exp")->prependTo($_);
	});
	
	# если после экспов остались элементы, то обернём их в экспы
	$q->find("exp")->each(sub {
		my $exp = $_->nextUntil("exp");
		if(!@$exp) {}
		elsif( $exp->eq(-1)->is_space ) {  $_->append($exp)  }
		else {  $_->after($q->new("<exp></exp>")->contents($exp));  }
	});
	
	#msg1 "after exp:", $q->as_html;
	
	my $addret = sub {
		my $ch = $_->children(-1);
		$ch = $_ if !$ch->is("exp");
		return if $ch->children(0)->is_text && $ch->children(0)->text =~ /\b(?:return|break|continue)\b/;
		$ch->prepend(@_);
	};
	
	# проставим sub-ам return
	$q->find("sub > code")->each(sub {
		$addret->("~ return ");
	});
	
	
	
	my $var;
	my $addvar = sub {
		$addret->("~ $var", "<assign>=</assign>");
	};
	
	# if, которые находятся в выражениях должны быть вынесены
	$q->find("if")->each(sub {
	
		# если if не одно
		if( $_->parent->children->grep(sub { !$_->is_space })->size>1 ) {
			# формируем переменную
			$var = "_ref" . $self->{replace}++;
			# в начало if вставили объявление переменной
			$_->prepend("~ var $var; ");
			# в последний exp then и else добавляем _ref =
			$_->children("then, else")->each($addvar);
			
			# сохраняем парент if
			my $parent = $_->parent;
			
			# заменяем if на переменную
			$_->replace("~$var");
			
			# переносим if до exp
			$parent->before($_);
		}
	});
	
	# выносим get
	$q->find("get, raw")->each(sub {
		$var = "_ref" . $self->{replace}++;
		$addvar->();
		my $parent = $_->parent;
		$_->replace("~$var");					# заменяем на переменную
		$_->prepend("~var $var; ")->append("~; ")->prependTo($parent);
	});
	
	$q->find("gosub")->each(sub {
		return if $_->name !~ /^(?:push|pop|splice|shift|unshift)$/;
		return unless my $unarray = $_->children("unarray:first-child");
		$unarray->children(0)->replace("~(");
		$unarray->children(-1)->replace("~)");
		
		# переставляем перед gosub
		$var = "_ref" . $self->{replace}++;
		
		my $ch = $unarray->children("code")->children;
		$ch->replace("~(typeof($var=", $ch, "~)=='undefined'? ($var=", $ch, "~=[]): $var)");
		
		
		
		# splice @$code, $i, 0, "(typeof($var=", $lcode->[$j], ")=='undefined'? ($var=", $lcode->[$j],"=[]): $var)";
		# $lcode->[$j] = "";
		# # удаляем пробелы и ,
		# $lcode->[$j] = "" if _next($lcode, $j, $j) eq ",";
		
		# # превращаем gosub в метод
		# %$line = (%$line, stmt => "method", begin => ".$line->{begin}", type => ".");
		#next;
		
	});
	
	#msg1 $q->as_html;
	
	return $self->vitaland . $q->text;
	
	
	#msg1 ":size10000", $TOP;
	my @path = ($TOP, 0);
	

	
	# обход в глубину. Первый проход
	while(@path) {
		my $i = pop @path;
		my $leaf = pop @path;
		my $code = $leaf->{code} //= [];

		while($i<@$code) {
			my $line = $code->[$i];
			
			if(ref $line) {
				my $stmt = $line->{stmt};

				if($stmt eq "sub") {
					# добавляем return на последний статемент
					$self->_addreturn($line->{code});

					if(my $class_name = $line->{class_name}) {
						# переносим sub в начало класса
						my $class;
						for(my $j = $#path; $j>=0; $i-=2) {
							$class = $path[$i-1], last if $path[$i-1]->{stmt} =~ /^(?:class|module|template)$/;
						}
						splice @{$class->{code}}, $class->{_subplace}++, 0, $line;
						# оставляем ссылку на неё
						$code->[$i] = $line->{name};						
					}
				}
				elsif($stmt eq "if") {
					# проставляем на последние выражения _refN=
					my $var = "_ref" . ($self->{replace}++);
					my $j;
					for($j=$i+1; $j<@$code && ref($code->[$j]) && $code->[$j]{stmt} =~ /^(?:elseif|then|else)$/; $j++) {
						$self->_addreturn($code->[$j]{code}, "$var = ") if $code->[$j]{stmt} =~ /^(?:then|else)$/;
					}
					
					push @path, map { ($code->[$_], 0) } $i .. $j;
					
					# переставляем if перед выражением
					$self->_beforeexp($code, $i, "var $var; ", splice @$code, $i, $j-$i, $var );
					
					$i++;
					next;
				}
				elsif($stmt =~ /^(?:get|raw)$/) {
					# переносим на начало выражения
					my $var = "_mas" . ($self->{replace}++);
					$code->[$i] = $var;
					$self->_addreturn($line->{code}, "$var = ");
					$self->_beforeexp($code, $i, "var $var; ", $line, ";");
				}
				elsif($stmt eq "gosub" && $line->{name} =~ /^(?:push|pop|splice|shift|unshift)$/) {
				
					my $lcode = $line->{code};
					# пропускаем пробелы
					my $j = _next_i($lcode, 0);
				
					$self->{view}->error("первым аргументом $line->{name} должен быть массив") unless ref($lcode->[$j]) && $lcode->[$j]{stmt} eq "unarray";
				
					$lcode->[$j]{begin} = "(";
					$lcode->[$j]{end} = ")";
					
					# переставляем перед gosub
					my $var = "_ref" . $self->{replace}++;
					splice @$code, $i, 0, "(typeof($var=", $lcode->[$j], ")=='undefined'? ($var=", $lcode->[$j],"=[]): $var)";
					$lcode->[$j] = "";
					# удаляем пробелы и ,
					$lcode->[$j] = "" if _next($lcode, $j, $j) eq ",";
					
					# превращаем gosub в метод
					%$line = (%$line, stmt => "method", begin => ".$line->{begin}", type => ".");
					next;
				}
				elsif($stmt =~ /^(?:unarray|unhash)$/ && _next($code, $i+1, my $j) eq "=") {
				
					# переправим line
					$line->{stmt} = "assign-$stmt";
					$line->{begin} = "(";
					$line->{end} = ")";
					
					my $ishash = $stmt eq "unhash";
					
					my $var = "_ref" . $self->{replace}++;
					
					msg1 "1) ", map {ref($_)? $_->{stmt}: $_} @$code;
					
					splice @$code, $i, $j, "(typeof($var=", $line, ")=='undefined'? ($var=", $line, "=".($ishash? "{}": "[]")."): $var)";
					
					msg1 "2) ", map {ref($_)? $_->{stmt}: $_} @$code;
					
					# превращаем присваивание в метод splice
					my $sk = _next($code, $i+5, my $k);
					#msg1 $sk, map {ref($_)? $_->{stmt}: $_} @$code[$i..$#$code];
					if(ref($sk) && $sk->{stmt} eq "(...)") {
						my $name = $ishash? "_assign": "splice";
						%$sk = (%$sk, stmt => "method", name=>$name, begin => ".$name(", type => ".");
						unshift @{$sk->{code}}, 0, ",", "$var.length", (@{$sk->{code}}? ",": ()) if !$ishash;
					} else {
						#my $e = _next_exp($code, $k);
						$self->{view}->error("используйте ".($ishash? "%": "\@")."x = (...)");
					}
				
					next;	# пройдёмся по коду
				}
				elsif($stmt eq "gosub" && $line->{name} =~ /^(?:keys|values)$/) {
				
					my $lcode = $line->{code};
					# пропускаем пробелы
					my $j = _next_i($lcode, 0);
				
					$self->{view}->error("первым аргументом $line->{name} должен быть хэш") unless ref($lcode->[$j]) && $lcode->[$j]{stmt} eq "unhash";
				
					$lcode->[$j]{begin} = "(";
					$lcode->[$j]{end} = ")";
					
					# переставляем перед gosub
					my $var = "_ref" . $self->{replace}++;
					splice @$lcode, $j, 1, "(typeof($var=", $lcode->[$j], ")=='undefined'? ($var=", $lcode->[$j],"={}): $var)";
				}
				
				
				if($stmt eq "gosub" && _isarrayparam($line)) {
					$line->{begin} = "$line->{name}.apply(this, ([";
					$line->{end} = "]))";
				}
				elsif($stmt eq "method" && _isarrayparam($line)) {
					$line->{begin} = "._apply('$line->{name}', ([";
					$line->{end} = "]))";
				}

				push @path, $leaf, $i+1;
				$leaf = $line;
				$code = $line->{code};
				$i = 0;
			}
			# elsif($line eq "") {
				# splice @$code, $i, 0;
			# }
			else {
				$i++;
			}
		}
	}
	
	$TOP->{begin} = $self->vitaland . $TOP->{begin};
}

# преобразует для печати
sub _je_perl {
	map {
		my $v = $_;
		$v = $v->get if ref $v eq "JE::LValue";
		if(ref($v) =~ /^JE::Object::(?:Array|Function::Arguments)$/) { [ _je_perl(@{$v->value}) ]
		} elsif(ref $v eq "JE::Object") { +{ _je_perl(%{$v->value}) }
		} elsif(ref $v eq "JE::String") { $v =~ s/"/\"/g; "\"$v\""
		} else { "$v" }
	} @_
}

# печатает je
sub _je_msg {
	my $self = shift;
	$app->log->info( ":on_cyan black", "console.log", ":reset", _je_perl(@_) );
	return;
}

# возвращает интерпретатор js
sub je {
	my ($self) = @_;
	
	return $self->{JE} if exists $self->{JE};
	require JE;
		
	my $je = $self->{JE} = JE->new;
	$je->eval("console={}")->new_method("log" => \&_je_msg);
	$je
}

# рендерит
sub render {
	my ($self, $name, $data, $output) = @_;
	
	$name = $self->{view}->get_name($name);
	$name = _class_name($name);
	
	my $j = $self->je;

	$j->{"DATA"} = $data // {};
	my $eval = "\$app_OUTPUT=[]; new $name().__RENDER__(DATA); \$app_OUTPUT.join('')";
	msg1 $eval;
	my $val = $j->eval($eval);
	msg("error in: $eval"), die $@ if $@;
	@$output = "$val";
	
	$self
}

# вычисляет выражение на javascript
sub eval {
	my ($self, $eval, $data) = @_;
	
	my $j = $self->je;
	my $e;
	
msg1 ":empty", "\n\n", $eval, "\n";
	
	eval {
		$j->{"DATA"} = $data // {};
		$j->eval( $eval );
		$e = $@;
	};
	$@ //= $e;
}

# очищает классы
sub clear_classes {
	my ($self) = @_;
	$self
}

# позиция в классах
sub len_classes {
	0
}

# инициализирует классы от указанного
sub init_classes {
	my ($self, $from) = @_;
	$self
}



1;