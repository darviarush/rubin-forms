package R::Css;
# Perl Awesome Stylesheets - pcss или pass
# конструктор правил css

use common::sense;
use R::App;

use R::Css::Type;
use R::Re;

use Exporter 'import';
our @EXPORT = qw/px em pc attr unit deg rgb hsl/;

# конструктор
sub new {
	my ($cls) = @_;
		
	my $self = bless {
		dom => {},			# пулы name => {maxim=>, maximus=>...}
		serf => [],			# стек для пулов
		register => {},		# зарегистрированные функции для обработки классов
		classes => {},		# классы уже выведенные в css
	}, ref $cls || $cls;
	
	# создаём правило
	$self->prince("main");
	
	$self
}

################ единицы измерений

our %UNIT = qw/% em ex px pc mm sm s ms rem rex/;

# # в стандартных lineHeight
# sub lh($) {
	# my ($val) = @_;
	# "${val}em"
# }


# em
sub em($) {
	my ($val) = @_;
	"${val}em"
}

# px
sub px($) {
	my ($val) = @_;
	"${val}px"
}

# проценты, пико - pk
sub pс($) {
	my ($val) = @_;
	"${val}%"
}

# градусы
sub deg {
	my ($val) = @_;
	"${val}deg"
}

# возвращает атрибут для content: attr(attr)
sub attr ($) {
	my ($attr) = @_;
	\"attr($attr)"
}

# возвращает единицу измерения или выдаёт ошибку если её нет
sub unit {
	my ($v) = @_;
	die "app.css::unit: Ну что сказать? `$v` без числа" if not $v =~ s/^-?(?:\d+|\d*\.\d+)//;
	die "$v не единица измерения css" if !exists $UNIT{$v};
	$v
}

# цвет rgb
# примеры:
#	rgb "00aaff", 0.5
#	rgb 0, 0, 1, 0.5	# измеряется не от 0 до 255, а от 0 до 1
sub rgb ($$$;$) {
	my ($r, $g, $b, $a) = @_;
	
	$r = int $r*255;
	$g = int $g*255;
	$b = int $b*255;
	
	if(defined $a) {
		return "rgba($r,$g,$b,$a)";
	}
	
	return sprintf "#%02x%02x%02x", $r,$g,$b;
}

sub hsl ($$$;$) {
	my ($h, $s, $l, $a) = @_;
	
	$h = int $h*359;
	$s = int($s*100) . "%";
	$l = int($l*100) . "%";
	
	if(defined $a) {
		return "hsla($h,$s,$l,$a)";
	}
	
	return "hsl($h,$s,$l)";
}

# изменяет значения
# если 
sub unitSize {
	my $self = shift;
	local $_;
	$_ = &R::Css::Type::size for @_;
	$self
}

# переводит в градусы из 0..1 -> 0..360
sub unitDeg {
	my $self = shift;
	local $_;
	$_ = &R::Css::Type::deg for @_;
	$self
}

################ стек

# ищет среди зарегистрированных функций css-класс
# если он не найден - вызывает по маске функцию-создателя, которая прописывает класс
sub reg {
	my $self = shift;
	
	my $classes = $self->{classes} //= {};
	my $register = $self->{register};
	
	for my $class (@_) {
		next if exists $classes->{$class};
		
		my $mask = $class;
		my @args = ();
		next if $mask !~ s/\d+/ push @args, $&; "*"/ge;
		
		my $fn = $register->{$mask};
		
		next if !defined $fn;
		
		$classes->{$class} = 1;
		
		$fn->($class, @args);	# добавляет $css->код
	}
	
	$self
}

# получает html, который парсит в поисках зарегистрированных классов и добавляет в css
sub reg_html {
	my $self = shift;
	
	$self->reg( reg_html_classes(@_) );
	
	$self
}

# получает html, который парсит в поисках зарегистрированных классов
sub reg_html_classes {
	my $self = shift;
	
	my $register = $self->{register};
	
	my @out;
	
	local ($_, $`, $', $&, $1, $2); 
	
	for my $html (@_) {
		while($html =~ m!\sclass=(?:['"]([^'"]+)|([\w-]+))!g) {
			my @re = defined($1)? split(/\s+/, $1): $2;
			push @out, grep {
				my $x = $_;
				$x =~ s/\d+/*/g;
				exists $register->{$x}
			} @re;
		}	
	}
	
	@out
}

# регистрирует классы идущие через пробел
sub reg_class {
	my ($self, $html) = @_;
	
	$self->reg( split /\s+/, $html );
	
	$self
}

# регистрирует функцию-создателя
# маски: наименования классов со *-ми вместо цифровых параметров
sub register {
	if(@_>2) {
		my ($self, $mask, $sub) = @_;
		$self->{register}{$mask} = $sub;
		$self
	} else {
		my ($self, $mask) = @_;
		$self->{register}{$mask};
	}
}

# сохраняет цепочки правил в файл
sub save {
	my ($self, $path) = @_;
	
	die "не хватает end" if @{$self->{serf}} > 1;
	die "лишние end" if @{$self->{serf}} < 1;
	
	my $f = $app->file->from($path);
	my $s = $self->stringify;
	
	$f->write($s) if !$f->exists or $s ne $f->read;
	
	$self->{saveTime} = $f->mtime;
	
	$self
}

# очищает css, не портя зарегистрированных классов
sub clear {
	my ($self) = @_;
	
	$self->{dom} = {};
	$self->{serf} = [];
	
	$self
}

# клонирует себя вместе с register и classes
sub clone {
	my ($self) = @_;
	
	my $new = bless {%$self}, ref $self;
	
	$new->{register} = {%{$self->{register}}};
	$new->{classes} = {%{$self->{classes}}};
	
	$new
}

# # импортирует (читает и парсит) файл *.css или включает файл *.pl, *.pm, *.pcss или *.pass
# sub require {
	# my ($self, $path) = @_;
	
	# my $files = $app->file($path)->glob;
	# if($files->length > 1) {
		# for $path ($self->files) { $self->include($path) }
		# return $self;
	# }
	
	# return $self if $self->{INC}{$path};
	# $self->{INC}{$path} = 1;
	
	# if($path =~ /\.(?:pl|pm|pass|pcss)$/) { require $path }
	# else {
		# $files->read
	# }
	
	# $self
# }

# парсит css-текст и добавляет в css
sub parse {
	my $self = shift;
	
	local ($_, $`, $', $&);
	($_, my $path) = @_;
	
	my $prince = 0;
	my $intro;
	my $the;
	my @set;
	my @S;
	my $rule;
	
	while( /\G
		\@ (?P<media> [\w-]+ ) \s+ (?P<migo> (?:$R::Re::string|[^\{\};])+) |
		(?P<rule> [\w-]+ ) \s*:\s* (?P<value> (?:$R::Re::string|[^\{\};])+) ) |
		(?P<the> [\{\};]+) |
		(?P<open> \{ ) |
		(?P<close> \} ) |
		(?P<end> ;) |
		(?P<rem> \/\* .* \*\/ ) |
		(?P<space>\s+)
	/xgsm ) {
		if($+{rem}) { $self->insert($+{rem}) }
		elsif($+{media}) {
			$intro = "\@$+{media} $+{migo}";
		}
		elsif($+{the}) { $the = $+{the} }
		elsif($+{rule}) { $rule = 1; push @set, $+{rule}, $+{value}; }
		elsif($+{open}) {
			if(defined $intro) {
				$self->prince("prince" . $prince++);
				$self->intro($intro);
				$intro = undef;
				push @S, "prince";
			}
			elsif(defined $the) {
				$self->the($the);
				$the = undef;
				push @S, "the";
			}
			else {
				die "нет ни intro, ни the";
			}
		}
		elsif($+{close}) {
			die "стек пуст" if !@S;
			if("the" eq pop @S) {
				$self->set(@set) if @set;
				@set = ();
			} else {
				$self->end;
			}
		}
		elsif($+{end}) {
			if(defined $intro) {
				$self->insert($intro . ";");
			}
			elsif(defined $the) {
				die "; после the `$the`";
			}
			elsif($rule) {
				$rule = undef;
			}
			else {
				die "; не после rule";
			}
		}
		elsif($+{space}) {}
		else {
			die "что-то неизвестное было распознано парсером css";
		}
	}
	
	if( pos() != length $_) {
		$_ = substr $_, 0, pos();
		my $lineno = 1;
		while(/\n/) { $lineno++ }
		die "ошибка распознавания кода css: $path:$lineno";
	}
	
	
	$self
}

# обрабатывает каждое значение
sub xak {
	my ($self, $key, $val) = @_;
	
	if(ref $val eq "ARRAY") {
		my $sep = $R::Css::Type::Sep{$key} // ", ";
		$val = join $sep, @$val;
	}
	
	my $norm = $key;
	$self->normalize($norm);
	
	my (@key, @val);
	
	if(my $unit = $R::Css::Type::KeyVal{$key}{$val}) {
		$_ = $val;
		$R::Css::Type::k = $norm;
		return $unit->($self);
	}
	
	if(my $unit = $R::Css::Type::Type{$key}) {
		$_ = $val;
		$R::Css::Type::k = $norm;
		@val = $unit->($self);
	}
	
	if(my $onkey = $R::Css::Type::Key{$key}) {
		$_ = $val;
		$R::Css::Type::k = $norm;
		@key = $onkey->($self);
	}
	
	@key = $norm if !@key;
	@val = $val if !@val;
	
	my @out;
	for my $k (@key) {
		push @out, "$k: $_" for @val;
	}
	join ";\n", @out;
}


# преобразует в строку
sub stringify {
	my ($self, $prince) = @_;
	
	local $_;
	my @f;

	my @prince = $prince //= $self->serf;

	if($prince->{keyframes}) {
		my $intro = substr $prince->{intro}, 1;
		for my $vendor (qw/webkit o moz ms/) {
			unshift @prince, {%$prince, intro=>"\@-$vendor-$intro"};
		}
	}
	
	for $prince (@prince) {
		
		push @f, "/* $prince->{name} */\n" if $prince->{name};
		
		push @f, $prince->{intro}, " {\n" if $prince->{intro};
		
		for my $maxim (@{$prince->{maximus}}) {
		
			push(@f, $maxim), next if !ref $maxim;
			push(@f, $self->stringify($maxim)), next if exists $maxim->{maximus};
		
			my $sep = @{$maxim->{order}} == 1? "": "\n";
		
			push @f, $maxim->{the}, " {$sep";
			#my $set = $maxim->{set};
			for my $m (@{$maxim->{order}}) {
				my ($key, $val, $important) = @$m;
				#print $f "\t";
				push @f, $self->xak($key, $val);
				push @f, "!important" if $important;
				push @f, $sep? ";\n": "";
			}
			push @f, "}\n";
		}
		
		push @f, "\n}\n" if $prince->{intro};
	}
	
	join "", @f;
}


# нормализует ключ
sub normalize {
	$_[1] =~ s/[A-Z]/ "-" . lc $&/ge;
	undef
}

# возвращает верхушку стека (prince)
sub serf {
	my ($self) = @_;
	my $serf = $self->{serf};
	$serf->[$#$serf]
}

# создаёт новое правило или возвращает текущее
sub the {
	if(@_>1) {
		my ($self, $the) = @_;
		my $serf = $self->serf;
		push @{$serf->{maximus}}, $serf->{maxim}{$the} = $serf->{the} = { the => $the };
		$self
	} else {
		shift->serf->{the};
	}
}

# создаёт именованный пул
sub prince {
	my ($self, $name) = @_;
	
	my $prince = { maxim => {}, maximus => [] };
	
	$self->{dom}{$name} = $prince, $prince->{name} = $name if defined $name;
	
	if($self->serf) {
		$self->serf->{the} = undef;
		push @{$self->serf->{maximus}}, $prince;
	}
	
	push @{$self->{serf}}, $prince;
	
	$self
}

# конец пула
sub end {
	my ($self) = @_;
	die "end: стек пуст" if @{$self->{serf}} == 0;
	if( pop(@{$self->{serf}})->{animedia} ) {	# animedia - для анимации
		die "end: стек пуст" if @{$self->{serf}} == 0;
		pop @{$self->{serf}};
	}
	
	$self
}

# переходит в указанный пул и писаться будет в него
sub gosub {
	my ($self, $prince) = @_;
	
	my $serf = $self->{dom}{$prince};
	
	die "нет prince($prince)" if !$serf;
	
	push @{$self->{serf}}, $serf;
	
	$self
}

# копирует media пула
sub goto {
	my ($self, $prince) = @_;
	
	my $serf = $self->{dom}{$prince};
	die "нет prince($prince)" if !$serf;
	die "нет медия-запроса в prince($prince)" if !$serf->{intro};
	
	$self->prince("$prince.copy")->intro($serf->{intro})
}

# завершает цепочку
sub final {}

# расширяет правило из указанного селектора
sub like {
	my ($self, $the, $prince) = @_;
	
	$prince = $self->{dom}{$prince // "main"};
	
	die "нет неймспейса $prince" unless $prince;
	die "не найдено правило" unless exists $prince->{maxim}{$the};
	
	my $from = $prince->{maxim}{$the};
	my $the = $self->the;
	
	push @{$the->{order}}, @{$from->{order}};
	%{$the->{set}} = (%{$the->{set}}, %{$from->{set}});
	
	$self
}

# вставляет файл или файлы
sub include {
	my ($self, $file) = @_;
	push @{$self->serf->{maximus}}, $app->file->from($file)->glob->reads("\n");
	$self
}

# вставляет текст
sub insert {
	my ($self, $insert) = @_;
	push @{$self->serf->{maximus}}, $insert;
	$self
}

# вставляет текст и новую строку
sub insertln {
	my ($self, $insert) = @_;
	push @{$self->serf->{maximus}}, $insert . "\n";
	$self
}


# комментарий
sub rem {
	my ($self, $rem) = @_;
	local ($`, $');
	$rem =~ s!\*/!\* /!g;
	$self->insert("/* " . $rem . " */")
}

# оборачивает пулл
sub intro {
	my ($self, $intro) = @_;
	$self->serf->{intro} = $intro;
	$self
}

# оборачивает пул в медиа-запрос или 
sub media {
	my ($self, $query) = @_;
	#$query = "($query)" if $query !~ /^\(/;
	$self->intro( "\@media $query" );
	$self
}

# устанавливает css-стиль
sub set {
	my $self = shift;
	
	my $the = $self->the;
	my $set = $the->{set} //= {};
	my $order = $the->{order} //= [];
	
	for(my $i=0; $i<@_; $i+=2) {
		my ($key, $val) = @_[$i, $i+1];
		#@$order = grep { $_->[0] ne $key } @$order ;
		push @$order, [$key, ($set->{$key} = $val)] if defined $val;
	}
	
	$self
}

# переустанавливает свойства последнего стиля
sub reset {
	my $self = shift;
	
	my $the = $self->the;
	my $set = $the->{set} //= {};
	my $order = $the->{order} //= [];
	
	for(my $i=0; $i<@_; $i+=2) {
		my ($key, $val) = @_[$i, $i+1];
		
		if(exists $set->{$key}) {
			for(my $j=$#$order; $j>=0; $j--) {
				$order->[$j][1] = $val, last if $order->[$j][0] eq $key;
			}
		} else {
			push @$order, [$key, $val] if defined $val;
		}

		$set->{$key} = $val;
	}
	
	$self
}

# добавляет к css-стилю
sub add {
	my $self = shift;
	
	my $the = $self->the;
	my $set = $the->{set} //= {};
	my $order = $the->{order} //= [];
	
	for(my $i=0; $i<@_; $i+=2) {
		my ($key, $val) = @_[$i, $i+1];
		
		next if !defined $val;
		
		if(exists $set->{$key}) {
			if(ref $set->{$key} eq "ARRAY") { push @{$set->{$key}}, $val; }
			elsif(!defined $set->{$key}) { $self->reset( $key => $val ) }
			else { $self->reset( $key => [$set->{$key}, $val] ) }
		}
		else {
			$self->reset($key => $val)
		}
	}
	
	$self
}


# возвращает по ключу значение, а если его нет - устанавливает
sub get {
	my ($self, $key, $val) = @_;
	my $v = $self->the->{set}{$key};
	
	if(!defined $v) {
		$self->reset($key => $val) if defined $val;
		$val;
	}
	else {
		$v
	}
}

# возвращает последний в массиве, используется с add
sub ret {
	my ($self, $key, $val) = @_;
	my $v = $self->the->{set}{$key};
	if(ref $v eq "ARRAY") {
		$v->[$#$v];
	}
	elsif(defined $v) {
		$v
	}
	else {
		$self->add($key => $val) if defined $val;
		$val
	}
}

# устанавливает последний
sub top {
	my ($self, $key, $val) = @_;
	my $v = $self->the->{set}{$key};
	if(ref $v eq "ARRAY") { $v->[$#$v] = $val }
	else { $self->reset($key => $val) }
	
	$self->get($key) if $key eq "x";
	
	$self
}

# проверяет на существование ключ в the
sub exists {
	my ($self, $key, %opt) = @_;
	
	#if($opt{media})
	#if($opt{the})
	
	# должен пробегать по всем селекторам, содержащим это
	
	exists $self->the->{set}{$key}
}

# устанавливает, если ещё не установлено
sub setdefault {
	my $self = shift;
	
	for(my $i=0; $i<@_; $i+=2) {
		my ($key, $val) = @_[$i, $i+1];
		$self->set($key => $val) if !$self->exists($key);
	}
	
	$self
}

# всем ключам в текущем the делает important
# если указан номер, то important делается только n ключам
sub important {
	my ($self, $n) = @_;
	
	for my $set (reverse @{$self->the->{order}}) {
		$set->[2] = 1;
		last if --$n == 0;
	}
	
	$self
}


################ размеры

# высота строки
sub line {
	my ($self, $val) = @_;
	$self->set(lineHeight => $val)
}

# size width, height
# можно использовать undef
sub size {
	my ($self, $w, $h) = @_;
	$self->set(width=>$w, height=>$h);
}

# устанавливает максимальный размер
sub max {
	my ($self, $w, $h) = @_;
	$self->set(maxWidth=>$w, maxHeight=>$h);
}

# устанавливает минимальный размер
sub min {
	my ($self, $w, $h) = @_;
	$self->set(minWidth=>$w, minHeight=>$h);
}

# устанавливает смещение верхнего левого угла
sub move {
	my ($self, $w, $h) = @_;
	$self->set(marginLeft=>$w, marginTop=>$h);
}

# устанавливает смещение нижнего правого угла
sub moveoff {
	my ($self, $w, $h) = @_;
	$self->set(marginRight=>$w, marginBottom=>$h);
}

# устанавливает смещения верхнего левого угла. Зависит от позиции: relative, absolute, fixed
sub locate {
	my ($self, $w, $h) = @_;
	$self->set(left=>$w, top=>$h);
}

# устанавливает смещения нижнего правого угла. Зависит от позиции: relative, absolute, fixed
sub locateoff {
	my ($self, $w, $h) = @_;
	$self->set(right=>$w, bottom=>$h);
}

# устанавливает внешние поля
sub offset {
	my ($self, $x, $y, $x2, $y2) = @_;
	
	if(@_==2) {
		$self->set(margin => $x);
	} elsif(@_==3) {
		$self->set(margin => "$y $x");
	}
	else {
		$self->set(margin => "$y $x2 $y2 $x");
	}
	
	$self
}

# устанавливает внутренние поля
sub field {
	my ($self, $x, $y, $x2, $y2) = @_;
	if(@_==2) {
		$self->set(padding => $x);
	} elsif(@_==3) {
		$self->set(padding => "$y $x");
	}
	else {
		$self->set(padding => "$y $x2 $y2 $x");
	}
	$self
}

# устанавливает поля верхнего левого угла
sub shift {
	my ($self, $w, $h) = @_;
	$self->set(paddingLeft=>$w, paddingTop=>$h);
}

# устанавливает поля нижнего правого угла
sub unshift {
	my ($self, $w, $h) = @_;
	$self->set(paddingRight=>$w, paddingBottom=>$h);
}


################ трансформации 2D

# сдвиг
sub xy {
	my ($self, $x, $y) = @_;
	$x //=  1.1;
	$self->unitSize($x, $y);
	$x .= ", $y" if defined $y;
	$self->add(transform => "translate($x)")
}

# поворот
sub angle {
	my ($self, $x) = @_;
	$x //=  "30deg";
	$self->unitDeg($x);
	$self->add(transform => "rotate($x)")
}

# масштаб
sub dim {
	my ($self, $x, $y) = @_;
	$x //=  1.1;
	$x .= ", $y" if defined $y;
	$self->add(transform => "scale($x)")
}

# скос
sub skew {
	my ($self, $x, $y) = @_;
	$x //=  1.1;
	$y //= $x;
	$self->unitDeg($x, $y);
	$self->add(transform => "skew($x, $y)")
}


################ трансформации 3D

# смещение translate
sub x {
	my ($self, $x) = @_;
	return $self if !defined $x;
	$self->unitSize($x);
	$self->add(transform => "translateX($x)");
	$self->setdefault(perspective => '70em');
}

# смещение translate
sub y {
	my ($self, $y) = @_;
	return $self if !defined $y;
	$self->unitSize($y);
	$self->add(transform => "translateY($y)");
	$self->setdefault(perspective => '70em');
}

# смещение translate
sub z {
	my ($self) = @_;
	my ($self, $z) = @_;
	return $self if !defined $z;
	$self->unitSize($z);
	$self->add(transform => "translateZ($z)");
	$self->setdefault(perspective => '70em');
}

# поворачивает по координатам
sub spin {
	my ($self, $x, $y, $z) = @_;
	$self->unitDeg($x)->add(transform => "rotateX($x)") if defined $x;
	$self->unitDeg($y)->add(transform => "rotateY($y)") if defined $y;
	$self->unitDeg($z)->add(transform => "rotateZ($z)") if defined $z;
	$self->setdefault(perspective => '70em') if defined $x or defined $y or defined $z;
	$self
}

# масштабирует
sub scale {
	my ($self, $x, $y, $z) = @_;
	
	$self->add(transform => "scaleX($x)") if defined $x;
	$self->add(transform => "scaleY($y)") if defined $y;
	$self->add(transform => "scaleZ($z)") if defined $z;
	$self->setdefault(perspective => '70em');
	$self
}

# указывает оси вокруг которых поворачивать:
# x: <длина> | <проценты> | left | center | right
# y: <длина> | <проценты> | top | center | bottom
# z: <длина>
sub axis {
	my ($self, $x, $y, $z) = @_;
	$x //= .5;
	$y //= .5 if defined $z;
	$z = "${z}em" if Num $z;
	$self->unitSize($x, $y);
	$self->set(transformOrigin=> defined($z)? "$x $y $z": defined($y)? "$x $y": $x)
}

# задаёт перспективу трансформации
sub perspective {
	my ($self, $perspective, $x, $y) = @_;
	
	$perspective = "${perspective}em" if Num $perspective;
	
	$self->set(perspective => $perspective) if defined $perspective;
	if(defined $x or defined $y) {
		$x //= .5;
		$self->unitSize($x, $y);
		$self->set(perspectiveOrigin=>"$x $y");
	}
	$self
}

# Дочерние элементы будут отображаться в 3D-пространстве
sub child3d {
	my ($self) = @_;
	$self->set(transformStyle => "preserve-3d")
}

# Дочерние элементы лежат в той же плоскости, что и их родитель
sub child2d {
	my ($self) = @_;
	$self->set(transformStyle => "flat")
}

################ шрифт

# устанавливает шрифт
# sub font {
	# my ($self, $size) = @_;
	# $self->unitSize($size);
	# $self->set(font=>$size);
	# $self
# }

# подчёркнутый текст
sub underline {
	my ($self, $x) = @_;
	$x //= 1;
	$self->set(textDecoration=> $x? "underline": "none");
}

# надчёркнутый текст
sub overline {
	my ($self, $x) = @_;
	$x //= 1;
	$self->set(textDecoration=> $x? "overline": "none");
}

# зачёркнутый текст
sub strike {
	my ($self, $x) = @_;
	$x //= 1;
	$self->set(textDecoration=> $x? "line-throught": "none");
}

# жирность
sub bold {
	my ($self, $bold) = @_;
	$bold = 700 if @_==1;	
	$self->set(fontWeight => $bold);
}

# наклон
sub italic {
	my ($self, $italic) = @_;
	$italic //= -1;
	$self->set(fontStyle => $italic==0? 'normal': $italic < 0? 'italic': 'oblique');
}

# шрифт sans-serif - обычный шрифт без засечек
sub sans {
	my ($self) = @_;
	$self->set(fontFamily => 'sans-serif');
}

# шрифт serif - обычный шрифт c засечками
sub serif {
	my ($self) = @_;
	$self->set(fontFamily => 'serif');
}

# шрифт фиксированной ширины
sub monospace {
	my ($self) = @_;
	$self->set(fontFamily => 'monospace');
}

# шрифт, имитирующий почерк
sub cursive {
	my ($self) = @_;
	$self->set(fontFamily => 'cursive');
}

# декоративный шрифт, для заглавий и т.д.
sub fantasy {
	my ($self) = @_;
	$self->set(fontFamily => 'fantasy');
}


################ позиции

# позиционировать абсолютно
sub absolute {
	my ($self) = @_;
	$self->set(position => 'absolute');
}

# позиционировать фиксированно
sub fixed {
	my ($self) = @_;
	$self->set(position => 'fixed');
}

# позиционировать относительно
sub relative {
	my ($self) = @_;
	$self->set(position => 'relative');
}

# позиционировать обычно
sub static {
	my ($self) = @_;
	$self->set(position => 'static');
}

# делает элемент "плавающим"
sub float {
	my ($self, $n) = @_;
	$n //= -1;
	$self->set(float => $n == 0? 'none': $n<0? 'left': 'right')
}

# контролирует скролл и отображение текста
sub scroll {
	my ($self) = @_;
	$self->set(overflow=>'auto');
}

################ отображение

# блочный элемент
sub block {
	my ($self) = @_;
	$self->set(display => 'block');
}

# строчный элемент
sub inline {
	my ($self) = @_;
	$self->set(display => 'inline');
}

# строчный блок
sub iblock {
	my ($self) = @_;
	$self->set(display => 'inline-block');
}

# скрытый элемент
sub hide {
	my ($self) = @_;
	$self->set(display => 'none');
}

# прозрачность
sub opacity {
	my ($self, $opacity) = @_;
	$self->set(opacity => $opacity // .7);
}

# указатель - курсор
sub pointer {
	my ($self, $pointer) = @_;
	$self->set(cursor => $pointer // "pointer");
}

################ цвета

# цвета
sub color {
	my ($self, $fg, $bg, $br) = @_;
	$self->set(color=>$fg, backgroundColor=>$bg);
	$self->set(border=>"solid 1px $br") if $br;
	$self
}

################ границы

# скругляет углы
sub radius {
	my ($self, $x1, $y1, $x2, $y2) = @_;
	if(@_ == 1) {
		#$x1 = ;
	}
	$self->set(borderRadius => "$x1 $y1 $x2 $y2");
}

# граница - цвет
sub limit {
	my ($self, ) = @_;
	$self
}

################ тени

# добавляет тень блоку
sub shadow {
	my $self = shift;
	my @x;
	if($_[0] eq "none") {
		@x = "none";
	}
	elsif($_[0] !~ /^[a-z]/) {
		my ($x, $y, $blur, $spread, $color, $in) = @_;
		$x //= ".3em";
		$y //= ".3em";
		$self->unitSize($x, $y);
		push @x, $x, $y;
		$blur //= ".3em";
		$self->unitSize($blur), push @x, $blur;
		$self->unitSize($spread), push @x, $spread if $spread;
		push @x, $color if $color;
		unshift @x, "inset" if $in;
	}
	else {
		my %x = @_;
		push @x, $x{x} // ".3em", $x{y} // ".3em";
		my $blur = $x{blur} // ".3em";
		$self->unitSize($blur);
		push @x, $blur;
		$self->unitSize($x{stretch}), push @x, $x{stretch} if $x{stretch};	# растягивает тень +- значение
		push @x, $x{color} if $x{color};
		unshift @x, "inset" if exists $x{in};
	}
	
	$self->add(boxShadow => join " ", @x)
}

# добавляет тень текста
sub shade {
	my $self = shift;
	my @x;
	if($_[1] =~ /^\d/) {
		my ($x, $y, $blur, $color) = @_;
		$x //= "1px";
		$y //= "1px";
		$blur //= "1px";
		$x .= "px" if Num $x;
		$y .= "px" if Num $y;
		$blur .= "px" if Num $blur;
		push @x, $x, $y, $blur;
		push @x, $color if $color;
	}
	else {
		my %x = @_;
		push @x, $x{x}//"1px", $x{y}//"1px";
		$self->unitSize($x{blur}), push @x, $x{blur} if $x{blur};
		push @x, $x{color} if $x{color};
	}
	
	$self->add(textShadow => join " ", @x)
}

################ рисование градиентов черепашкой (пришло из языка LOGO)

# turtle, tortoise - черепаха, little turtle - черепашка
# angle - угол
# line - пройденный путь: цвет позиция, ...
# x, y - позиция точки на которую стала черепашка

# http://frontender.info/dig-deep-into-css-gradients/

# поворачивает черепашку влево на 0-360: 0-1
sub left {
	my ($self, $angle) = @_;
	$self->unitDeg($angle);
	$self->_add_linear($angle);
	$self->the->{pen}{angle} += $angle;
	$self
}

# поворачивает черепашку вправо на 0-360: 0-1
sub right {
	my ($self, $angle) = @_;
	$self->unitDeg($angle);
	$self->_add_linear($angle);
	$self->the->{pen}{angle} -= $angle;
	$self
}

# добавляет "линию" к градиенту
sub _add_linear {
	my ($self, $angle) = @_;
	
	if($angle != 0 && (my $line = $self->the->{pen}{line}) ) {
		$self->add("background", "linear-gradient(" . ($self->the->{angle} // 0) . "deg," . join(", ", @$line) . ") ");
		delete $self->the->{pen}{line};
	}
	
	$self
}

# идти вперёд на значение. Указывается в стандартных единицах
sub forward {
	my ($self, $n) = @_;
	$self->unitSize($n);
	
	my $pen = $self->the->{pen};
	push @{ $pen->{line} }, ($pen->{color} || "transparent") . " " . $n;
	
	# рассчитаем точку в которой находится перо
	#$pen->{x} = sin
	#$pen->{y} = 
	
	$self
}

# рисует радиальный градиент. Но для этого надо сделать два airward-а, чтобы через эти две точки провести окружность
sub airward {
	my ($self) = @_;
	
	$self
}

# устанавливает цвет градиента
# если цвет не указан - поднимает перо (делает цвет прозрачным)
sub pen {
	my ($self, $color) = @_;
	$self->the->{pen}{color} = $color;
	$self
}

################ переходы

# включает переход
sub to {
	my ($self, $param, $stand) = @_;
	$param //= "all";
	$stand //= .4;
	local ($`, $', $&);
	$param =~ s/[A-Z]/"-" . lc $&/ge;
	$self->add(transition => "$param ${stand}s")
}

# продолжительность перехода
sub interval {
	my ($self, $stand) = @_;
	$stand //= .4;
	my @x = split /\s+/, $self->ret("transition", "all .4s");
	$x[1] = "${stand}s";
	$self->top(transition => join " ", @x)
}

# функция перехода
sub ease {
	my ($self, $ease) = @_;
	$ease = @_>2? "cubic-bezier(".join(",", @_[1..$#_]).")":
		!$ease? "ease":
		$ease eq "linear"? $ease:
		"ease-$ease";
		
	my @x = split /\s+/, $self->ret("transition", "all .4s");
	$x[2] = $ease;

	$self->top(transition => join " ", @x)
}

# задержка перехода
sub delay {
	my ($self, $delay) = @_;
	$delay //= .2;
	my @x = split /\s+/, $self->ret("transition", "all .4s");
	$x[3] = "${delay}s";
	$self->top(transition => join " ", @x)
}


################ анимация

# объявляет анимацию
sub keyframes {
	my ($self, $name) = @_;
	$self->prince("$name")->intro("\@keyframes \"$name\"");
	$self->serf->{keyframes} = 1;
	$self->frame(0)
}

# шаг анимации от 0 до 1
sub frame {
	my ($self, $step) = @_;
	if($self->serf->{animedia}) {
		pop @{$self->{serf}};
	}
	$self->prince->intro($step * 100 . "%");
	$self->serf->{animedia} = 1;
	$self
}

# скорость анимации в секундах
# speed(0.5)
sub animation {
	my ($self, $name, %opt) = @_;
	# animation-name animation-duration animation-timing-function animation-delay animation-iteration-count animation-direction

	my $speed = delete($opt{speed}) // 1;
	/\s/? "cubic-bezier(".join(",", split /\s+/).")":
	my $ease = delete $opt{ease};
	$ease = $ease? (/\s/? "cubic-bezier(".join(",", split /\s+/).")": "ease-$ease"): "ease";
	my $delay = delete($opt{delay}) // 0;
	my $count = delete($opt{count}) // 1;
	my $direct = delete($opt{direct}) // "alternate";
	
	die "неверные опции в анимации: " . join ", ", keys %opt if keys %opt;
	
	$self->add(animation => "$name ${speed}s $ease ${delay}s $count $direct")
}

# приостанавливает анимацию
sub pause {
	my ($self) = @_;
	$self->set(animationPlayState => "pause")
}

# запрещает прерывать анимацию
sub running {
	my ($self) = @_;
	$self->set(animationPlayState => "running")
}


################ события

# хелпер - инвертирует показатель
sub _hover {
	my ($self, $hover) = @_;
	$self->serf->{the} = join ",", map { s/$hover\b//? $_: "$_$hover" } split /\s*,\s*/, $self->serf->{the};
	$self
}

# добавляет ко всем в the :hover
sub hover {
	my ($self) = @_;	
	$self->_hover(":hover");
}

# добавляет ко всем в the :active
sub active {
	my ($self) = @_;
	$self->_hover(":active");
}

# добавляет ко всем в the :focus
sub focus {
	my ($self) = @_;
	$self->_hover(":focus");
}

# добавляет ко всем в the :checked
sub checked {
	my ($self) = @_;
	$self->_hover(":checked");
}

################ конвертеры

# конвертирует css в R::Css
sub css2r {
	my ($self, $css) = @_;
	
	my @st;
	my $shl = "";
	
	my $push = sub { push @st, shift; $shl .= "\t" };
	my $pop = sub { $shl = substr $shl, 1; pop @st };
	my $top = sub { $st[$#st] };
	
	my $replace = sub {
		$+{rem}? do { my $r = $+{rem}; $r =~ s/^/# /mg; $r }:
		$+{prince}? do { my $o = "${shl}prince('$+{prince}')->\n"; $push->("prince"); $o }:
		$+{the}? do { &$pop if &$top eq "the"; my $o = "${shl}the(\"$+{the}\")->set(\n"; $push->("the"); $o }:
		$+{end}? do {
			my $o="";
			if(&$top eq "key") { $o="\",\n"; &$pop }
			if(&$top eq "the") { &$pop; "${o}$shl)->" }
			elsif(&$top eq "prince") { &$pop; "$o${shl}end->\n" }
			elsif(@st == 0) { $o }
			else { $o . $& } 
		}:
		$+{end_val}? do { if(&$top eq "key") { &$pop; "\",\n" } else {$&} }:
		$+{key}? do { my $s=$shl; $push->("key"); my $key=$+{key}; $key=~s/-(\w)/uc $1/ge; "${s}$key => \"" }:
		$+{str}? do { #my $s=$+{str}; $s =~ s/^.(.*).$/$1/; $s 
			$&
		}:
		$&;
	};
	
	$css =~ s!
		(?P<str> "(?:\\"|[^"])+" | '(?:\\'|[^'])+' ) |
		/\* (?P<rem>.*?) \*/ |
		
		(?P<prince> \@[^\{\}]*?) \s* \{ |
		(?P<the> [^\n]+?) \s* \{ |
		(?P<end> \s* \}) |
		(?P<key> [\-\w]+ ) \s*:\s* |
		(?P<end_val> \s*;)
	!
		$replace->();
	!gexsm;
	
	$css
}



1;