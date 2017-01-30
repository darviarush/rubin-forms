package R::Html;
# всё что связано с html

use common::sense;
use R::App;

use Scalar::Util qw/blessed/;

# конструктор
sub new {
	my $cls = shift;
	bless [@_], ref $cls || $cls;
}


my %SIGN = (
'nbsp' => ' ',
'ensp' => ' ',
'emsp' => ' ',
'ndash' => '–',
'mdash' => '—',
'shy' => '­',
'copy' => '©',
'reg' => '®',
'trade' => '™',
'ordm' => 'º',
'ordf' => 'ª',
'permil' => '‰',
'pi' => 'π',
'brvbar' => '¦',
'sect' => '§',
'deg' => '°',
'micro' => 'µ',
'para' => '¶',
'hellip' => '…',
'oline' => '‾',
'acute' => '´',
'times' => '×',
'divide' => '÷',
'lt' => '<',
'gt' => '>',
'plusmn' => '±',
'sup1' => '¹',
'sup2' => '²',
'sup3' => '³',
'not' => '¬',
'frac14' => '¼',
'frac12' => '½',
'frac34' => '¾',
'frasl' => '⁄',
'minus' => '−',
'le' => '≤',
'ge' => '≥',
'asymp' => '≈',
'ne' => '≠',
'equiv' => '≡',
'radic' => '√',
'infin' => '∞',
'sum' => '∑',
'prod' => '∏',
'part' => '∂',
'int' => '∫',
'forall' => '∀',
'exist' => '∃',
'empty' => '∅',
'Oslash' => 'Ø',
'isin' => '∈',
'notin' => '∉',
'ni' => '∗',
'sub' => '⊂',
'sup' => '⊃',
'nsub' => '⊄',
'sube' => '⊆',
'supe' => '⊇',
'oplus' => '⊕',
'otimes' => '⊗',
'perp' => '⊥',
'ang' => '∠',
'and' => '∧',
'or' => '∨',
'cap' => '∩',
'cup' => '∪',
'euro' => '€',
'cent' => '¢',
'pound' => '£',
'current' => '¤',
'yen' => '¥',
'fnof' => 'ƒ',
'bull' => '•',
'middot' => '·',
'spades' => '♠',
'clubs' => '♣',
'hearts' => '♥',
'diams' => '♦',
'loz' => '◊',
'quot' => '"',
'amp' => '&',
'laquo' => '«',
'raquo' => '»',
'prime' => '′',
'Prime' => '″',
'lsquo' => '‘',
'rsquo' => '’',
'sbquo' => '‚',
'ldquo' => '“',
'rdquo' => '”',
'bdquo' => '„',
'larr' => '←',
'uarr' => '↑',
'rarr' => '→',
'darr' => '↓',
'harr' => '↔',
'crarr' => '↵',
'lArr' => '⇐',
'uArr' => '⇑',
'rArr' => '⇒',
'dArr' => '⇓',
'hArr' => '⇔',
'Alpha' => 'Α',
'Beta' => 'Β',
'Gamma' => 'Γ',
'Delta' => 'Δ',
'Epsilon' => 'Ε',
'Zeta' => 'Ζ',
'Eta' => 'Η',
'Theta' => 'Θ',
'Iota' => 'Ι',
'Kappa' => 'Κ',
'Lambda' => 'Λ',
'Mu' => 'Μ',
'Nu' => 'Ν',
'Xi' => 'Ξ',
'Omicron' => 'Ο',
'Pi' => 'Π',
'Rho' => 'Ρ',
'Sigma' => 'Σ',
'Tau' => 'Τ',
'Upsilon' => 'Υ',
'Phi' => 'Φ',
'Chi' => 'Χ',
'Psi' => 'Ψ',
'Omega' => 'Ω',
'alpha' => 'α',
'beta' => 'β',
'gamma' => 'γ',
'delta' => 'δ',
'epsilon' => 'ε',
'zeta' => 'ζ',
'eta' => 'η',
'theta' => 'θ',
'iota' => 'ι',
'kappa' => 'κ',
'lambda' => 'λ',
'mu' => 'μ',
'nu' => 'ν',
'xi' => 'ξ',
'omicron' => 'ο',
'pi' => 'π',
'rho' => 'ρ',
'sigmaf' => 'ς',
'sigma' => 'σ',
'tau' => 'τ',
'upsilon' => 'υ',
'phi' => 'φ',
'chi' => 'χ',
'psi' => 'ψ',
'omega' => 'ω',
'Rub' => '₽',
'rub' => '₽',
);

# возвращает текст без тегов
sub text {
	my ($self, $html) = @_;
	
	local ($1, $`, $', $&);
	
	$html =~ s!</?\w[^<>]*>!!g;
	
	# переводим html-сущности в символы
	$html =~ s!&#(\d+);!chr($1)!ge;
	
	$html =~ s!&(\w+);!$SIGN{$1}!ge;
	
	$html
}

# декодирует из html
sub unescape {
	my ($self, $html) = @_;
	todo;
}
*from = \&unescape;

# кодирует в html
sub escape {
	shift;
	goto &_escape;
}
*to = \&escape;

# магический метод render
sub render { $_[0] }

sub _escape {
	my ($val) = @_;
	if(ref $val and blessed $val and $val->can("render"))  {
		return @{$val->render};
		#return join "", @$val if Isa $val, "R::Html";
		#return @{$val->render} if Isa $val, "R::Form::Form", "R::Form::Input", "R::Form::Tag";
	}
	local ($', $', $1, $2, $3, $4);
	$val =~ s!(&)|(<)|(>)|(")|(')! $1? '&amp;': $2? '&lt;': $3? '&gt;': $4? '&quot;': '&#39;' !ge;
	$val
}

# для ошибок
sub escape_ansi {
	my ($self, $html) = @_;
	
	# переводим цвета в цвета html
	my $stack = 0;
	$html =~ s!(&)|(<)|(>)|(")|(')|\e\[(\d+)m|(\n)|( {2})|(\t)! $1? '&amp;': $2? '&lt;': $3? '&gt;': $4? '&quot;': $5? '&#39;': defined($6)? do {
		$_ = $Term::ANSIColor::ATTRIBUTES_R{$6};
		if(/clear|reset/) { my $x='</span>' x $stack; $stack = 0; $x }
		elsif(s/^on_//) { $stack++; "<span style='background-color:$_'>" }
		else { $stack++; "<span style='color:$_'>" }
	}:
	$7? "<br>\n":
	$8? " &nbsp;\n":
	" &nbsp; &nbsp; &nbsp; &nbsp;"
	!ge;
	
	$html
}

# чекбокс для css:
# <label for="id">кликать сюда</label> ... <% app.html.ch(id) %> <div>а тут всё меняется</div>
sub ch {
	my ($self, $label) = splice @_, 0, 2;
	my $checked = 0;
	$checked=shift if !defined $_[0] or Num $_[0];
	$checked = $checked? " checked": "";
	
	# my @attr = @_;
	# for(my $i=0; $i<@attr; $i+=2) {
		# $attr[$i+1] .= " ch-up" if $attr[$i] eq "class";
	# }
	
	my $attr = $self->attr(@_);
	my $id = "ch" . ++$app->{q}{HTML_CH};
	$self->new("<input id=\"$id\" class=\"ch\" type=checkbox$checked><label for=\"$id\"$attr>", _escape($label), "</label>");
}

# возвращает атрибуты
sub attr {
	my ($self, %attr) = @_;
	my $attr = join " ", map { defined($attr{$_})? "$_=\"" . _escape($attr{$_}) . "\"": $_ } keys %attr;
	$attr? " $attr": ""
}

# переводит абревиатурную запись (а ля css) в текст html
use R::Re;
sub emmet {
	my ($self, $abbr) = @_;
	local ($_, $`, $', $&, $1, $2);
	
	my $pre_text; # текст в начале тега
	my $post_text; # текст в конце тега
	my $is_tag;	# тег уже был
	my $is_id;	# id уже было
	my @class;	# классы тега
	my @attr;	# атрибуты тега
	my @pre;	# теги до
	my @post;	# теги после
	
	pos($abbr) = 0;
	while($abbr =~ /
		(?P<s>\s+|$) |
		(?P<tag>$R::Re::css_id) |
		(?: (?P<class>\.) | (?P<id>\#) ) (?P<name>$R::Re::css_id) |
		\[ (?P<attr> [^\[\]]+ ) \] |
		(?P<post>!)? \{ (?P<text> [^\{\}]+ ) \} |
		(?P<error> .* )
	/gxo) {
		if(exists $+{error}) {
			die("ошибка в описании на `$+{error}` в `$abbr`");
		}
		elsif(exists $+{tag}) {
			die "тег `$is_tag` уже описан" if defined $is_tag;
			$is_tag = $+{tag};
		}
		elsif(exists $+{id}) {
			die "id в теге `$is_tag` уже было" if defined $is_id;
			$is_id = $+{name};
		}
		elsif(exists $+{class}) {
			push @class, $+{name};
		}
		elsif(exists $+{attr}) {
			push @attr, $+{attr};
		}
		elsif(exists $+{text}) {
		
			if($is_id || $is_tag || @class || @attr) {
				if(exists $+{post}) {
					$post_text .= $+{text};
				}
				else {
					$pre_text .= $+{text};
				}
			} else {
				if(exists $+{post}) {
					unshift @post, $+{text};
				}
				else {
					push @pre, $+{text};
				}
			}
		}
		elsif(exists $+{s}) {	# окончание описания тега
			$is_tag = "div" if !defined $is_tag;
			
			my @abbr;

			push @abbr, " id=\"$is_id\"" if $is_id;
			push @abbr, " class=\"".join(" ", @class)."\"" if @class;
			push @abbr, join " ", "", map { s/=/="/, s/$/"/ if /^$R::Re::css_id=[^'"]/o; $_ } @attr if @attr;
			
			push @pre, join "", "<$is_tag", @abbr, ">$pre_text";
			unshift @post, "$post_text</$is_tag>";
			$pre_text = $post_text = $is_tag = $is_id = undef;
			@class = @attr = ();
		}
		else {
			die "неизвестная ошибка при разборе описания"
		}
	}
	
	#msg1 length $abbr, '!=', pos $abbr;
	
	die "строка не разобрана до конца `$abbr`" if defined pos $abbr;
	

	$self->new(join("", @pre), join "", @post);
}



1;
