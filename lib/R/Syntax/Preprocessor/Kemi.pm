package R::Syntax::Preprocessor::Kemi;
# препроцессор шаблонов - преобразует код шаблона в код Серебряны

use common::sense;
use R::App;

# конструктор
# file - файл
# text - код, если не указан - берётся из файла
# to - выходной файл
sub new {
	my $cls = shift;
	bless { @_ }, ref $cls || $cls;
}

my $re_inbrackets = $app->re->inbrackets;
my $re_id = $app->re->id;
my $re_space = $app->re->space;
my $re_space_ask = $app->re->space_ask;

# морфирует файл шаблона в код Серебряны
sub morf {
	my ($self) = @_;
	
	my $text = $self->{text} //= $app->file($self->{file})->read;
	
	my $echo = ' @ECHO ,= "';
	my $end = '"; ';
	
	my $inline = '", (';
	my $outline = '), "';
	
	my $escape = '" . app.html.escape(';
	
	my @ret;
	my $inherits;
	
	while($text =~ m{
		(?<text> .*? )
		( <% ( $re_space_ask (
			(?<set>		if | elseif | while | for | else | sub | block ) |
			(?<end>		end ) |
			(?<get>		get ) |
			(?<raw>		raw ) |
			(?<inherits>	extends | inherits )
		) \b)? (?<tail> .*? ) %> |
		\$ (?<get> (?<tail> $re_id $re_inbrackets? ( [\.:]$re_id $re_inbrackets? )* )) |
		$ )
	}gxnis) {
		do {
			local %+;
			my $txt = $+{text};
			$txt =~ s!"!""!g;
			$txt =~ s!\\!\\\\!g;			
			push @ret, $txt;
		};
		
		#msg1 {%+};
		
		if(exists $+{set}) {
			push @ret, $end, $+{set}, $+{tail}, "\n", $echo;
		}
		if(exists $+{end}) {
			my $lex_end = $+{end};
			my $tail = $+{tail};
			die "tail в end! $tail" if $tail !~ /^\s*$/;
			push @ret, $end, "\n$lex_end\n", $echo;
		}
		elsif(exists $+{get}) {
			push @ret, $escape, $+{tail}, $outline;
		}
		elsif(exists $+{raw}) {
			push @ret, $inline, $+{tail}, $outline;
		}
		elsif(exists $+{inherits}) {
			$inherits = $+{tail};
		}
		elsif(exists $+{tail}) {
			my $tail = $+{tail};
			if($tail =~ /==|=<|=>|(=)/ && defined $1) {
				push @ret, $end, $tail, "; ", $echo;
			} else {
				push @ret, $inline, $tail, $outline;
			}
		}
		else {
			
		}
	}
	
	my $name = $inherits? '__undefined__': 'render';
	my $return = $inherits? '': ' @(LOCAL DELETE "ECHO") join';
	
	msg1 join "", ($inherits? "EXTENDS $inherits\n": ()), 
	'SUB __UNDEF__
	BLOCK ', $name ,'
	', $echo, @ret, $end, '
	RETURN', $return, "
	END
END
me.render";
}

1;