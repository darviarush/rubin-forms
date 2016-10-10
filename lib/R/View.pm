package R::View;
# шаблонизатор

use common::sense;
use R::App;
use R::Re;
#use R::View::Filter;
use R::View::Metafilter;


has qw/compile_dir scenario_dir dir file outfile before stack begin/;

my $re_string = $R::Re::string;
my $re_id = $R::Re::id;
my $re_endline = $R::Re::endline;
my $re_number = $R::Re::number;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		dir => "view",
		compile_dir => "var/c_view",
		scenario_dir => "var/c_scenario",
		#scenario => [],			# список файлов сценариев
		begin => [],				# код который нужно добавить в начало шаблона. См. add_begin
		file => undef,				# путь к файлу
		outfile => undef,			# путь к получившемуся файлу
		#before => undef,
		stack => undef,			# стек выражений языка
		route => {},			# все роутеры route->{key} = [1-<% ACTION %>|2-on|0-cls, cls, sub|sub_name]
		trace => "view/classes/input1.html",				# шаблон трейс которого показать
		lineno => 1,			# номер строки в текущем файле
		INHERITS => undef,		# вспомогательная для шаблонов
		lang => $app->viewPerl->new,	# драйвер текущего языка
		metafilter => $app->ini->{design}{metafilter},	# наименования дефолтных метафильтров
		metafilters => [],		# метафильтры
		meta => {},				# данные метафильтров - очищаются при завершении шаблона
		INC => {},				# подключённые шаблоны и файлы кода => класс
		inc => ["."],			# пути в которых искать шаблоны и файлы кода
		class => {},			# скомпилированный класс
	}, ref $cls || $cls;
}

# устанавливает язык
sub lang {
	if(@_ == 1) { shift->{lang} } else {
		my ($self, $lang) = @_;
		if(ref $lang) { $self->{lang} = $lang } else {
			if($lang eq "js") { $self->{lang} = $app->viewJavascript->new }
			elsif($lang eq "perl") { $self->{lang} = $app->viewPerl->new }
			else { die "неизвестный язык $lang" }
		}
		$self
	}
}

# добавляет код к begin
sub add_begin {
	my ($self, $text) = @_;
	
	push @{$self->{begin}}, $text;
	
	$self
}

# устанавливает роутер для классов
sub route {
	my ($self, $route, $type, $sub) = @_;
	
	die "диспетчер $route уже добавлен" if exists $self->{route}{$route};
	
	$self->{route}{$route} = my $disp = $app->httpDispatcher->new->uri($route);
	$disp->type("class")->class($type)->sub($sub);
	$self
}

# устанавливает экшн
sub action {
	my ($self, $route, $class, $file) = @_;
	
	die "диспетчер $route уже добавлен" if exists $self->{route}{$route};
	
	$self->{route}{$route} = my $disp = $app->httpDispatcher->new->uri($route);
	$disp->type(1);
	$disp->class($class);
	$disp->file($file);
	
	$disp->sub(sub {
		my $q = $app->{q};
		
		push @{$self->{FRAME}}, [$R::View::Views::OUTPUT, $R::View::Views::LAYOUT];
		
		$R::View::Views::OUTPUT = $q->{echo};
		
		my $class = $disp->{class};
		
		my $data = bless {}, $class;
		
		$data->__RENDER__;
		
		($R::View::Views::OUTPUT, $R::View::Views::LAYOUT) = @{ pop @{$self->{FRAME}} };
	});
	
	$self
}

# устанавливает ON
sub route_on {
	my ($self, $route, $sub, $file) = @_;
	
	die "диспетчер $route уже добавлен" if exists $self->{route}{$route};
	
	$self->{route}{$route} = my $disp = $app->httpDispatcher->new->uri($route);
	$disp->type(2);
	$disp->sub($sub);
	$disp->file($file);
	
	$self
}

# возвращает скомпиллированный путь
sub compile_path {
	my ($self, $path, $compile_dir) = @_;
	
	my $dir = $self->dir;
	$compile_dir //= $self->compile_dir;
	
	$path =~ s/$dir/$compile_dir/;
	$path .= ".pl";
	$path
}

# возвращает путь для сценария
sub scenario_path {
	my ($self) = @_;
	$self->compile_path($self->scenario_dir);
}

# просматривает директорию и решает: какие файлы надо парсить, если скомпиленного файла нет или его время модификации больше скомпиленного (он старше)
sub compile {
	my ($self) = @_;
	
	my $dir = $self->dir;
	#my $compile_dir = $self->compile_dir;
	
	#my $requires = $app->file($compile_dir)->find;
	my $mtime = $app->file("lib/R/View.pm", "lib/R/View")->find->maxmtime; 
	
	$app->file($dir)->find(sub {
		my $path = $_;

		return if !-f $path;
		#return if $path !~ /\.html$/;

		my $outfile = $self->compile_path($path);
		
		my $f = $app->file($outfile);
		my $exists = $f->exists;
		$f->mkpath if !$exists;
		
		$app->bench->time, $self->parsefile($path, $outfile), msg("парсится", ":green", $path, $app->bench->log) if !$exists || $f->mtime < $mtime || $f->oldest($path);
		
		undef
	});
	
	@$self{qw/before file/} = ();
	
	$self
}

# перекомпиллирует всё
sub recompile {
	my ($self, $path) = @_;
	
	my $dir = $path // $self->dir;
	
	$app->file($dir)->find(sub {
		my $path = $_;

		return if !-f $path;
		#return if $path !~ /\.html$/;

		my $outfile = $self->compile_path($path);
		
		my $f = $app->file($outfile);
		my $exists = $f->exists;
		$f->mkpath if !$exists;
	
		$app->bench->time;
		$self->parsefile($path, $outfile);
		msg("парсится", ":green", $path, $app->bench->log);
	});
	
	$self
}

# загружает шаблоны
sub load {
	my $self = shift;
	
	#$self->{lang}->clear_classes;
	
	my $dir = $self->dir;
	my $compile_dir = $self->compile_dir;
	my @dir = @_? (map { "$compile_dir/$_" } @_): $compile_dir;
	
	$app->file(@dir)->find(sub {
		my $path = $_;
		
		return if !-f $path;
		
		my $view = $path;
		return if not $view =~ s/\.pl$//;
		$view =~ s/$compile_dir/$dir/;

		msg("удаляется", ":green", $path), $app->file($path)->rm->rmpath, return if !-e $view;
		msg("компилиться", ":green", $view), $self->parsefile($view, $path) if -M $view < -M $path;
		
		require $path;
		
		undef
	});
	
	$self->init_classes;
	
	$self
}


# инициализирует классы
sub init_classes {
	my ($self, $from) = @_;
	$self->{lang}->init_classes($from // 0);
	$self
}

# парсит файл и сохраняет в путь $outfile
sub parsefile {
	my ($self, $path, $outfile) = @_;
	
	$self->{file} = $path;
	$self->{outfile} = $outfile;
	
	open my $f, "<:utf8", $path or die "not open `$path`: $!";
	read $f, my $buf, -s $f;
	close $f;
	
	my $name = substr $path, length $self->dir;
	
	my $pol = $self->parse($buf, $name);
	
	open my $f, ">:utf8", $outfile or die "not write `$outfile`: $!";
	print $f $pol;
	close $f;
	
	if($app->ini->{design}{check_lines}) {
	
		my ($i, $j);
		while($buf =~ /$re_endline/g) { $i++ }
		while($pol =~ /$re_endline/g) { $j++ }
		
		die "$path: $i строк <> $j строк" if $i != $j;
	}
	
	$self
}


# маскирование переменных
my $re_space = qr/[\ \t]+/;
my $re_space_ask = qr/[\ \t]*/;
my $re_rem = qr/[\ \t]*(?:(?:\#|\brem\b)(?P<rem>[^\n\r]*))?/i;
my $re_sk = qr/[\[\{]/;
my $re_arg = qr/(?:$re_id|\*)/o;
my $re_class = qr/$re_id(?:::$re_id)*/o;
my $re_extends = qr!$re_class(?:$re_space_ask,$re_space_ask$re_class)*!;
my $re_class_stmt = qr!
(?P<class>$re_class)
(?: [\ \t]+ (?:EXTENDS|INHERITS) [\ \t]+ (?P<extends>$re_extends))?
(?P<with> [\t\ ]+ with [\t\ ]+ (?P<with_args> [^\r\n]+) )?
!xismo;				
my $re_args = qr!
(?: [\ \t]* (?P<sub_args>$re_arg (?:$re_space_ask,$re_space_ask $re_arg)*))??
!xismo;
my $re_sub = qr!
	(?P<sub>$re_id|"\w+"|[[:punct:]]+|0\+)
	$re_args
	(?: [\ \t]+ CLASS [\ \t]+ (?P<sub_in>(?P<sub_self>::)?$re_class) )?
!xismo;
my $re_for = qr!
(?P<for_k>$re_id) (?: $re_space_ask,$re_space_ask (?P<for_v>$re_id) (?: $re_space_ask,$re_space_ask (?P<for_i>$re_id) )? )? (?: $re_space (?P<for_in>IN) \b | $re_space (?P<for_of>OF) \b | $re_space_ask = )
!xismo;
my $re_gosub_after = qr{
\b [\ \t]* (?! [ !\+\-\*/<>=  \)\}\] \|& \? .:,; \r\n ] | %\s |  (?:or|and|not|eq|ne|le|ge|lt|gt|then|else|end|cmp|from) \b | $ )
}xismo;



# describe context it Given

# ключевые слова:
# super null extends action of block process include raw wrapper eq ne le ge lt gt keys values use sort scenario pairmap map grep reduce from repeat self this me                 ucfirst lcfirst uc lc ref cmp push pop undef next last redo return pairs or and not eq ne le ge lt gt scalar msg msg1 keys values exists closure length use push pop shift unshift splice delete defined wantarray


my $re_masking = qr{
	(?<=[\w\}\]\)"'\+\-!])$re_rem(?P<endline>$re_endline) |
	$re_rem(?P<endline_then>$re_endline) |
	
	(?P<sepexpression> ;) |
	
	" (?P<QR> (?:[^"]|\\")* ) "! (?P<qr_args> \w+ )? |
	
	(?P<array> \[ ) |
	(?P<hash> \{ ) |
	(?P<group> \( ) |
	(?P<end_tag> [\}\]\)] ) |
	
	(?P<string>$re_string) |
	(?P<func>$re_id)\( |
	(?P<key>$re_id) $re_space_ask => |
	
	(?P<method>\.\$|[\.:\$]|::)(?P<m_id>$re_id)(?P<m_sk> $re_sk | \( ) |
	(?P<method>\.\$|[\.:\$]|::)(?P<m_id>$re_id)(?P<gosub>) $re_gosub_after |
	(?P<method>\.\$|[\.:\$]|::)(?P<m_id>$re_id) |
	
	(?P<var>$re_id)(?P<var_sk>$re_sk) |
	
	^ (?P<gosub> [\t\ ]* THEN ) \b |
	
	\b (
		(?P<self> self | this | me ) |
		(?P<app> app ) |
		(?P<q> q ) |
		(?P<user> user ) |
		(?P<while> WHILE ) |
		(?P<repeat> REPEAT ) |
		(?P<until> UNTIL ) |
		(?P<if> IF ) |
		(?P<then> THEN ) |
		(?P<elseif> ELSEIF ) |
		(?P<else> ELSE ) |
		(?P<end> END ) |
		(?P<map> MAP ) |
		(?P<pairmap> PAIRMAP ) |
		(?P<grep> GREP ) |
		(?P<reduce> REDUCE ) |
		(?P<sort> SORT ) |
		(?P<from> FROM ) |
		(?P<addhandler> addhandler ) |
		(?P<paramarray> paramarray | arguments ) |
		(?P<begin> BEGIN ) |
		
		(?P<operator> cmp|mod|xor|or|and|not|eq|ne|le|ge|lt|gt ) |
		
		(?P<word> undef|next|last|redo|return|use|wantarray ) |
		(?P<unary> ref|pairs|scalar|defined|length|exists ) |

		(?P<nothing> null | nothing) |
		(?P<true> true) |
		(?P<false> false) |
		(?P<throw> throw)
	) \b |
	
	(?P<super> \bsuper\b ) (?: \.(?P<super_call> $re_id) (?P<super_sk> \( )? | \b) |
	\b (?P<try> try ) \b |
	\b (?P<catch> catch ) (?: $re_space (?P<catch_var> $re_id) (?: $re_space AS $re_space (?P<catch_isa> $re_class (?: $re_space_ask , $re_space_ask $re_class )* )? )? )? |
	\bFOR $re_space $re_for |
	\bON $re_space (?P<route>$re_string) |
	\b(?: (?P<class_new> object ) | class ) $re_space $re_class_stmt |
	\b(?P<module> module ) $re_space $re_class_stmt |
	\b(?P<def> DEF ) $re_space $re_sub (?: (?P<sub_then> [\ \t]+ then \b) | $re_rem $re_endline) |
	\bSUB $re_space $re_sub (?: (?P<sub_then> [\ \t]+ then \b) | $re_rem $re_endline) |
	\b (?P<do>do) $re_args (?: (?P<sub_then> [\ \t]+ then \b) | $re_rem $re_endline) |
	\bNEW $re_space (?P<new>$re_id(?:::$re_id)*) |

	
	\@(?P<unarray> $re_id(?:[\.:]$re_id)* (?P<sk>$re_sk)? | \{ ) |
	%(?P<unhash> $re_id(?:[\.:]$re_id)* (?P<sk>$re_sk)? | \{ ) |
	
	(?P<gosub>$re_id) $re_gosub_after |
	
	(?P<var>$re_id) |
	(?P<num>$re_number) |
	
	# (?P<outdoor> %> ) |
	
	(?P<ass_delim> => ) |
	(?P<operator> //= | // | \|\|= | \|\| | &&= | && | <<= | >>= | << | >> | <=> | =~ | !~ | \+\+ | -- | ~~ | \*= | \+= | -= | /= | == | != | <= | >= | < | > | ! | - | \+ | \* | / | \^ | ~ | % | \.\.\. | \.\. | \.= | \. | \? | : ) |
	(?P<assign> = ) |
	(?P<comma> , ) |
	(?P<space> $re_space) |
	(?P<nosim> . )
}sxiom;


my %CloseTag = qw/ ( ) { } [ ] /;

# маскирует распознанную лексему
sub masking_step {
	my ($self) = @_;
		
	$self->error("masking: %+ пуст! `$&`") if !%+;
	
	if(!exists $+{space} && !exists $+{do}) {
		# top на предыдущей лексеме
		my $top = $self->etop;
		# счётчик лексем в этом элементе стека. Используется в do
		$top->{counter}++;
		# prevop - предыдущий оператор, используется в do
		$top->{prevop} = exists $+{assign} || exists $+{comma} || exists $+{ass_delim} || exists $+{gosub} || exists $+{func} || exists $+{start_tag};
	}
	
	# # для унарных операторов добавляем
	
	# if($top->{unary} && $top->{counter} >= 2) {
		# $RET .= $self->endstmt;
	# }

	my $pluslineno = $+{re_endline};

	my $RET =

	exists $+{space}? $self->{lang}->space($+{space}):
	exists $+{string}? $self->replace_dollar($+{string}):
	exists $+{QR}? $self->{lang}->regexp($+{QR}, $+{qr_args}):
	exists $+{var}? do {
		my $sk = $+{var_sk};
		my $six = $+{var};

		my ($begin, $end) = $six =~ /^\p{Uppercase}/? $self->{lang}->classname($six, $sk): $self->{lang}->var($six, $sk);
		
		$self->push(stmt=>"var", tag=>$CloseTag{$sk}, end=>$end) if $sk;
		
		$begin
	}:
	exists $+{method}? do {
		my $method = $+{method};
		my $name = $+{m_id};
		my $sk = $+{m_sk};
		my $gosub = exists $+{gosub};

		$sk = "(" if $gosub;
		
		my ($begin, $end) =
			$method eq ".\$"? $self->{lang}->dotref($name, $sk):
			$method eq "."? $self->{lang}->dot($name, $sk):
			$method eq ":"? $self->{lang}->colon($name, $sk):
			$method eq "::"? $self->{lang}->twocolon($name, $sk):
			$self->{lang}->dollar($name, $sk);
		
		if($gosub) {
			$self->push(stmt=>"method", name=>$name, type=>$method, endline=>1, gosub=>1, end=>$end);
		}
		elsif($sk) {
			$self->push(stmt=>"method", name=>$name, type=>$method, tag=>$CloseTag{$sk}, end=>$end);
		}
		
		$begin
	}:
	exists $+{func}? do {
		my $name = $+{func};
		my ($begin, $end) = $self->{lang}->gosub($name);
		$self->push(stmt=>"gosub", name=>$name, tag=>")", end=>$end);
		$begin
	}:
	exists $+{key}? $self->{lang}->key($+{key}):
	exists $+{word}? $self->{lang}->word( lc $+{word} ):

	exists $+{self}? $self->{lang}->self:
	exists $+{app}? $self->{lang}->appvar:
	exists $+{q}? $self->{lang}->q:
	exists $+{user}? $self->{lang}->user:
	exists $+{while}? do {
		my ($begin, $then, $end) = $self->{lang}->while;
		$self->push(stmt=>"while", then=>$then, end=>$end);
		$begin
	}:
	exists $+{repeat}? do {
		$self->push(stmt=>"repeat", end=>"REPEAT ERROR!!!");
		$self->{lang}->repeat
	}:
	exists $+{until}? do {
		$self->check(stmt=>"repeat")->pop;
		my ($begin, $end) = $self->{lang}->until;
		$self->push(stmt=>"until", end=>$end, endline=>1);
		$begin
	}:
	exists $+{if}? do {
		my ($begin, $then, $end) = $self->{lang}->if;
		$self->push(stmt=>"if", then=>$then, end=>$end);
		$begin
	}:
	exists $+{then}? do {
		my $outfile=$self->endgosub;
		my $then = $self->then;
		$self->top->{endline} = 1;
		$outfile . $then
	}:
	exists $+{elseif}? do {
		my $outfile = $self->endgosub;
		$self->check(stmt=>"if", else=>undef, then=>undef);
		my ($begin, $then) = $self->{lang}->elseif;
		$self->top->{then} = $then;
		$outfile . $begin
	}:
	exists $+{else}? do {
		my $outfile = $self->endgosub;
		$self->check(stmt=>"if", else=>undef, then=>undef);
		my ($begin, $end) = $self->{lang}->else;
		$self->top->{else} = 1;
		$self->top->{end} = $end;
		$outfile . $begin
	}:
	exists $+{try}? do { $self->push(stmt=>"try"); $self->{lang}->try }:
	exists $+{catch}? do {
		my $top = $self->check(stmt=>"try")->top;
		my $is_end = delete $top->{end};
		my $isa = $+{catch_isa};
		my $var = $+{catch_var};
		my ($begin, $end) = $self->{lang}->catch($isa, $var, $is_end);
		$top->{end} = $end;
		$begin
	}:
	exists $+{end}? do {
		my $top = $self->top;
		$self->error("$top->{stmt}: end встречен до then") if defined $top->{then};
		$self->error("нет end") if !defined $top->{end};
		$self->endstmt
	}:
	exists $+{array}? do {			# открывающая скобка
		my ($begin, $end) = $self->{lang}->array( $+{array} );
		$self->push(stmt=>"[...]", tag=>"]", end=>$end);
		$begin
	}:
	exists $+{hash}? do {			# открывающая скобка
		my ($begin, $end) = $self->{lang}->hash( $+{hash} );
		$self->push(stmt=>"{...}", tag=>'}', end=>$end);
		$begin
	}:
	exists $+{group}? do {			# открывающая скобка
		my ($begin, $end) = $self->{lang}->group( $+{group} );
		$self->push(stmt=>"(...)", tag=>")", begin=>$begin, end=>$end, ($self->etop->{not_group}? (not_group => 1): ()));
		$begin
	}:
	exists $+{end_tag}? do {			# закрывающая скобка
		my $endtag = $+{end_tag};
		my $endline = $self->endline;
		my $top = $self->top;
	
		$self->error("нет открывающей скобки к `$endtag`") if $endtag ne $top->{tag};
		$endline . $self->endstmt
	}:
	exists $+{pairmap}? do {
		$self->push(stmt=>"pairmap");
		$self->{lang}->pairmapconv
	}:
	exists $+{map}? do {
		$self->push(stmt=>"map");
		$self->{lang}->map
	}:
	exists $+{grep}? do {
		$self->push(stmt=>"grep");
		$self->{lang}->grep
	}:
	exists $+{reduce}? do {
		$self->push(stmt=>"reduce");
		$self->{lang}->reduceconv
	}:
	exists $+{sort}? do {
		$self->push(stmt=>"sort");
		$self->{lang}->sort
	}:
	exists $+{from}? do {
		my $endline = $self->endline;
		my $top = $self->top;
	
		$self->error("FROM должен использоваться после MAP, PAIRMAP, GREP, SORT или REDUCE") if $top->{stmt} !~ /^(?:map|grep|sort|reduce|pairmap)$/;
		
		my ($begin, $end) = $self->{lang}->from;
		
		%$top = (%$top, stmt=>"from", gosub=>1, endline=>1, end=>$end);
		
		$endline . $begin
	}:
	exists $+{begin}? do {
		my ($begin, $end) = $self->{lang}->begin;
		$self->push(stmt=>"BEGIN", end=>$end);
		$begin
	}:
	exists $+{route}? do {
		my $route = $app->perl->unstring($+{route});
		my ($begin, $end) = $self->{lang}->route($route);
		$self->push(stmt=>"on", end=>$end);
		$begin
	}:
	exists $+{addhandler}? do { $self->check(stmt=>"on"); $self->{lang}->addhandler }:
	exists $+{paramarray}? $self->{lang}->paramarray:
	#exists $+{super_call}? "Super(\$self, '$+{super_call}'" . ($+{super_sk}? ", ": ")"):
	exists $+{super}? $self->stmt_super:
	exists $+{for_k}? $self->stmt_for:
	exists $+{gosub}? do {
		my $name = $+{gosub};
		my ($begin, $end) = $self->{lang}->gosub($name);
		$self->push(stmt=>"gosub", name=>$name, gosub=>1, endline=>1, begin=>$begin, end=>$end);
		$begin
	}:
	exists $+{unary}? do {
		my $name = $+{unary};
		my ($begin, $end) = $self->{lang}->gosub($name);
		$self->push(stmt=>"gosub", name=>$name, gosub=>1, endline=>1, unary=>1, begin=>$begin, end=>$end);
		$begin
	}:
	# module должно находиться перед классом
	exists $+{module}? $self->stmt_class("", "", 1):
	exists $+{class}? $self->stmt_class("", "", 0, $+{class_new}):
	exists $+{sub}? $self->stmt_sub:
	exists $+{do}? $self->stmt_do:
	exists $+{new}? $self->{lang}->newstmt($+{new}):
	exists $+{unarray} || exists $+{unhash}? do {
		my $s = $+{unarray} // $+{unhash};
		my $un = exists $+{unarray}? "unarray": "unhash";
		my ($begin, $end) = $self->{lang}->$un;
		
		if($s eq "{") {
			$self->push(stmt => $un, tag=>"}", end => $end);
			$begin
		} else {
			my $sk = $+{sk};
			$self->push(stmt => $un, end => $end);
			my $masking = $self->masking($s, 1);
			if($sk) {
				my $top = $self->top(1);
				%$top = (%$top, gosub=>1, endline=>1, unary=>1);
				$begin . $masking
			} else {
				join "", $begin, $masking, $self->endstmt
			}
		}
	}:
	exists $+{sepexpression}? $self->endgosub . $self->{lang}->sepexpression:
	exists $+{endline}? do {
		my $ends = $self->{lang}->endline($+{rem}, $+{re_endline});
		my $end = $self->endline;
		my $top = $self->etop;
		
		my $in;
		if($top->{then}) {
			$end = join "", $end, $self->then, $self->{lang}->sepexpression_after_then;
		}
		elsif(($in=$top->{stmt}) eq "{...}" || $in eq "[...]" || $in eq "(...)") {
			$end .= $self->endunary . $self->{lang}->comma;
		}
		else {
			$end .= $self->{lang}->sepexpression;
		}

		$end . $ends
	}:
	exists $+{endline_then}? $self->{lang}->endline($+{rem}, $+{re_endline}):
	exists $+{nothing}? $self->{lang}->nothing:
	exists $+{true}? $self->{lang}->true:
	exists $+{false}? $self->{lang}->false:
	exists $+{throw}? $self->{lang}->throw:
	exists $+{num}? $self->{lang}->number($+{num}):
	exists $+{assign}? do {
		$self->{_assign} = 1; 
		$self->{lang}->assign
	}:
	exists $+{ass_delim}? $self->endunary . $self->{lang}->fat_comma:
	exists $+{operator}? $self->endunary . $self->{lang}->operator($+{operator}):
	exists $+{comma}? $self->endunary . $self->{lang}->comma:
	exists $+{nosim}? $self->error("неизвестный науке символ `$+{nosim}`"):
	#exists $+{outdoor}? $self->error("неизвестный науке символ `%>`"):
	$self->error("нет соответствия распознанной лексеме `$&`");

	$self->{lineno}++ if $pluslineno;
	
	$RET
}


# выбрасывает end
sub endstmt {
	my ($self) = @_;
	my $end = $self->pop->{end}; 
	ref $end eq "CODE"? $end->($self->{lang}): $end;
}

# выбрасывает then
sub then {
	my ($self) = @_;
	my $top = $self->top;
	my $then = delete $top->{then};
	ref $then eq "CODE"? $then->($self->{lang}): $then
}

# выбрасывает endline
sub endline {
	my ($self) = @_;
	my @end;
	while($self->etop->{endline}) {	# если есть endline - сбрасываем
		push @end, $self->endstmt;
	}
	join "", @end
}

# выбрасывает gosub
sub endgosub {
	my ($self) = @_;
	my @end;
	while($self->etop->{gosub}) {
		push @end, $self->endstmt;
	}
	join "", @end
}

# выбрасывает унарные операции
sub endunary {
	my ($self) = @_;
	my @end;
	while($self->etop->{unary}) {
		push @end, $self->endstmt;
	}
	join "", @end
}


sub masking {
	my ($self, $expirience, $with_open_sk) = @_;
	local ($&, $_, $`, $');
	
	if(!$with_open_sk) {
		my $class_name = $self->etop->{class_name};
		$self->push(stmt => "masking", ($class_name? (class_name => $class_name): ()));
	}
	
	$expirience =~ s{ $re_masking }{ $self->masking_step }gsximeo;
	
	$self->{_assign} = 0, $_[3] = 1 if $self->{_assign};
	
	if(!$with_open_sk) {
		my $end = $self->endline;
		
		$self->check(stmt => "masking");
		$self->pop;

		join "", $expirience . $end;		
	} else {
		$expirience
	}
}

# заменяет переменные в строке
#my $re_id = $R::Re::id;
sub replace_dollar {
	my ($self, $string) = @_;
	local ($_, $`, $', $&, $1, $2);
	
	$string =~ /(.)/; my $kav = $1;
	
	my $dollar = sub {
		defined($1)? do {
			my $dollar = $2;
			$self->{lang}->escape_string($1, $kav) .
			(defined($dollar)? $self->{lang}->replace_dollar($self->masking($dollar), $kav): $kav)
		}:
		$kav
	};
	
	$string =~ s{
		^ ['"] |
		( .*? ) (?: \$($re_id(?:[\.:]$re_id)*) | ['"] $ )
	}{ $dollar->() }gexs;
	$string

}

# аналог parse для кода, а не шаблона
sub mask {
	my ($self, $expirience) = @_;
	#$self->push(stmt=>"mask");
	$expirience = $self->masking($expirience);
	$expirience = $self->{lang}->expirience($expirience);
	#$self->check(stmt=>"mask");
	#$self->pop;
	$expirience
}

# парсит из строки шаблон и возвращает пакет perl
sub parse {
	my ($self, $buf, $name) = @_;
	
	$name //= "EXAMPLE";
	%{$self->{meta}} = ();
	
	$self->{stack} = [];
	$self->{lineno} = 1;
	$self->{INHERITS} = undef;
	$self->{lang}{view} = $self;
	
	my $class = $self->get_name($name);
	
	$self->push(stmt=>"template", class=>$class);
	
	# если указаны метафильтры - фильтруем
	my $metafilter = $self->{metafilters};
	if(my $metafilters = $self->{metafilter}) {
		@$metafilter = map { $self->metafilter($_) } split /\s+/, $metafilters;
	}
	
	my $prev;	# предыдущая лексема или undef
	
	my $re_expression = qr{
		(?P<ex_html> .*? )
	
		(?:
			<% $re_space_ask (?P<ex_stmt> .*? ) %> |
			\$(?P<ex_id>$re_id([\.:]$re_id)*) |
			<\*\*\* (?P<ex_comment>.*?) \*\*\*> |
			$
		)
	}isx;
	
	my $expression = sub {
	
		my $html = $+{ex_html};
	
		if(length $html) {
			local(%+);
			$self->{lineno} += $app->perl->lines($html);
		
			for my $filter (@$metafilter) {
				$html = $filter->($self, $html, $prev);
			}
			
			$prev = $html;
			$html =~ s/['\\]/\$&/g;
		}
	
		$html .
		(exists $+{ex_stmt}? $self->expression($+{ex_stmt}):
		exists $+{ex_id}? do {
			my $expression = $self->masking($+{ex_id});
			my ($begin, $end) = $self->{lang}->v_escape;
			join "", $begin, $expression, $end
		}:
		exists $+{ex_comment}? do {
			my $i = $app->perl->lines($+{ex_comment});
			$self->{lineno} += $i;
			my ($begin, $end) = $self->{lang}->v_in;
			join "", $begin, ("\n" x $i), $end
		}:
		"");
	};
	
	$buf =~ s{ $re_expression }{ $expression->() }isgxe;
	
	# у темплейта не должно быть завершающего end
	$self->check(stmt => "template");
	
	$self->error("стек не пуст: нет <% end " . $self->top(1)->{stmt} . " %>") if @{$self->stack}>1;
	
	my $inherits = delete $self->{INHERITS};
	
	my @inherits = split /\s+/, $inherits;
	@inherits = map { $self->get_name($_) } @inherits;
	
	# код, который выполниться при загрузке скрипта
	my $begin = $self->{begin};
	my $begin = @$begin? do { my $ret = " " . join "", @$begin; @$begin = (); $ret }: "";
	
	my ($begin, $end) = $self->{lang}->template($class, \@inherits, $begin);
	my ($v_in_begin, $v_in_end) = $self->{lang}->v_in;
	
	$buf = $self->{lang}->expirience(join "", $begin, $v_in_end, $buf, $v_in_begin, $end);
	
	$self->pop;
	
	%{$self->{meta}} = ();
	
	$buf
}


# выражение в <% %>
sub expression {
	my ($self, $expression) = @_;
	local ($&, $_, $`, $');
	
	return "" if $expression =~ /^#/;	# комментарий
	
	my $word = "";
	my $WORD = "";
	
	$WORD = $&, $word = lc $1 if $expression =~ s/^([a-z_]\w*)$re_space_ask//io;
	
	my $top = $self->etop;
	
	my $in = 1;
	
	my $RET =
	$word eq "perl"? do {	# без маскирования
		$expression
	}:
	$word eq "if"? do {					# if
		$self->error( "<% if %> без условия" ) if $expression eq "";
		$self->masking("if $expression\n", 1)
	}:
	$word eq "elseif"? do {		# else if
		$self->error( "<% elseif %> без условия" ) if $expression eq "";
		$self->error( "<% elseif %> без <% if %>" ) if $top->{stmt} ne "if";
		$self->masking("elseif $expression\n", 1)
	}:
	$word eq "else"? do {					# else
		$self->error( "<% else %> без <% if %>" ) if $top->{stmt} ne "if";
		$self->masking("else\n$expression\n", 1)
	}:
	$word eq "end"? do {				# end
		$self->error( "<% end %> c выражением" ) if $expression ne "";
		die "$top->{stmt} не содержит end" if !defined $top->{end};

		$in = 0;
		if($top->{v_in} // 1) {
			my($v_in_begin, $v_in_end) = $self->{lang}->v_in;
			$top->{end} = join "", $v_in_begin, (ref $top->{end} eq "CODE"? $top->{end}->(): $top->{end}), $v_in_end;
		}
		$self->endstmt;
	}:
	$word eq "for"? do {	# for in
		$self->error( "<% for %> без данных" ) if $expression eq "";
		$self->error( "ошибка синтаксиса <% for %>: $_" ) unless $expression =~ /^$re_for$re_space_ask/io;
		$self->masking("for $expression\n", 1);
	}:
	$word eq "while"? do {	# while
		$self->error( "<% while %> без условия" ) if $expression =~ /^\s*$/;
		$self->masking("while $expression\n", 1)
	}:
	$word eq "repeat"? do {	# repeat
		$self->masking("repeat $expression\n", 1)
	}:
	$word eq "until"? do {	# repeat
		$self->error( "<% until %> без условия" ) if $expression =~ /^\s*$/;
		$self->masking("until $expression\n", 1)
	}:
	$word =~ /^(?:class|(object))$/? do {	# class
		my $new = defined $1;
		$self->error( "ошибка синтаксиса <% class name %>: $_" ) unless $expression =~ s/^$re_class_stmt$re_space_ask//io;
		
		$self->error("with можно использовать только с object") if $+{with} && !$new;
		
		$new? do {
			my ($v_escape_begin, $v_escape_end) = $self->{lang}->v_escape;
			my ($v_in_begin, $v_in_end) = $self->{lang}->v_in;
		
			my $class_declare = $self->stmt_class($v_in_begin, $v_escape_end, 0, 1);
			$self->top->{v_in} = 0;
			$in = 0;
			join "", $v_escape_begin, $class_declare, " ", $self->masking($expression), " " , $v_in_end
		}: do {
			my $class_declare = $self->stmt_class("", "; ", 0, 0);
			join "", $class_declare, " ", $self->masking($expression), ($expression ne ""? ";": ())
		}
	}:
	$word eq "module"? do {	# class
		$self->error( "ошибка синтаксиса <% module name %>: $_" ) unless $expression =~ s/^$re_class_stmt$re_space_ask//io;
		my $class_declare = $self->stmt_class("", "; ", 1, 0);
		join "", $class_declare, " ", $self->masking($expression), ($expression ne ""? ";": ())
	}:
	$word eq "sub"? do {	# метод
		$self->error( "ошибка синтаксиса <% sub name args... %>: $_" ) unless $expression =~ /^$re_sub$re_space_ask$/io;
		
		my ($begin, $end) = $self->{lang}->subinblock;
		my $sub = $self->stmt_sub;
		my $subtop = $self->top;
		$subtop->{end} = $end . $subtop->{end};
		$sub . $begin
	}:
	$word =~ /^(?:inherits|extends)$/? do {	# без маскирования
		$self->error( "ошибка синтаксиса <% $word %>: $_" ) if $expression !~ s/^($re_string)$re_space_ask//;
		$self->{INHERITS} = $app->perl->unstring($1);
		$expression =~ /\S/? do {
			my ($begin, $end) = $self->{lang}->block('init');
			join "", $begin, $self->masking_quote($expression), $end
		}: $expression
	}:
	$word eq "action"? do {	# регистрация отображения и блока при AJAX в диспетчерах
		$self->error( "ошибка синтаксиса <% action [extends \"view\"] [init] %>: $_" ) unless $expression =~ s/^(?:(?:extends|inherits) $re_space ($re_string)) $re_space_ask//iox;
		
		$self->{INHERITS} = $app->perl->unstring($1) if $1;
		
		my $view = my $key = substr $self->file, length $self->dir;
		$key =~ s/\.[^\.\/]+$//;
		my $route = $self->get_name($view);
		if($expression =~ /\S/) {
			my ($begin, $end) = $self->{lang}->block("init");
			$end = "; $end";
			$expression = join "", $begin, $self->masking($expression), $end;
		}
		$self->{lang}->action($key, $route, $view) . $expression
	}:
	$word eq "block"? do {				# block
		$self->error( "ошибка синтаксиса <% $word name %>: $_" ) unless $expression =~ s/^($re_id)$re_space_ask//o;
		my $name = $1;
		my ($begin, $end) = $self->{lang}->block($name);
		$self->push(stmt => "block", block_name => $name, end => $end);
		$begin . $self->masking_quote($expression)
	}:
	$word eq "process"? do {	# process
		$self->error( "ошибка синтаксиса <% process [block from] \"file\" %>: $_" ) unless $expression =~ s/^(?:($re_id)$re_space FROM $re_space ($re_string) | ($re_string))$re_space_ask//iox;
		my $block = $1;
		my $name = $self->get_name( $app->perl->unstring($2 // $3) );
		my ($begin, $end) = $self->{lang}->process($name, $block);
		join "", $begin, $self->masking_quote($expression), $end
	}:
	$word eq "include"? do {	# include
		$self->error( "ошибка синтаксиса <% include [block from] \"file\" %>: $_" ) unless $expression =~ s/^(?:($re_id)$re_space FROM $re_space ($re_string) | ($re_string))$re_space_ask//iox;
		my $block = $1;
		my $name = $self->get_name( $app->perl->unstring($2 // $3) );
		my ($begin, $end) = $self->{lang}->include($name, $block);
		join "", $begin, $self->masking_quote($expression), $end
	}:
	$word eq "set"? do {	# присваивание html в переменную
		$self->error( "<% set %> c выражением" ) unless $expression =~ s!^($re_id)\s*$!!;
		my ($begin, $end) = $self->{lang}->set($1);
		$self->push(stmt=>"set", end=>$end);
		$begin
	}:
	$word eq "filter"? do {	# фильтр в html
		$self->error( "<% filter name %>" ) unless $expression =~ s!^($re_id)\s*$!!;
		
		my ($begin, $end) = $self->{lang}->filter($1);
		
		$self->push(stmt=>"filter", end=>$end);
		$begin
	}:
	$word eq "metafilter"? do {	# фильтр в html
		$self->error( "<% metafilter name %>" ) unless $expression =~ s!^($re_id)\s*$!!;
		push @{$self->{metafilters}}, $self->metafilter($1);
		$self->push(stmt=>"metafilter", end=>closure($self, sub { pop @{shift->{metafilters}}; "" }));
		$in=0;
		""
	}:
	$word eq "js"? do {	# добавляет код в html/js/app.js
		$self->error( "<% js [unic_id] %>" ) unless $expression =~ s!^($re_id)?\s*$!!;
		
		my $var = $1;
		
		todo if $var;
		
		my ($begin, $end) = $self->{lang}->js;
		
		$self->push(stmt=>"js", end=>$end);
		$begin
	}:
	$word eq "scenario"? do {	# сценарий страницы (тест)
		my $lines = $self->{lineno};
		
		my $view = substr $self->file, length $self->dir;	# обрезаем рутовую директорию
		my $outfile = $self->scenario_dir . $view . ".pl";
		
		my $f = $app->file($outfile);
		my $exists = $f->exists;
		$f->mkpath if !$exists;
		
		my $view = substr $self->file, length $self->dir;
		my $name = $self->get_name($view);
		
		my $masking = $self->masking($expression);
		
		$f->write(("\n" x $lines) . $self->{lang}->scenario($name, $masking));
		$expression =~ s/.*//gm;
		$expression
	}:
	$word =~ /^(?:call|let)$/? do {	# без вывода
		$self->masking_quote($expression)
	}:
	$word eq "get"? do {	# вывод
		$in=0;
		my ($begin, $end) = $self->{lang}->v_escape;
		my $masking = $self->masking($expression);
		join "", $begin, $masking, $end
	}:
	$word eq "raw"? do {	# без экранирования html
		$in=0;
		my ($begin, $end) = $self->{lang}->v_raw;
		my $masking = $self->masking($expression);
		join "", $begin, $masking, $end
	}:
	do {	# вывод или выполнение без вывода, если есть =
		my $masking = $self->masking($WORD . $expression, 0, my $assign);
		if($assign) {
			$masking
		} else {
			$in = 0;
			my ($begin, $end) = $self->{lang}->v_escape;
			join "", $begin, $masking, $end
		}
	};

		
	if($in && $RET ne "") {
		my ($begin, $end) = $self->{lang}->v_in;
		return join "", $begin, $RET, $end;
	}

	$RET
}

# вызов метода из суперкласса
sub stmt_super {
	my ($self) = @_;
	
	my $sk = $+{super_sk};
	my $method = $+{super_call};
	
	my $element = $self->current_class;
	
	$self->error("super не в классе") if !$element;
	
	my $sub = $self->current_sub;
	
	$self->push(stmt=>$sk) if $sk;
	
	$sub->{block_name}?
		$self->{lang}->template_super($method // $sub->{block_name}, $sk):
		$self->{lang}->super($method // $sub->{sub_name}, $sk, $method)
}

# объявление класса
sub stmt_class {
	my ($self, $end1, $end2, $its_module, $its_object) = @_;
	
	my $with = $+{with};
	my $with_args = $+{with_args};
	
	my ($begin, $end);
	
	my $top = $self->etop;
	my $in_module = $top->{stmt} eq "module";

	my $real_cls = my $cls = $+{class};
	$cls = $top->{class_name} . "::" . $cls if $in_module;
	
	my $extends = $+{extends};
	# в модуле расширяем
	$extends = $top->{inherits} if !defined $extends and $in_module;

	
	$self->error("class: with можно использовать только с object") if $with && !defined $its_object;
	
	$self->error("object with пуст") if $with && $with_args =~ /^\s*$/;
	
	# добавляем подпрограмму, если класс в модуле
	my $add_module_sub;
	if($in_module) {
		my $module = $top->{class_name};
		my $sub = lcfirst $real_cls;
		$sub =~ s/::([A-Z])/ ucfirst $1 /ie;
		$add_module_sub = $self->{lang}->modulesub($module, $sub, $cls);
	}
	
	if($its_module) {
		($begin, $end) = $self->{lang}->module($cls, "R::View::Module");
	}
	else {
		($begin, $end) = $self->{lang}->class($cls, $extends);
	}
	
	if($its_object) {
	
		if($with) {
			$with_args = $self->masking($with_args);
			#$with_args =~ s/;\s*$//;
		}
	
		my ($obegin, $oend) = $self->{lang}->object($cls);
		$end = join "", $end, $obegin, $with_args, $oend;
	}
	
	$self->{class}{$cls} = 1;
	
	$end = join "", $end1, $end, $end2;
	
	$self->push(stmt => ($its_module? "module": "class"), class_name => $cls, end => $end, @_);
	
	$self->top->{inherits} = $extends if $its_module;
	
	$add_module_sub . $begin
}

# подпрограмма
sub stmt_sub {
	my ($self) = @_;

	my $name = $+{sub};
	my $sub_args = $+{sub_args};
	my $sub_then = $+{sub_then};
	my $endline = $self->{lang}->endline($+{rem}, $+{re_endline});
	
	my $class = $self->empty? undef: $self->top->{class_name};
	
	
	my $class_in = $+{sub_in}? ($+{sub_self}? "$class$+{sub_in}": $+{sub_in}): undef;
	$class = $class_in if defined $class_in;
	
	my @args = split /$re_space_ask,$re_space_ask/, $sub_args;
	
	# my $NAME = "SUB__$name";
	my ($begin, $end);
	if($name =~ /^\W/) {
		$name =~ s!^"(.+)"$!$1!;
		$self->error("оператор может быть только в классе") if !$class;
		# # чтобы получить корректное имя переводим в 16-е значение
		# $NAME = "OVL__" . join "", map { sprintf "%02x", ord $_ } split /./, $name;
		
		($begin, $end) = $self->{lang}->overload($name, \@args, $class_in, $class, $endline);
	}
	else {
		($begin, $end) = $self->{lang}->sub($name, \@args, $class_in, $class, $endline);
	}
	
	my @add;
	push @add, endline => 1 if $sub_then;
	push @add, class_name => $class if defined $class;
	
	$self->push(stmt=>"sub", end=>$end, sub_name => $name, @add);
	
	$begin
}


# блок - подпрограмма без имени
sub stmt_do {
	my $self = shift;

	my $sub_then = $+{sub_then};
	my $endline = $self->{lang}->endline($+{rem}, $+{re_endline});
	my @args = split /$re_space_ask,$re_space_ask/, $+{sub_args};
	my $prevop = $self->top->{prevop};
	my $counter = $self->top->{counter};
	
	my ($begin, $end) = $self->{lang}->do($prevop || $counter==0, \@args, $endline);
	#msg1 $begin, $end, $prevop, \@args, $endline;
	$self->push(stmt=>"do", end=>$end, @_);
	$self->top->{endline} = 1 if $sub_then;
	
	$begin
}


# начало цикла
sub stmt_for {
	my ($self, $end1, $end2) = @_;
	$self->error("for k, v, i можно использовать только с of") if $+{for_i} && !$+{for_of};

	my $for_k = $+{for_k};
	my $for_v = $+{for_v};
	my $for_i = $+{for_i};
	
	my ($begin, $then, $end);
	
	if($+{for_in}) {
		($begin, $then, $end) = $self->{lang}->for_in($for_k, $for_v);
		
	} elsif($+{for_of}) {
		($begin, $then, $end) = $self->{lang}->for_of($for_k, $for_v, $for_i);
	}
	else {
		($begin, $then, $end) = $self->{lang}->for($for_k, $for_v);
	}
	
	$self->push(stmt=>"for", then=>$then, end => join "", $end1, $end, $end2);
	$begin
}

# возвращает текущий класс по стеку
sub current_class {
	my ($self) = @_;
	
	my $stack = $self->{stack};
	
	# просматриваем с конца
	for(my $i = @$stack-1; $i>=0; $i--) {
		my $el = $stack->[$i];
		return $el if exists $el->{class_name} or $el->{stmt} eq "template";
	}

}

# возвращает текущую подпрограмму или блок по стеку
sub current_sub {
	my ($self) = @_;
	
	my $stack = $self->{stack};
	
	# просматриваем с конца
	for(my $i = @$stack-1; $i>=0; $i--) {
		my $el = $stack->[$i];
		return $el if $el->{stmt} eq "sub" or $el->{stmt} eq "block";
	}

}



# добавляет ; для вывода, если есть выражение
sub masking_quote {
	my ($self, $masking) = @_;
	my $masking = $self->masking($masking);
	return $masking =~ /^\s*$/? $masking: "$masking;";
}

# возвращает название блока
sub get_name {
	my ($self, $name) = @_;
	local ($`, $', $&);
	
	$name = substr $self->file, length $self->dir if !defined $name;
	
	$name =~ s!^/?!$app->{project_name}/!;
	$name =~ s!\.[^/]+$!!g;
	$name =~ s![^/\w]!__!g;
	$name =~ s!/!::!g;
	$name =~ s!^\d!_$&!;
	

	$name
}

# отображает операции со стеком в лог
sub trace {
	my ($self, $op) = @_;
	
	my $trace = $self->{trace};
	if( defined($trace) && $self->{file} eq $trace ) {
		my $top = $self->top;
		my $stmt = $top->{stmt};
		my $class = $top->{class_name};
		my $sub = $top->{sub_name};
		my $name = $top->{name} // "";
	
		my $after = $stmt eq "sub"? "$sub :$class": $stmt eq "class"? $class: $name;
		
		$app->log->info( ":space", "$self->{lineno}:", ($op eq "+"? ":red": ":bold blue"), $op, $stmt, $after );
	}
	
	$self
}

# выбрасывает ошибку
sub error {
	my ($self, $msg) = @_;
	local ($_, $`, $', $&);
	
	$app->log->error( "$self->{file}:$self->{lineno}: $msg", $self->{stack} );
	
	die "$self->{file}:$self->{lineno}: $msg";
}

# проверяет параметры на верхушке стека и выбрасывает ошибку, если они не совпадают
sub check {
	my $self = shift;
	my $top = $self->top;
	for(my $i=0; $i<@_; $i+=2) {
		next if $_[$i] eq "e";
		if( $top->{$_[$i]} ne $_[$i+1] ) {
			my %check = @_;
			$self->error("$check{stmt}: не совпадает $_[$i] в стеке. $check{e}");
		}
	}
	$self
}

# записывает в стек
sub push {
	my $self = shift;
	
	my $push = {@_};
	
	push @{$self->{stack}}, $push;
	
	$self->trace("+");
	
	$self
}

# выбрасывает из стека
sub pop {
	my ($self) = @_;
	my $count = @{$self->{stack}};
	$self->error("нет элементов в стеке. Лишний <% end %>") if $count == 0;
	
	$self->trace("-");
	
	pop @{$self->{stack}};
}

# просматривает вершину стека
sub top {
	my ($self) = @_;
	my $count = @{$self->{stack}};
	$self->error("нет элементов в стеке") if $count == 0;
	$self->{stack}->[$count-1];
}

# просматривает вершину стека, если в стеке ничего нет выдаёт {}
sub etop {
	my ($self, $n) = @_;
	my $count = @{$self->{stack}} - $n;
	$count>0? $self->{stack}->[$count-1]: {};
}

# стек пуст
sub empty {
	my ($self) = @_;
	@{$self->{stack}} == 0;
}


# возвращает текущий класс
# sub get_class {
	# my ($self) = @_;
	# my $stack = $self->{stack};
	# my $class = undef;
	# for(my $i=@$stack; $i>=0; $i--) {
		# my $top = $stack->[$i];
		# $class = $top->{class_name}, last if exists $top->{class_name};
	# }
	
	# $class
# }

# возвращает функцию метафильтра по имени
sub metafilter {
	my ($self, $name) = @_;
	my $ref = "R::View::Metafilter::$name";
	$self->error("нет метафильтра $name") if !*{$ref}{CODE};
	\&$ref
}

# возвращает экшены
sub routers {
	my ($self) = @_;
	my $route = $self->{route};
	while(my ($key, $dispatcher) = each %$route) {
		if(!defined $dispatcher->sub) {
			die "не определена sub для роутера $key"
		}
	}
	
	return %$route;
}

# для вставки в html
$app->html;
*R::View::Views::escapeHTML = \&R::Html::_escape;

# рендерит в output
sub render {
	my ($self, $name, $data, $output) = @_;
	$self->{lang}->render($name, $data, $output);
	$self;
}

# рендерит и возвращает текст
sub renderis {
	my ($self, $path, $data) = @_;
	my $output = [];
	$self->render($path, $data, $output);
	join "", @$output;
}

# вычисляет выражение на языке шаблона
sub eval {
	my ($self, $code, $data) = @_;
	
	local($self->{stack}, $self->{lineno}, $self->{INHERITS}, $self->{file});

	my $path = "EXAMPLE";
	$self->{file} = $path;	
	$self->{stack} = [];
	$self->{lineno} = 1;
	$self->{INHERITS} = undef;

	my $name = $self->get_name($path);
	
	$code = $self->mask($code);
	$code = $self->{lang}->foreval($code);
	
	my $from = $self->{lang}->len_classes;

	#msg1 ":empty", "\n\n", $code, "\n";
	
	my @res = $self->{lang}->eval( $code );
	die $@ if $@;
	
	$self->init_classes($from);

	@res
}

# хелпер для вывода кода в лог
sub _show_error {
	my $e = $@;
	my ($code) = @_;
	
	my $i=1;
	my @code = map { ("\n", ":dark red", sprintf("%02d ", $i++), ":reset", ":bold black", $_) } split /\n/, $code;
	msg ":empty", "\n", @code, "\n";
	die $e if $e;
}

# создаёт отображение из текста и вычисляет его
sub create {
	my ($self, $view, $data, $path) = @_;
	$self->{file} = $path //= "EXAMPLE";
	my $code = $self->parse($view, $path);
	my $from = $self->{lang}->len_classes;

	$self->{lang}->eval($code);
	_show_error($code) if $@;
	
	$self->init_classes($from);
	
	$self->{file} = undef;

	my $res = eval { $self->renderis($path, $data) };
	_show_error($code) if $@;
	
	$_[4] = $code;
	
	$res
}

# логирует парсинг
sub createlog {
	my $self = shift;
	my ($view, $data, $path) = @_;
	my $trace = $self->{trace};
	$self->{trace} = $path // "EXAMPLE";
	my $res = $self->create($view, $data, $path, my $code);
	$self->{trace} = $trace;
	
	_show_error($code);
	
	$res
}


# запускает сценарии
sub scenario {
	my $self = shift;
	
	$app->file("var/look")->rm;
	
	my $view = $self->dir;
	my $dir = $self->scenario_dir;
	
	#$self->{lang}->clear_classes;
	
	# загружаем сценарии
	my $files = $app->file($dir)->find("-f", sub {
		my $file = $app->file(my $x=$_);
		my $template = $file->subdir($dir, $view)->exts("html");
		if( !$template->exists ) {
			msg ":space red", "удалён", ":reset", $file->path, $template->path;
			$file->rm;
			0
		} else {
			require $file->path;
			1
		}
	});
	
	$self->init_classes;
	
	my $scnames = [ $files->map(sub { $_->subdir($dir)->exts("")->path }) ];
	my @sc;
	if(@_) {
		
		for my $sc (@_) {
			if($sc =~ s/\+$//) {
				my $i = 0;
				push @sc, grep { $i || $sc eq $_? do { $i=1; $_ }: () } @$scnames;
			}
			else {
				push @sc, $sc;
			}
		}
	}
	
	# выполняем
	for my $sc (@_? @sc: @$scnames) {
	
		$app->log->info(":on_red yellow", $sc);
	
		$sc =~ s/\//::/g;
		$sc = "__sc__" . $app->project_name . "::${sc}";
		die "нет указанного сценария" if !*$sc{CODE};
		(\&{$sc})->();
	}
	
}

# подключает скрипт, написанный на R::View
# получает путь к скрипту
# возвращает класс
sub require {
	my ($self, $class) = @_;
	
	return $class if exists $self->{class}{$class};
	
	local ($`, $', $&);
	my $ag = $class;
	$ag =~ s!::!/!g;
	$ag .= ".ag";
	
	# перебираем пути в которых ищем скрипт
	for my $path (@{$self->{inc}}) {
		my $file = "$path/$ag";
		next if !-e $file;
		my $cc = $app->file($file)->ext("ag.pm")->path;
		if(!-e $cc or -M $cc > -M $file) {
			#$self->parsefile($file, $cc);
			$app->file($cc)->write( $self->masking( $app->file($file)->read ) );
		}
		
		require $cc;
		
		die "после подключения файла `" . $file . "` класс не появился" if !exists $self->{class}{$class};
		
		#$self->{INC}{$ag} = $class;
		
		return $class;
	}
	
	die "Файл `$ag` не найден";
}


1;