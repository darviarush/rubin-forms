package R::Syntax::Ag;
# синтаксис языка Бэйсик

use base R::Syntax;

use common::sense;
use R::App;
use R::Re;

$Nil::INC = [$app->file(__FILE__)->file( "/../../../ag" )->abs->path];

my $BASICSYNTAX = $app->syntax->new(name => 'ag')->lang("perl");
my $STRINGSYNTAX = $app->syntax->new(name => 'ag.string');

$BASICSYNTAX->bar($STRINGSYNTAX);

# конструктор
sub new {
	my $cls = shift;
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
my $re_css_id = $R::Re::css_id;
my $re_endline = $R::Re::endline;
my $re_number = $R::Re::number;

my $re_space = qr/[\ \t]+/;
my $re_space_ask = qr/[\ \t]*/;
my $re_rem = qr/(?:(?:\#|\brem\b)(?<rem>[^\n\r]*))?/i;
my $re_sk = qr/[\[\{\(]/;
my $re_arg = qr/$re_id|\*/on;
#my $re_STRING = qr/'(\\'|[^\n\r']*)'|"(\\"|[^\n\r"]*)"/on;
my $re_class = qr/ (::)? $re_css_id(::$re_css_id)* /xon;
my $re_extends = qr!$re_class(?:$re_space_ask,$re_space_ask$re_class)*!;
my $re_class_stmt = qr!
(?<class>$re_class)
(?: [\ \t]+ (?:EXTENDS|INHERITS) [\ \t]+ (?<extends>$re_extends))?
(?<with> [\t\ ]+ with [\t\ ]+ (?<with_args> [^\r\n]+) )?
!xismo;				
my $re_args = qr!
$re_space_ask (?<args>$re_arg ($re_space_ask , $re_space_ask $re_arg)*)
!xismon;
# my $re_overload_id = qr!
	# (?<id>"\w+"|[[:punct:]]+|0\+)
# !xismo;
#my $re_sub_in = qr/ [\ \t]+ CLASS [\ \t]+ (?<sub_in>(?<sub_self>::)?$re_class) /xn;
my $re_SUB = qr/ $re_id /xon;
my $re_args_then = qr/ $re_space_ask (?<then> \b THEN \b ) | $re_args $re_space_ask (?<then> \b THEN \b ) | $re_args | /ixno;
# my $re_then = qr/ (?<re_endline> $re_space_ask \b THEN \b) | $re_rem $re_endline /xn;
# my $re_for = qr!
# (?<for_k>$re_id) (?: $re_space_ask,$re_space_ask (?<for_v>$re_id) (?: $re_space_ask,$re_space_ask (?<for_i>$re_id) )? )? (?: $re_space (?<for_in>IN) \b | $re_space (?<for_of>OF) \b | $re_space_ask = )
# !xismo;
# my $re_gosub_after = qr{
# \b [\ \t]* (?! [ !\+\-\*/<>=  \)\}\] \|& \? .:,; \r\n ] | %\s |  (?:or|and|not|eq|ne|le|ge|lt|gt|then|else|end|cmp|from) \b | $ )
# }xismo;

#\p{Uppercase}

# describe context it Given

# ключевые слова:
# super null extends action of block process include raw wrapper eq ne le ge lt gt keys values use sort scenario pairmap map grep reduce from repeat self this me ucfirst lcfirst uc lc ref cmp push pop undef next last redo return pairs or and not eq ne le ge lt gt scalar msg msg1 keys values exists closure length use push pop shift unshift splice delete defined wantarray


    # equ «Равно». Дает True, если значения равны
    # neq «Не равно». Дает True, если значения не равны
    # lss «Меньше». Дает True, если зпачение1 меньше, чем значение2
    # lcq «Меньше или равно». Дает True, если значепие1 равно или меньше, чемзначение2
    # gtr «Больше». Дает True, если значение1 больше, чем значение2
    # geq «Больше или равно». Дает True, если значепие1 равно или больше, чем значение2

	# equal great less greateq lesseq noneq
	# equal to   greater then	less then	greater or equal to		less or equal to
	
	# x == 2.1 +- 0.1
	# flip-flop		^ff^

{
my $s = $BASICSYNTAX;

$s->tr("yf",  qw{		.word ?.word .$word ?.$word :word			});
$s->td("yS",  qw{		.word( ) .$word( ) ?.word( ) ?.$word( ) 	});
$s->td("xfy", qw{		.word+ .$word+ ?.word+ ?.$word+ 			});
$s->tr("yF",  qw{		[ ]		{ }									});
$s->tr("xF",  qw{		@[ ]	@{ }								});
$s->tr("fx",  qw{		@	%	pop shift							})->td('xf', qw{	pop shift	});
$s->tr("yf",  qw{		++ --				})->td("fy", qw{	++ -- 	}); 	# ?!
$s->tr("fy",  qw{  		len lc uc lcfirst ucfirst chr ord	})->td("yf", qw{	len  abs ceil floor round rand srand keys values	});
$s->tr("xfy", qw{  		ceil floor round	});
$s->tr("xf",  qw{		?  					})->td("fy", qw{	Num		});
$s->tr("xfy", qw{		?					});
$s->tr("yfx", qw{		^					});
$s->tr("fy",  qw{ 		+ - ! +~			});
$s->tr("xfy", qw{		~	!~	~r~	!~r~	});
$s->tr("xfy", qw{		* / mod div ** ***	});
$s->tr("xfy", qw{		+ - .				});
$s->tr("xfy", qw{		+< +>				});
$s->tr("xfy", qw{		+&					});
$s->tr("xfy", qw{		+|  +^				});
$s->tr("xfy", qw{		%					});
$s->tr("xfx", qw{		< > <= >= lt gt le ge		});
$s->tr("xfx", qw{		== != eq ne  <=> cmp 		});			# ~~
$s->tr("xfx", qw{		isa can	of					});
$s->tr("xfy", qw{		&&					});
$s->tr("xfy", qw{		|| ^^				});
$s->tr("xfx", qw{		flipflop ^flipflop flipflop^ ^flipflop^				});
$s->tr("xfx", qw{		.. ... ^.. ^...  to ^to ^to^   step			})->td("fx", qw{	^	});
$s->tr("xfy", qw{		=>		})->td("fy",  qw{	word=>			});
$s->tr("xfx", qw{		split	})->td("xf",  qw{	split			});
$s->tr("xfy", qw{		,		})->td("yf",  qw{ 	,				});
$s->tr("xfy", qw{		zip		})->td("fy",  qw{	zip				});
$s->tr("xfx", qw{		splice	delete	});
$s->tr("yfx", qw{		join	})->td("yf", qw{	reverse join	});
$s->tr("yfx", qw{		-> =   += -= *= /= ^= div= mod=   &&= ||= ^^=   and= or= xor=   +&= +|= +^= +<= +>=   **= ***= .= ?= ,= =, %=   =sreplace =kreplace });
$s->tr("xfy", qw{		sreplace kreplace		});
$s->tr("fx",  qw{		gosub+					});
$s->tr("fx",  qw{		gen		})->td("xfx", qw{		gen					});
$s->tr("xfy", qw{		:						});
$s->tr("xfy", qw{		|						});	# TODO: |=
$s->tr("fy",  qw{		not						});
$s->tr("xfy", qw{		and						});
$s->tr("xfy", qw{		or	xor					});
$s->tr("yfx", qw{		as	is					});
$s->tr("fx",  qw{		return	raise msg msg1	})->td("Fx", qw{   REPEAT UNTIL  });
$s->tr("xfy", qw{		;						});
$s->tr("fx",  qw{		decorator				});
$s->tr("xfy", qw{		\n						})->td("yf", qw{	\n	})->td("fy", qw{	\n	});
$s->tr("xfy", qw{		rescue					});
$s->tr("xfy", qw{		THEN	ELSEIF	ELSE	});


### дополнительные опции операторов

# a-1 тогда не сработает
# $s->opt("-", order => 10000);	# чтобы был за num и -1.1 распознавался как num, а не - и num
$s->opt("^", order => 10000);	# чтобы распознавались скобки ^{...}

$s->opt(":word",		re => qr{		: (?<var>$re_id)			}x);

$s->opt(".word",		re => qr{		\. (?<var>$re_id)			}x);
$s->opt(".word(",		re => qr{		\. (?<var>$re_id) \(		}x);

$s->opt(".\$word",		re => qr{		\.\$ (?<var>$re_id)			}x);
$s->opt(".\$word(",		re => qr{		\.\$ (?<var>$re_id) \(		}x);

$s->opt("?.word",		re => qr{		\?\. (?<var>$re_id)			}x);
$s->opt("?.word(",		re => qr{		\?\. (?<var>$re_id) \(		}x);

$s->opt("?.\$word",		re => qr{		\?\.\$ (?<var>$re_id)		}x);
$s->opt("?.\$word(",	re => qr{		\?\.\$ (?<var>$re_id) \(	}x);


$s->opt("~r~", re => qr{ ~ (?<id> $re_id ) ~ }x);
$s->opt("!~r~", re => qr{ !~ (?<id> $re_id ) ~ }x);

$s->opt("raise", re => qr/ \b ( die | throw | raise ) \b /xni);
$s->opt("rescue", re => qr/ \b ( rescue | catch | except ) ( ( $re_space_ask \* | $re_space (?<isa> $re_extends ) ( $re_space_ask AS $re_space (?<id> $re_id ) )? )? ( $re_space_ask THEN \b ) | \b )  /xni, sub => sub {
	my ($self, $push) = @_;
	$push->{id} = 'e' if !$push->{id};
	if($push->{isa}) {
		# TODO: дополнить ::CLASS
		$push->{isa} = [ split /\s*,\s*/, $push->{isa} ];
		$push->{tmpl} = 'rescue isa';
	}
});

$s->opt("word=>", re => qr{ (?<id>$re_id) $re_space_ask => }xn );

$s->opt("|", re => qr{ 
	\| $re_space_ask ( 
		( (?<param> $re_id ( $re_space_ask , $re_space_ask $re_id)* ) $re_space )? (?<op> map | grep | first | all | any | reduce | assort | sort | order | group | groupby | compress | compressby ) (?<arity> \d+ )? \b |
		(?<op> join ) \b
	)? 
}xni, sub => sub {
	my ($self, $push) = @_;
	
	$self->error("| $push->{op} не может иметь и параметры $push->{param} и арность $push->{arity} одновременно") if defined $push->{param} and defined $push->{arity};
	#$self->error("у | $push->{op} не может быть арности") if any { $push->{op} eq $_} qw/sort order join/ and defined $push->{arity};
	#$self->error("у | join не может быть параметров") if $push->{op} eq "join" and defined $push->{param};
	$self->error("| $push->{op} - арность не может быть равна 0") if defined $push->{arity} and $push->{arity} == 0;
	
	$push->{arity} = 2 if $push->{op} =~ /^(assort|reduce)$/ni && !defined $push->{param} && !defined $push->{arity};

	
	if(defined $push->{param}) {
		$push->{param} = [ split /\s*,\s*/, $push->{param} ];
	}
	else {
		my $arity = $push->{arity} // 1;
		for(my $i=0, my $n='a'; $i<$arity; $i++, $n++) {
			push @{$push->{param}}, $n;
		}
	}
	
	
	my $op = $push->{op};
	$op = lc $op || "map";

	$push->{tmpl} = $op;

	$push->{arity} = @{$push->{param}};
	$push->{arity0} = $push->{arity} - 1;
	$push->{qwparam} = join " ", @{$push->{param}};
	
	$self->error("арность assort должна быть кратна 2-м") if $op eq "assort" and $push->{arity} % 2;
	$self->error("арность reduce должна быть больше 1-го") if $op eq "reduce" and $push->{arity} < 2;
	
});

$s->x('\n');
$s->opt('\n', re => "$re_rem $re_endline", sub => sub {
	my ($self, $push) = @_;
	
	$self->newline;
	
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
	
	# для FOR
	if($br->{stmt} eq "FOR") {
		$push->{param} = $br->{param};
		$push->{i} = $br->{i};
		$push->{L} = $br->{L};
		$push->{tmpl} = $br->{op} eq "in"? "FOR IN": $br->{op} eq "of"? "FOR OF": "FOR THEN";
		
	}
	else {
		$push->{tmpl} = "$br->{stmt} THEN";
	}
	
});
$s->opt("ELSEIF", sub => sub {
	my ($self, $push) = @_;
	my $br = $self->check("ELSEIF", stmt=>"IF", else=>"", then=>"")->top;
	$br->{then} = 1;
});
$s->opt("ELSE", sub => sub { my ($self, $push) = @_; $self->check("ELSE", stmt=>"IF", else=>"", then=>"")->top->{else} = 1 });



### скобки

$s->sr(qw{			(	)			});
$s->sr(qw{			[	]			});
$s->sr(qw{			{	}			});
$s->sr(qw{			^{	}			});

$s->sr("word(" => qr{		(?<var>$re_id) \(	 }x => ")");

$s->br(FOR => qr{ FOR $re_space (?<args> $re_id ( $re_space_ask , $re_space_ask $re_id)* ) ( $re_space(?<op> in | of ) | $re_space_ask = ) }xin => sub {
	my($self, $push) = @_;
	$push->{then} = 1;
	my $args = $+{args};
	$push->{param} = [ split /\s*,\s*/, $args ];
	$push->{i} = $self->{lang}->ref;
	$push->{L} = $self->{lang}->label;
} => "END");
$s->br(WHILE => sub { my($self, $push) = @_; $push->{then}=1 } => qw{		END		});
$s->br(IF => sub { my($self, $push) = @_; $push->{then}=1 } => qw{		END		});
$s->br(qw{		DO		END		});

# $s->br(qw{			ON	} => qr{ \b ON $re_space (?<route>$re_string) }x => sub {
	# my ($self, $push) = @_; 
	# $push->{route}=$self;
	# $app->perl->unstring($push->{route});
# }, "END");

$s->opt("END", sub => sub {
	my ($self, $push) = @_;
	my $top = $self->top;
	$self->error("$top->{stmt}: end встречен до then") if $top->{then};
});

# $s->br(qw/			REPEAT				/);
# $s->br(qw/			MAP					/);
# $s->br(qw/			PAIRMAP				/);
# $s->br(qw/			GREP				/);
# $s->br(qw/			REDUCE				/);
# $s->br(qw/			SORT				/);
# $s->br(qw/			QSORT				/);
# $s->br(qw/			NSORT				/);
#$s->opt("UNTIL", sub => sub { my ($self, $push) = @_; $self->check("UNTIL", stmt=>"REPEAT")->top->{endline} = 1 });
#$s->opt("FROM", sub => sub { my ($self, $push) = @_; my $top = $self->endline->top; $self->error("FROM должен использоваться после MAP, PAIRMAP, GREP, SORT, NSORT, QSORT или REDUCE") if $top->{stmt} !~ /^(?:map|grep|[nq]sort|reduce|pairmap)$/; $push->{endline} = $push->{gosub} = 1 });

sub _class {
	my ($self, $push) = @_;
	my $S = $self->{stack};
	#$push->{lineno} = $self->{lineno};
	#$push->{file} = $self->{file};
	
	# получаем вышестоящий класс
	my $class;
	for(my $i=$#$S; $i>=0; $i--) {
		$class = $S->[$i]{class}, last if $S->[$i]{stmt} =~ /^(CLASS|OBJECT)$/;
	}
	

	# иерархия классов
	$push->{class} = "${class}::$push->{class}" if defined $class;
	
	$push->{realname} = $push->{class};
	
	$push->{class} =~ s/-/__/g;
	
	# обрабатываем extends
	if($push->{extends}) {
		$push->{extends} = [ map { s/-/__/g; /^:/? "$push->{class}$_": $_ } split /\s*,\s*/, $push->{extends} ];
	}
	else {
		$push->{extends} = ["Nil"] if $push->{class} ne "Nil";
	}
}

$s->br("CLASS" => qr{ \b CLASS $re_space $re_class_stmt }ix => \&_class => "END");
$s->br("OBJECT" => qr{ \b OBJECT ( $re_space (?<extends> $re_class ( $re_space_ask , $re_space_ask $re_class )* ) )? ($re_space CLASS $re_space (?<class> $re_class))? ($re_space WITH $re_space)? }ixn => sub {
	my ($self, $push) = @_;
	$push->{class} = "Ag::OBJECT::OBJECT" . (++$self->{OBJECT_COUNT}) if !defined $push->{class};
	&_class;
} => "END");

$s->opt("decorator", nolex=>1);
sub br_sub {
	my ($self, $push) = @_;
	
	$self->error("void - метод тела класса. Он уже объявлен", $push) if $push->{SUB} eq "void";
	
	$push->{args} = [ split /\s*,\s*/, $push->{args} ];
	$push->{endline} = 1 if delete $push->{then};
	
	# в каком классе находится функция
	my $stack = $self->{stack};
	for(my $i=$#$stack; $i>=0; $i--) {
		my $s = $stack->[$i];
		if($s->{stmt} eq "CLASS") {
			$push->{class} = $s->{class};
			goto NEXT;
		}
	}	
	
	$self->error("метод $push->{SUB} не в классе!");
	NEXT:
	
	
	# пытаемся обнаружить декораторы
	my $A = $stack->[-1]{'A+'};
	
	if($A && @$A && $A->[-1]{stmt} eq '\n') {
	
		# двигаемся назад, пока не обнаружим перевод строки или начало последовательности
		# тогда если предыдущий элемент - @, то меняем на декоратор
		for(my $i=$#$A-1; $i>=-1; $i--) {
			
			if($i==-1 || $A->[$i]{stmt} eq '\n') {
				my $op = $A->[$i+1];
				my $stmt = $op->{stmt};

				if($stmt eq '\n') { next; }		# пропускаем \n
				elsif($stmt ne '@') { last; }	# выходим
				
				# заменяем на декоратор
				$op->{SUB} = $push->{SUB};
				$op->{stmt} = 'decorator';
				
				my ($next) = splice @$A, $i+2, 1;
				if($next->{stmt} eq "var") {
					$op->{name} = $next->{var};
				}
				elsif($next->{stmt} eq "classname") {
					$op->{name} = $next->{classname};
				}
				else {
					$self->error("после \@ должен быть указан декоратор", $op);
				}
	
				$op->{class} = $push->{class};
			}
		}
		
	}
}

$s->br("SUB" => qr{ \b SUB $re_space (?<SUB> $re_SUB ) $re_args_then }ix => \&br_sub => "END");
$s->br("BLOCK" => qr{ \b BLOCK $re_space (?<SUB> $re_SUB ) $re_args_then }ix => \&br_sub => "END");



#$s->br("SUB_CLASS" => qr{ \b SUB $re_space $re_id $re_args_then }ix => "END");

#$s->br("DEF" => qr{ \b DEF $re_space $re_sub (?<endline> $re_space_ask THEN \b)? }ix => "END");
#$s->br("LET" => qr{ \b LET $re_space $re_sub (?<endline> $re_space_ask THEN \b)? }ix => "END");


$s->br("SCENARIO" => sub { my ($self, $push) = @_; $push->{lineno} = $self->{lineno} } => "END");


### строки

# $s->x("words" => qr{		}xn => sub {
	# my ($self, $push) = @_;
# });

$s->opt("sreplace", nolex => 1);
$s->opt("kreplace", nolex => 1);
$s->opt("=sreplace", nolex => 1);
$s->opt("=kreplace", nolex => 1);

$s->br("regexp");			$s->opt("regexp", nolex => 1);
$s->br("like");				$s->opt("like", nolex => 1);
$s->br("string_modify");	$s->opt("string_modify", nolex => 1);



my $re_string = qr{ " (?<string> (?:\\"|""|[^"])* ) " | ' (?<string> (?:\\'|''|[^'])* ) ' }xn;

$s->x("replace", qr{	(?<assign> = $re_space_ask)? (?<s> [sk]) $re_string (?<arg> $re_id )? ( ~ (?<id> $re_id ))?	}xn, sub {
	my ($self, $push) = @_;
	my $isS = $push->{s} eq "s";
	my $sk = $isS? ($push->{assign}? "=sreplace": "sreplace"): ($push->{assign}? "=kreplace": "kreplace");
	$self->checkout("ag.string")->push($sk)->masking($push->{string})->pop($sk)->checkout("ag")->assign($push);
	$push->{F_stmt} = $isS? 'F_sreplace': 'F_kreplace';	# устанавливаем смычку: sreplace - F_sreplace = 
	$push->{arg} .= 'g' if $push->{arg} !~ s/G// && $push->{arg} !~ /g/;
	$push->{arg} .= 'e';
	$push->{id} //= "s";
	
});
$s->opt("replace", order => -1000);

$s->x("regex"	=> qr{	 $re_string ! (?<arg> $re_id )?	}xn => sub {
	my ($self, $push) = @_;
	$self->checkout("ag.string")->push("regexp")->masking($push->{string})->pop("regexp")->checkout("ag")->assign($push);
});

$s->x("likes"	=> qr{	 $re_string \? (?<arg> $re_id )?	}xn => sub {
	my ($self, $push) = @_;
	$self->checkout("ag.string")->push("like")->masking($push->{string})->pop("like")->checkout("ag")->assign($push);
});

$s->x("string"	=> qr{	 $re_string (?<arg> $re_id )?	 }xn => sub {
	my ($self, $push) = @_;
	$self->push("new_apply", new => "String::Fix::$push->{arg}") if $push->{new} = exists $push->{arg};
	$self->checkout("ag.string")->push("string")->masking($push->{string})->pop("string")->checkout("ag")->assign($push);
});
$s->opt("string", sur => sub {
	my ($self, $push) = @_;
	$self->pop("new_apply") if $push->{new};
});

### операнды

# возвращает скобку в стеке имеющую параметр $id
sub get_sk {
	my ($self, $id) = @_;
	my $stack = $self->{stack};

	for(my $i=$#$stack; $i>=0; $i--) {
		my $sk = $stack->[$i];
		if(ref $sk->{param}) {
			my $param = $sk->{param};
			for(my $j=0; $j<@$param; $j++) {
				return $sk, $j if $param->[$j] eq $id;
			}
		}
	}
	
	return;
}

$s->x("index" => qr{ \b INDEX\( $re_space_ask (?<id> $re_id ) $re_space_ask \) }ixn => sub {
	my ($self, $push)=@_;
	
	my $id = $push->{id};
	my ($sk, $n) = $self->get_sk($id);
	$self->error("index($id): переменная $id не связана с циклом или конвеером") if !defined $sk;
	
	$push->{i} = $sk->{i}; 
	$push->{n} = $n;
});
$s->x("next label" => qr/ \b NEXT \( $re_space_ask (?<id> $re_id ) $re_space_ask \) /xin => sub {
	my ($self, $push) = @_;
	my $id = $push->{id};
	my ($sk, $n) = $self->get_sk($id);
	$self->error("next $push->{id}: переменная $id не связана с циклом или конвеером") if !defined $sk;
	$push->{L} = $sk->{L};
});
$s->x("last label" => qr/ \b LAST \( $re_space_ask (?<id> $re_id ) $re_space_ask \) /xin => sub {
	my ($self, $push) = @_;
	my $id = $push->{id};
	my ($sk, $n) = $self->get_sk($id);
	$self->error("last $push->{id}: переменная $id не связана с циклом или конвеером") if !defined $sk;
	$push->{L} = $sk->{L};
});
$s->opt("index", order => -1000);
$s->opt("next label", order => -1000);
$s->opt("last label", order => -1000);

# $s->x("&ref" => qr/ & (?<id> $re_id ) /x => sub {
	# my ($self, $push)=@_;
	
	# my $id = $push->{id};
	# my ($sk, $n) = $self->get_sk($id);
	# $self->error("&$id: переменная $id не связана с циклом или конвеером") if !defined $sk;
	
	# $push->{i} = $sk->{i}; 
	# $push->{n} = $n;
# });


$s->x("self"		=> qr{ 	\b	(?:	self | this | me	)	\b 	}x);
$s->x("app");
$s->x("q");
$s->x("user");
$s->x("super");
$s->x("nothing" => qr/\b(?: null | nothing | undef | nil | void) \b/x);
$s->x("pi");
$s->x("nan");
$s->x("inf");
$s->x("true");
$s->x("false");
$s->x("paramarray" => qr/\b(?:paramarray | arguments)\b/x);

$s->x("next");
$s->x("last");

#$s->x("redo");
#$s->x("wantarray");
$s->x("local");

$s->br("new_apply" => qr{ 	\b NEW $re_space (?<new>$re_class) \(	}ix => sub {
	my ($self, $push) = @_;
	$push->{new} =~ s/-/__/g;
}  => ")");
$s->x("new"			=> qr{ 	\b NEW $re_space (?<new>$re_class) 	}ix => sub {
	my ($self, $push) = @_;
	$push->{new} =~ s/-/__/g;
});

$s->br("new_x_apply" => qr{ 	\b NEW $re_space \$(?<new>$re_id) \(	}ix  => ")");
$s->x("new_x"		 => qr{ 	\b NEW $re_space \$(?<new>$re_id) 		}ix);


$s->x("classname"	=> qr{ 	(?<classname> $re_id(::$re_id)+ ) 	}x);
$s->x("var"			=> qr{ 	(?<var>$re_id) 						}x);
$s->x("hex"			=> qr{	0x[\da-f_]+	}ix);
$s->x("bin"			=> qr{	0b[10_]+	}ix);
$s->x("radix"		=> qr{	(?<radix> (?<rad>\d+) r (?<num> [\da-z_]+ ) )	}ix => sub {
	my ($self, $push) = @_;
	$self->error("$push->{radix} - система счисления не может быть 0") if $push->{rad} == 0;
	$self->error("$push->{radix} - система счисления должна быть не более 62-х")  if $push->{rad} > 62;
	my $num = $push->{num};
	$num =~ s/_//g;
	$push->{radix} = $app->perl->from_radix($num, $push->{rad});
});
$s->x("num"		=> qr{ 	(?<num> -? ( \d[\d_]*(\.[\d_]+)? | \.[\d_]+ )	( E[\+\-][\d_]+ )?	) (?<new> \w+)?	}ixn);
$s->opt("num", sub => sub {
	my ($self, $push) = @_;
	$self->push("new_apply", new => "Number::Fix::$push->{new}") if exists $push->{new};
}, sur => sub {
	my ($self, $push) = @_;
	$self->pop("new_apply") if exists $push->{new};
});


### какие операторы в каких скобках могут существовать
$s->in("if"		=> qw{		else elseif		});


### фиксы
$s->opt('zip', re => qr{	\b zip (?<arity>\d+)? \b	}ix, sub => sub { my ($self, $push)=@_; $push->{arity} //= 1 });
$s->fixes(
'xfy zip' => sub {
	my ($self, $push) = @_;
	$push->{left}{stmt} = "zip" if $push->{left}{stmt} eq "xfy zip";
},
'fy zip' => sub {
	my ($self, $push) = @_;
	$push->{right}{stmt} = "zip" if $push->{right}{stmt} eq "xfy zip";
},
);


# устанавливаем обработчик на начало pop
$s->opt("gosub+", nolex=>1);
$s->opt(".word+", nolex=>1);
$s->opt('.$word+', nolex=>1);
$s->opt("?.word+", nolex=>1);
$s->opt('?.$word+', nolex=>1);
my %PULLOP = qw( .word  .word+  .$word  .$word+   ?.word  ?.word+	?.$word ?.$word+		);
$s->pull(join(" ", keys %PULLOP) => \&onpull);

sub onpull {
	my ($self, $i) = @_;
	my $A = $self->{stack}[-1]{"A+"};
	$#$A == $i && return;	# мы в конце скобки
	my $me = $A->[$i];
	$me->{spacer} || return;	# нужен space
	
	my $op = $A->[$i+1];
	my $lex = $self->{LEX}{ $op->{stmt} };
	my $fix = $lex->{fix};
	
	#msg1 "xxx", $me->{stmt}, "spacer:", $me->{spacer}, $A->[$i+1]->{spacer}, "u:", !($fix & ($R::Syntax::prefix | $R::Syntax::infix | $R::Syntax::postfix)), $fix & $R::Syntax::prefix && !($fix & ($R::Syntax::infix | $R::Syntax::postfix)), $fix & $R::Syntax::prefix && $fix & ($R::Syntax::infix | $R::Syntax::postfix) && !$A->[$i+1]->{spacer};
	
	# следующий кроме оператора
	if( !($fix & ($R::Syntax::prefix | $R::Syntax::infix | $R::Syntax::postfix)) ||
	
	# следующий prefix оператор и нет такого infix и постфикс
	$fix & $R::Syntax::prefix && !($fix & ($R::Syntax::infix | $R::Syntax::postfix)) ||
	
	# следующий prefix и infix или postfix, но у me есть space, а у оператора - нет
	$fix & $R::Syntax::prefix && $fix & ($R::Syntax::infix | $R::Syntax::postfix) && !$op->{spacer}
	) {
		# тогда меняем на оператор .word+ и добавляем постфиксный оператор, для захвата параметров
		#msg1 "sk!";
		
		# поменять stmt оператора
		$me->{stmt} = $PULLOP{ $me->{stmt} };
		
		# вставляем оператор
		splice @$A, $i+1, 0, { stmt => "gosub+" };
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

my $re_inbrackets = qr{
	(?<R1> \(  ( [^\(\)]+ | (?&R1) )* \) ) |
	(?<R2> \{  ( [^\{\}]+ | (?&R2) )* \} ) |
	(?<R3> \[  ( [^\[\]]+ | (?&R3) )* \] )
}xn;

$string->opt("CAT", re => qr/ 
	(?<str> [^\$]* ) ( 
		\$ (?<CAT> $re_id $re_inbrackets? ( [\.:]$re_id $re_inbrackets? )* ) | 
		(?<dollar> \$ ) |
		$ 
	) 
/nxs, sub => sub {
	my ($self, $push) = @_;
	if( $self->top->{stmt} eq "string" ) {
		$push->{str} =~ s/""|''|\\["']/\\"/g;
	}
	else {
		$push->{str} =~ s/""/"/g;
		$push->{str} =~ s/''/'/g;
	}
	$push->{str} .= delete $push->{dollar} if exists $push->{dollar};
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

# добавляем ROOT
sub expirience {
	my ($self, $root) = @_;
	$self->SUPER::expirience({stmt=>"ROOT", right=>$root});
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

	if($path ne "Aquafile") {
		my $Aquafile = $self->include( "Aquafile" );
	
		# строим окружение
		$Aquafile->new->void(@args);
	}
	
	die "нет " . $app->perl->qq($path) if !$app->file($path)->exists;
	
	my $file = $app->file($path)->abs->subdir($root, "");
	my $class = $self->path2class( $file->path );
	
	$self->include( $class );
	
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
	
	#msg1 $path, $to, $name;
	
	die "compile: не указан Класс" if !$name;
	die "compile: не указан путь файла" if !$path;
	die "compile: не указано куда компилировать" if !$to;
	
	my $file = $app->file($path);
	my $text = $file->read;
	my $ext = $file->ext;
	
	if($ext ne "" and $ext ne "ag") {
		my $Ext = "syntaxPreprocessor" . ucfirst $ext;
		$text = $app->$Ext->new(file => $path, text => $text)->morf;
	}
	
	my $cc = $self->new(file => $path, tofile => $to, trace => $self->{trace});
	
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

# # подключает файл как класс или шаблон
# # получает рутовую директорию
# # если Aquafile ещё не загружен - загружает
# sub _require {
	# my ($self, $path, $INC) = @_;
	
	# $INC //= $Nil::INC;
	
	# for my $inc (@$INC) {
			
		# $f = $app->file("$inc/$path");
	
		# next if !$f->isfile;
		
		# my $class = $self->path2class($path);
		# my $to = $app->file("$inc/.Aqua/$rpath.pm");

		# $self->compile($f->path, $to->path, $class) if !$to->exists || $to->mtime < $f->mtime;
		
		# require $to->path;
		# return $class;
	# }
	
	# die "нет " . $app->perl->qq($path);
# }

# подключает классы Ag или Perl
sub include {
	my $self = shift;
	
	CLASS:
	for my $class (@_) {
	
		# класс уже подключен
		return $class if $class->can("new");
		
		my @path = split /::/, $class;
		
		my $INC = $Nil::INC;
		
		# по указанному пути могут быть файлы с этим классом. Они могут иметь разные расширения или не иметь их вообще
		# так же нужно проверить, что класс не описан дважды
		# файлы проверяем только по одному пути
		
		my $load = "";
		
		for my $inc (@$INC) {
		
			for(my $i=0; $i<@path; $i++) {
				my $path = join "/", @path[0..$i];
		
				my $file = $app->file("$inc/$path $inc/$path.*")->glob("-f");
			
				die "несколько подходящих файлов: " . join ", ", $file->files if $file->length > 1;
				if($file->length == 1) {

					#$self->_require($file->subdir($inc, "")->path, [$inc]);
					my $strip_path = $file->subdir($inc, "")->path;
					my $to = $app->file("$inc/.Aqua/$strip_path.pm");
					my $newclass = $self->path2class($strip_path);
					
					$self->compile($file->path, $to->path, $newclass) if !$to->exists || $to->mtime < $file->mtime;
					
					require $to->path;
					
					die "нет класса $newclass в " . $file->path if !$newclass->can("new");
					
					if($class->can("new")) {
						die "класс $class встречается в файлах $load и " . $file->path if $load;
						$load = $file->path;
					}
				}
			}
			
			next CLASS if $load;
		}
		
		my $pm = $class;
		$pm =~ s/::/\//g;
		$pm .= ".pm";
		
		eval { require $pm; };
		
		die "нет класса $class\nв путях:\n" . (join "\n", @$INC) . "\n" if !$class->can("new");
		
	}
	
	wantarray? @_: $_[0];
}

# оформляет метод функции
sub decorate {
	my ($self, $name, $class, $sub) = splice @_, 0, 4;
	
	my $decorator = "Decorator::$name";
	
	my $dec = ($decorator->can("new")? $decorator: $self->include($decorator))->new;
	
	$dec->{class} = $class;
	$dec->{name} = $sub;
	$dec->{args} = [@_];
	
	$dec->init(@_) if $dec->can("init");
	
	$dec->{noBefore} = 1 if !$dec->can("before");
	$dec->{noReplace} = 1 if !$dec->can("replace");
	$dec->{noAfter} = 1 if !$dec->can("after");
	
	my $key = "${class}::$sub";
	my $can = $class->can($sub);
	
	*$key = closure $dec, $key, $can, sub {
		my ($dec, $key, $address, $self) = splice @_, 0, 4;
		
		$dec->{me} = $self;
		my $save = \&$key;
		*$key = $address;
		
		$dec->{arguments} = [@_];
		
		$dec->before(@_) if !$dec->{noBefore};
		
		my @ret;
		
		if(!$dec->{noReplace}) {
			@ret = wantarray? $dec->replace(@{$dec->{arguments}}): scalar $dec->replace(@{$dec->{arguments}});
		}
		else {
			@ret = wantarray? $address->($self, @{$dec->{arguments}}): scalar $address->($self, @{$dec->{arguments}});
		}
		
		$dec->{return} = \@ret, $dec->after(@{$dec->{arguments}}), $dec->{return} = undef if !$dec->{noAfter};
		
		*$key = $save;
		$dec->{me} = $dec->{arguments} = undef;
		
		wantarray? @ret: $ret[0];
	} if !$dec->{noReplace} || !$dec->{noBefore} || !$dec->{noAfter};
	
	$self
}

1;
