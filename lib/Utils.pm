package Utils;

use strict;
use warnings;



use Data::Dumper;

# создаёт множество
sub set { map { $_=>1 } @_ }
sub starset { my $i=shift; map { $_=>$i++ } @_ }

# удаляет дубликаты
sub unique { my %x; map { if(exists $x{$_}) { () } else { $x{$_} = 1; $_ } } @_ }

# замыкание
sub closure {
	my $sub = pop;
	my @args = @_;
	sub {
		$sub->(@args, @_);
	}
}

# создаёт функции-свойства в указанном классе
sub has {
	my ($cls) = caller(0);
	for my $name (@_) {
		eval "sub ${cls}::$name { if(\@_>1) { \$_[0]->{'$name'} = \$_[1]; \$_[0] } else { \$_[0]->{'$name'} } }"
	}
}

# свойства только для чтения
sub has_const {
	my ($cls) = caller(0);
	for my $name (@_) {
		eval "sub ${cls}::$name { \$_[0]->{'$name'} }"
	}
}

# свойства ссылки на массив - забрасывают все свои аргументы в массив и возвращают или ссылку на массив (скалярный контекст) или все свои значения
sub has_array {
	my ($cls) = caller(0);
	for my $name (@_) {
		eval "sub ${cls}::$name { if(\@_>1) { my \$s=shift; push \@{\$s->{'$name'}}, \@_; \$s } else { wantarray? \@{\$_[0]->{'$name'}}: \$_[0]->{'$name'} }"
	}
}

# возвращает указанную переменную или все занчения или ссылку (скалярный контент). Устанавливает ссылку, либо свои параметры, как ключ => значение
sub has_hash {
	my ($cls) = caller(0);
	for my $name (@_) {
		eval "sub ${cls}::$name { if(\@_>1) { my \$s=shift; push \@{\$s->{'$name'}}, \@_; \$s } else { wantarray? \@{\$_[0]->{'$name'}}: \$_[0]->{'$name'} }"
	}
}

# проверяет на соответствие isa
use Scalar::Util qw/blessed/;
sub isa {
	my ($val, $cls) = @_;
	return unless blessed $val;
	$val->isa($cls);
}


# время для БД
use POSIX qw(strftime);
sub now {
	strftime("%F %T", localtime);
}

# сортирует по свойству
sub order_by {
	my ($sort, $arr, $desc) = @_;
	if($desc) {	sort { $b->{$sort} <=> $a->{$sort} } values %$arr }
	else { sort { $a->{$sort} <=> $b->{$sort} } values %$arr }
}

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
		my $arr = ref $tree eq "HASH"? [$tree]: $tree;
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
	my ($path, $ini) = @_;
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
	$val =~ s/^\s*(.*?)\s*$/$1/;
	$val = "$key = $val\n";
	my $flag;
	$_[0] =~ s/$/\n\n[$section]\n$val/, return unless $_[0] =~ s/$re.*?$to/ $_=$&; $flag=1 unless s!^\s*$key\s*=.*\n?!$val!m; $_ /mse;
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
	my @unic_id;

	for(my $i=0; $i<$size; $i++) {
		my $j = int rand scalar @abc;
		push @unic_id, $abc[$j];
	}

	return join "", @unic_id;
}

# sub unic_id {
	# my $size = shift || 16;
	# to_radix(int(rand 2**32), 62);
# }


# создаёт соль заданной длины
sub gen_salt {
	my $size = shift || 16;
	my @salt;

	for(my $i=0; $i<$size; $i++) { push @salt, chr(rand 256); }

	return join "", @salt;
}

# распаковывает данные переданные в виде параметров url
#	$sep - разделитель параметров. По умолчанию "&". Для кук установить ";\s*"
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
			if(ref $val eq "ARRAY") { push @$val, $newval } else { $param->{$key} = [$val, $newval]}
		} else {
			$param->{$key} = $newval;
		}
	}
	return $param;
}

# распаковывает данные переданные в виде параметров url
#	$sep - разделитель параметров. По умолчанию "&". Для кук установить ";\s*"
#	k=v&e=1,2&x=3,&y={f=6&r=,&z=&m}&z={}, распознаётся как 
#		{k => "v", e=>[1,2], x => [3], y => {
#			f => 6, r => [], z => "", m => undef
#		}, z => [{}]
# ...


# считывает из потока параметры POST
sub param_from_post {
	my ($stdin, $type, $len) = @_;
	#print STDERR "param_from_post: $stdin, $type, $len\n";
	return unless $len;
	local ($_, $`, $', $1);
	if($type =~ m!^multipart/form-data;\s*boundary=!i) {
		my $boundary = qr/^--$'(--)?\r?\n/;
		my $param = {};
		my $file = {};
		my $is_val = 0;
		my @buf;
		my $val;
		my ($head, $is_head);
		my ($name, $encoding) = ("");
		require R::Utils::File;
		while(<$stdin>) {
			#main::msg(":nonewline", $_);
			if($_ =~ $boundary) {
				my $the_end = $1;
				@buf = "" if @buf == 0;
				$buf[$#buf] =~ s/\r?\n//;
				if($name ne "") {
					my $file_val = $val;
					if($is_val and @buf == 1) {
						$val = $buf[0];
					} else {
						$val = R::Utils::File->new({body => join('', @buf), head=>$head});
					}
					
					if(exists $file->{$name}) {
						my $p = $file->{$name};
						$file->{$name} = $p = [$p] unless ref $p eq "ARRAY";
						push @$p, $val;
					}
					else {$file->{$name} = $val}
				}
				last if $the_end;
				$is_head = 1;
				$head = {};
				@buf = ();
				$is_val = 0;
				$name = "";
				#$encoding = "";
			} elsif($is_head && /^\r?$/) {
				$is_head = undef;
			} elsif($is_head) {
				$name = $1, $is_val = !/\bfilename=/ if /^Content-Disposition: .*?\bname=['"]?([\$\w-]+)/i;
				#$encoding = $1 if /Content-Transfer-Encoding: ([\w-]+)/;
				s/\r?\n//;
				/: /; $head->{$`} = $';
			} else {
				push @buf, $_;
			}
		}
		return $param, $file;
	} elsif($type =~ m!\bapplication/json\b!i) {
		read $stdin, $_, $len;
		require JSON::XS;
		JSON::XS->new->decode($_);
	} else {
		read $stdin, $_, $len;
		param($_);
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
$Data::Dumper::Useqq     = 1;	# использовать двойные кавычки

{ no warnings 'redefine';
	sub Data::Dumper::qquote {
		my $s = shift;
		#print STDERR "\n!!!\n";
		$s =~ s/\'/\\\'/g;
		return "'$s'";
	}
}


# возвращает дамп ссылки
sub Dump { substr(Dumper($_[0]), 8, -2) }


# читает весь файл
sub read {
	my ($path, $encode) = @_;
	return "" unless -e $path;
	open my($f), "<", $path or die("Utils::read: Не могу открыть $path: $!\n");
	binmode $f, ":encoding($encode)" if $encode;
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
	my ($from, $to, $bufsize) = @_;
	my ($open_from, $open_to);
	unless(ref $from) {
		$open_from = $from; undef $from;
		open $from, "<", $open_from or die "не могу открыть `$open_from`. $!";
	}
	unless(ref $to) {
		$open_to = $to; undef $to;
		open $to, ">", $open_to or die "не могу записать `$open_to`. $!";
	}
	
	$bufsize //= 1024*1024*8;
	my $buf;
	
	for(;;) {
		last unless CORE::read $from, $buf, $bufsize;
		print $to $buf;
	}
	close $from if $open_from;
	close $to if $open_to;
	#Utils::write($to, Utils::read($from));
}

# переносит файл
sub mv {
	my ($from, $to) = @_;
	Utils::cp($from, $to), unlink $from unless rename $from, $to;
}

# возвращает расширение файла
sub ext {
	my ($file) = @_;
	$file =~ /\.([^\.]+)/;
	return $1;
}

# stderr и stdout записывает так же и в файл
sub tee {
	my ($path, $nodel) = @_;

	# удаляем файл
	unlink $path unless $nodel;

	require File::Tee;

	# перенаправляем вывод тестов
	File::Tee::tee(\*STDERR, ">>$path");
	File::Tee::tee(\*STDOUT, ">>$path");

	select STDERR; $| = 1;  # make unbuffered
	select STDOUT; $| = 1;  # make unbuffered
}

# делает файл внеблоковым
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK O_NDELAY);
sub nonblock {
    for my $file (@_) {
		my $flags = fcntl($file, F_GETFL, 0) or die "Can't get flags: $!\n";
		fcntl($file, F_SETFL, $flags | O_NONBLOCK) or die "Can't make file nonblocking: $!\n";
	}
}

# делает файл блоковым
sub block {
    for my $file (@_) {
		my $flags = fcntl($file, F_GETFL, 0) or die "Can't get flags: $!\n";
		fcntl($file, F_SETFL, $flags &~ O_NONBLOCK) or die "Can't make file blocking: $!\n";
	}
}

####################################### Операции с url ##########################################

# эскейпит для url
sub uri_escape {
	my ($v, $re) = @_;
	local ($`, $', $&);
	utf8::decode($v) unless utf8::is_utf8($v);
	$re //= qr/[^A-Za-z0-9\-\._~]/;
	$v =~ s!$re!my $x=ord($&); $x<256? sprintf("%%%02X", $x): sprintf("%%u%04X", $x) !ge;
	$v
}

# разэскейпливает url
sub uri_unescape {
	my ($v) = @_;
	local ($`, $', $1, $2);
	$v =~ s!%u(\d{4})|%(\d{2})! defined($1)? unichr($1): chr($2) !ge;
	$v
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
	my ($url, $param, @headers) = @_;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(5);
	if(ref $headers[0] and ${$headers[0]} eq "keepAlive") {
		require LWP::ConnCache;
		$ua->conn_cache(LWP::ConnCache->new);
	}
	my $response = $ua->post($url, @headers, Content => form_param($param));
	die $response->status_line unless $response->is_success;
	wantarray? ($ua, $response->content, $response): $response->content;
}

# превращает файл в массив
package Utils::requestTieArray;

sub TIEARRAY {
	my ($cls, $path, $buf_size) = @_;
	
	my $static_file;
	open $static_file, "<", $path or die $!; binmode $static_file;
	
	my $len = (-s $static_file) / $buf_size; $len++ if $len > int $len;
	$len = int $len;
	
	bless {file => $static_file, len => $len, buf_size => $buf_size}, $cls
}
sub FETCHSIZE { $_[0]->{len} }
sub FETCH { my ($self, $i) = @_; my ($file, $buf_size, $buf) = ($self->{file}, $self->{buf_size}); seek $file, $i*$buf_size, 0; read $file, $buf, $buf_size; $buf }
#sub CLEAR { untie @Utils::_BODY }	# @_BODY = (); уничтожит
sub DESTROY { close $_[0]->{file} }

package Utils;

#our @_BODY;

# создаёт array для файла
# sub file2array {
	# my ($path, $buf_size) = @_;
	# tie @_BODY, 'Utils::requestTieArray', $path, $buf_size;
	# return \@_BODY;
# }

sub file2array {
	my ($path, $buf_size) = @_;
	my $body = [];
	tie @$body, 'Utils::requestTieArray', $path, $buf_size;
	return $body;
}

# для вставки в html
sub escapeHTML {
	my ($x) = @_;
	my $r;
	$x =~ s!(&)|(<)|(>)|(")|(')! $1? '&amp;': $2? '&lt;': $3? '&gt;': $4? '&quot;': '&#39;' !ge;
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

# парсит из строки
sub unstring { my $x = $_[0] // ""; if($x=~/^["']/) { $x = substr $x, 1, -1; $x=~s/\\([\\'"nrt])/my $x=$1; $x=~tr!nrtv!\n\r\t!; $x/ge; } $x }

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

# создаёт для процесса два двунаправленного вывода
sub pipe {
	my ($reader, $ch_writer, $ch_reader, $writer);
	
	pipe $ch_reader, $writer or die "not create pipe. $!";
	pipe $reader, $ch_writer or die "not create pipe. $!";;
	
	binmode $reader; binmode $writer; binmode $ch_reader; binmode $ch_writer;

	my $stdout = select $writer; $| = 1;
	select $ch_writer; $| = 1;
	select $stdout;
	return {
		rd=>$reader, crd=>$ch_writer, cwr=>$ch_reader, wr=>$writer
	};
}

# дублирует в указанные пайпы stdin и stdout
sub std2pipe {
	require POSIX;
	my ($in, $out, $err) = @_;
	POSIX::dup2(0, $in) if $in;
	POSIX::dup2(1, $out) if $out;
	POSIX::dup2(2, $err) if $err;
}


# изменяет путь cygwin на виндовый
sub winpath {
	return "--undef path in winpath--" if !defined $_[0];
	require Cwd;
	local ($`, $');
	my $file = eval { Cwd::abs_path($_[0]) };
	$file //= $_[0];
	$file =~ s!^/cygdrive/(\w)!$1:!;
	$file =~ s!^/(usr/)?!c:/cygwin/!;
	$file =~ s!/!\\!g;
	$file
}

# создаёт каталоги в пути
sub mkpath { local ($_, $`, $'); $_ = $_[0]; mkdir $` while /\//g; $! = undef; }

# удаляет все пустые директории вверх
sub rmpath {
	local ($_, $`, $');
	$_ = $_[0];
	my @path;
	push @path, $` while /\//g;
	rmdir $_ or last for reverse @path;
	$! = undef;
}

# обходит рекурсивно директории и применяет к файлам и каталогам указанную функцию
sub by_files {
	my $fn = pop;
	require File::Find;
	File::Find::find({
		no_chdir => 1,
		wanted => sub {
			$fn->($File::Find::name);
		}
	}, @_);
}

sub find (&@) {
	my $fn = shift;
	require File::Find;
	File::Find::find({
		no_chdir => 1,
		wanted => sub {
			local $_ = $File::Find::name;
			$fn->($_);
		}
	}, @_);
}

# удаляет файлы и директории с файлами
sub rm {
	my @dir;
	by_files(@_, sub {
		my ($path) = @_;
		if(-d $path) {unshift @dir, $path} else {::msg("не могу удалить файл `$path`: $!") unless unlink $path}
	});
	do { ::msg("rm: не могу удалить каталог `$_`: $!") unless rmdir $_ } for @dir;
}

# удаляет всё в указанной директории
sub rmdown {
	for my $dir (@_) {
		my @dir = <$dir/*>;
		rm(@dir) if @dir;
	}
}

# путь к картинке
sub img_path {
	my ($id) = @_;
	local ($_, $`, $', $&);
	$_ = to_radix($id, 62);
	s!.!$&/!g;
	$_;
}

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
		push @$fields, (ref $field eq 'ARRAY'? { key => $field->[0], fields => from_fields(@$field[1..$#$field]) } : $field);
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
	from__rows([my $ret = {}, $fields->[0], $data->{rows}]);
	$ret->{0};
}

# превращает набор записей в заголовок и набор значений
sub to_rows ($) {
	my ($rows) = @_;
	return {rows => [], fields => []} if @$rows == 0;
	
	my ($fields, $fld) = to_fields($rows, 0);
	shift @$fields;
	to__rows([my $ret = [], $fld, $rows]);
	return {fields => $fields, rows => $ret->[0]};
}


# возвращает по ключу в дебрях данных массив [ [ key-1-key-1-1, data] ... ], где data - это хэш или array на уровень выше запрашиваемых данных
sub path {
	my ($data, $path, $val) = @_;
	if(!ref $path) {
		$path = [split /\./, $path];
	}
	$data = ref $data eq "ARRAY"? $data: [$data];
	for my $key ( @$path ) {
		NEXT:
		return [] unless @$data;
		if(ref $data->[0] eq "ARRAY") { $data = [ map { @$_ } @$data]; goto NEXT }
		$data = [ map { $_->{$key} } @$data ];
	}
	return $data;
}

# парсит фреймы
sub parse_frames {
	my ($param) = @_;
	map { /=/; $` => $' } split /,/, $param;
}

# темплейт, аналогичный из js-библиотеки CTemplate::compile. Возвращает текст функции без обёртки в sub{}
my $code_begin = 'sub {	my ($dataset, $id1) = @_; my ($i, @res) = 0; for my $data (@$dataset) { my $id = "$id1-".($data->{id} // $i); push @res, \'';
my $code_end = '\';	$i++; }	return join "", @res; }';
my $code_begin1 = 'sub { my ($data, $id) = @_; return join "", \'';
my $code_end1 = '\' }';

my $code_begin_i = 'sub { my ($dataset, $id1) = @_; my $i = 0; for my $data (@$dataset) { my $id = "$id1-".($data->{id} // $i);'."\n";
my $code_end_i = "\$i++; } }\n";
my $code_begin1_i = "sub { my (\$data, \$id) = \@_; \n";
my $code_end1_i = "}\n";
our $code_begin_param = "my (\$app, \$data, \$id, \$LAYOUT) = \@_; ";


sub TemplateBare {
	
	require Helper;
	
	local ($_, $&, $`, $', $1, $2, $3, $4, $5);
	$_ = $_[0];
	#my $index = $_[3];
	
	my $RE_TYPE = qr/("(?:\\"|[^"])*"|'(?:\\'|[^'])*'|-?\d+(?:\.\d+)?(?:E[+-]\d+)?)/;
	
	my $re_type = sub { my ($x)=@_; return unless defined $x; local($`, $', $1); $x=~s/^'(.*)'$/$1/, $x=~s/"/\\"/g, $x="\"$x\"" if $x =~ /^'/; $x};

	my $_tags = qr/(?:input|meta|br)/i;
	my %tags = (
		th => qr/^(?:tr|table|tbody|tfoot|thead)$/i,
		td => qr/^(?:tr|table|tbody|tfoot|thead)$/i,
		tr => qr/^(?:table|tbody|tfoot|thead)$/i,
		option => qr/^select$/i,
		li => qr/^(?:ol|ul)$/i,
	);

	my $forms = {};	# fields=> {}, lists=> {}, forms=> {}
	
	
	my ($orig, $pos, $open_tag, $open_id, @html, @T, $T, $TAG, $NO, $STASH, $layout_id, @ifST, @code) = ($_, 0);
	my $page = my $form = {};
	
	my $get_id = sub { $open_id? ($form->{id}? "$form->{id}-$open_id": $open_id): /\bid=["']?([\w-]+)[^<]*\G/i && $1 };
	
	my $vario = sub {
		my ($type, $var, $const) = @_;
		defined($const)? $re_type->($const): defined($type)? (
			$var eq "user_id"? do { $page->{is_user_id} = 1; $page->{is_stash} = 1; "\$_STASH->{'user_id'}" }:
			$var eq "_DATA"? "\$data":
			$var eq "_STASH"? do { $page->{is_stash} = 1; "\$_STASH"}:
			$var eq 'i'? "\$i":
			$var eq "i0"? "(\$i-1)":
			$var eq "id"? "\$id":
			do { $page->{is_stash} = 1; "\$_STASH->{'$var'}" }
		): "\$data->{'$var'}"
	};
	my $helper = sub {
		my ($type, $var, $const, $open_braket) = @_;
		push @html, $vario->($type, $var, $const);
		my ($fn_idx, @fn_idx) = ($#html, $#html);
		my $VAR = undef;
		my $braket = 0;
		for(;;) {
			pos() = $pos;

			push @html, (
			!$VAR && m!\G:(\w+)(\()?!? do { $html[$fn_idx] = "Helper::$1(".$html[$fn_idx]; if($2) { ++$braket; ", " } else { $VAR = !$VAR; ")" } }:
			$VAR && m!\G(?:\$(%)?(\w+)|$RE_TYPE)!? do { push @fn_idx, $fn_idx; $fn_idx = scalar @html; $vario->($1, $2, $3) }:
			!$VAR && m!\G,\s*!? do { $fn_idx = pop @fn_idx; $& }:
			m!\G\)!? do { $VAR = 1; --$braket; $fn_idx = pop @fn_idx; ")" }:
			m!\G\}!? do { die "нет `{` для `}`" unless $open_braket; $pos++; last; }:
			last);
			$pos += length $&;
			$VAR = !$VAR;
			
		}
		if($open_braket) { die "не закрыта `}`" unless m!\G\}!; }
		die "не закрыты скобки ($braket) в шаблоне `$_`" if $braket;
		
		return $fn_idx;
	};
	
	
	
	my $pop = sub {	# закрывается тег
		my $tag = pop @T;
		
		if(@$tag > 2) {	# тег список - $* или форма - $+
			local ($&, $`, $');
			my ($tmp_open_tag, $begin, $name, $type, $cinit, $idx, $_form) = @$tag;
			my $template = substr $_, $begin, $pos-$begin;
			if($cinit) { $template=~s/!/!!/g; $template=~s/-->/--!>/g; $html[$idx] .= "<!--$template-->" }
			my $call = ")->(\$data".($name? "->{'$name'}": "").", \$id".($name? ".'-$name'": "");
			push @html, ($type? $code_end: $code_end1) . $call . "), '";
			
			push @code, ['end', ($type? $code_end_i: $code_end1_i) . $call . ");\n"];
			
			$form->{template} = $template;
			push @{$_form->{forms}}, $form->{id};
			$form = $_form;
		}
		$TAG = $tag->[0];
	};
	
	for(;;) {
		
		pos() = $pos;

		push @html,
		!$NO && m!\G<(\w+)!? do {
			$TAG = $1;
			$open_tag = lc $TAG;
			$NO=1 if $TAG =~ /^(?:script|style)$/;
			if(my $re = $tags{$open_tag}) { $pop->() while @T and $T[$#T]->[0] !~ $re; }
			"<$TAG" 
		}:
		!$NO && m!\G>!? do {
			die "Невалидный шаблон - обнаружена `<` без тега: `$_`" if not defined $TAG;
			if($TAG =~ $_tags) { $TAG = $open_id = undef; ">" } else {
				my (@ret, $type, $name);
				if($T) {
					local($&, $`, $'); my $m;
					my $frm = $T;
					$T = [$open_tag, $pos+1, $name=$T->{name}, $type=$T->{is_list}, $m=/\bcinit[^<]*\G/i, scalar(@html), $form];
					my $id = (exists($form->{id})? "$form->{id}-": "") . $name;
					$frm->{id} = $id;
					$frm->{parent_form} = $form->{id};
					$forms->{$id} = $form = $frm;
					my $load = "";
					if($form->{load}) {
						my $data = ($name? "\$data->{'$name'}": "\$_[0] = \$data");
						my $where = exists $form->{where}? ", $form->{where}": '';
						#$name =~ s!-\d+!!g;
						$load = "$data = \$app->action->form_load(\$id.'-$name'$where) unless ref($data);";
						push @code, ["load", $load . "\n"];
						$load = "do { $load () }, ";
					}
					push @code, ["begin", "(" . ($type? $code_begin_i: $code_begin1_i)];
					@ret=(">", "', $load(" . ($type? $code_begin: $code_begin1))
				} else { $T = [$open_tag]; @ret = ">" }
				push @T, $T;
				$T = $open_tag = undef;
				@ret
			}
		}:
		!$NO && m!\G/>!? do { $TAG = $open_id = undef; $& }:
		!$NO && m!\G</(\w+)\s*>!? do { $TAG = $open_id = undef; my ($tag) = ($1); while(@T and $pop->() ne $tag) {}; $& }:
		!$NO && m!\G<\!--.*?-->!s? do { $& }:
		!$NO && m!\G<\!doctype[^>]+>!i? do { $& }:
		$NO && m!\G</$TAG\s*>!? do { $TAG = $open_id = $open_tag = $NO = undef; $& }:
		m!\G\$-(\w+)?!? do { $open_id = $1; "', \$id, '".(defined($1)? "-$1": "") }:
		m!\G\$@([/\w-]+)!? do {
			my $name = $1;
			$page->{include}{$1} = 1;
			push @code, ["include", "\$app->action->include_ajax('$name', \$data, \$id, \$LAYOUT);\n"];
			"', \$app->action->include('$name', \$data, \$id, \$LAYOUT), '"
		}:
		m!\G\$&!? do { $page->{layout_id} = $get_id->(); "', \@\$LAYOUT, '" }:
		m!\G\{%\s*(\w+)\s*=%\}!? do { $page->{is_stash} = 1; "', do { \$_STASH->{'$1'} = join '', ('" }:
		m!\G\{%\s*end\s*%\}!? do { "'); () }, '" }:
		m!\G\{%\s*if\s+(?:\$(%)?(\w+)|$RE_TYPE)!? do {
			$pos += length $&;
			push @html, "', ((";
			my $from = @html;
			$helper->($1, $2, $3);
			die "Нет закрывающей `%}` для if" unless m!\G\s*%\}!;
			push @ifST, 1;
			$pos += length $&;
			push @code, ["if", join "", "\nif(", @html[$from..$#html], ") {\n"];
			push @html, ")? ('";
			next
		}:
		m!\G\{%\s*elif\s+(?:\$(%)?(\w+)|$RE_TYPE)!? do {
			die "Нельзя использовать elif" if @ifST==0 or $ifST[$#ifST] != 1;
			$pos += length $&; push @html, "'): (";
			my $from = @html;
			$helper->($1, $2, $3);
			die "Нет закрывающей `%}` для elif" unless m!\G\s*%\}!;
			$pos += length $&;
			push @code, ["elif", join "", "\n} elsif(", @html[$from..$#html], ") {"];
			push @html, ")? ('";
			next
		}:
		m!\G\{%\s*else\s*%\}!? do { die "Нельзя использовать else" if @ifST==0 or $ifST[$#ifST]!=1; $ifST[$#ifST] = 2; push @code, ["else", "\n} else {"]; "'): ('" }:
		m!\G\{%\s*fi\s*%\}!? do { die "Нельзя использовать fi" if @ifST==0; push @code, ["fi", "}\n"]; "')".(pop(@ifST) == 1? ": ()": "")."), '" }:
		m!\G\{%\s*(\w+)\s+$RE_TYPE(?:\s*,\s*$RE_TYPE)?(?:\s*,\s*$RE_TYPE)?(?:\s*,\s*$RE_TYPE)?(?:\s*,\s*$RE_TYPE)?\s*%\}!? do { push @{$page->{options}}, [$1, unstring($2), unstring($3), unstring($4), unstring($5)]; () }:
		m!\G&#?\w+;?!? $&:
		m!\G(?:\$(\{\s*)?(?:(%)?(\w+)|$RE_TYPE)|(#)(\{\s*)?(%)?(\w+))!? do {
			my $open_span = $5;
			my $open_braket = $1 // $6;
			my $type = $2 // $7;
			my $var = $3 // $8;
			my $const = $4;
			my $content = $&;
			if($open_span && ($open_tag || $TAG && $TAG =~ /^(?:script|style)$/i)) { $content }
			else {
				$pos += length $content;

				$form->{fields}{$var} = 1 if defined $var and not $type;
				push @html, "<span id=', \$id, '-$var>" if $open_span;
				push @html, "', ";
				my $fn_idx = $helper->($type, $var, $const, $open_braket);
				
				$html[$fn_idx] = "Helper::html($html[$fn_idx]", push @html, ")" unless $html[$fn_idx] =~ /^Helper::(\w+)/? exists $Helper::_NO_ESCAPE_HTML{$1}: undef;
				
				push @html, ", '" . ($open_span? "</span>": "");
				next;
			}
		}:
		
		# :load([model,] "where"|id|%id|5)
		# :model(model [, "where"|id|%id|5])
		# шаблон для ajax - добавляет данные в load учитывая циклы и ифы
		# load присваивает данным, но только если там их нет
		$open_tag && m!\G\$([+*])(\w+)(?::(?:(noload)|(load|model)\((?:(\w+),\s*)?(?:(%?\w+)|($RE_TYPE))\)))?!? do {
			my ($type, $name, $noload, $load, $model, $var, $where) = ($1, $2, $3, $4, $5, $6, $7);
			$T = {
				name => $name, 
				is_list => $type eq "*",
			};
			
			$T->{noload} = 1 if $noload;
			# load=1, model=2, noload=0, 'nothing'=0, 'from'=2
			$load = $noload? 0: defined($load)? ($load eq "load"? 1: 2): $form->{load}? 2: 0;
			$model = $var // $name, $var = undef if $load == 2 and not defined $model;
			$model = $name if $load == 1 and not defined $model;
			$T->{model} = $model =~ /\./? [split /\./, $model]: $model if $model;
			
			$T->{load}  = $load if $load;
			$T->{where} = unstring($where) if $where;
			$T->{where} = "\$$var" if $var;
			
			if(exists $T->{where}) {
				$T->{where} =~ s!['\\]!\\$&!g;
				$T->{where} =~ s!^[^\$]!'$&!;
				$T->{where} .= "'" if $T->{where} !~ /\$%?\w+$/;
				$T->{where} =~ s/\$(%)?(\w+)/ $form->{fields}{$2}=1 unless $1; ($` ne ""? "', ": "") . $vario->($1, $2) . ($' ne ""? ", '": "")/ge;
			}
			"', \$id, '-$name";
		}:
		$open_tag && m!\G\$([+*])!? "', \$id, '":
		m!\G[\\']!? "\\$&":
		m!\G.!s? $&:
		last;
		
		$pos += length $&;
	}

	$pop->() while @T;
	
	$_[1] = $forms;
	$_[2] = $form;
	
	# текст темплейта
	#$form->{template} = $_;
	
	# CODE: for(my $i=0; $i<@code; $i++) {
		# my ($code) = @{$code[$i]};
		# if($code eq "if") {
			# my $k = $i;
			# for(; $code[$i+1]->[0] =~ /^(?:elif|else)$/; $i++) {}
			# if($code[$i+1]->[0] eq "fi") { splice @code, $k, $i-$k+2; goto CODE; }
		# }
		# if($code eq "begin" and $code[$i+1]->[0] eq "end") { splice @code, $i, 2; goto CODE; }
	# }
	
	my @begin;
	
	#my $code_quote = "my \$dbh = \$app->connect->{dbh}; ";
	my $code_stash = "my \$_STASH = \$app->response->stash; ";
	my $code_user_id = "\$_STASH->{user_id} = \$app->request->user->id; ";
	
	#push @begin, $code_quote if $form->{is_quote};
	push @begin, $code_stash if $form->{is_stash};
	push @begin, $code_user_id if $form->{is_user_id};
	
	$form->{code} = join "", "sub { $code_begin_param", @begin, "\n", map({$_->[1]} @code), "\n}";
	
	my $x = join "", "sub { $code_begin_param", @begin, " return join \"\", '", @html, "'};";
	#our $rem++;
	#Utils::write("$rem.pl", $x);
	$x
}

# добавляет обёртку в sub{}
#sub TemplateStr {
#	join "", $code_begin1, TemplateBare(@_), $code_end1;
#}

# возвращает функцию
sub Template {
	my $str = TemplateBare(@_);
	::msg($str);
	my $fn = eval $str;
	die $@ if $@;
	$fn;
}

1;