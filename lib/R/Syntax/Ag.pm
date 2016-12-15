package R::Syntax::Ag;
# синтаксис языка Бэйсик

use base R::Syntax;

use common::sense;
use R::App;
use R::Re;

my $BASICSYNTAX = $app->syntax->new(name => 'ag')->lang("perl");
my $STRINGSYNTAX = $app->syntax->new(name => 'ag.string');

$BASICSYNTAX->bar($STRINGSYNTAX);

# конструктор
sub new {
	my ($cls) = @_;
	my $self = bless {
		%$BASICSYNTAX,
		trace => "«eval»",
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
my $re_extends = qr!$re_class(?:$re_space_ask,$re_space_ask$re_class)*!;
my $re_class_stmt = qr!
(?<class>$re_class)
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
my $re_args_then = qr/ (?<then> \b THEN \b ) | $re_args (?<then> \b THEN \b ) | ( $re_args )? $re_rem $re_endline /ixno;
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
$s->tr("xf",  qw{		@	%		});
$s->tr("fy",  qw{ ref pairs scalar defined length exists });
$s->tr("yf",  qw{		++ --			})->td("fy", qw{ ++ -- });
$s->tr("yfx", qw{		^				});
$s->tr("yfx", qw{		! +~ \			})->td("fy", qw{ + - });
$s->tr("xfy", qw{		=~ !~	~		});
$s->tr("xfy", qw{		* / % mod **		});
$s->tr("xfy", qw{		+ - .				});
$s->tr("xfy", qw{		<< >>				});
# in perl in this: named unary operators
$s->tr("xfx", qw{	< > <= >= lt gt le ge		});
$s->tr("xfx", qw{	== != <=> eq ne cmp ~~		});
$s->tr("xfy", qw{		+&					});
$s->tr("xfy", qw{		+|  +^				});
$s->tr("xfy", qw{		&&					});
$s->tr("xfy", qw{		|| //				});
$s->tr("xfx", qw{		..  to				});
#$s->tr("yfx", qw{		?:					});
$s->tr("yfx", qw{		= += -= *= /= &&= ||= //=  and= or= xor= ,= =, 	});				# goto last next redo dump
$s->tr("xfy", qw{		, =>					})->td("yf", qw{ , })->td("fy", qw{ => });
#$s->tr("xfx", qw{	list operators (rightward)});
$s->tr("yfx", qw{		not						});
$s->tr("xfy", qw{		and						});
$s->tr("xfy", qw{		or	xor					});
$s->tr("yfx", qw{		as						});
$s->tr("fx",  qw{		return					});

$s->tr("xfy", qw{	;	})->td("yf", qw{	;	})->td("fy", qw{	;	});
$s->tr("xfy", qw{	\n	})->td("yf", qw{	\n	})->td("fy", qw{	\n	});
$s->tr("xfy", qw{		THEN	ELSEIF	ELSE	UNTIL	FROM	CATCH	ADDHANDLER	});


$s->tr("xfy", qw{		CAT						});			# операция конкантенации в шаблонах


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



$s->opt("=>", re => qr{ (?<id>$re_id)? \s* => }xn );
$s->opt("=", sub => sub {	$_[0]->{assign} = 1 });

$s->opt('\n', re => "$re_rem $re_endline", sub => sub {
	my ($self, $push) = @_;
	$self->{lineno}++;
	$push->{then} = delete $self->endline->top->{then}
});

$s->opt("THEN", sub => sub { my ($self, $push) = @_; my $br = $self->{stack}[-1]; $br->{endline}=1; $push->{stmt} = delete $br->{then} });
$s->opt("ELSEIF", sub => sub { my ($self, $push) = @_; $self->check(stmt=>"IF", else=>"", then=>"")->top->{then} = "elseif_then" });
$s->opt("ELSE", sub => sub { my ($self, $push) = @_; $self->check(stmt=>"IF", else=>"", then=>"")->top->{else} = 1 });
$s->opt("UNTIL", sub => sub { my ($self, $push) = @_; $self->check(stmt=>"REPEAT")->top->{endline} = 1 });
$s->opt("FROM", sub => sub { my ($self, $push) = @_; my $top = $self->endline->top; $self->error("FROM должен использоваться после MAP, PAIRMAP, GREP, SORT, NSORT, QSORT или REDUCE") if $top->{stmt} !~ /^(?:map|grep|[nq]sort|reduce|pairmap)$/; $push->{endline} = $push->{gosub} = 1 });



### скобки

$s->br(qw{			(	)			});
$s->br(qw{			[	]			});
$s->br(qw{			{	}			});

$s->br(qw{			FOR		} => sub { my ($self, $push) = @_; $push->{then}="for_then"},	qw{		END		});
$s->br(qw{			WHILE	} => sub { my ($self, $push) = @_; $push->{then}="while_then"},	qw{		END		});
$s->br(qw{			IF		} => sub { my ($self, $push) = @_; $push->{then}="if_then"},	qw{		END		});
$s->br(qw{			TRY			END		});
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

$s->br("CLASS" => qr{ \b CLASS $re_space $re_class_stmt }ix => "END");
#$s->br("OBJECT" => qr{ \b OBJECT $re_space $re_class_stmt }ix => "END");
#$s->br("MODULE" => qr{ \b MODULE $re_space $re_class_stmt }ix => "END");

$s->br("SUB" => qr{ \b SUB $re_space $re_id $re_args_then }ix => "END");
#$s->br("SUB_CLASS" => qr{ \b SUB $re_space $re_id $re_args_then }ix => "END");

#$s->br("DEF" => qr{ \b DEF $re_space $re_sub (?<endline> $re_space_ask THEN \b)? }ix => "END");
#$s->br("LET" => qr{ \b LET $re_space $re_sub (?<endline> $re_space_ask THEN \b)? }ix => "END");
$s->br("DO" => qr{ \b DO $re_args  }ix => "END");

### операнды

$s->x("()");
$s->x("[]");
$s->x("{}");

$s->x("self"		=> qr{ 	\b	(?:	self | this | me	)	\b 	}x);
$s->x("app");
$s->x("q");
$s->x("user");
$s->x("super");
$s->x("null" => qr/\b(?: null | nothing | undef) \b/x);
$s->x("true");
$s->x("false");
$s->x("paramarray" => qr/\b(?:paramarray | arguments)\b/x);
$s->x("throw" => qr/ \b (?: die | throw | raise ) \b /x => sub { $b->{gosub} = $b->{endline} = 1 });
$s->x("next");
$s->x("last");
$s->x("redo");
$s->x("wantarray");

$s->x("new"		=> qr{ 	\b NEW $re_space (?<new>$re_id(?:::$re_id)*) 	}x);
$s->x("var"		=> qr{ 	(?<var>$re_id) 									}x);
$s->x("num"		=> qr{ 	(?<num> -? (?: [\d_]+(\.[\d_]+)? | \.[\d_]+ )	(?: E[\+\-][\d_]+ )?	)			}ix);
$s->x("regexp"	=> qr{ 	" (?<QR> (?:[^"]|\\")* ) "! (?<qr_args> \w+ )? 	}x);

$s->x("string"	=> qr{	" (?<string> (?:\\"|""|[^"])* ) "	 }x => sub {
	my ($self, $push) = @_;
	$self->checkout("ag.string")->push("string")->masking($push->{string})->pop("string")->checkout("ag")->assign($push);
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


# заменяет переменные в строке
#my $re_id = $R::Re::id;
sub replace_dollar {
	my ($self, $s) = @_;
	
	#local($_, $a, $b, $`, $', $&);
	
	my $is_string = "\"" eq substr $s, 0, 1;
	
	if($is_string) {
		$self->push('string');

		while($s =~ m{
			^ "			|
			(?<str> .*? )
			(?:
				\$(?<id> $re_id(?:[\.:]$re_id)* )	(?{ 1 }) |
				(?: \\" | "" )						(?{ 2 })  |
				" $									(?{ 3 })
			)
			
		}gxs) {
		
			$^R==1? do {
				my $id = $+{id};
				$self->push('interpolation')->masking($id)->pop('interpolation')->op("CAT");
			}:
			$^R==2? $self->atom('kav')->op("CAT"):
			$^R==3? $self->atom('str'):
			$self->error("неверная часть строки");
		}
		
		$self->pop('string');
		
		return $self;
	}
	
	todo;
	
	
	
	$self
}

########################################### строки ########################################### 
{
my $string = $STRINGSYNTAX;
# отключаем добавление дефолтных лексем
$string->addspacelex(0);

$string->tr("yfx", qw/CAT/)->tr("yf", qw/CAT/);

$string->opt("CAT", re => qr/ (?<str> [^\$]* ) (?: \$ (?<exec> $re_id([\.:]$re_id)* ) | $ ) /nxs, sub => sub {
	my ($self, $push) = @_;
	if(exists $push->{exec}) {
		$self->checkout("ag")->push("exec1")->masking($push->{exec})->pop("exec1")->checkout("ag.string");
		delete $push->{str};
	}
});
}


########################################### require ###########################################

# класс по-умолчанию
sub classByDefault {
	my ($self, $name, $code) = @_;
	$self->{lineno} = 0;
	"class $name\n$code\nend";
}

# переопределяем eval
sub eval {
	my ($self, $code) = splice @_, 0, 2;
	$self->SUPER::eval( $self->classByDefault('EVAL', $code) . ".render" );
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
	
	push @{ $app->{syntaxAg}{INC} }, $root;
	
	$self->require("Aquafile");
	
	my $class = $self->require( $app->file($path)->abs->subdir($root, "")->path );
	
	$class->new->render(@args);
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
	my ($self, $path, $to) = @_;
	
	my $file = $app->file($path);
	my $name = $file->nik;
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
	
	my $code = $cc->morf( $text );
	$app->file($to)->write($code);

	$self
}

# подключает файл как класс или шаблон
# получает рутовую директорию
# если Aquafile ещё не загружен - загружает
sub require {
	my ($self, $path, $INC) = @_;
	
	return if exists $app->{syntaxAg}{require}{$path};
	
	$INC //= $app->{syntaxAg}{INC};
	my $file = $app->file($path);
	
	for my $inc (@$INC) {
		my $f = $file->frontdir($inc);
		if($f->exists) {
			my $to = $app->file("$inc/.Aqua/$path.pm");
			
			if(!$to->exists || $to->mtime < $f->mtime) {
				$self->compile($f->path, $to->path);
			}
			require $to->path;
			$app->{syntaxAg}{require}{$path} = 1;
			return $self->path2class($path);
		}
	}
	
	die "файл ".$app->perl->qq($path)." не найден";
}

# подключает класс Ag, Au или Perl
sub include {
	my ($self, $class, $INC) = @_;
	$INC //= $app->{INC};
	
	$class =~ s!::!/!g;
	#$file =
	
	for my $inc (@$INC) {
	}
	
	$self
}

1;
