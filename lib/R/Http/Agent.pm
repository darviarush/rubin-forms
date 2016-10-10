package R::Http::Agent;
# тестировщик страниц

use common::sense;
use R::App;


use WWW::Mechanize;
use Web::Query;
#use Http::Cookies;

# хак, испраляющий ошибку невернога referer-а
package WWW::Mechanize::PATCH {
	use base "WWW::Mechanize";
	sub _update_page {
		my $self = shift;
		my $res = $self->SUPER::_update_page(@_);
		$self->{last_uri} = $res->base->as_string;
		$res
	}
}

has qw/id mech cookie_jar log/;

# конструктор
sub new {
	my ($cls, $host, $timeout, %opt) = @_;
	
	
	my $cookie_jar = {};
	my $mech = WWW::Mechanize::PATCH->new( agent => 'LWP', autocheck => 0, cookie_jar => $cookie_jar, max_redirect=>1, %opt );
	
	
	$mech->timeout($timeout // 5);
	bless {
		id => 0,
		mech => $mech,
		pos => 0,
		text => undef,
		form => undef,
		link => undef,
		last => undef,		# последняя операция
		form_name => undef,
		Q => undef,			# для кеширования запроса
		host => $host // (ref $cls? $cls->{host}: do { my $port = $app->ini->{site}{port}; $port =~ /^\d+$/? "http://127.0.0.1:$port": $port }),
		log_html => "var/look.html",
		log_road_dir => "var/look",
		log_road => "var/look-road.log",
		log => 0,
		cookie_jar => $cookie_jar,
	}, ref $cls || $cls;
}

our $log_page_counter = 0;

# очищает настройки, после перехода на другую страницу
sub clear {
	my ($self) = @_;
	
	if($self->log) {
		my $content = $self->mech->content;
		
		$app->file($self->{log_html})->write($content);
		
		my $f = $app->file($self->{log_road_dir})->mkdir;
		$app->file($f->path . "/" . sprintf("%03d-%s%s", $log_page_counter++, 
			$self->{log_road},
			($self->{form_name}? "-".$self->{form_name}: "")) . ".html")->write($content);
		#msg $self->mech->text;
	}
	
	$self->{pos} = 0;
	$self->{text} = undef;
	$self->{form} = undef;
	$self->{link} = undef;
	$self->{last} = undef;
	$self->{form_name} = undef;
	$self->{Q} = undef;
	
	$self
}

# переходит на указанный url
sub go {
	my ($self, $url) = @_;
	($url) = $self->mech->response->base->as_string =~ m!^\w+://[^/]+(.*)$! if $url eq "";
	$self->it("\t$url");
	$self->mech->get("$self->{host}$url");
	$self->clear;
	die "переход на `$url` не произведён: " .  $self->mech->response->status_line if !$self->mech->success;
	$self
}

# переходит на указанный url. Не выдаёт ошибку, если статус не 200
sub goto {
	my ($self, $url) = @_;
	$self->it("\t$url");
	$self->mech->get("$self->{host}$url");
	#die "переход на `$url` не произведён" if !$self->mech->success;
	$self->clear;
	$self
}

# перезагружает страницу
sub reload {
	my ($self) = @_;
	$self->go( "" );
}

# проверяет титл
sub title {
	my ($self, $title) = @_;
	if(ref $title) {
		die "заглавие не совпадает: ".$self->mech->title." vs /$title/" if $self->mech->title !~ $title;
	} else {
		die "заглавие не совпадает: ".$self->mech->title." vs `$title`" if $self->mech->title ne $title;
	}
	
	$self
}

# возвращает Web::Query
sub Q {
	my ($self, $query) = @_;
	($self->{Q} //= Web::Query->new_from_html($self->mech->content))->find($query);
}

# проверяет что на странице есть текст n раз
sub count {
	my ($self, $text, $size) = @_;
	$self->look("", $text, $size);
}

# проверяет что на странице есть текст
sub look {
	my ($self, $query, $text, $size) = @_;
	if(@_>=3) {
		
		if($query ne "") {
		
			my $q = $self->Q($query);

			die "по $query не найдено тегов" if $q->size == 0;
			
			my $ref = ref $text? $text: do { my $t = quotemeta $text; qr/$t/ };
			$q = $q->filter(sub { my($i, $e)=@_; $e->as_html =~ $ref });
			
			die "количество найденных тегов не совпадает  $query =~ $ref: ".$q->size." != $size" if defined $size and $q->size != $size;
			die "ничего не найдено  $query =~ $ref" if !defined $size and $q->size==0;
			
			return $self;
		}
		
	} else {
		$size = $text;
		$text = $query;
	}
	
	
	my $ref = ref $text? $text: do { my $t = quotemeta $text; qr/$t/ };
	my $content = $self->mech->content;
	
	
	if(defined $size) {
		my $i = 0;
		while($content =~ /$ref/g) { $i++ }
		die "текст /$ref/ встречается $i раз, а не $size" if $i != $size;
	} else {
		die "не вижу /$ref/" if $content !~ /$ref/;
	}
	
	# my $pos = $self->{pos};
	# if(ref $text) {
		# die "не вижу /$text/" if not $self->mech->content =~ /$text/g;
		# $self->{pos} = pos();
	# } else {
		# die "не вижу `$text`" . ($pos? " после $pos": "") if 0 > ($self->{pos} = index $self->mech->content, $text);
		# $self->{pos} += length $text;
	# }
	
	$self->{text} = $text;
	$self->{last} = "look";
	
	$self
}

# проверяет что на странице нет текста
sub looknt {
	if(@_>=3) {
		my ($self, $query, $text) = @_;
		my $q = $self->Q($query);
		#die "количество найденных тегов не совпадает  $query =~ $text" if defined $size and $q->size != $size;
		#die "ничего не найдено  $query =~ $text" if $q->size!=0;

		if($text eq "") {
			die "есть $query" if $q->size>0;
			return $self;
		}
		
		local $_;
		$_ = $q->as_html;
		if(ref $text) {
			die "вижу  $query =~ /$text/" if /$text/;
			#$self->{pos} = pos();
		} else {
			die "вижу  $query of `$text`" if 0 > index $_, $text;
		}
	
		return $self;
	}
	
	
	my ($self, $text) = @_;
	
	my $pos = $self->{pos};
	if(ref $text) {
		die "вижу /$text/" if $self->mech->content =~ /$text/g;
	} else {
		die "вижу `$text`" . ($pos? " после $pos": "") if 0 <= index $self->mech->content, $text;
	}
	
	$self
}


# форма: #id, name, "!f1 f2"
# остальные параметры: поля формы для заполнения
sub form {
	my ($self, $name, %fld) = @_;

	$self->{form_name} = $name;
	$self->{last} = "form";
	
	# устанавливаем форму
	my $form;
	if($name =~ s/^~//) {
		my @fld = split /\s+/, $name;
		$form = $self->mech->form_with_fields(@fld);
	} elsif($name =~ s/^#//) {
		$form = $self->mech->form_id( $name );
	} else {
		#$form = $self->mech->form_name( $name );
		my $number;
		my $i=1;
		
		#my @forms = $self->mech->forms;
		
		for $form ($self->mech->forms) {
			$number = $i, last if $form->attr("name") eq $name;
			$i++;
		}
		$form = $self->mech->form_number( $number ) if defined $number;
	}
	
	die "не вижу форму $name" if !$form;
	
	my $input_len = @{$form->{inputs}};
	while(my ($key, $val) = each %fld) {
		my $input = $form->find_input($key);
		die "не вижу инпут $key у формы $name" if !$input;
		if($input->type eq "file" && ref $val eq "ARRAY") {
			$form->value($key, $val->[0]);
			
			for(my $i=1; $i<@$val; $i++) {
				push @{$form->{inputs}}, my $inp = bless {%$input}, ref $input;
				$inp->file($val->[$i]);
			}
		}
		elsif($input->type eq "select") {
			$self->mech->select($key, $val);
		} else {
			$self->mech->field($key, $val);
		}
	}

	$self->{form} = $form;
	
	$self->_click;
	
	splice @{$form->{inputs}}, $input_len;
	
	$self
}

# проверяет, что есть ссылка
sub link {
	my ($self, $text, $res) = @_;
	
	my $link;
	
	if(defined $res) {
		my $key = $text;
		$key .= "_regex" if ref $res;
		$link = $self->mech->find_link($key => $res);
	}
	elsif(ref $text) {
		$link = $self->mech->find_link(text_regex => $text);
	}
	elsif($text =~ s/^\^//) {
		$link = $self->mech->find_link(name => $text);
	}
	elsif($text =~ s/^#//) {
		$link = $self->mech->find_link(id => $text);
	}
	elsif($text =~ s/^!//) {
		$link = $self->mech->find_link(url => $text);
	}
	else {
		my $re = quotemeta $text;
		$link = $self->mech->find_link(text_regex => qr/$re/);
	}
	
	die "Нет ссылки \"$text\"" if !defined $link;
	die "Ссылка не <a>" if $link->tag ne "a";
	
	$self->{link} = $link;
	$self->{last} = "link";
	
	#$self->it(":empty", "\tlink by \"", $text, "\" found ", $link->url, " ", $link->text);
	
	$self->_click;
	
	$self
}

# заполняет указанный look input
sub type_ {
	my ($self) = @_;
	$self
}

# нажимает на указанное последним see ссылку или кнопку
sub _click {
	my ($self) = @_;
	
	my $last = $self->{last};
	if($last eq "form") {
		my $submit = $self->{form}->find_input( undef, 'submit' );
		my $form_name = $self->{form_name};
		die "У формы  нет submit" if !$submit;
		$self->it("\t" . $self->{form}->method . " " . $self->{form}->action . " form/$form_name");
		$self->mech->click_button(input => $submit);
		$self->clear;
		my $count_errors = $self->mech->response->header("X-Errors");
		die "на форме $form_name - ошибок $count_errors: " . join "",
			@{$self->Q("div.error")->map(sub{ my ($i, $q)=@_; $q->prev->attr("name") . ": " . $q->text . "\n" })},
			@{$self->Q("ol.error li")->map(sub{ my ($i, $q)=@_; $q->text . "\n" })}
		if $count_errors;
		die "ошибка при нажатии на $form_name.submit: " . $self->mech->response->status_line if !$self->mech->success;
	} elsif($last eq "link") {
		my $url = $self->{link}->url;
		$self->goto($url);
		$self->clear;
		my $count_errors = $self->mech->response->header("X-Errors");
		die "на форме ".$self->mech->uri->path." - ошибок $count_errors: " . join "", @{$self->Q("ol.error li")->map(sub{ my ($i, $q)=@_; $q->text . "\n" })} if $count_errors;
		die "переход по ссылке $url не произведён: " . $self->mech->response->status_line if !$self->mech->success;
	} elsif($last eq "look") {
		$self->_click_by_look;
		$self->clear;
		die "переход по ссылке ".$self->{link}->url." не произведён: " . $self->mech->response->status_line if !$self->mech->success;
	} else {
		die "ничего не было выбрано для клика";
	}

	$self
}


# предыдущий - look
sub _click_by_look {
	my ($self) = @_;

	local ($_, $`, $', $&);
	
	$_ = $self->mech->content;
	
	# устанавливаем pos
	my $pos = $self->{pos};
	my $p2;
	my $url;
	
	while( /<a\s[^<>]*href=(?:['"]([^'"]+)['"]|(\S+))[^<>]*>/gis ) {
		last if pos() > $pos;
		$p2 = pos();
		$url = $1 || $2;
	}
	
	die "click by look: нет <a>" if !defined $p2;
	
	$_ = substr $_, $p2, $pos-$p2;
	
	# проверяем, что мы входим в а
	die "click by look: </a>" if /<\/a\s*>/i;
		
	$self->go($url);

	
	# unless(/<(input|a)(\s[^<>]*)?>[^<>]+\G/i) {	
		# # возможно input далее
		# die "click: не нахожу <input> или <a>" if !/\G.*?<(input)(\s[^<>]*)?>[^<>]+/i;
	# }
	# if(lc $1 eq "a") {	# выцепляем ссылку
		# $_ = $2;
		# die "click: нет href" if !/\shref=['"]?(\S+)['"]?/i;
		# my $url = $1;
		# $self->go($url);
	# } else {	# подсчитываем <form>
		# $_ = $2;
		# die "click: <input> не кнопка (submit)" if !(/\stype=['"]?(\S+)['"]?/i && lc $1 eq "submit");
		# $self->set_current_form_by_pos->click;
	# }
	
	$self
}

# устанавливает форму по позиции курсора
sub set_current_form_by_pos {
	my ($self, $name) = @_;
	local ($_, $`, $', $&);
	$_ = $self->mech->content;
	my $pos = $self->{pos};
	pos() = 0;
	my $n = 0;
	while(pos() < $pos && /<form[\s>]/ig) { $n++ }
	$self->mech->form_number($n);
	
	$self->{last} = "form";

	$self
}


# комментарий. Логируется при проходе
sub it {
	my $self = shift;
	$app->log->info($self->id, @_) if $self->{log};	
	$self
}


# оканчивает цепочку
sub end {
	1
}

1;