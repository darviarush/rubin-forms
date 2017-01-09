package R::Syntax::Ag;
# синтаксис языка Бэйсик

use base R::Syntax;

use common::sense;
use R::App;
use R::Re;

$Nil::INC = [$app->file(__FILE__)->file( "/../../../ag" )->abs->path];
#%Nil::REQUIRE;

my $BASICSYNTAX = $app->syntax->new(name => 'ag')->lang("perl");
my $STRINGSYNTAX = $app->syntax->new(name => 'ag.string');

$BASICSYNTAX->bar($STRINGSYNTAX);

# конструктор
sub new {
	my ($cls) = @_;
	my $self = bless {
		%$BASICSYNTAX,
		trace => 0,
		@_
	}, ref $cls || $cls;
	
	#$self->trace_help if defined $self->{trace};
	
	#msg1 $app->raise->tracex;
	
	$self
}


# маскирование переменных
my $re_string = $R::Re::string;
my $re_id = $R::Re::id;
my $re_endline = $R::Re::endline;
my $re_number = $R::Re::number;

my $re_space = qr/[\ \t]+/;
my $re_space_ask = qr/[\ \t]*/;
my $re_rem = qr/(?:(?:\#|\brem\b)(?<rem>[^\n\r]*))?/i;
my $re_sk = qr/[\[\{\(]/;
my $re_arg = qr/$re_id|\*/on;
my $re_class = qr/(::)?$re_id(::$re_id)*/on;
my $re_class_abs = qr/$re_id(::$re_id)*/on;
my $re_extends = qr!$re_class(?:$re_space_ask,$re_space_ask$re_class)*!;
my $re_class_stmt = qr!
(?<class>$re_class_abs)
(?: [\ \t]+ (?:EXTENDS|INHERITS) [\ \t]+ (?<extends>$re_extends))?
(?<with> [\t\ ]+ with [\t\ ]+ (?<with_args> [^\r\n]+) )?
!xismo;				
my $re_args = qr!
[\ \t]* (?<args>$re_arg (?:$re_space_ask , $re_space_ask $re_arg)*)
!xismo;
my $re_overload_id = qr!
	(?<id>"\w+"|[[:punct:]]+|0\+)
!xismo;
my $re_sub_in = qr/ [\ \t]+ CLASS [\ \t]+ (?<sub_in>(?<sub_self>::)?$re_class) /xn;
my $re_args_then = qr/ $re_space (?<then> \b THEN \b ) | $re_args (?<then> \b THEN \b ) | ( $re_args )? /ixno;
my $re_then = qr/ (?<re_endline> $re_space_ask \b THEN \b) | $re_rem $re_endline /xn;
my $re_for = qr!
(?<for_k>$re_id) (?: $re_space_ask,$re_space_ask (?<for_v>$re_id) (?: $re_space_ask,$re_space_ask (?<for_i>$re_id) )? )? (?: $re_space (?<for_in>IN) \b | $re_space (?<for_of>OF) \b | $re_space_ask = )
!xismo;
# my $re_gosub_after = qr{
# \b [\ \t]* (?! [ !\+\-\*/<>=  \)\}\] \|& \? .:,; \r\n ] | %\s |  (?:or|and|not|eq|ne|le|ge|lt|gt|then|else|end|cmp|from) \b | $ )
# }xismo;

#\p{Uppercase}

# describe context it Given

# ключевые слова:
# super null extends action of block process include raw wrapper eq ne le ge lt gt keys values use sort scenario pairmap map grep reduce from repeat self this me ucfirst lcfirst uc lc ref cmp push pop undef next last redo return pairs or and not eq ne le ge lt gt scalar msg msg1 keys values exists closure length use push pop shift unshift splice delete defined wantarray



{
my $s = $BASICSYNTAX;

$s->tr("yf",  qw{		.$word .word :word 	});
$s->td("xfy", qw{		.$word() .word() :word()	.$word[] .word[] :word[]	.$word{} .word{} :word{}	});
$s->td("xfy", qw{		word() word[] word{}	});
$s->tr("fx",  qw{		@	%		});
$s->tr("yf",  qw{		++ --			})->td("fy", qw{ ++ -- });
$s->tr("fy",  qw{  		length delete })->td("xf", qw{  ? instanceof }); # ?!
$s->tr("yfx", qw{		^				});
$s->tr("fy",  qw{ 		+ - ! +~		});
$s->tr("xfy", qw{		=~ !~	~		});
$s->tr("xfy", qw{		* / % mod **		});
$s->tr("xfy", qw{		+ - .				});
# in perl in this: named unary operators
$s->tr("xfy", qw{		+< +>				});
$s->tr("xfy", qw{		+&					});
$s->tr("xfy", qw{		+|  +^				});
$s->tr("xfx", qw{		< > <= >= lt gt le ge		});
$s->tr("xfx", qw{		== != eq ne  <=> cmp 		});			# ~~
$s->tr("xfy", qw{		in of isa can				});
$s->tr("xfy", qw{		&&					});
$s->tr("xfy", qw{		|| ^^ ?				});
$s->tr("xfx", qw{		.. ...  to  step		});
$s->tr("xfy", qw{		, =>		})->td("yf",  qw{ 	,		})->td("fy", qw{	=>		});
$s->tr("xfx", qw{		split		})->td("yfx", qw{	join	})->td("xf", qw{ split })->td("yf", qw{ join });
$s->tr("yfx", qw{		-> = += -= *= /= ^= &&= ||= ^^=   and= or= xor=  ,= =, .= 	}); # goto last next redo dump
#$s->tr("xfx", qw{	list operators (rightward)});
$s->tr("yfx", qw{		|						});
$s->tr("xfx", qw{		explode		})->td("yfx", qw{		implode		})->td("xf", qw{ explode })->td("yf", qw{ implode });
$s->tr("fy",  qw{		not						});
$s->tr("xfy", qw{		and						});
$s->tr("xfy", qw{		or	xor					});
$s->tr("yfx", qw{		as	is					});
$s->tr("fx",  qw{		return					});

$s->tr("xfy", qw{	;	})->td("yf", qw{	;	})->td("fy", qw{	;	});
$s->tr("xfy", qw{	\n	})->td("yf", qw{	\n	})->td("fy", qw{	\n	});
$s->tr("xfy", qw{		THEN	ELSEIF	ELSE	UNTIL	FROM	CATCH	});


#$s->tr("xfy", qw{		CAT						});			# операция конкантенации в шаблонах


### дополнительные опции операторов



$s->opt("word()", 		re => qr{		(?<var>$re_id) \(			}x);
$s->opt("word[]", 		re => qr{		(?<var>$re_id) \[			}x);
$s->opt("word{}", 		re => qr{		(?<var>$re_id) \{			}x);


$s->opt(":word",		re => qr{		: (?<var>$re_id)			}x);
$s->opt(":word()",		re => qr{		: (?<var>$re_id) \(			}x);
$s->opt(":word[]",		re => qr{		: (?<var>$re_id) \[			}x);
$s->opt(":word{}",		re => qr{		: (?<var>$re_id) \{			}x);

$s->opt(".word",		re => qr{		\. (?<var>$re_id)			}x);
$s->opt(".word()",		re => qr{		\. (?<var>$re_id) \(		}x);
$s->opt(".word[]",		re => qr{		\. (?<var>$re_id) \[		}x);
$s->opt(".word{}",		re => qr{		\. (?<var>$re_id) \{		}x);

$s->opt(".\$word",		re => qr{		\.\$ (?<var>$re_id)			}x);
$s->opt(".\$word()",	re => qr{		\.\$ (?<var>$re_id) \(		}x);
$s->opt(".\$word[]",	re => qr{		\.\$ (?<var>$re_id) \[		}x);
$s->opt(".\$word{}",	re => qr{		\.\$ (?<var>$re_id) \{		}x);

$s->opt(".?word",		re => qr{		\.\? (?<var>$re_id)			}x);
$s->opt(".?word()",		re => qr{		\.\? (?<var>$re_id) \(		}x);
$s->opt(".?word[]",		re => qr{		\.\? (?<var>$re_id) \[		}x);
$s->opt(".?word{}",		re => qr{		\.\? (?<var>$re_id) \{		}x);



$s->opt("=>", re => qr{ (?<id>$re_id)? \s* => }xn );
$s->opt("=", sub => sub {	$_[0]->{assign} = 1 });

$s->opt("instanceof", re => qr{ \b instanceof $re_space (?<class> $re_class_abs ) }xin);

$s->opt("|", re => qr{ \| ( (?<param> $re_id (, $re_id)*)?  (?<op> map | grep | reduce | sort | order ) (?<arity> \d+ )? \b )? }xni, sub => sub {
	my ($self, $push) = @_;
	$self->error("| $push->{op} не может иметь и параметры $push->{param} и арность $push->{arity} одновременно") if defined $push->{param} and defined $push->{arity};
	$self->error("может быть только |sort2") if $push->{op} eq "sort" and defined $push->{arity} and $push->{arity} != 2;
	$push->{op} //= "map";
});

$s->x('\n');
$s->opt('\n', re => "$re_rem $re_endline", sub => sub {
	my ($self, $push) = @_;
	$self->{lineno}++;
	my $br = $self->endline->top;
	if($br->{then}) {
		$self->op("THEN");
		delete $br->{endline};
	}
});

$s->opt("THEN", sub => sub {
	my ($self, $push) = @_;
	my $br = $self->check("THEN", then=>1)->top;
	$br->{endline} = 1;
	delete $br->{then};
	$push->{then} = $br->{stmt};
});
$s->opt("ELSEIF", sub => sub {
	my ($self, $push) = @_;
	my $br = $self->check("ELSEIF", stmt=>"IF", else=>"", then=>"")->top;
	$br->{then} = 1;
});
$s->opt("ELSE", sub => sub { my ($self, $push) = @_; $self->check("ELSE", stmt=>"IF", else=>"", then=>"")->top->{else} = 1 });
$s->opt("UNTIL", sub => sub { my ($self, $push) = @_; $self->check("UNTIL", stmt=>"REPEAT")->top->{endline} = 1 });
$s->opt("FROM", sub => sub { my ($self, $push) = @_; my $top = $self->endline->top; $self->error("FROM должен использоваться после MAP, PAIRMAP, GREP, SORT, NSORT, QSORT или REDUCE") if $top->{stmt} !~ /^(?:map|grep|[nq]sort|reduce|pairmap)$/; $push->{endline} = $push->{gosub} = 1 });



### скобки

$s->br(qw{			(	)			});
$s->br(qw{			[	]			});
$s->br(qw{			{	}			});

$s->br(qw{			FOR		} => sub { my($self, $push) = @_; $push->{then}=1 } => qw{		END		});
$s->br(qw{			WHILE	} => sub { my($self, $push) = @_; $push->{then}=1 } => qw{		END		});
$s->br(qw{			IF		} => sub { my($self, $push) = @_; $push->{then}=1 } => qw{		END		});
$s->br(qw{			BEGIN		END		});
$s->br(qw{			ON	} => qr{ \b ON $re_space (?<route>$re_string) }x => sub {
	my ($self, $push) = @_; 
	$push->{route}=$self;
	$app->perl->unstring($push->{route});
}, "END");

$s->opt("END", sub => sub {
	my ($self, $push) = @_;
	my $top = $self->top;
	$self->error("$top->{stmt}: end встречен до then") if $top->{then};
});

$s->br(qw/			REPEAT				/);
$s->br(qw/			MAP					/);
$s->br(qw/			PAIRMAP				/);
$s->br(qw/			GREP				/);
$s->br(qw/			REDUCE				/);
$s->br(qw/			SORT				/);
$s->br(qw/			QSORT				/);
$s->br(qw/			NSORT				/);

$s->br("CLASS" => qr{ \b CLASS $re_space $re_class_stmt }ix => sub {
	my ($self, $push) = @_;
	my $S = $self->{stack};
	my $class;
	for(my $i=$#$S; $i>=0; $i--) {
		$class = $S->[$i]{class}, last if $S->[$i]{stmt} eq "CLASS";
	}
	$push->{class} = "${class}::$push->{class}" if defined $class;
	if($push->{extends}) {
		$push->{extends} = [ map { /^:/? "$push->{class}$_": $_ } split /\s*,\s*/, $push->{extends} ];
	}
	else {
		$push->{extends} = ["Nil"] if $push->{class} ne "Nil";
	}
} => "END");
#$s->br("OBJECT" => qr{ \b OBJECT $re_space $re_class_stmt }ix => "END");
#$s->br("MODULE" => qr{ \b MODULE $re_space $re_class_stmt }ix => "END");

$s->br("SUB" => qr{ \b SUB $re_space (?<SUB> $re_id ) $re_args_then }ix => sub {
	my ($self, $push) = @_;
	if($push->{then}) {
		$push->{endline}=1; 
		delete $push->{then};
	}
} => "END");
#$s->br("SUB_CLASS" => qr{ \b SUB $re_space $re_id $re_args_then }ix => "END");

#$s->br("DEF" => qr{ \b DEF $re_space $re_sub (?<endline> $re_space_ask THEN \b)? }ix => "END");
#$s->br("LET" => qr{ \b LET $re_space $re_sub (?<endline> $re_space_ask THEN \b)? }ix => "END");
$s->br("DO" => qr{ \b DO $re_args  }ix => "END");

$s->br("new_apply" => qr{ 	\b NEW $re_space (?<new>$re_class) \(	}ix => ")");

### операнды

$s->x("()");
$s->x("[]");
$s->x("{}");

$s->x("self"		=> qr{ 	\b	(?:	self | this | me	)	\b 	}x);
$s->x("app");
$s->x("q");
$s->x("user");
$s->x("super");
$s->x("nothing" => qr/\b(?: null | nothing | undef | nil) \b/x);
$s->x("pi");
$s->x("nan");
$s->x("inf");
$s->x("true");
$s->x("false");
$s->x("paramarray" => qr/\b(?:paramarray | arguments)\b/x);
$s->x("throw" => qr/ \b (?: die | throw | raise ) \b /x => sub { $b->{gosub} = $b->{endline} = 1 });
$s->x("next");
$s->x("last");
$s->x("redo");
$s->x("wantarray");

$s->x("new"		=> qr{ 	\b NEW $re_space (?<new>$re_class) 	}ix);
$s->x("var"		=> qr{ 	(?<var>$re_id) 						}x);
$s->x("hex"		=> qr{	0x[\da-f_]+	}ix);
$s->x("bin"		=> qr{	0b[10_]+	}ix);
$s->x("radix"	=> qr{	(?<radix> (?<rad>\d+) r (?<num> [\da-z_]+ ) )	}ix => sub {
	my ($self, $push)=@_;
	$self->error("$push->{radix} - система счисления не может быть 0") if $push->{rad} == 0;
	$self->error("$push->{radix} - система счисления должна быть не более 62-х")  if $push->{rad} > 62;
	$push->{radix} = $app->perl->from_radix($push->{num}, $push->{rad});
});
$s->x("num"		=> qr{ 	(?<num> -? ( \d[\d_]*(\.[\d_]+)? | \.[\d_]+ )	( E[\+\-][\d_]+ )?	)			}ixn);
#$s->x("regexp"	=> qr{ 	" (?<QR> (?:[^"]|\\")* ) "! (?<qr_args> \w+ )? 	}x);

$s->x("string"	=> qr{	( " (?<string> (?:\\"|""|[^"])* ) " | ' (?<string> (?:\\'|''|[^'])* ) ' ) (?<qr>! (?<qr_args> \w*))?	 }xn => sub {
	my ($self, $push) = @_;
	my $sk = $push->{qr}? "qr": "string";
	$self->checkout("ag.string")->push($sk)->masking($push->{string})->pop($sk)->checkout("ag")->assign($push);
});

### какие операторы в каких скобках могут существовать
$s->in("on"		=> qw{		addhandler		});
$s->in("try"	=> qw{		catch			});
$s->in("if"		=> qw{		else elseif		});
$s->in("repeat"	=> qw{		until			});

# устанавливаем обработчик на начало pop
my %STOPOP = $app->perl->set("\n", qw/ ; THEN ELSE ELSEIF UNTIL FROM | /);
my %PULLOP = qw(	:word :word()	.$word .$word()		.word .word()	var word()	);

#$s->pull(join(" ", keys %PULLOP) => \&onpull);

sub onpull {
	my ($self, $i) = @_; 
	my $A = $self->{stack}[-1]{"A+"};
	$#$A == $i && return;
	my $me = $A->[$i];
	$me->{space} || return;	# нужен space
	my $op = $A->[$i+1];
	my $op_stmt = $op->{stmt};
	
	# следующий кроме оператора
	if( !$self->{PREFIX}{$op_stmt} && !$self->{INFIX}{$op_stmt} ||
	
	# следующий prefix оператор и нет такого infix
	$self->{PREFIX}{$op_stmt} && !$self->{INFIX}{$op_stmt} ||
	
	# следующий prefix и infix, но у me есть space, а у оператора - нет
	$self->{PREFIX}{$op_stmt} && $self->{INFIX}{$op_stmt} && length($op->{space})
	) {
		# тогда взять в скобки до \n|;|конца
		msg1 "sk!";
		my $j;
		for($j=$i+1; $j<@$A && !exists $STOPOP{ $A->[$j]{stmt} }; $j++) {}
		return if $j==$i+1;
		my $push = {stmt=>".word.br"};
		$push->{"A+"} = [ splice @$A, $i+1, $j, $push ];
		push @{$self->{stack}}, $push;
		# а потом сделать pop
		$self->pop(".word.br");
		
		# поменять stmt оператора
		$me->{stmt} = $PULLOP{ $me->{stmt} };
	}
	
}

};


# выбрасывает endline
# у всех gosub есть ещё и endline
sub endline {
	my ($self) = @_;
	my $S = $self->{stack};
	while(@$S && $S->[-1]{endline}) {	# если есть endline - сбрасываем
		$self->pop;
	}
	$self
}


########################################### строки ########################################### 
{
my $string = $STRINGSYNTAX;
# отключаем добавление дефолтных лексем
$string->addspacelex(0);

$string->tr("yfx", qw/CAT/)->tr("yf", qw/CAT/);
$string->x(qw/CAT/);
$string->br(qw/exec1/);
$string->opt("exec1", nolex => 1);

$string->opt("CAT", re => qr/ (?<str> [^\$]* ) ( \$ (?<CAT> $re_id([\.:]$re_id)* ) | $ ) /nxs, sub => sub {
	my ($self, $push) = @_;
	$push->{str} =~ s/""|''|\\["']/\\"/g;
	if(exists $push->{CAT}) {
		$self->checkout("ag")->push("exec1")->masking($push->{CAT})->pop("exec1")->checkout("ag.string");
		delete $push->{str};
	}
});
}


########################################### require ###########################################

# добавляем \n
sub morf {
	my ($self, $text) = @_;
	$self->SUPER::morf("$text\n");
}

# возвращает рутовую директорию проекта
sub root {
	my ($self, $path) = @_;
	
	my $file = $app->file($path)->abs;
	
	# находим корень проекта
	my $root;
	my $Aquafile;
	for my $dir ($file->paths->reverse->files) {
		$Aquafile = $file->new("$dir/Aquafile");
		$root = $dir, last if $Aquafile->exists;
	}
	
	die "файл находится не в проекте: создайте Aquafile" if !$root;
	
	$root;
}

# определяет откуда вызывали и загружает Aquafile
sub ag {
	my ($self, $path, @args) = @_;
	
	my $root = $self->root($path);
	
	unshift @$Nil::INC, $root if $Nil::INC->[0] ne $root;
	
	$self->require("Aquafile");
	
	my $class = $self->require( $app->file($path)->abs->subdir($root, "")->path );
	
	$class->new->void(@args);
}

# превращает путь в класс
sub path2class {
	my ($self, $path) = @_;
	
	my $class = $app->file($path)->exts("")->path;
	$class =~ s!/!::!g;
	$class
}



# компилирует файл
sub compile {
	my ($self, $path, $to, $name) = @_;
	
	die "compile: не указан Класс" if !$name;
	die "compile: не указан путь файла" if !$path;
	die "compile: не указано куда компилировать" if !$to;
	
	my $file = $app->file($path);
	my $text = $file->read;
	
	my $cc = $self->new(file => $path);
	
	if($text !~ /^($re_space_ask $re_rem $re_endline)* $re_space_ask (?i: class ) $re_space_ask \Q$name\E/xn) {
		if($text =~ s/^(?<first>($re_space_ask $re_rem $re_endline)* $re_space_ask) (?<last>extends|inherits) \b /$+{first}class $name $+{last}/xin) {
			$cc->{lineno} = 1;
			$text = "$text\nend";
		} else {
			$cc->{lineno} = 0;
			$text = "class $name\n$text\nend";
		}
	}
	
	#msg1 $path, $to, $name, $text;
	
	my $code = $cc->morf( $text );
	$app->file($to)->mkpath->write($code);

	$self
}

# подключает файл как класс или шаблон
# получает рутовую директорию
# если Aquafile ещё не загружен - загружает
sub require {
	my ($self, $path, $INC) = @_;
	
	return $Nil::REQUIRE{$path} if exists $Nil::REQUIRE{$path};
	
	$INC //= $Nil::INC;
	
	#my $to_dir = $Nil::INC->[0];
	
	my $file = $app->file($path);
	my $class = $self->path2class($path);
	my @path = split /\//, $path;
	
	for my $inc (@$INC) {
		my $load = 0;
		
		for(my $i=0; $i<@path; $i++) {
			my $rpath = join "/", @path[0..$i];
			my $f = $app->file("$inc/$rpath");
			
			if($f->exists) {
				my $to = $app->file("$inc/.Aqua/$rpath.pm");
				
				if(!$to->exists || $to->mtime < $f->mtime) {
					$self->compile($f->path, $to->path, $class);
				}
				
				$Nil::REQUIRE{$rpath} = $rpath;
				require $to->path;
				$load = 1;
			}
		}
		return $class if $load;
	}
	
	die "нет " . $app->perl->qq($path);
}

# подключает классы Ag или Perl
sub include {
	my $self = shift;
	

	CLASSES: for my $class (@_) {
	
		next if exists $Nil::CLASSES{$class};
		
		my $path = $class;
		$path =~ s!::!/!g;

		my $INC = $Nil::INC;

		for my $inc (@$INC) {
			$self->require("$path.ag", [$inc]), next CLASSES if -e "$inc/$path.ag";
			#$self->parse("$path.au", [$inc]), next CLASSES if -e "$inc/$path.au";
		}
		
		require "$path.pm";
		
		die "нет new у " . $app->perl->qq($class) if !$class->can("new");
		
		$Nil::CLASSES{$class}++;
	}
	
	@_==1? $_[0]: @_
}



1;
