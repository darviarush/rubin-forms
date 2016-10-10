package R::Model::Type::Msg;
# текстовое поле, преобразует текст в html.
# выделяются линки и переводы строк заменяются на br
# заменяются последовательности пробелов и знаки табуляции
# ненормативная лексика заменяется на ***

use common::sense;
use R::App;

#use overload "" => \&stringify;

# # конструктор
# sub new {
	# my ($cls) = @_;
	# bless {}, ref $cls || $cls;
# }

# возвращает тип колумна в базе 
sub typeCol {
	my ($field, $length) = @_;
	
	$field->input("area");
	
	$app->meta->getTextType($length // ((1 << 16) - 1));
}

# конструктор - возвращает новый объект из базы
sub fromCol {
	my ($field, $html) = @_;
	bless {
		html => $html
	}, $field->{class};
}

# преобразует из объекта в представление базы
sub toCol {
	my ($self) = @_;
	$self->{html}
}

# рендерит в шаблоне
sub render {
	my ($self) = @_;
	my $html = $self->{html};
	
	# почему на этом этапе, а не сохраняем в базу?
	# да потому, что текст может понадобиться для изменения коммертария в textarea
	# так же потому что в случае дополнения этого модуля старые записи будут отредактированы одинаково
	# конвертируем
	$html = $app->html->escape($html);
	$html =~ s{
		(?P<br> \n) |
		#(?P<space> [\ \t]+ ) |
		(?P<link> \b([a-z]+://|www\.) (?: \S+ (?P<unlink> [\.!\?] (?:\s|$)) | \S+ ) ) 
	}{
		&_convert;
	}gxei;
	
	bless [$html], "R::Html";
}



# конвертирует текст в html
sub _convert {
	my ($html) = @_;
	exists $+{br}? "<br>":
	exists $+{link}? do {
		my $unlink = $+{unlink};
		my $link = $app->html->escape($+{link}); 

		$link = substr $link, 0, -length $unlink if defined $unlink;
		my $real_link = $link;
		
		$link = "http://$link" if $link !~ /^\w+:/;
		
		my $gen_link = sub { "<a href=\"$link\" target=_blank>$real_link</a>" };
		
		my $text_link;
		
		if($real_link =~ /\.(?:gif|png|jpeg|jpe|jpg)(?:\?|#|$)/i) {
			$text_link = "<a href=\"$link\" target=_blank><img src='$link'></a>";
		}
		elsif($real_link =~ m![\./]youtube\.com/.*?([^/]+)(?:\?|#|$)!i) {
			$text_link = "<iframe src=\"//youtube.com/embed/$1\" frameborder=0 allowfullscreen style='max-width:100%' width=540 height=480></iframe>" . $gen_link->();
		}
		elsif($real_link =~ m![\./](?:vk\.com|vkontakte\.ru)/video(\d+)_(\d+)!i) {
			$text_link = "<iframe src=\"//vk.com/video_ext.php?oid=$1&id=$2\" frameborder=0 allowfullscreen style='max-width:100%' width=540 height=480></iframe>" . $gen_link->();
		}
		else {
			$text_link = $gen_link->();
		}
		# elsif($real_link =~ m![\./]rutube\.ru/video/([^/]+)/!i) {
			# $text_link = "<iframe src=\"//rutube.ru/play/embed/$1\" frameborder=0 allowfullscreen style='max-width:100%' width=540 height=480></iframe>";
		# }
		
		#<iframe width="500" height="281" src="//rutube.ru/play/embed/7431068" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowfullscreen></iframe>
		
		#http://vk.com/video2290682_456239053
		#<iframe src="//vk.com/video_ext.php?oid=2290682&id=456239053&hash=da24778609e1852d&hd=2" width="853" height="480"  frameborder="0"></iframe>
		
		$text_link . $unlink
	}:
	die "что-то неопределённое `$&`";
}

1;