package R::Syntax::Morf::Perl;
# драйвер для перевода языка Argentum в язык perl

use common::sense;
use R::App;

# не имеет конструктора - не может использоваться как тип

my $in = "'; "; my $_in = "; push \@{\$R::App::app->{q}{echo}}, '";
my $raw = "', (scalar do { "; my $_raw = " }), '";
my $esc = "', R::View::Views::escapeHTML(scalar do { "; my $_esc = " }), '";

### шаблоны
our @templates = (

'fx msg' => 'msg({{ right }})',
'fx msg1' => 'msg1({{ right }})',


# разыменования
'yf :word' => '{{ left }}->{{{ var }}}',

'yf .word' => '{{ left }}->{{ var }}',
'yf .$word' => '{{ left }}->${$DATA->{{{ var }}}}',
'yf .?word' => '(do { my $q = {{ left }}; $q->can("{{ var }}")? $q->{{ var }}: () })',
'yf .?$word' => '(do { my $q = {{ left }}; $q->can($DATA->{{{ var }}})? $q->{{ var }}: () })',

'yS .word(' => '{{ left }}->{{ var }}({{ right }})',
'yS .$word(' => '{{ left }}->${$DATA->{{{ var }}}}({{ right }})',
'yS ?.word(' => '(do { my $q = {{ left }}; $q->can("{{ var }}")? $q->{{ var }}( {{ right }} ): () })',
'yS ?.$word(' => '(do { my $q = {{ left }}; $q->can($DATA->{{{ var }}})? $q->{{ var }}( {{ right }} ): () })',

'xfy .word+' => '{{ left }}->{{ var }}({{ right }})',
'xfy .$word+' => '{{ left }}->${$DATA->{{{ var }}}}({{ right }})',
'xfy ?.word+' => '(do { my $q = {{ left }}; $q->can("{{ var }}")? $q->{{ var }}( {{ right }} ): () })',
'xfy ?.$word+' => '(do { my $q = {{ left }}; $q->can($DATA->{{{ var }}})? $q->{{ var }}( {{ right }} ): () })',

'fx gosub+' => '{{ right }}',

'yF [' => '{{ left }}->[ {{ right }} ]',
'yF {' => '{{ left }}->{ {{ right }} }',

# операторы распределения данных
'xfy \n' => "{{ left }};{{ _rem rem }}\n{{ right }}",
'fy \n' => "{{ _rem rem }}\n{{ right }}",
'yf \n' => "{{ left }}{{ _rem rem }}\n",
'\n' => "{{ _rem rem }}\n",

"xfy ;" => '{{ left }}; {{ right }}',
#'fy ;' => "{{ right }}",
#'yf ;' => "{{ left }}; ",

'xfy :' => "{{ left }}; {{ right }}",

"xfy ," => '({{ left }}), ({{ right }})',
"yf ," => '{{ left }}',
"xfy =>" => '{{ left }} => {{ right }}',
"fy word=>" => '{{ id }} => {{ right }}',

# операторы присваивания
"yfx =" => '({{ left }}) = ({{ right }})',
"yfx is" => '({{ left }}) = ({{ right }})',
"yfx ->" => '({{ right }}) = ({{ left }})',
"yfx as" => '({{ right }}) = ({{ left }})',

# арифметические операторы
"yf ++" => '({{ left }})++',
"yf --" => '({{ left }})--',
"fy ++" => '++({{ right }})',
"fy --" => '--({{ right }})',


"xfy +" => '({{ left }}) + ({{ right }})',
"xfy -" => '({{ left }}) - ({{ right }})',
"xfy *" => '({{ left }}) * ({{ right }})',
"xfy /" => '({{ left }}) / ({{ right }})',
"xfy div" => 'int(({{ left }}) / ({{ right }}))',
"xfy mod" => '({{ left }}) % ({{ right }})',
"yfx ^" => '({{ left }}) ** ({{ right }})',

"fy +" => '0+({{ right }})',
"fy -" => '-({{ right }})',


"yfx +=" => '({{ left }}) += ({{ right }})',
"yfx -=" => '({{ left }}) -= ({{ right }})',
"yfx *=" => '({{ left }}) *= ({{ right }})',
"yfx /=" => '({{ left }}) /= ({{ right }})',
"yfx ^=" => '({{ left }}) **= ({{ right }})',
"yfx div=" => '({{ left }}) = int(({{ left }}) / ({{ right }}))',
"yfx mod=" => '({{ left }}) %= ({{ right }})',

#

# строковые
"xfy **" => 'scalar({{ left }}) x scalar({{ right }})',
"yfx **=" => '{{ left }} x= scalar({{ right }})',
"xfy ." => '({{ left }}) . ({{ right }})',
"yfx .=" => '({{ left }}) .= ({{ right }})',
"yf len" => 'length({{ left }})',
"fy len" => 'length({{ right }})',
"fy lc" => 'lc({{ right }})',
"fy uc" => 'uc({{ right }})',
"fy lcfirst" => 'lcfirst({{ right }})',
"fy ucfirst" => 'ucfirst({{ right }})',
"fy chr" => 'chr({{ right }})',
"fy ord" => 'ord({{ right }})',
"xfy %" => 'sprintf({{ left }}, {{ right }})',
"yfx %=" => '({{ left }}) = sprintf({{ left }}, {{ right }})',

# логические
"xfy and" => '(({{ left }}) and ({{ right }}))',
"xfy or" => '(({{ left }}) or ({{ right }}))',
"xfy xor" => '(({{ left }}) xor ({{ right }}))',
"fy not" => '(not ({{ right }}))',

"xfy &&" => '(({{ left }}) && ({{ right }}))',
"xfy ||" => '(({{ left }}) || ({{ right }}))',
"xfy ^^" => '(scalar({{ left }}) xor scalar({{ right }}))',
"fy !" => '(! ({{ right }}))',

'yfx ||=' => '({{ left }}) ||= ({{ right }})',
'yfx &&=' => '({{ left }}) &&= ({{ right }})',
'yfx ^^=' => '({{ left }}) = ({{ left }}) xor ({{ right }})',

'yfx or=' => '({{ left }}) ||= ({{ right }})',
'yfx and=' => '({{ left }}) &&= ({{ right }})',
'yfx xor=' => '({{ left }}) = ({{ left }}) xor ({{ right }})',


# побитовые
"xfy +&" => '({{ left }}) & ({{ right }})',
"xfy +|" => '({{ left }}) | ({{ right }})',
"xfy +^" => '({{ left }}) ^ ({{ right }})',
"fy  +~" => '(~ ({{ right }}))',
"xfy +<" => '({{ left }}) << ({{ right }})',
"xfy +>" => '({{ left }}) >> ({{ right }})',

"yfx +&=" => '({{ left }}) &= ({{ right }})',
"yfx +|=" => '({{ left }}) |= ({{ right }})',
"yfx +^=" => '({{ left }}) ^= ({{ right }})',
"yfx +<=" => '({{ left }}) <<= ({{ right }})',
"yfx +>=" => '({{ left }}) >>= ({{ right }})',


# сравнения
"xfx lt" => '({{ left }}) lt ({{ right }})',
"xfx gt" => '({{ left }}) gt ({{ right }})',
"xfx le" => '({{ left }}) le ({{ right }})',
"xfx ge" => '({{ left }}) ge ({{ right }})',
"xfx ne" => '({{ left }}) ne ({{ right }})',
"xfx eq" => '({{ left }}) eq ({{ right }})',
"xfx <" => '({{ left }}) < ({{ right }})',
"xfx >" => '({{ left }}) > ({{ right }})',
"xfx <=" => '({{ left }}) <= ({{ right }})',
"xfx >=" => '({{ left }}) >= ({{ right }})',
"xfx !=" => '({{ left }}) != ({{ right }})',
"xfx ==" => '({{ left }}) == ({{ right }})',
"xfx <=>" => '({{ left }}) <=> ({{ right }})',
"xfx cmp" => '({{ left }}) cmp ({{ right }})',
"xfy ~r~" => 'do { my $s; ($s = ({{ left }})) =~ ({{ right }})? do { $DATA->{{{ id }}} = bless({ "~"=>$s, "^"=>[@-], "\$"=>[@+], %+ }, "MatchData"); 1 }: ""}',
"xfy !~r~" => 'do { my $s; ($s = ({{ left }})) =~ ({{ right }})? do { $DATA->{{{ id }}} = bless({ "~"=>$s, "^"=>[@-], "\$"=>[@+], %+ }, "MatchData"); "" }: 1}',
"xfy ~" => '({{ left }}) =~ ({{ right }})',
"xfy !~" => '({{ left }}) !~ ({{ right }})',

# замены
"xfy sreplace" => 'do { my $s = ({{ left }}); $s =~ {{ right }}{{ arg }}; $s }',
"yfx =sreplace" => 'do { my ($s, $f); $f=\({{ left }}); $s=$$f; $$f =~ {{ right }}{{ arg }} }',
F_sreplace => sub { my($s, $p, $path)=@_; $p->{id} = $path->[-1]{id} },
	's{{{ left }}}{ $DATA->{{{ id }}} = bless({ "~"=>$s, "^"=>[@-], "\$"=>[@+], %+ }, "MatchData"); do { {{ right }} } }',

"xfy kreplace" => 'do { my $s = ({{ left }}); $s =~ {{ right }}{{ arg }}; $s }',
"yfx =kreplace" => 'do { my ($s, $f); $f=\({{ left }}); $s=$$f; $$f =~ {{ right }}{{ arg }} }',
F_kreplace => sub { my($s, $p, $path)=@_; $p->{id} = $path->[-1]{id} },
	's{${\($R::App::app->perl->likes( \'{{ left }}\', \'P\' ))}}{ $DATA->{{{ id }}} = bless({ "~"=>$s, "^"=>[@-], "\$"=>[@+], %+ }, "MatchData"); do { {{ right }} } }',


# проверки
"xf ?" => 'defined({{ left }})',
"xfy ?" => 'defined({{ left }})? ({{ left }}): ({{ right }})',
"yfx ?=" => '({{ left }}) //= ({{ right }})',
"xfx isa" => 'Isa({{ left }}, {{ right }})',
"xfx can" => '(Can({{ left }}, {{ right }})? 1: "")',
"fy Num" => 'Num({{ right }})',
"xfx flipflop" => 'scalar(({{ left }}) .. ({{ right }}))',


# интервальные
"fx ^" => '0 .. ({{ right }})-1',
"xfx .." => '({{ left }}) .. ({{ right }})',
"xfx ..." => '({{ left }}) .. ({{ right }})-1',
"xfx ^.." => '({{ left }})+1 .. ({{ right }})',
"xfx ^..." => '({{ left }})+1 .. ({{ right }})-1',

# генерации
"fx gen" => 'do { my @A=(); while(my @x = do { {{ right }} }) { push @A, @x } @A }',
"xfx gen" => 'do { my @A=(); while(do { {{ left }} }) { push @A, do { {{ right }} } } @A }',

# массивов
'fx @' => '@{{{ right }}}',
'fx %' => '%{{{ right }}}',
'yfx ,=' => 'push({{ left }}, {{ right }})',
'yfx =,' => 'unshift({{ left }}, {{ right }})',
'fx pop' => 'pop(@{{{ right }}})',
'fx shift' => 'shift(@{{{ right }}})',
'xf pop' => 'pop(@{{{ left }}})',
'xf shift' => 'shift(@{{{ left }}})',
'xfx splice' => 'splice(@{{{ left }}}, {{ right }})',
'xF @[' => '@{ {{ left }} }[ {{ right }} ]',
'xF @{' => '@{ {{ left }} }{ {{ right }} }',

'xfy zip' => '$R::App::app->perl->zip([{{ left }}], {{ arity }}, [{{ right }}])',
'fy zip' => '$R::App::app->perl->zip({{ arity }}, [{{ right }}])',
'zip' => '{{ left }}], {{ arity }}, [{{ right }}',

"xfy ***" => '({{ left }}) x scalar({{ right }})',
"yfx ***=" => '{{ left }} = ({{ left }}) x scalar({{ right }})',

"xfy splice" => 'splice(@{{{ left }}}, {{ right }})',
"yfx join" => 'join({{ right }}, {{ left }})',
"xfy split" => 'split({{ right }}, {{ left }})',
"yf join" => 'join("", {{ left }})',
"xf split" => 'split(/\s+/, {{ left }})',
"xfx split" => '{{ _split * }}split(do { my ({{i}})=({{ right }}); ref({{i}})? {{i}}: quotemeta({{i}}) }, {{ left }})',
"yf reverse" => 'reverse( {{ left }} )',

#"xfy in" => '(grep { {{ left }} }, {{ right }})',

# хешей
"xfx delete" => 'delete(@{ {{left}} }{ {{ right }} })',
"xfx of" => 'exists( {{ right }}->{{{ left }}} )',
"yf keys" => 'keys( {{ left }} )',
"yf values" => 'values( {{ left }} )',


# конвеер
# TODO: рефакторинг для конвеера и for - отказаться от ref-переменных. И |=
map => '{{ _init_conveer * }}do { my {{A}} = [do { {{ left }} }]; my {{R}} = []; for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; push @{{R}}, do { {{ right }} } } @{{R}} }',
grep => '{{ _init_conveer * }}do { my {{A}} = [do { {{ left }} }]; my {{R}} = []; for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; push @{{R}}, map { {{A}}->[$_] } {{i}}..({{i}}+{{arity0}}>$#{{A}}? $#{{A}}: {{i}}+{{arity0}}) if do { {{ right }} } } @{{R}} }',
first => '{{ _init_conveer * }}do { my {{A}} = [do { {{ left }} }]; my {{R}} = []; for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; push(@{{R}}, map { {{A}}->[$_] } {{i}}..({{i}}+{{arity0}}>$#{{A}}? $#{{A}}: {{i}}+{{arity0}})), last if do { {{ right }} } } @{{R}} }',
any => '{{ _init_conveer * }}do { my {{A}} = [do { {{ left }} }]; my {{R}} = ""; for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; {{R}} = 1, last if do { {{ right }} } } {{R}} }',
all => '{{ _init_conveer * }}do { my {{A}} = [do { {{ left }} }]; my {{R}} = 1; for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; {{R}} = "", last if !do { {{ right }} } } {{R}} }',
sort => 'do { my @list = do { {{ left }} }; my $fn = sub { @$DATA{qw/{{ qwparam }}/} = @_; {{ right }} }; map { @list[$_..$_+{{ arity0 }}] } sort { my ($i,$j)=($a,$b); $fn->(@list[$i..$i+{{ arity0 }}]) cmp $fn->(@list[$j..$j+{{ arity0 }}]) } map { $_*{{ arity }} } 0 .. int(@list / {{ arity }}) - (@list % {{ arity }}? 0: 1) }',
order => 'do { my @list = do { {{ left }} }; my $fn = sub { @$DATA{qw/{{ qwparam }}/} = @_; {{ right }} }; map { @list[$_..$_+{{ arity0 }}] } sort { my ($i,$j)=($a,$b); $fn->(@list[$i..$i+{{ arity0 }}]) <=> $fn->(@list[$j..$j+{{ arity0 }}]) } map { $_*{{ arity }} } 0 .. int(@list / {{ arity }}) - (@list % {{ arity }}? 0: 1) }',
assort => '{{ _assort_init * }}do { my @list = do { {{ left }} }; map { @list[$_..$_+{{ arity0 }}] } sort { @$DATA{qw/{{ qwparam1 }}/} = @list[$a..$a+{{ arity0 }}]; @$DATA{qw/{{ qwparam2 }}/} = @list[$b..$b+{{ arity0 }}]; {{ right }} } map { $_*{{ arity }} } 0 .. int(@list / {{ arity }}) - (@list % {{ arity }}? 0: 1) }',
reduce => '{{ _init_conveer * }}do { my {{A}} = [do { {{ left }} }]; my {{R}} = {{A}}->[0]; for(my {{i}}=1; {{i}}<@{{A}}; {{i}}+={{ arity0 }}) { @$DATA{qw/{{ qwparam }}/} = ({{R}}, map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}-1); {{R}} = do { {{ right }} } } {{R}} }',
group => '{{ _group_init * }}do { my {{A}} = [do { {{ left }} }]; my {{R}} = []; my {{M}} = {}; for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; my {{E}} = {{M}}->{do { {{ right }} }} //= do { my $x = []; push @{{R}}, $x; $x }; push @{{E}}, map { {{A}}->[$_] } {{i}}..({{i}}+{{arity0}}>$#{{A}}? $#{{A}}: {{i}}+{{arity0}}) } @{{R}} }',

groupby => 'do { my @A = do { {{ left }} }; my @R = (); my %M = (); for(my $i=0; $i<@A; $i+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { $A[$_] } $i..$i+{{arity0}}; my $K = do { {{ right }} }; my $E = $M{$K} //= do { my $x = []; push @R, $K, $x; $x }; push @$E, map { $A[$_] } $i..($i+{{arity0}}>$#A? $#A: $i+{{arity0}}) } @R }',
compress => 'do { my @A = do { {{ left }} }; my @R; my $E; my $M; for(my $i=0; $i<@A; $i+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { $A[$_] } $i..$i+{{arity0}}; my $K = do { {{ right }} }; if($i==0) { $M=$K; push @R, $E=[] } else { push(@R, $E=[]), $M=$K if $M ne $K; } push @$E, map { $A[$_] } $i..($i+{{arity0}}>$#A? $#A: $i+{{arity0}}) } @R }',
compressby => 'do { my @A = do { {{ left }} }; my @R; my $E; my $M; for(my $i=0; $i<@A; $i+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { $A[$_] } $i..$i+{{arity0}}; my $K = do { {{ right }} }; if($i==0) { $M=$K; push @R, $K, $E=[] } else { push(@R, $K, $E=[]), $M=$K if $M ne $K; } push @$E, map { $A[$_] } $i..($i+{{arity0}}>$#A? $#A: $i+{{arity0}}) } @R }',


join => 'join({{ _for_join *, right }}, {{ left }}){{ newline }}',


# исключения
'fx raise' => 'die( {{ right }} )',
'xfy rescue' => '(sub { my @ev = eval { {{ left }} }; if($@) { $DATA->{{{id}}} = $@; {{ right }} } else { wantarray? @ev: $ev[0] } })->()',
'rescue isa' => '(sub { my @ev = eval { {{ left }} }; if($@ && Isa( $@, qw/qwISA/ )) { $DATA->{{{id}}} = $@; {{ right }} } else { wantarray? @ev: $ev[0] } })->()',


# скобки

# - массивы
'(' => '( {{ right }} )',
'[' => '[ {{ right }} ]',
'{' => '+{ {{ right }} }',
'^{' => '$R::App::app->perl->starsetref( {{ right }} )',



# - смысловые конструкции

'fx decorator' => '{{ _decorate * }}',

SCENARIO => '{{ _scenario right, lineno }}',

CLASS => '(do { package {{ _class_id class }}; use common::sense; use R::App;{{ _extends class, extends, lineno, file }} sub void { my $DATA = { me => shift }; {{ right }} } __PACKAGE__ })',

SUB => sub { my ($self, $push) = @_;
		# вернуть self, если это конструктор
		$push->{RET} = $push->{SUB} eq "new"? '; $DATA->{me}': '';
		# если имя функции == new
		$push->{SHIFT} = $push->{SUB} eq "new"? 'bless({}, do { my $cls=shift; ref $cls || $cls })': 'shift';
	},
	'sub {{ _sub_id SUB, class }} { my $DATA = { me => {{ SHIFT }} }; {{ _args args }} {{ right }}{{ RET }} }',
BLOCK => 'do { sub {{ _sub_id SUB, class }} { my $DATA = shift; {{ _args args }} {{ right }} }; $DATA->{{ SUB }} }',

IF => '(({{ right }}{{ _else else }})',
"IF THEN" => '{{ left }})? do {{{ right }}',
"xfy ELSE" => '{{ left }} }: do { {{ right }}',
"xfy ELSEIF" => '{{ left }} }: ({{ right }}',

# as ->
FOR => '{{ right }}',
"FOR THEN" => '{{ _init_for * }}do { my {{A}} = [do { {{ left }} }]; {{L}}: for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; {{ right }} } }',
"FOR IN" => '{{ _init_for * }}do { my {{A}} = do { {{ left }} }; {{L}}: for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; {{ right }} } }',
"FOR OF" => '{{ _init_for * }}do { my {{A}} = [%{ {{ left }} }]; {{L}}: for(my {{i}}=0; {{i}}<@{{A}}; {{i}}+={{ arity }}) { @$DATA{qw/{{ qwparam }}/} = map { {{A}}->[$_] } {{i}}..{{i}}+{{arity0}}; {{ right }} } }',

WHILE => '{{ right }}',
"WHILE THEN" => 'do { while({{ left }}) { {{ right }} } }',

"Fx REPEAT" => 'do { do { {{ left }} } until( {{ right }} ) }',

DO => 'do { {{ right }} }',

'fx return' => 'return {{ right }}',
'local' => '$DATA',

# атомы
#"&ref" => '({{ var }})',
index => '({{i}}+{{n}})',
self => '$DATA->{me}',
app => '$R::App::app',
q => '$R::App::app->{q}',
nothing => 'undef()',
inf => '(0+"inf")',
nan => '(0+"nan")',
pi => '(atan2(1,1)*4)',
true => '$R::App::app->json->true',
false => '$R::App::app->json->false',
paramarray => '(\@_)',
last => 'last',
"last label" => 'last {{L}}',
next => 'next',
"next label" => 'next {{L}}',

var => '$DATA->{{{ var }}}',
num => '{{ num }}',
hex => '{{ hex }}',
bin => '{{ bin }}',
radix => '{{ radix }}',
new => '("{{ new }}"->can("new")? "{{ new }}": $R::App::app->syntaxAg->include("{{ new }}"))->new',
new_apply => '("{{ new }}"->can("new")? "{{ new }}": $R::App::app->syntaxAg->include("{{ new }}"))->new({{ right }})',

# строки
CAT => '{{ str }}',
"yfx CAT" => "{{ left }}{{ str }}{{ right }}",
"yf CAT" => "{{ left }}{{ str }}",
exec1 => '{{ str }}${\({{ right }})}',
string => '"{{ right }}"',
regexp => 'qr{{{ right }}}{{ arg }}',
like => '$R::App::app->perl->likes( \'{{ right }}\', \'{{ arg }}\' )',
string_modify => '("{{ arg }}"->can("new")? "{{ arg }}": $R::App::app->syntaxAg->include("{{ new }}"))->new("{{ right }}")',

);

# возвращает новую переменную
sub ref {
	my ($self) = @_;
	'$ref' . (++$self->{REF})
}

# возвращает новую метку
sub label {
	my ($self) = @_;
	'A' . (++$self->{LABEL})
}

# инициализирует конвеер
sub _init_conveer {
	my ($self, $push) = @_;
		
	$push->{i} = $self->ref;
	$push->{A} = $self->ref;
	$push->{R} = $self->ref;
	
	""
}

# инициализирует for
sub _init_for {
	my ($self, $push) = @_;

	my $args = $push->{param};
	
	#$self->error("у FOR нет параметров!") if !@$args;
	
	$push->{arity} = @$args;
	$push->{arity0} = $push->{arity} - 1;
	$push->{qwparam} = join " ", @$args;

	
	#$push->{i} = $self->ref;
	$push->{A} = $self->ref;
	
	""
}


# инициализация группировки
sub _group_init {
	my ($self, $push) = @_;
	
	$self->_init_conveer($push);
	
	$push->{M} = $self->ref;
	$push->{E} = $self->ref;
	
	""
}

# инициализирует assort
sub _assort_init {
	my ($self, $push) = @_;
	
	$push->{arity} /= 2;
	$push->{arity0} = $push->{arity} - 1;
	
	$push->{qwparam1} = join " ", @{$push->{param}}[0..$push->{arity0}];
	$push->{qwparam2} = join " ", @{$push->{param}}[$push->{arity}..$#{$push->{param}}];
	
	""
}

# добавляет '', если ничего нет
sub _for_join {
	my ($self, $push, $right) = @_;
	$right =~ /^\s*$/? do { $push->{newline} = $right; "''" }: $right
}

# сценарий - добавляет в файл
sub _scenario {
	my ($self, $right, $lineno) = @_;
	
	push @{$self->{SCENARIO}}, {lineno => $lineno, text => $right};
	
	""
}

# если есть комментарий - выводит
sub _rem {
	my ($self, $rem) = @_;
	defined($rem)? "# $rem": "";
}

# какое окончание у if
sub _else {
	my ($self, $else) = @_;
	$else? ' }': ' }: ()'
}

# формирует аргументы функции
sub _args {
	my ($self, $args) = @_;
	local $_;
	my $AST=0;
	$args = join ", ", map { $_ eq "*"? do { $AST++; "my \$_AST$AST"}: "\$DATA->{'$_'}"} @$args;
	$args = "($args) = \@_; " if $args;
	$args .= "%\$DATA = (".join(", ", map { "\%\$_AST$_" } 1..$AST).", %\$DATA); " if $AST;
	$args
}

# хелпер для расширения класса
sub _extends {
	my ($self, $class, $extends, $lineno, $file) = @_;
	
	#push @Nil::CLASSES, "{{ class }}"$Nil::CLASSES{"{{ class }}"}++;
	
	# $file =~ s!'!\'!g;
	# $self->{BEGIN} .= "my (\$class, \$file, \$lineno) = (\"$class\", '$file', $lineno); my \$c = \$Nil::CLASSES{\$class}; die \"класс \$class встречается в \$file:\$lineno и в \$c->{file}:\$c->{lineno}\" if \$c; \$Nil::CLASSES{\$class} = { file => \$file, lineno => \$lineno }; ";
	
	push @{$self->{INCLUDES}}, @$extends if @$extends;
	
	my $ext = "";
	$ext .= " BEGIN { \@${class}::ISA = qw/".join(" ", @$extends)."/ }" if @$extends;
	$ext .= " use mro 'c3';" if @$extends>1;
	$ext
}


# разбиение строки
sub _split {
	my ($self, $push) = @_;
	$push->{i} = $self->ref;
	""
}

# описывает декоратор
sub _decorate {
	my ($self, $push) = @_;
	
	$self->{START} .= "\$R::App::app->syntaxAg->decorate(\"$push->{name}\", \"$push->{class}\", \"$push->{SUB}\", ($push->{right}));\n";
	
	""
}

# вызывается после разбора файла
sub end {
	my ($self, $ret, $syntax) = @_;
	
	# добавляет в начало
	if(my $begin = delete $self->{BEGIN}) {
		$ret = "BEGIN { use common::sense; $begin } $ret";
	}
	
	if($self->{INCLUDES}) {
		my %exists;
		$self->{START} = 'R::App::app->syntaxAg->include(qw/' . join(" ", map { exists $exists{$_}? (): ($exists{$_} = $_) } @{$self->{INCLUDES}}) . "/);\n" . $self->{START};
	}
	
	# добавляет в начало без BEGIN
	if(my $begin = delete $self->{START}) {
		$ret = "use common::sense; use R::App; $begin; $ret";
	}
	
	# сценарий - в отдельный файл
	if(my $scenario = delete $self->{SCENARIO}) {
		my $to = $syntax->{tofile};
		die "не указан выходной файл" if !$to;
		$to =~ s/\.pm$/.t/;
		
		my $code = "";
		my $lineno = 0;
		for my $x (@$scenario) {
			$code .= ("\n" x ($lineno - $x->{lineno})) . $x->{text} . "; ";
			$lineno = $x->{lineno} + $x->{endlineno}; # TODO: endlineno добавить
		}
		
		$code = join '', 'use common::sense; use R::App; my $DATA = { me => \$app->syntaxAg->include(\"Nil\")->new }; ', $code ,'1';
		
		$app->file($to)->mkpath->write($code);
	}
	
	# обнуляем
	$self->{REF} = undef;
	
	$ret
}

# вычисляет выражение на perl
sub eval {
	my ($self, $eval) = @_;
	eval "my \$DATA={me => \$app->syntaxAg->include(\"Nil\")->new }; $eval";
}

# # перегрузка оператора
# sub overload {
	# my ($self, $name, $args, $class_in, $class, $endline) = @_;
	
	# my $sub = _sub($name, $args, $class);
	
	# return ($class_in? "package $class_in {": "") . "use overload '$name' => sub { my \$DATA = {}; $sub$endline(); ", ($class_in? "}}": "};");
# }


# # заменяет спецсимволы в строке
# sub escape_string {
	# my ($self, $string, $kav) = @_;
	# if($kav eq "'") {
		# $string =~ s/'/\\'/g;
	# } else {
		# $string =~ s/[\$\@]/\\$&/g;
	# }
	# $string
# }

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

# # рендерит
# sub render {
	# my ($self, $name, $data, $output) = @_;
	
	# my $class = $self->get_name($name);
	
	# $data //= {};
	# bless $data, $class;
	
	# push @{$app->{q}{VIEW_FRAME}}, $app->{q}{echo};
	
	# $app->{q}{echo} = $output;
	
	# $data->__RENDER__;
	
	# $app->{q}{echo} = pop $app->{q}{VIEW_FRAME};
	
	# $self
# }

# # добавляет данные для вычисления
# sub foreval {
	# my ($self, $code) = @_;
	# "my \$DATA={}; $code"
# }



# our %Classes;
# our @Classes;

# # очищает классы
# sub clear_classes {
	# my ($self) = @_;
	
	# %Classes = ();
	# @Classes = ();
	
	# $self
# }

# # позиция в классах
# sub len_classes {
	# int @Classes
# }

# # инициализирует классы
# sub init_classes {
	# my ($self, $from) = @_;
	
	# return $self if $from == @Classes;
	
	# my @cls = @Classes[$from .. $#Classes];
	
	# # проверка на вшивость
	# for my $class (@cls) {
		# die "дважды объявлен класс $class" if $Classes{$class} > 1;
		# $Classes{$class} = 1;
	# }
	
	# # запускаем тело класса
	# for my $class (@cls) {
		# $class->__INIT__CLASS__;
	# }
	
	# # инициализируем инпуты
	# for my $class (@cls) {
		# $class->create_meta if $class->isa("R::Form::Input");
	# }
	
	# # инициализируем формы
	# for my $class (@cls) {
		# $class->create_meta if $class->isa("R::Form::Form");
	# }	
		
	# # запускаем конструктор класса
	# for my $class (@cls) {
		# $class->CLASS_INIT if $class->can("CLASS_INIT");
	# }
	
	# $self
# }

1;