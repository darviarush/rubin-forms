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
		_lang => undef,	# драйвер текущего языка
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
	if(@_ == 1) {
		my $self = shift;
		$self->{_lang} // $self->lang("perl")->{_lang}
	} else {
		my ($self, $lang) = @_;
	
		if($lang eq "js") { $self->{lang} = $app->use("R::View::Javascript") }
		elsif($lang eq "perl") { $self->{lang} = $app->use("R::View::Perl") }
		else { die "неизвестный язык $lang" }

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


my %CloseTag = qw/ ( ) { } [ ] /;

sub masking {
	my ($self) = @_;
	local ($&, $_, $`, $');
	
	
	while($_[1] =~ m{
	
	(?<=[\w\}\]\)"'\+\-!])$re_rem(?P<endline>$re_endline) (?{ $self->stmt_endline; $self->{lineno}++ }) |
	$re_rem(?P<endline_then>$re_endline) (?{ $self->{lineno}++ }) |
	
	;				(?{ $self->endgosub->code('sepexpression') }) |
	
	" (?P<QR> (?:[^"]|\\")* ) "! (?P<qr_args> \w+ )?  (?{ $self->code('regexp') }) |
	
	\[				 				(?{ $self->push('array', tag=>']') }) |
	\{								(?{ $self->push('hash', tag=>"\}") }) |
	\(								(?{ $self->push('group', tag=>')') }) |
	
	(?<end_tag> [\]\}\)] )		 	(?{ $self->stmt_endtag }) |
	
	(?P<string>$re_string) 			(?{ $self->code('string', string=>$self->replace_dollar($+{string})) })  |
	(?P<name> $re_id ) \( 			(?{ $self->push('gosub', tag=>')') })  |
	(?P<key>$re_id) $re_space_ask => 		(?{ $self->code('key') })  |
	
	(?P<method>\.\$|[\.:\$]|::)(?P<name>$re_id)(?P<m_sk> $re_sk | \( )		(?{ $self->stmt_method })  |
	(?P<method>\.\$|[\.:\$]|::)(?P<name>$re_id)(?P<gosub>) $re_gosub_after	(?{ $self->stmt_method }) |
	(?P<method>\.\$|[\.:\$]|::)(?P<name>$re_id)		(?{ $self->stmt_method }) |
	
	(?P<var>$re_id)(?P<var_sk>$re_sk)		(?{ $self->stmt_var }) |
	
	^ (?P<name> [\t\ ]* THEN ) \b		(?{ $self->push("gosub", gosub=>1, endline=>1) })  |
	
	\b (
		self | this | me					(?{ $self->code('self') })  |
		app			 						(?{ $self->code('app') }) 	|
		q		 	(?{ $self->code('q') }) 	|
		user 		(?{ $self->code('user') })  |
		FOR			(?{ $self->push("for", then=>1) })  |
		IN			(?{ $self->check("for", then=>1)->code("in") })  |
		OF			(?{ $self->check("for", then=>1)->code("of") })  |
		TO			(?{ $self->check("for", then=>1)->code("to") })  |
		STEP		(?{ $self->check("for", then=>1)->code("step") })  |
		WHILE		(?{ $self->push('while', then=>1) }) |
		REPEAT		(?{ $self->push('repeat', noend=>1) }) |
		UNTIL		(?{ $self->pop('repeat')->push('until', endline=>1) }) |
		IF			(?{ $self->push('if', then=>1) }) |
		THEN		(?{ my $x=$self->check(then=>1)->endgosub->top; delete $x->{then}; $x->{endline}=1 }) |
		ELSEIF		(?{ $self->check(stmt=>"if", else=>"", then=>"")->endgosub->code('elseif')->top->{then}=1 }) |
		ELSE		(?{ $self->check(stmt=>"if", else=>"", then=>"")->endgosub->code('else')->top->{else}=1 }) |
		END			(?{ $self->stmt_end }) |
		MAP			(?{ $self->push('map', noend=>1) }) |
		PAIRMAP		(?{ $self->push('pairmap', noend=>1) }) |
		GREP		(?{ $self->push('grep', noend=>1) }) |
		REDUCE		(?{ $self->push('reduce', noend=>1) }) |
		SORT		(?{ $self->push('sort', noend=>1) }) |
		FROM		(?{ $self->stmt_from }) |
		addhandler		(?{ $self->check(stmt=>"on")->code('addhandler') }) |
		(?P<paramarray> paramarray | arguments ) 		(?{ $self->code('paramarray') })  |
		BEGIN		(?{ $self->push('begin') }) |
		
		(?P<operator> cmp|mod|xor|or|and|not|eq|ne|le|ge|lt|gt )  		(?{ $self->code('operator') })  |
		
		(?P<word> undef|next|last|redo|return|use|wantarray ) 		(?{ $self->code('word', word=>lc $+{word}) }) |
		
		(?<name> ref|pairs|scalar|defined|length|exists )		(?{ $self->code('unary') }) |

		(?<nothing> null | nothing) 		(?{ $self->code('null') }) |
		true		 						(?{ $self->code('true') }) |
		false								(?{ $self->code('false') })  |
		throw			(?{ $self->push('throw', gosub=>1, endline=>1) }) 
	) \b |
	
	\b super \b (?: \.(?P<super_call> $re_id) (?P<super_sk> \( )? | \b) |
	
	\b (?P<try> try ) \b		(?{ $self->push('try') })  |
	\b (?P<catch> catch ) (?: $re_space (?P<catch_var> $re_id) (?: $re_space AS $re_space (?P<catch_isa> $re_class (?: $re_space_ask , $re_space_ask $re_class )* )? )? )? 
			(?{ $self->check(stmt=>"try")->code('catch') }) |
	
	\b ON $re_space (?P<route>$re_string) 		(?{ $self->push('on', route=>$app->perl->unstring($+{route})) })  |
	
	\b CLASS $re_space $re_class_stmt		(?{ $self->push('class') })  |
	\b OBJECT $re_space $re_class_stmt		(?{ $self->push('object') }) |
	\b MODULE $re_space $re_class_stmt		(?{ $self->push('module') })  |
	\b DEF $re_space $re_sub (?: (?P<sub_then> [\ \t]+ THEN \b) | $re_rem $re_endline) 		
					(?{ $self->push('def', endline=>exists $+{sub_then}) }) |
	\b SUB $re_space $re_sub (?: (?P<sub_then> [\ \t]+ THEN \b) | $re_rem $re_endline) 
					(?{ $self->push('sub', endline=>exists $+{sub_then}) })  |
	\b DO $re_args (?: (?P<sub_then> [\ \t]+ THEN \b) | $re_rem $re_endline)
			(?{ $self->push('do', endline=>exists $+{sub_then}) })  |
	\b NEW $re_space (?P<new>$re_id(?:::$re_id)*)		(?{ $self->code('new') })  |

	
	\@		(?{ $self->code('unarray') }) |
	%		(?{ $self->code('unhash') })  |
	
	(?P<gosub>$re_id) $re_gosub_after		(?{ $self->push("gosub", gosub=>1, endline=>1) })  |
	
	(?P<var>$re_id)			(?{ $self->stmt_var })  |
	(?P<num>$re_number)		(?{ $self->code('num') })  |
	
	# (?P<outdoor> %> ) |
	
	=>	(?{ $self->code('ass_delim') })  |
	(?P<operator> //= | // | \|\|= | \|\| | &&= | && | <<= | >>= | << | >> | <=> | =~ | !~ | \+\+ | -- | ~~ | \*= | \+= | -= | /= | == | != | <= | >= | < | > | ! | - | \+ | \* | / | \^ | ~ | % | \.\.\. | \.\. | \.= | \. | \? | : )
		(?{ $self->code('operator') })  |
	=		(?{ $self->{_assign} = 1; $self->code('assign') })  |
	, 		(?{ $self->code('comma') })  |
	(?P<space> $re_space) | # ничего не делаем, если пробелы
	(?P<nosim> . )		(?{ $self->error("неизвестный науке символ `$+{nosim}`") }) 
	
	}gsxiom) {}
	
	$self
}

# конец строки
sub stmt_endline {
	my ($self) = @_;
	
	my $top = $self->endline->etop;
	
	if($top->{then}) {
		delete $top->{then};
		$self->code("then");
	}
	elsif($top->{stmt} eq "array" || $top->{stmt} eq "hash" || $top->{stmt} eq "group") {
		$self->endunary->code("comma");
	}
	else {
		$self->code("exp");
	}

	$self
}

# закрывающая скобка
sub stmt_endtag {
	my ($self) = @_;
	my $endtag = $+{end_tag};
	$self->endline;
	my $top = $self->top;
	$self->error("нет открывающей скобки к `$endtag`") if $endtag ne $top->{tag};
	$self->pop;
	$self
}

# метод
sub stmt_method {
	my ($self) = @_;
	
	my $method = $+{method};
	my $sk = $+{m_sk};
	my $gosub = exists $+{gosub};
	
	my $stmt =
		$method eq ".\$"? "dotref":
		$method eq "."? "dot":
		$method eq ":"? "colon":
		$method eq "::"? "twocolon":
		"dollar";
	
	if($gosub) {
		$self->push($stmt . "_sk", endline=>1, gosub=>1);
	}
	elsif($sk) {
		$self->push($stmt . "_sk", tag=>$CloseTag{$sk});
	}
	else {
		$self->code($stmt);
	}
	
	$self
}

# переменная, возможно с открытой скобкой
sub stmt_var {
	my ($self) = @_;

	my $sk = $+{var_sk};
	my $six = $+{var};

	my $stmt = $six =~ /^\p{Uppercase}/? 'classname': 'var';
	
	if($sk) {
		$self->push($stmt, name=>$six, tag=>$CloseTag{$sk});
	} else {
		$self->code($stmt, name=>$six);
	}
	
	$self
}

# map ... from ...
sub stmt_from {
	my ($self) = @_;
	
	$self->endline;
	
	my $top = $self->top;

	$self->error("FROM должен использоваться после MAP, PAIRMAP, GREP, SORT или REDUCE") if $top->{stmt} !~ /^(?:map|grep|sort|reduce|pairmap)$/;
	
	$self->pop->push("from", gosub=>1, endline=>1);

	$self
}

# выбрасывает end
sub stmt_end {
	my ($self) = @_;
	
	my $top = $self->top;
	
	$self->error("$top->{stmt} не заканчивается на end") if $top->{noend};
	$self->error("$top->{stmt}: end встречен до then") if $top->{then};

	$self->pop
}


# # выбрасывает then
# sub then {
	# my ($self) = @_;
	# delete $self->check(then=>1, e=>"ожидается then")->top->{then};
	# $self
# }

# выбрасывает endline
sub endline {
	my ($self) = @_;
	while($self->etop->{endline}) {	# если есть endline - сбрасываем
		$self->pop;
	}
	$self
}

# выбрасывает gosub
sub endgosub {
	my ($self) = @_;
	while($self->etop->{gosub}) {
		$self->pop;
	}
	$self
}

# # выбрасывает унарные операции
# sub endunary {
	# my ($self) = @_;
	# while($self->etop->{unary}) {
		# $self->pop;
	# }
	# $self
# }




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

# # аналог parse для кода, а не шаблона
# sub mask {
	# my ($self, $expirience) = @_;
	# #$self->push(stmt=>"mask");
	# $expirience = $self->masking($expirience);
	# $expirience = $self->{lang}->expirience($expirience);
	# #$self->check(stmt=>"mask");
	# #$self->pop;
	# $expirience
# }

# парсит из строки шаблон и возвращает пакет perl
sub parse {
	my ($self, $buf, $name) = @_;
	
	$name //= "EXAMPLE";
	%{$self->{meta}} = ();
	
	$self->{stack} = [];
	$self->{lineno} = 1;
	$self->{INHERITS} = undef;
	
	my $class = $self->get_name($name);
	
	$self->push("TEMPLATE", class=>$class, block => "__RENDER__");
	
	# если указаны метафильтры - фильтруем
	my $metafilter = $self->{metafilters};
	if(my $metafilters = $self->{metafilter}) {
		@$metafilter = map { $self->metafilter($_) } split /\s+/, $metafilters;
	}
	
	my $prev;	# предыдущая лексема или undef
	
	my $tmpl_html = sub {
		my $html = $+{html};
		{
			local(%+);
			
			$self->{lineno} += $app->perl->lines($html);
		
			for my $filter (@$metafilter) {
				$html = $filter->($self, $html, $prev);
			}
			
			$prev = $html;
			$html =~ s/['\\]/\$&/g;
			$self->code('HTML', html=>$html);
		}
		undef
	};
	
	while( $buf =~ m{
	
	(?<html> .*? )		(?{ $tmpl_html->() if length $+{html} }) 

	(?:
	
		<% $re_space_ask GET \b				(?{ $self->push('GET')->masking($buf)->pop('GET') })   |
		
		
		\$(?<id>$re_id([\.:]$re_id)*) 		(?{ $self->push('GET')->masking($+{id})->pop('GET') }) |
		<\*\*\* (?<comment>.*?) \*\*\*>		(?{ $self->{lineno} += my $i = $app->perl->lines($+{comment}); $self->code('COMMENT', lines=>("\n" x $i)) }) |
		$
	)
	
	}isgx ) {}
	
	# у темплейта не должно быть завершающего end
	$self->check(stmt => "TEMPLATE");
	
	$self->error("стек не пуст: нет <% end " . $self->top(1)->{stmt} . " %>") if @{$self->stack}>1;
	
	# # код, который выполниться при загрузке скрипта
	my $begin = $self->{begin};
	$self->top->{begin} = @$begin? do { my $ret = " " . join "", @$begin; @$begin = (); $ret }: "";
	
	my $out = $self->expirience;
	
	$self->pop;
	
	%{$self->{meta}} = ();
	
	$out
}


# возвращает шаблоны языка
sub get_lang_modifiers {
	my ($self) = @_;
	
	my $cache = $self->lang . "::modifiers";
	return \%$cache;
}


# возвращает шаблоны языка
sub get_lang_templates {
	my ($self) = @_;
	
	my $cache = $self->{lang} . "::cashe_templates";
	return \%$cache if %$cache;
	
	my $c = \%$cache;
	
	my $key = $self->lang . "::templates"
	
	while(my ($key, $val) = each %$key) {
		$val =~ s/'/\\'/g;
		$val =~ s/\{\{\s*(\w+)\s*\}\}/', \$_->{$1} ,'/g;
		
		$c->{$key} = eval "sub { join '', '$val' }";
	}

	$c
}



# осуществляет два прохода по дереву кода и формирует код
sub expirience {
	my ($self) = @_;
	
	die "expirience: в стеке должен быть 1-н элемент" if @{$self->{stack}} != 1;
	
	# обход в глубину - модификации дерева
	my $modifiers = $self->get_lang_modifiers;
	my @path = $self->top;
	while(@path) {
		my $node = $path[$#path];
		
		# вызываем модификатор, если мы на элементе впервые
		if(!exists $node->{"&"}) {
			my $fn = $modifiers->{$node->{stmt}};
			$fn->($self, $node, \@path) if $fn;
		}
		
		my $code = $node->{code};
		if($code && $node->{"&"} < @$code) {	# на подэлемент
			push @path, $code->{ $node->{"&"}++ };
		}
		else {
			pop @path;		# удаляем элемент
		}
	}
	
	# формирование кода из шаблонов
	my $templates = $self->get_lang_templates;
	my $out;
	my @path = $self->top;
	while(@path) {
		my $node = $path[$#path];
		
		my $code = $node->{code};
		if($code && $node->{"#"} < @$code) {	# на подэлемент
			push @path, $code->{ $node->{"#"}++ };
		}
		else {
			$_ = pop @path;		# удаляем элемент
			
			$_->{code} = join "", @$code if $code;
			
			my $template = $templates->{ $_->{stmt} };
			die "нет шаблона $_->{stmt} в языке $self->{lang}" if !$template;
			
			if(@path) {
				my $parent = $path[$#path];
				$parent->{code}[$parent->{"#"}-1] = $template->();
			}
			else {
				$out = $template->();
			}
		}
	}
	
	$out
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

# # начало цикла
# sub stmt_for {
	# my ($self) = @_;
	# $self->error("for k, v, i можно использовать только с of") if $+{for_i} && !$+{for_of};
	# $self->push("for", then=>1);
	# $self
# }

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



# # добавляет ; для вывода, если есть выражение
# sub masking_quote {
	# my ($self, $masking) = @_;
	# my $masking = $self->masking($masking);
	# return $masking =~ /^\s*$/? $masking: "$masking;";
# }

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
		my ($k, $v) = @_[$i, $i+1];
		next if $k eq "e";
		if( $top->{$k} ne $v ) {
			my %check = @_;
			$self->error("$check{stmt}: не совпадает $_[$i] в стеке. $check{e}");
		}
	}
	$self
}

# записывает в стек
sub push {
	my $self = shift;
	
	my $push = {%+, 'stmt', @_};
	
	push @{$self->{stack}}, $push;
	
	$self->trace("+");
	
	$self
}

# выбрасывает из стека
sub pop {
	my $self = shift;
	
	$self->check('stmt', @_) if @_;
	
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

# добавляет код к элементу
sub code {
	my $self = shift;
	push @{$self->top->{code}}, {%+, 'stmt', @_};
	$self
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
	
	return $class if $app->perl->exists($class);
	
	local ($`, $', $&);
	my $pag = $class;
	$pag =~ s!::!/!g;

	my $ag = "${pag}.ag";
	my $al = "${pag}.al";
	my $pm = "${pag}.pm";
	
	# перебираем пути в которых ищем скрипт
	
	for my $path (@INC) {
		
		my $load = undef;
		
		my $file = "$path/$ag";
		
		if( -e $file ) {
			my $cc = $app->file($file)->ext("ag.pm")->path;
			if(!-e $cc or -M $cc > -M $file) {
				my $read = $app->file($file)->read;
				# пропускаем пустые строки и комментарии
				# если начинается с класса или модуля с именем нужного нам класса - пропускаем
				# если на inherits - добавляем класс
				my $AddClass = "";
				$self->{lineno} = 1;
				
				if( $read =~ /^(?:[ \t]*(?i:#|rem\b).*[\r\n]+)*(?:((?i:class|module)[ \t]+$class)|((?i:inherits|extends)))/ ) {
				
					if($1) {}
					elsif($2) { $AddClass = "class $class " }
					else { $AddClass = "class $class\n"; $self->{lineno} = 0; }
	
				}
				
				my $sep = /inherits/;
				$app->file($cc)->write( $self->masking( join "", $AddClass, $read, "\nend" ) );
			}
			
			require $cc;
			$load = 1;
		}
		
		$file = "$path/$al";
		
		if( -e $file ) {
			my $cc = $app->file($file)->ext("al.pm")->path;
			if(!-e $cc or -M $cc > -M $file) {
				$self->parsefile($file, $cc);
			}
			
			require $cc;
			$load = 1;
		}
		
		$file = "$path/$pm";
		
		if( -e $file ) {
			require $file;
			$load = 1;
		}
		
		next if !$load;
		
		die "после подключения файла `" . $file . "` класс не появился" if !$app->perl->exists($class);
		
		# TODO: тут нужно подгрузить все классы, к-х нет, но которые используются в файле
		
		return $class;
	}
	
	die "Файл `$ag` или `$al` или `$pm` не найден";
}


1;