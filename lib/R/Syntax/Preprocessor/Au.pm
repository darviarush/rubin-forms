package R::Syntax::Preprocessor::Au;
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
		( <% ((
			(?<set>		if | elseif | while | for | end | else ) |
			(?<get>		get ) |
			(?<raw>		raw ) |
			(?<inherits>	extends | inherits )
		) \b)? (?<tail> .*? ) %> | $ )
	}gxnis) {
		my $txt = $+{text};
		$txt =~ s!"!""!g;
		$txt =~ s!\\!\\\\!g;
		
		push @ret, $txt;
		
		if(exists $+{set}) {
			push @ret, $end, $+{set}, $+{tail}, "\n", $echo;
		}
		elsif(exists $+{get}) {
			push @ret, $escape, $+{tail}, $outline;
		}
		elsif(exists $+{raw}) {
			push @ret, $inline, $+{tail}, $outline;
		}
		elsif(exists $+{tail}) {
			if($+{tail} =~ /==|=<|=>|(=)/ && defined $1) {
				push @ret, $end, $+{tail}, $echo;
			} else {
				push @ret, $inline, $+{tail}, $outline;
			}
		}
		elsif(exists $+{inherits}) {
			$inherits = $+{tail};
		}
		else {
		}
	}
	
	my $name = $inherits? '__undefined__': 'render';
	my $return = $inherits? '': ' @(LOCAL DELETE "ECHO") join';
	
	join "", ($inherits? $inherits: ()), 'SUB __UNDEF__ THEN BLOCK ', $name ,' THEN DO ', $echo, @ret, $end, 'RETURN', $return, " END\nme.render";
}

1;