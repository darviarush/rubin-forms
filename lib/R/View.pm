package R::View;
# шаблонизатор

use common::sense;
use R::App;
use R::Re;
#use R::View::Filter;
use R::View::Metafilter;


has qw/compile_dir scenario_dir dir file outfile before begin ag/;

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
		
		route => {},			# все роутеры route->{key} = [1-<% ACTION %>|2-on|0-cls, cls, sub|sub_name]
		
		ag => $app->syntaxAg,		# синтаксический анализатор
		
		INHERITS => undef,		# вспомогательная для шаблонов
		langs => {},			# кэш языков
		lang => undef,			# драйвер текущего языка
		metafilter => $app->ini->{design}{metafilter},	# наименования дефолтных метафильтров
		metafilters => [],		# метафильтры
		meta => {},				# данные метафильтров - очищаются при завершении шаблона
		INC => {},				# подключённые шаблоны и файлы кода => класс
		inc => ["."],			# пути в которых искать шаблоны и файлы кода
		class => {},			# скомпилированный класс
	}, ref $cls || $cls;
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
	$self->{ag}{lang}->init_classes($from // 0);
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
	
	%{$self->{meta}} = ();
	$self->{INHERITS} = undef;
	
	$self->ag( $app->syntaxAg->new );
	
	#$self->ag->lang("perl") if !$self->{lang};
	
	$self->ag->premorf($name);
	$name //= $self->{file};
	
	my $class = $self->get_name($name);
	
	$self->ag->push("TEMPLATE", class=>$class, block => "__RENDER__");
	
	# если указаны метафильтры - фильтруем
	my $metafilter = $self->{metafilters};
	if(my $metafilters = $self->{metafilter}) {
		@$metafilter = map { $self->metafilter($_) } split /\s+/, $metafilters;
	}
	
	my $prev;	# предыдущая лексема или undef
	
	my $html = sub {
		my $html = $+{html};
		if(length($html))	{
			local(%+);
			
			$self->{lineno} += $app->perl->lines($html);
		
			for my $filter (@$metafilter) {
				$html = $filter->($self, $html, $prev);
			}
			
			$prev = $html;
			$html =~ s/['\\]/\$&/g;
		}
		$html
	};
	
	my $HTML;
	
	while( $buf =~ m{
	
	(?<html> .*? )

	(?:
	
		<% $re_space_ask (?: (?<comment> \#) | (?<word> \w+ ) $re_space_ask )? (?<expression> .*? ) %>  |
		
		\$(?<id>$re_id([\.:]$re_id)*) 		 |
		
		<\*\*\* (?<comment>.*?) \*\*\*>		 |
		
		$
	)
	
	}isgnx ) {
		my $h=&$html;
		
		exists $+{comment}? do {
			$self->{lineno} += my $i = $app->perl->lines($+{expression} // $+{comment});
			#$self->atom('COMMENT', html=>$h, lines=>("\n" x $i))->op('CAT')
		}:
		exists $+{id}? $self->expression($+{id}):
		exists $+{expression}? $self->expression($+{expression}, $+{word}):
		"";
	
	}
	
	# у темплейта не должно быть завершающего end
	$self->ag->pop("TEMPLATE");
	
	#$self->error("стек не пуст: нет <% end " . $self->top(1)->{stmt} . " %>") if @{$self->{stack}}>1;
	
	my $top = $self->{ag}{stack}[-1];
	
	# код, который выполнится при загрузке скрипта
	my $begin = $self->{begin};
	$top->{begin} = @$begin? do { my $ret = " " . join "", @$begin; @$begin = (); $ret }: "";
	
	my $out = $self->ag->postmorf;
	
	%{$self->{meta}} = ();
	
	$out
}


# выражение в <% %>
sub expression {
	my ($self, $expression, $word) = @_;
	local ($&, $_, $`, $');
	
	my $WORD = "";
	
	#$WORD = $&, $word = lc $1 if $expression =~ s/^([a-z_]\w*)$re_space_ask//io;
	
	my $top = $self->top;
	
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
	$self->lang->can("render")->($self, $name, $data, $output);
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
	my ($self, $text, $data) = @_;
	
	local($self->{stack}, $self->{lineno}, $self->{INHERITS}, $self->{file});

	$self->{INHERITS} = undef;
	
	my $rootsk = $app->perl->qq("¥");
	
	my $code = $self->premorf->push($rootsk)->masking($text)->pop($rootsk)->postmorf;
	
	$code = $self->lang->can("foreval")->($self, $code);
	
	my $from = $self->ag->lang->can("len_classes")->($self);

	#msg1 ":empty", "\n\n", $code, "\n";
	
	my @res = $self->ag->lang->can("eval")->( $self, $code );
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
	$self->{file} = $path //= $app->perl->q("eval");
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
	$self->{trace} = $path //= $app->perl->q("eval");
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