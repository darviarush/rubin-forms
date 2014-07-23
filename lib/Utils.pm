package Utils;

use Data::Dumper;

# создаёт множество
sub set { map { $_=>1 } @_ }

# разбирает построчный файл. Возвращает массив. Начальные и конечные пробельные символы удаляются
sub parse_vector {
	my ($path) = @_;

	return () unless -e $path;

	local ($_, $', $`, $1);

	open my($f), $path or die "not open vector file `$path`. $!\n";
	my @lines = grep {$_} map {s/^\s*(.*?)\s*$/$1/; $_} <$f>;
	close $f;
	return @lines;
}

# печатает построчный файл
sub print_vector {
	my $path = shift;
	open my($f), ">", $path or die "not create vector file `$path`. $!\n";
	local ($\, $_) = "\n";
	print $f $_ for @_;
	close $f;
}

# перезаписывает построчный массив
sub replace_vector {
	my ($path, $sub) = @_;
	my @args = parse_vector($path);
	print_vector($path, &$sub(@args));
}

# разбирает ini-файл и возвращает хэш
sub parse_ini {
	my ($path, $text) = @_;
	my $f;
	if(defined $path) {
		return {} unless -e $path;
		open $f, $path or die "not open ini file `$path`. $!\n";
	} else {
		require IO::String;
		$f = IO::String->new($text);
	}
	local ($_, $1, $2, $3, $4, $', $`);

	my $result = {};
	my $entry = $result;

	my $canon = sub {
		return unless ref $entry eq "ARRAY";
		my $arr = $entry;
		$entry = $entry->[$#$entry];
		push @$arr, ($entry = {}) unless ref $entry eq "HASH";
	};

	my $can = sub {
		my ($key, $val) = @_;
		my $v = $entry->{$key};
		if(ref $v eq "ARRAY") { push @$v, $val } else { $entry->{$key} = [$v, $val] }
	};

	while(<$f>) {
		# удаляем начальные и конечные пробельные символы
		s/^\s*(.*?)\s*$/$1/;

		# пропускаем пустые строки и комментарии
		next if $_ eq "" or /^[;#]/;

		# строка с "="
		/^(.*?)\s*=\s*/ && do {
			my ($key, $val) = ($1, $');
			$val = undef if $val eq "";
			$entry->{$key} = $val, next unless exists $entry->{$key};
			&$can($key, $val);
			next;
		};

		# новая глава
		/^\[(.*?)\]$/ && do {
			$entry = $result;
			my @x = split '::', $1;
			my $key = pop @x;
			$entry = $entry->{$_} // ($entry->{$_} = {}), &$canon for @x;
			if(exists $entry->{$key}) { my $val = {}; &$can($key, $val); $entry = $val; }
			else { $entry = ($entry->{$key} = {}); }
		};
		next;

		# ошибка в ini
		close $f;
		die "$.. Error parsing ini-file `$path`\n";
	}

	close $f;

	return $result;
}

# сериализирует данные в ini
sub dump_ini {
	my ($ini, $order) = @_;
	return "" unless keys %$ini;
	my @tree = ([], $ini);
	my @dump = ();
	my $tek = '';
	while(@tree) {
		my ($path, $tree) = splice @tree, -2;
		$arr = ref $tree eq "HASH"? [$tree]: $tree;
		for $tree (@$arr) {
			push @dump, "\n[".join("::", @$path)."]\n" if @$path;
			while(my($a, $b) = each %$tree) {
				push(@dump, "$a = $b\n"), next unless ref $b;
				push @tree, ([@$path, $a]), $b;
			}
		}
	}

	return join "", @dump;
}

# печатает ini в файл
sub print_ini {
	($path, $ini) = @_;
	open my($f), ">", $path or die "not create ini-file `$path`. $!\n";
	print $f dump_ini($ini);
	close $f;
}

# вставляет или заменяет в ini-тексте значение
sub inject_ini {
	my ($ini, $section, $key, $val, $ins_key, $before) = @_;
	local ($_, $&, $`, $', $1);
	my $re = $section eq ""? qr'\A'm: "^\\[$section\\]\\s*\$";
	my $to = qr/^\[[^\n]*?\]|\Z/m;
	$val = '""' if $val eq "" and defined $val;
	$val = "$key = $val\n";
	my $flag;
	$_[0] =~ s/$/\n\n[$section]\n$val/, return unless $_[0] =~ s/$re.*?$to/ $_=$&; $flag=1 unless s!^\s*$key\s*=.*$!$val!m; $_ /mse;
	return unless $flag;
	if($ins_key) {
		$flag = 0;
		$_[0] =~ s/$re.*?$to/ $_=$&; $flag = 1 unless s!^\s*$ins_key\s*=.*(?:\n|\z)! $before? "$val$&": "$&$val" !me; $_ /mse;
		return unless $flag;
	}
	$_[0] =~ s/$re/$&$val/m if $before;
	$_[0] =~ s/($re.*?\n?)(\s*$to)/$1$val$2/ms unless $before;
}

# удляляет из ini-текста ключ. Если key не указан, то - секцию
sub delete_ini {
	my ($ini, $section, $key) = @_;
	local ($_, $&, $`, $', $1);
	my $to = qr/^\[[^\n]*?\]|\Z/m;
	if(defined $key) {
		my $re = $section eq ""? qr'\A'm: "^\\[$section\\]\\s*\$";
		$_[0] =~ s/$re.*?$to/ $_=$&; s!^\s*$key\s*=.*\n?!!m; $_ /mse;
	} else {
		$_[0] =~ s/^\[$section\].*?($to)/$1/ms;
	}
}


# создаёт уникальный идентификатор
my @abc = ('A'..'Z', 'a'..'z', '0'..'9', '/', '$', '.');

sub unic_id {
	my $size = shift || 16;
	my $unic_id = "";

	for(my $i=0; $i<$size; $i++) {
		my $j = int rand scalar @abc;
		$unic_id .= $abc[$j];
	}

	return $unic_id;
}


# создаёт соль заданной длины
sub gen_salt {
	my $size = shift || 16;
	my $salt = "";

	for(my $i=0; $i<$size; $i++) { $salt .= chr(rand 256); }

	return $salt;
}

# распаковывает данные переданные в виде параметров url
sub param {
	my ($data, $sep) = @_;
	local ($_, $`, $');
	require URI::Escape;
	my $param = {};
	for ($data? split($sep // qr/&/, $data): ()) {
		tr/+/ /;
		/$/ unless /=/;
		my $key = URI::Escape::uri_unescape($`);
		my $val = $param->{$key};
		my $newval = URI::Escape::uri_unescape($');
		if(defined $val) {
			if(ref $val) { push @$val, $newval } else { $param->{$key} = [$val, $newval]}
		} else {
			$param->{$key} = $newval;
		}
	}
	return $param;
}


# считывает из потока параметры POST
sub param_from_post {
	my ($stdin, $type, $len) = @_;
	#print STDERR "param_from_post: $stdin, $type, $len\n";
	return unless $len;
	local ($_, $`, $', $1);
	if($type =~ m!^multipart/form-data;\s*boundary=!i) {
		my $boundary = qr/^--$'(--)?\r?\n/;
		my $param = {};
		my $this_is_header = 0;
		my $is_val = 0;
		my $buf = [];
		while(<$stdin>) {
			if($_ =~ $boundary) {
				my $the_end = $1;
				if($name ne "") {
					$buf = $buf->[0] || "", $buf =~ s/\r?\n// if $is_val and @$buf <= 1;
					$param->{$name} = $buf;
				}
				last if $the_end;
				$this_is_header = 1;
				$buf = [];
				$is_val = 0;
				$name = "";
				$encoding = "";
			} elsif(/^\r?$/) {
				$this_is_header = 0;
			} elsif($this_is_header) {
				$name = $1, $is_val = !/\bfilename=/ if /^Content-Disposition: .*\bname=['"]?([\$\w-]+)/i;
				$encoding = $1 if /Content-Transfer-Encoding: ([\w-]+)/;
			} else {
				push @$buf, $_;
			}
		}
		$param;
	} elsif($type =~ m!\bapplication/json\b!i) {
		read $stdin, $_, $len;
		require JSON;
		JSON::from_json($_);
	} else {
		read $stdin, $_, $len;
		param($_, qr/&/);
	}
}

# отправляет сигнал всем процессам, подходящим по маске
sub killall {
	my ($sig, $name) = @_;
	local ($1, $`, $', $_);
	kill $sig, map { /(\d+)/ && $1 } grep { /$name/ } split "\n", `ps -A -o pid,command`;
}

# спрашивает пользователя через stdin
sub confirm {
	my $yes = "";
	do { print("$_[0] (yes/no) "); } while ($yes = <STDIN>) !~ /^yes|no$/;
	return $yes =~ /yes/;
}

# Dumper не должен возвращать \x{...}
$Data::Dumper::Useqq = 1;

{ no warnings 'redefine';
	sub Data::Dumper::qquote {
		my $s = shift;
		$s =~ s/\'/\\\'/g;
		return "'$s'";
	}
}


# возвращает дамп ссылки
sub Dump { substr(Dumper($_[0]), 8, -2) }


# читает весь файл
sub read {
	my ($path) = @_;
	return "" unless -e $path;
	open my($f), $path or die("Utils::read: Не могу открыть $path: $!\n");
	read $f, my($body), -s $f;
	close $f;
	return $body;
}


# записывает весь файл
sub write {
	my $path = shift;
	open my($f), ">", $path or die("Utils::write: Не могу создать $path: $!\n");
	local $_;
	local $\ = "";
	print $f $_ for @_;
	close $f;
}

# дописывает в конец файла
sub endwrite {
	my $path = shift;
	open my($f), ">>", $path or die("Utils::endwrite: Не могу открыть $path: $!\n");
	local $_;
	local $\ = "";
	print $f $_ for @_;
	close $f;
}


# перезаписывает весь файл
sub replace {
	my ($path, $block) = (shift, shift);
	my $file = Utils::read($path);
	&$block($file, @_);
	Utils::write($path, $file);
}

# копирует файл
sub cp {
	my ($from, $to) = @_;
	Utils::write($to, Utils::read($from));
}

# stderr и stdout записывает так же и в файл
sub tee {
	my ($path, $nodel) = @_;

	# удаляем файл
	unlink $path unless $nodel;

	require File::Tee;

	# перенаправляем вывод тестов
	File::Tee::tee(STDERR, ">>$path");
	File::Tee::tee(STDOUT, ">>$path");

	select STDERR; $| = 1;  # make unbuffered
	select STDOUT; $| = 1;  # make unbuffered
}

# формирует параметры
sub form_param {
	my ($param) = @_;
	require URI::Escape;
	my $uri_escape = sub { my ($x) = @_; utf8::encode($x) if utf8::is_utf8($x); URI::Escape::uri_escape($x) };
	join "&", map {
		my $p = $param->{$_};
		my $s = &$uri_escape($_)."=";
		if(ref $p eq "ARRAY") { $s = join "&", map {$s.&$uri_escape($_)} @$p }
		else { $s .= &$uri_escape($p) }
	} keys %$param;
}

# отправляет запрос http-пост
sub post {
	require LWP::UserAgent;
	my ($url, $param) = @_;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	my $response = $ua->post($url, Content => form_param($param));
	my ($service) = caller 1;
	die(error505($service, $response->status_line)) unless $response->is_success;
	$response->content;
}

# для вставки в html
sub escapeHTML {
	my ($x) = @_;
	my $r;
	$x =~ s!&(?{$r='&amp;'})|<(?{$r='&lt;'})|>(?{$r='&gt;'})|"(?{$r='&quote;'})|'(?{$r='&#39;'})]!$r!g;
	$x
}

# для вставки в строки javascript
sub escapejs {
	my ($x) = @_;
	local $&;
	$x =~ s/[\\\"\']/\\$&/g;
	$x =~ s/\n/\\n/g;
	$x =~ s/\r/\\r/g;
	return $x;
}

# возвращает строку javascript
sub stringjs { '"'.escapejs($_[0]).'"' }

# понятно
sub camelcase {
	my $s = ucfirst $_[0];
	$s =~ s/_([a-z])/uc $1/ge;
	$s
}

# понятно
sub decamelcase {
	my $s = lcfirst $_[0];
	$s =~ s/[A-Z]/"_".lc $&/ge;
	$s
}

# создаёт путь
sub mkpath { local ($_, $`, $'); $_ = $_[0]; mkdir $` while /\//g }

# возвращает путь к каталогу картинки без /image/. Параметр - id
sub img_path { $_[1] = 62; $_[2] = '/'; goto &to_radix; }

# переводит натуральное число в заданную систему счисления
sub to_radix {
	my ($n, $radix) = @_;
	my ($x, $y) = "";
	for(;;) {
		$y = $n % $radix;
		$x = ($y < 10? $y:  chr($y + ($y<36? ord("A") - 10: $y<62? ord("a")-36 : 128-62))).$x;
		last unless $n = int $n / $radix;
	}
	return $x;
}

# парсит число в указанной системе счисления
sub from_radix {
	my ($s, $radix) = @_;
	my $x = 0;
	for my $ch (split "", $s) {
		$a = ord $ch;
		$x = $x*$radix + $a - ($a <= ord("9")? ord("0"): $a <= ord("Z")? ord('A')-10: $a <= ord('z')? ord('a')-36: 128-62);
	}
	return $x;
}

# вспомогательные f-ции
sub from__rows {
	my @st = $_[0];
	while(@st) {
		my ($out, $fields, $rows) = @{ pop(@st) };
		my $fld = $fields->{fields};
		my($outrows, $outrow);
		$out->{$fields->{key}} = $outrows = [];
		for my $row (@$rows) {
			push @$outrows, $outrow = {};
			for(my $i=0; $i<@$fld; $i++) {
				my $field = $fld->[$i];
				if(ref $field) { push @st, [$outrow, $field, $row->[$i]]; }
				else { $outrow->{$field} = $row->[$i]; }
			}
		}
	}
}

sub to__rows {
	my @st = $_[0];
	while(@st) {
		my ($out, $fields, $rows) = @{ pop(@st) };
		my ($outrows, $outrow);
		$out->[$fields->{key}] = $outrows = [];
		my $fld = $fields->{fields};
		for my $row (@$rows) {
			push @$outrows, $outrow = [];
			for(my $i=0; $i<@$fld; $i++) {
				my $field = $fld->[$i];
				if(ref $field) { push @st, [$outrow, {key => $i, fields => $field->{fields}}, $row->{$field->{key}}]; }
				else { $outrow->[$i] = $row->{$field}; }
			}
		}
	}
}


sub from_fields {
	my $fields = [];
	for my $field (@_) {
		my ($key, @fields) = @$field;
		push @$fields, (ref $field eq 'ARRAY'? { key => $key, fields => from_fields(@fields) } : $field);
	}
	return $fields;
}

sub to_fields {
	my ($rows, $key) = @_;
	my $fields = [$key];
	my $fld = [];
	my $row = $rows->[0];
	while( my ($field, $val) = each %$row) {
		if(ref $val eq 'ARRAY') {
			my($f0, $f1) = to_fields($val, $field);
			push @$fld, $f1;
			push @$fields, $f0;
		} else {
			push @$fld, $field; 
			push @$fields, $field;
		}
	}
	return ($fields, {key => $key, fields => $fld});
};

# переводит полученные данные из вида [[заголовки столбцов], [1-я строка], ...] в [{заголовок1: данные1, ...}, ...]
sub from_rows ($) {
	my ($data) = @_;
	my $fields = from_fields([0, @{$data->{fields}}]);
	from__rows([$ret = {}, $fields->[0], $data->{rows}]);
	$ret->{0};
}

# превращает набор записей в заголовок и набор значений
sub to_rows ($) {
	my ($rows) = @_;
	return {rows => [], fields => []} if @$rows == 0;
	
	my ($fields, $fld) = to_fields($rows, 0);
	shift @$fields;
	to__rows([$ret = [], $fld, $rows]);
	return {fields => $fields, rows => $ret->[0]};
}

# вспомогательная функция для TemplateStr. Парсер хелперов
sub applyHelper {
	local ($_, $`, $', $1, $2);
	my ($a) = @_;
	$a =~ s/\\'/'/g;
	my $b = $a;
	my @a = split /([:,\(\)]|"(?:\\"|[^"])*"|'(?:\\'|[^'])*')/, $a;
	@a = map { s/^\s*(.*?)\s*$/$1/;  s/\$(\w+)/\$data->{'$1'}/g; $_ eq ""? (): $_ eq "{"? "(": $_ eq "}"? "": $_ } @a;
	$a[0] = "\$data->{'$a[0]'}";
	return "Utils::escapeHTML($a[0])" if @a == 1;

	push @a, ")";
	my (@T, @S);
	for $a (@a) {
		if($a eq ")") {
			while("(" ne ($a = pop @T) and defined $a) {
				if($a eq ",") {	$a = pop @S; push @S, pop(@S).", ".$a; }
				elsif($a eq ":") { push @S, "Helper::".pop(@S)."(".pop(@S).")"; }
				else { die "Неизвестный оператор `$a` в хелпере"; }
			}
			if(defined($a = pop @T)) {
				die "не `:`" if $a ne ":";
				$a = pop @S;
				push @S, "Helper::".pop(@S)."(".pop(@S).", $a)";
			}
		}
		elsif($a =~ /^[:,\(]$/) { push @T, $a; }
		else { push @S, $a }
	}

	die "Ошибка синтаксиса хелпера: \${$b} S " . join("|", @S) . " T " . join("|", @T) if @S != 1;
	die "Остались операторы в стеке хелпера: \${$b} " . join("|", @S) . " T " . join("|", @T) if @T != 0;

	return $S[0];
}

# темплейт, аналогичный из js-библиотеки CTemplate::compile. Возвращает текст функции
sub TemplateStr {
	local ($_, $`, $');
	($_) = @_;
	my $re_tag = qr!(<script\b.*?</script\s*>|<style/b.*?</style\s*>|<[\/\w](?:"(?:\\"|[^"])*"|'(?:\\'|[^'])*'|[^<>])*>)!is;
	my @html = split $re_tag;
	my @orig = @html;
	
	my $code_begin = 'sub {
	my ($dataset, $id1) = @_;
	my ($number_id, @res) = ref($dataset) eq "ARRAY";
	$dataset = [$dataset] unless $number_id;
	for(my $i=0; $i<@$dataset; $i++) {
		my ($data, $id) = $dataset->[$i];
		if($number_id) { $id="$id1-$i"; $data->{"_NUMBER"}=$i; $data->{"_NUMBER1"}=$i+1; }
		else { $id=$id1 }
		push @res, \'';
	
	my $code_end = '\';
	}
	return join "", @res;
}';

	my %tags = (
		th => qr/^(?:tr|table|tbody|tfoot|thead)$/,
		td => qr/^(?:tr|table|tbody|tfoot|thead)$/,
		tr => qr/^(?:table|tbody|tfoot|thead)$/,
		option => qr/^select$/,
		li => qr/^(?:ol|ul)$/,
	);
	
	my (@T, $i);
	
	my $pop = sub {
		my $tag = pop @T;
		if(@$tag > 1) {
			my $ret = $tag->[1];
			$html[$tag->[2]] .= $tag->[3]? do { my $x = join "", @orig[$tag->[2]..$i-1]; $x=~s/!/!!/g; $x=~s/-->/--!>/g; "<!--$x-->" }: "";
			splice @orig, $i, 0, "";
			splice @html, $i++, 0, "$code_end)->(\$data".($ret? "->{'$ret'}": "").", \$id".($ret? ".'-$ret'": "")."), '";
		}
		$tag->[0];
	};
	
	for($i=0; $i<@html; $i++) {
	
		$html[$i] =~ s/'/\\'/g;
	
		$html[$i] =~ s!([\$#]){((?:"(?:\\"|[^"])*"|\\'(?:\\\\'|[^'])*?\\'|[^\{\}])*)}|([\$#])(\w+(?::\w+(?:\(((?>[^()]+)|(?R))*\)?))*)!
			if(($1 // $3) eq "#") {
				if($html[$i] =~ /</) { $& } else {
					my $x = $2 // $4;
					$x =~ /^.(\w+)/;
					'<span id=\' . $id . \'-'.$1.'>'.applyHelper($x).'</span>'
				}
			} else { applyHelper($2 // $4) }
		!ge;
		$html[$i] =~ s!\$\+!', \$id, '!g;
		$html[$i] =~ s!\$-(\w+)!', \$id, '-$1!g;
	
		if($html[$i] =~ m!<([\w:-]+)!) {
			my $tag = $1;
			if(my $re = $tags{lc $tag}) {
				$pop->() while @T and $T[$#T]->[0] !~ $re;
			}
			if($html[$i] =~ /\$\*(?:\w+)?/) {
				my $ret = undef;
				$html[$i] =~ s!\$\*(\w+)?! $ret = $1; "', \$id, '".($1? "-$1": "") !e;
				splice @orig, $i+1, 0, "";
				splice @html, $i+1, 0, "', ($code_begin";
				push @T, [$tag, $ret, $i, $html[$i] =~ /\scinit[\s>]/i];
				$i++;
			} else {
				push @T, [$tag];
			}
		} elsif($html[$i] =~ m!</([\w:-]+)!) {
			my $tag = $1;
			while(@T and $pop->() ne $tag) {}
		}
	}
		
	$pop->() while @T;
	
	$x =join "", $code_begin, @html, $code_end;
	print STDERR $x;
	$x
}

# возвращает функцию
sub Template {
	eval TemplateStr(@_);
}

1;