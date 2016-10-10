package R::View::Metafilter;
# пакет содержит суперфильтры шаблонов

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}


# форматирует html
sub htmlformatter {
	my ($view, $html, $prev) = @_;		
	return $prev eq " "? "": " " if $html =~ /^\s+$/;
	$html
}


# фильтр парсит class="..." и создаёт найденные в style.css 
sub css_class {
	my ($view, $html, $prev) = @_;
	
	my $haclasses = $view->{meta}{haclasses} //= {};
	my @classes;
	my $flag = $view->{meta}{flagclasses};

	# если class="xxl <% ... %> m <% ... %> right"
	if(defined $flag) {
		if($html =~ /^([\w-\s])*['"]/) {
			$html = "$flag$html";
			undef $view->{meta}{flagclasses};
		}
		elsif($html =~ /^([\w-\s])*$/) {
			$view->{meta}{flagclasses} .= $html;
		}
		else {
			undef $view->{meta}{flagclasses};
		}
	}
	
	if($html =~ /\bclass=['"]([\w-\s]*)$/) {
		$view->{meta}{flagclasses} = $1;
	}
	
	push @classes, grep { my $x=!exists $haclasses->{$_}; $haclasses->{$_}=1; $x } $app->css->reg_html_classes($html);
	
	$view->add_begin( "\$app->css->reg(qw/" . join(" ", @classes) . "/);" ) if @classes;
	
	$html
}

# фильтр заменяет &name; на значки из фонтов и спрайты
sub html_sign {
	my ($view, $html) = @_;
	local ($1, $`, $', $&);

	my $sign = $app->sign->{orig};		# подгружаем знаки
	my $classes = $app->sprite->{classes};
	
	{use bytes;
		$html =~ s!&([\w-]+);?!
			{ no bytes; 
				my $x=$sign->{$1}; defined($x)? "<span class=sign>$x</span>":
				defined($x=$classes->{$1})? "<span class=$x>&nbsp;</span>":
				$&;
			}
		!ge;
	}
	$html
}


1;