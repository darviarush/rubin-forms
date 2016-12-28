package R::File;
# синхронный файловый интерфейс

use common::sense;
use R::App qw/$app msg1 msg todo closure Num Isa Can/;

# конструктор
sub new {
	my $cls = shift;
	bless {
		files => [@_],
		encode => 'utf-8',
	}, ref $cls || $cls;
}

# превращает в картинку
sub image {
	my ($self) = @_;
	bless scalar($self->clone), ref $app->fileImage;
}

# клонирует
sub clone {
	my $self = shift;
	my $new = $self->new;
	%$new = (%$self, @_);
	wantarray? @{$new->{files}}: $new;
}


# устанавливает/возвращает кодировку файла
sub encode {
	my $self = shift;
	if(@_) {
		$self->clone(encode => shift());
	} else {
		$self->{encode}
	}
}

# устанавливает/возвращает режим чтения: >> или >
sub mode {
	my $self = shift;
	if(@_) {
		$self->clone(mode => shift());
	} else {
		$self->{mode}
	}
}

# устанавливает/возвращает для cp размер буфера
sub bufsize {
	my $self = shift;
	if(@_) {
		$self->clone(bufsize => shift());
	} else {
		$self->{bufsize}
	}
}


# создаёт файлы из строчных путей и из файлов
sub from {
	my $self = shift;
	$self->clone(files => [ map { ref $_? $_->files: $_ } @_ ]);
}

# сокращение для  $self->clone(files=>[$path]);
sub one {
	my ($self, $path) = @_;
	$self->clone(files=>[$path]);
}

# возвращает n-й файл. Счёт с нуля. -1 - последний
sub eq {
	my ($self, $n) = @_;
	$self->one($self->{files}[$n]);
}

# возвращает функцию для сравнения файлов или регулярку. Она используется в find для отсечения ненужных файлов
sub _filters {
	
	my $filters;
	
	for my $filter (@_) {
		my $fn;
		if(!ref $filter and $filter =~ /^-\w$/) {
			$fn = eval "sub {$filter}";
			die $@ if $@;
		}
		elsif(!ref $filter) {
			$fn = $app->perl->like($filter);
			$fn = closure($fn, sub { scalar $_ =~ $_[0] });
		}
		elsif(ref $filter eq "Regexp") {
			$fn = closure($filter, sub { scalar $_ =~ $_[0] });
		}
		elsif(ref $filter eq "CODE") { $fn = $filter }
		else {
			die "параметр - не функция и не Regexp: $filter " . ref $filter;
		}
		
		push @$filters, $fn;
	}	
	
	$filters;
}

# # очищает фильтр и добавляет в него новые
# sub reset_filter {
	# my $self = shift;
	
	# delete $self->{filter};
	# $self->filter(@_) if @_;
	
	# $self
# }

# ищет файлы и применяет к ним функцию
sub find {
	my $self = shift;
	
	my $files = [];
	
	if(@{$self->{files}}) {
	
		my $filters = _filters(@_);
		
		require File::Find;
		
		File::Find::find({
			no_chdir => 1,
			wanted => ($filters? sub {
				local $_;
				for my $fn (@$filters) {
					$_ = $File::Find::name;
					return if !$fn->();
				}
				push @$files, $File::Find::name;
			}: sub {
				push @$files, $File::Find::name;
			}),
		}, @{$self->{files}});

	}
	
	$self->clone(files => $files)
}

# выполняет функцию для каждого из файлов
sub then {
	my ($self, $sub) = @_;
	local $_;
	for my $file (@{$self->{files}}) {
		$_ = $self->one($file);
		$sub->();
	}
	$self
}

# возвращает файлы прошедшие проверку
sub grep {
	my $self = shift;
	local $_;
	if(my $filters = _filters(@_)) {
		my $files = [];
	
		FILE: for my $path (@{$self->{files}}) {
			for my $fn (@$filters) {
				$_ = $path;
				next FILE if !$fn->();
				push @$files, $path;
			}
		}
		
		$self->clone(files => $files);
	} else {
		$self->clone
	}
}

# маппинг для файлов
sub map {
	my ($self, $sub) = @_;
	local $_;
	map { my $save=$_; $_ = $self->one($_); my $ret=$sub->(); $_=$save; $ret } $self->files;
}

# преобразовывает пути файлов
sub filemap {
	my ($self, $sub) = @_;
	local $_;
	$self->clone(files => [map { my $save=$_; $_ = $self->one($_); my $ret=$sub->(); $_=$save; $ret } $self->files]);
}

# переворачивает коллекцию
sub reverse {
	my ($self) = @_;
	$self->clone(files => [reverse @{$self->{files}}])
}

# объединяет
sub reduce {
	my $self = shift;
	local($a, $b);
	my $files = $self->{files};
	my $i = 0;
	$a = @_==1? do {$i++; $self->one($files->[0]) }: shift @_;
	my $sub = shift;
	
	for(; $i<@$files; $i++) {
		$b = $self->one($files->[$i]);
		$a = $sub->();
	}
	
	$a
}

# сортирует файлы
sub sort {
	my ($self, $code) = @_;
	local $_;
	if(@_ == 1) {
		@{$self->{files}} = sort @{$self->{files}};
	}
	else {
		@{$self->{files}} = map { $_->{files}[0] } sort $code, map { $self->one($_) } @{$self->{files}};
	}
	$self
}

# количество файлов в коллекции
sub length {
	my ($self) = @_;
	scalar @{$self->{files}}
}

# пути файлов через разделитель
# разделитель по умолчанию - перевод строки
sub join {
	my ($self, $sep) = @_;
	$sep //= "\n";
	join $sep, @{$self->{files}}
}

# пропускает имена файлов маской - не модифицирует изначальный массив
sub glob {
	my $self = shift;
	
	my $files = [];
	
	for my $file (@{$self->{files}}) {
		push @$files, glob $file;
	}
	
	$self->clone(files => $files)->grep(@_)
}

# a моложе b
# чем моложе файл - тем время модификации больше
# все файлы a должны быть младше всех файлов b
sub youngest {
	my $self = shift;
	$self->minmtime > $self->from(@_)->maxmtime 
}

# a старше b
# a обновлялся до того как обновлялся b
# чем старше файл - тем время модификации меньше
# значит a имеет меньшее mtime
# все файлы a должны быть старше всех файлов b
sub oldest {
	my $self = shift;
	$self->maxmtime < $self->from(@_)->minmtime
}

# youngling - детёныш, незрелый, юнец, новичёк
# хотя бы один файл из a младше 
sub youngling {
	my ($self) = @_;
	$self
}

# минимальное mtime
sub minmtime {
	my $self = shift;
	local ($a, $b);
	$self->reduce(0+"inf", sub { my $y=$b->mtime; $a < $y? $a: $y })
}

# максимальное mtime
sub maxmtime {
	my $self = shift;
	local ($a, $b);
	$self->reduce(0, sub { my $y=$b->mtime; $a > $y? $a: $y })
}

# возвращает время модификации
# чем моложе файл - тем время модификации больше
sub mtime {
	my $self = shift;
	#my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $self->{files}[0];
	my $mtime = (stat $self->{files}[0])[9];
	#$! = undef;
	$mtime
}

sub _mtime { (stat $_[0])[9] }

# номер файловой системы
sub device {
	my $self = shift;
	my $dev = (stat $self->{files}[0])[0];
	#$! = undef;
	$dev
}

# номер в таблице inode
sub inode {
	my $self = shift;
	my $inode = (stat $self->{files}[0])[1];
	#$! = undef;
	$inode
}

# возвращает и устанавливает тип и права
sub mod {
	my $self = shift;
	if(@_) {
		my ($mod) = @_;
        $mod = oct($mod) if !Num $mod;
		for my $path (@{$self->{files}}) {
			chmod $mod, $path;
		}
		#$! = undef;
		$self
	}
	else {
		my $mod = (stat $self->{files}[0])[2];
		#$! = undef;
		$mod
	}
}

# файл можно модифицировать
sub writable {
	my ($self) = @_;
	-w $self->{files}[0]
}

# файл можно читать
sub readable {
	my ($self) = @_;
	-r $self->{files}[0]
}

# файл можно выполнять
sub executable {
	my ($self) = @_;
	-x $self->{files}[0]
}


# файл остаётся в памяти после выгрузки
sub sticky {
	my ($self) = @_;
	#http://search.cpan.org/~bdfoy/PerlPowerTools-1.011/bin/chmod
	-k $self->{files}[0]
}

# это директория
sub isdir {
	my ($self) = @_;
	-d $self->{files}[0]
}

# это регулярный файл
sub isfile {
	my ($self) = @_;
	-f $self->{files}[0]
}

# это символьная ссылка
sub issymlink {
	my ($self) = @_;
	-l $self->{files}[0]
}

# это именованная очередь
sub isfifo {
	my ($self) = @_;
	-p $self->{files}[0]
}

# это именованный сокет
sub issock {
	my ($self) = @_;
	-S $self->{files}[0]
}

# это устройство
*isdev = \&isdevice;
sub isdevice {
	my ($self) = @_;
	my $path = $self->{files}[0];
	(-c $path) || -b $path
}

# это символьное устройство
sub ischar {
	my ($self) = @_;
	-c $self->{files}[0];
}

# это блочное устройство
sub isblock {
	my ($self) = @_;
	-b $self->{files}[0];
}

# файл связан с терминалом
sub istty {
	my ($self) = @_;
	-t $self->{files}[0]
}

# это текстовый файл
sub istext {
	my ($self) = @_;
	-T $self->{files}[0]
}

# это бинарный файл
*isbin = \&isbinary;
sub isbinary {
	my ($self) = @_;
	-B $self->{files}[0]
}

# файл существует
sub exists {
	my ($self) = @_;
	-e $self->{files}[0]
}

# размер файла в байтах
sub size {
	my ($self) = @_;
	-s $self->{files}[0]
}


# это свой файл
sub owned {
	my ($self) = @_;
	-O $self->{files}[0]
}


# -R  File is readable by real uid/gid.
# -W  File is writable by real uid/gid.
# -X  File is executable by real uid/gid.
# -O  File is owned by real uid.
# -z  File has zero size (is empty).

# -u  File has setuid bit set.
# -g  File has setgid bit set.
# -k  File has sticky bit set.
# -B  File is a "binary" file (opposite of -T).
# -M  Script start time minus file modification time, in days.
# -A  Same for access time.
# -C  Same for inode change time (Unix, may differ for other platforms)


# -r  File is readable by effective uid/gid.
# -w  File is writable by effective uid/gid.
# -x  File is executable by effective uid/gid.
# -o  File is owned by effective uid.
# -R  File is readable by real uid/gid.
# -W  File is writable by real uid/gid.
# -X  File is executable by real uid/gid.
# -O  File is owned by real uid.
# -e  File exists.
# -z  File has zero size (is empty).
# -s  File has nonzero size (returns size in bytes).
# -f  File is a plain file.
# -d  File is a directory.
# -l  File is a symbolic link (false if symlinks aren't supported by the file system).
# -p  File is a named pipe (FIFO), or Filehandle is a pipe.
# -S  File is a socket.
# -b  File is a block special file.
# -c  File is a character special file.
# -t  Filehandle is opened to a tty.
# -u  File has setuid bit set.
# -g  File has setgid bit set.
# -k  File has sticky bit set.
# -T  File is an ASCII or UTF-8 text file (heuristic guess).
# -B  File is a "binary" file (opposite of -T).
# -M  Script start time minus file modification time, in days.
# -A  Same for access time.
# -C  Same for inode change time (Unix, may differ for other platforms)


# подсчитывает размер всех файлов и папок
sub space {
	my ($self) = @_;
	my $space = 0;
	$self->find(sub {
		$space += -s $_;
		0;
	});
	$space
}

# размер одних файлов
sub space_usage {
	my ($self) = @_;
	my $space = 0;
	$self->find(sub {
		$space += -s $_ if -f $_;
		0;
	});
	$space
}

# удаляет файлы и директории с файлами
sub rm {
	my ($self) = @_;
	my @dir;
	$self->find(sub {
		if(-d $_) {unshift @dir, $_} else { msg("rm: не могу удалить файл `$_`: $!") unless unlink $_}
		0
	});
	do { msg("rm: не могу удалить каталог `$_`: $!") unless rmdir $_ } for @dir;
	$self
}

# удаляет всё в указанной директории
*rmcontent = \&rmdown;
sub rmdown {
	my ($self) = @_;
	for my $dir (@{$self->{files}}) {
		$self->new( <$dir/*> )->rm;
	}
	$self
}

# читает первый файл целиком или указанный размер
sub read {
	my ($self, $size) = @_;
	my $f = $self->open;
	$f->read(my($body), $size // -s $f);
	$f->close;
	return $body;
}

# считывает все файлы через разделитель, а если разделитель не указан и wantaaray, то выдаёт в виде массива
sub reads {
	my ($self, $delim) = @_;
	!defined($delim) && wantarray? (map { $self->one($_)->read } $self->files):
		(join $delim, map { $self->one($_)->read } $self->files );
}

# устанавливает межстрочный сепаратор
sub sep {
	my $self = shift;
	if(@_) {
		$self->clone(sep => shift());
	} else {
		$self->{sep}
	}
}

# устанавливает обрезать ли разделитель строки
sub chop {
	my $self = shift;
	if(@_) {
		$self->clone(chop => shift());
	} else {
		$self->{chop}
	}
}

# считывает строки в массив через разделитель
sub readlines {
	my ($self, $sep, $chop) = @_;
	
	$sep //= $self->{sep} // "\n";
	$chop //= $self->{chop};
	
	local $_;
	
	if($chop) {
		$sep = qr/$sep/;
		return map { split $sep, $self->one($_)->read } $self->files;
	}
	
	local $/ = $sep;
	
	map { my $f = $self->one($_)->open; my @lines = <$f>; $f->close; @lines } $self->files
}

# записывает в 1-й файл
sub write {
	my $self = shift;
	my $f = $self->open($self->{mode} // ">");
	local $_;
	local $\ = "";
	$f->print($_) for @_;
	$f->close;
	$self
}

# дописывает в конец файла
sub endwrite {
	my $self = shift;
	$self->clone(mode => '>>')->write(@_);
	$self
}

# записывает во все файлы
sub writes {
	my $self = shift;
	for my $file ($self->files) {
		$self->one($file)->write(@_);
	}
	$self
}


# перезаписывает файлы через функцию
# если контент не изменился - не записывает и время модификации не меняется
sub replace {
	my ($self, $block) = splice @_, 0, 2;
	local $_;
	
	my $i = 0;
	for my $path (@{$self->{files}}) {
		my $f = $self->one($path);
		my $buf = $_ = $f->read;
		$block->($f, $i, @_);
		$f->write($_) if $_ ne $buf;
		$i++;
	}
	$self
}

# путь файла с индексом idx в коллекции
sub path {
	my ($self, $idx) = @_;
	$self->{files}[$idx]
}

# переводит файл в путь
sub topath {
	my ($self, $to) = @_;
	Isa($to, "R::File")? $to->{files}[0]: $to;
}

# переводит файл в путь
sub tofile {
	my ($self, $to) = @_;
	Isa($to, "R::File")? $to: $self->new($to);
}


# копирует файлы
# чтобы скопировать все файлы в директорию используйте слеш на конце "dir/", иначе - скопируются только первый
sub cp {
	my ($self, $to) = @_;
	
	$to = $self->topath($to);
	
	my $bufsize = $self->{bufsize} // 1024*1024*8;
	
	my $dir = $to =~ m!/$!;
	
	my $self = $self->encode(undef);
	
	for my $path ($dir? @{$self->{files}}: $self->{files}[0]) {
	
		my $f = $self->one($path);
		my $k = $self->one($dir? $to . $f->file: $to);
		
		my $from = $f->open;
		my $file_to = $k->open(">");
		
		my $buf;
		
		for(;;) {
			last unless $from->read($buf, $bufsize);
			$file_to->print( $buf );
		}
	}
	
	$self
}

# переносит файлы
# используйте / в конце пути, чтобы перенести все файлы в одну директорию, иначе перенесётся только первый
sub mv {
	my ($self, $to) = @_;
	
	$to = $self->topath($to);
	
	if($to =~ m!/$!) {
		for my $from (@{$self->{files}}) {
			my $file = $self->one($from);
			my $to_path = $to . $file->file;
			$file->cp($to_path), unlink $from unless rename $from, $to_path;
		}
	} else {
		my $from = $self->{files}[0];
		$self->cp($to), unlink $from unless rename $from, $to;
	}
	$! = undef;
	$self
}

# открывает первый файл и возвращает описатель
sub open {
	my ($self, $mode) = @_;
	my $mode = ($mode // $self->{mode} // "<") . ($self->{encode}? ":encoding($self->{encode})": "");
	my $path = $self->{files}[0];
	open my($f), $mode, $path or die "file($path)->open($mode): Не могу открыть: $!\n";
	
	# для Coro
	#$f = Coro::Handle->new_from_fh($f) if $app->{coro};
	
	$f
}

# возвращает ссылку на хэш связанный с файлом в формате dbm
sub dbm {
	my ($self) = @_;
	my $hash = {};
	dbmopen %$hash, $self->path, 0642 or die "dbm(" . $self->path . "): Не могу открыть: $!\n";
	$hash
}

# возвращает массив файлов
sub files {
	my ($self) = @_;
	@{$self->{files}}
}

# меняет начальную директорию на dir2 у всех файлов. Ошибка, если хоть у одного нет такой директории
sub subdir {
	my ($self, $dir, $dir2) = @_;
	local ($', $');
	$dir .= "/" if $dir ne "" and $dir !~ m!/$!;
	$dir2 .= "/" if $dir2 ne "" and $dir2 !~ m!/$!;
	my $files = [];
	for my $path (@{$self->{files}}) {
		die "$path не начинается с $dir" if $dir ne substr $path, 0, length $dir;
		push @$files, $dir2 . substr $path, length $dir;
	}
	$self->clone(files => $files);
}

# root/mmd/dir1/dir2/name.ext1.ext2.ext3
# ext = ext3
# exts = ext1.ext2.ext3
# name = name.ext1.ext2
# nik = name
# file = name.ext1.ext2.ext3
# dir = root/mmd/dir1/dir2
# subdir(root/mmd) => dir1/dir2/name.ext1.ext2.ext3
# subdir(root/mmd => rss/mmx) => rss/mmx/dir1/dir2/name.ext1.ext2.ext3

# возвращает каталог первого файла или заменяет у всех и возвращает клон
sub dir {
	my $self = shift;
	local ($`, $', $_);
	if(@_) {
		my $dir = shift;
		$dir .= "/" if $dir ne "" and $dir !~ m!/$!;
		my $files = [];
		for my $path (@{$self->{files}}) {
			my $file = $path; # $path в for является ссылкой - не копируется
			$file =~ s/^/$dir/ unless $file =~ s!.*/!$dir!s;
			push @$files, $file;
		}
		$self->clone(files => $files);
	} else {
		$self->{files}[0] =~ /\/(?:[^\/]*)$/? $`: "";
	}
}

# возвращает название первого файла nik+все расширения, кроме последнего
sub name {
	my $self = shift;
	local ($`, $', $1);
	if(@_) {
		my $name = shift;
		my $files = [];
		for my $path (@{$self->{files}}) {
			my $file = $path; # $path в for является ссылкой - не копируется
			$file =~ s!(?:[^/]+?)(\.[^\./]+)?$!$name$1!;
			push @$files, $file;
		}
		$self->clone(files => $files);
	} else {
		$self->{files}[0] =~ m!([^/]+?)(?:\.[^\./]+)?$!? $1: "";
	}
}

# возвращает имя без расширений
sub nik {
	my ($self) = @_;
	my $self = shift;
	local ($', $', $1);
	if(@_) {
		my $name = shift;
		my $files = [];
		for my $path (@{$self->{files}}) {
			my $file = $path; # $path в for является ссылкой - не копируется
			$file =~ s!(?:[^/\.]+)(\.[^/]+)?$!$name$1!;
			push @$files, $file;
		}
		$self->clone(files => $files);
	} else {
		$self->{files}[0] =~ m!([^/\.]+)(?:\.[^/]+)?$!? $1: "";
	}
}

# возвращает расширение первого файла
sub ext {
	my $self = shift;
	local ($', $', $1);
	if(@_) {
		my $ext = shift;
		$ext = ".$ext" if $ext ne "" and $ext !~ /^\./;
		my $files = [];
		for my $path (@{$self->{files}}) {
			my $file = $path; # $path в for является ссылкой - не копируется
			$file =~ s!$!$ext! unless $file =~ s!\.[^\.]+$!$ext!;
			push @$files, $file;
		}
		$self->clone(files => $files);
	} else {
		$self->{files}[0] =~ m!\.([^\./]+)$!? $1: "";
	}
}

# возвращает расширения первого файла
sub exts {
	my $self = shift;
	local ($', $', $1, $_);
	if(@_) {
		my $ext = shift;
		$ext = ".$ext" if $ext ne "" and $ext !~ /^\./;
		my $files = [];
		for my $path (@{$self->{files}}) {
			my $file = $path; # $path в for является ссылкой - не копируется
			$file =~ s!$!$ext! unless $file =~ s!\.[^/]+$!$ext!;
			push @$files, $file;
		}
		$self->clone(files => $files);
	} else {
		$self->{files}[0] =~ m!\.([^/]+)$!? $1: "";
	}
}

# имя + расширение первого файла
sub file {
	my $self = shift;
	local ($', $', $1, $_);
	if(@_) {
		my $main = shift;
		my $files = [];
		for my $path (@{$self->{files}}) {
			my $file = $path; # $path в for является ссылкой - не копируется
			$file =~ s!([^/]+?)$!$main!;
			push @$files, $file;
		}
		$self->clone(files => $files);
	} else {
		$self->{files}[0] =~ m!([^/]+?)$!? $1: "";
	}
}

# добавляет к файлу дату. Если есть такой же файл ...
sub adddate {
	my ($self, $ext) = @_;
	my $files = [];
	my @ext = defined($ext)? ".$ext": ();
	my $time = $app->perl->strftime("%Y%m%d_%H%M%S", localtime);
	for my $path ($self->files) {
		push @$files, join "", $path, ".", $time, @ext;
	}
	$self->clone(files => $files);
}

# добавляет в конец пути файлов 
sub back {
	my ($self, $back) = @_;
	my $files = [];
	for my $path ($self->files) {
		push @$files, $path . $back;
	}
	$self->clone(files => $files);
}

# добавляет в начало имени файлов
sub front {
	my ($self, $front) = @_;
	my $files = [];
	for my $path ($self->files) {
		push @$files, $front . $path;
	}
	$self->clone(files => $files);
}

# добавляет в начало имени файлов директорию
sub frontdir {
	my ($self, $front) = @_;
	my $files = [];
	local ($`, $', $&);
	
	$front =~ s!/?$!/!;
	
	for my $path ($self->files) {
		my $file = $path;
		$file =~ s!^/?!$front!;
		push @$files, $file;
	}
	$self->clone(files => $files);
}

# добавляет в конец файлов путь, файлы считаются директориями
sub sub {
	my ($self, $dir) = @_;
	local ($', $');
	
	$dir =~ s!^/?!/!;
	
	my $files = [];
	for my $file (@{$self->{files}}) {
		my $path = $file;	# в for $file является ссылкой - не копируется
		$path =~ s!/?$!$dir!;
		push @$files, $path;
	}
	$self->clone(files => $files);
}

# возвращает текущий каталог
sub cwd {
	require "Cwd.pm";
	Cwd::getcwd();
}

# возвращает текущий каталог c учётом архитектуры
sub pwd {
	require "Cwd.pm";
	Cwd::cwd();
}

# переводит в абсолютные все пути
sub abs {
	my ($self) = @_;
	my $pwd = $self->pwd;
	my $files = [];
	for my $path (@{$self->{files}}) {
		$path = "$pwd/$path" if "/" ne substr $path, 0, 1;
		my @path = split m!/+!, $path;
		for(my $i=0; $i<@path; $i++) {
			if($path[$i] eq "..") {
				die "выход за пределы рутовой директории (/) `$path`" if $i == 1;
				splice @path, $i-1, 2;
				$i-=2;
			} elsif($path[$i] eq ".") {
				splice @path, $i, 1;
				$i--;
			}
		}
		$path = @path == 1? "/": join "/", @path;
		push @$files, $path;
	}
	$self->clone(files => $files);
}

# создаёт каталоги в пути для всех файлов
sub mkpath {
	my ($self) = @_;
	local ($_, $`, $');
	for(@{$self->{files}}) {
		mkdir $` while /\//g;
	}
	$! = undef;
	$self
}

# возвращает коллекцию путей файла
sub paths {
	my ($self) = @_;
	local ($_, $`, $');
	
	my $files = [];
	
	if(defined( $_ = $self->{files}[0] )) {
		push @$files, $` while /\//g;
	}
	
	$self->clone(files => $files);
}

# создаёт директорию для всех файлов
sub mkdir {
	my ($self, $mode) = @_;
	
	$mode //= 0744;
	
	CORE::mkdir($_, $mode) for $self->files;
	
	$self
}

# удаляет все пустые директории вверх для всех файлов
sub rmpath {
	my ($self) = @_;
	local ($_, $`, $');
	for(@{$self->{files}}) {
		my @path = ();
		push @path, $` while /\//g;
		rmdir $_ or last for reverse @path;
	}
	$! = undef;
	$self
}

# переходит в 1-й каталог
*cd = \&chdir;
sub chdir {
	my ($self) = @_;
	chdir $self->{files}[0];
	die( ($!+0) . ": $!" ) if $! && $! != 17;	# 17 - file exists
	$self
}

# возвращает $!
sub err {
	$!
}

# пакует файлы в bz2 и записывает в файлы c расширением bz2 или 1-й с указанным имененем
sub bzip2 {
	my ($self, $name, $append, $bksize, $wf) = @_;
	require IO::Compress::Bzip2;
	
	$bksize //= 9;
	$wf //= 30;
	$append //= 1;
	
	for my $path (defined($name)? $self->{files}[0]: $self->files) {
		my $out = $name // "$path.bz2";
		IO::Compress::Bzip2::bzip2($path, $out, Append=>$append, BlockSize100K=>$bksize, WorkFactor=>$wf) or die "bzip2 failed: $IO::Compress::Bzip2::Bzip2Error";
	}
	$self
}

# Запоминает время файлов при первом вызове и сравнивает - не изменились ли при втором.
# Возвращает 3 файловых объекта: изменившиеся, появившиеся и исчезнувшие файлы.
sub watch {
	my ($self) = @_;
	
	my ($changed, $new, $deleted) = ([], [], []);
	
	my $watch = $self->{watch} //= {};
	my %watched;
	
	$self->find(sub {
		my $today = _mtime($_);
		my $before = $watch->{$_};

		#msg1 $before, $today, $_;
		
		if(!defined $before) {
			push @$new, $_;
		}
		elsif($before < $today) {
			push @$changed, $_;
		}
		
		$watched{$_} = 1;
		$watch->{$_} = $today;
		0;
	});
	
	my @watch = keys %$watch;
	for my $path (@watch) {
		delete($watch->{$path}), push @$deleted, $path if !exists $watched{$path};
	}
	
	$changed = $self->clone(files => $changed);
	$new = $self->clone(files => $new);
	$deleted = $self->clone(files => $deleted);
	
	$! = undef;

	require "R/File/Watch.pm";
	
	wantarray? ($changed, $new, $deleted): bless { changed => $changed, new => $new, deleted => $deleted }, "R::File::Watch";
}


# как и watch, но сравнивает не с прежним значением, а с другим файловым массивом
sub cmpmtime {
	my ($self, $deps) = @_;

	my $watch = $deps->{watch};
	
	die "cmpmtime: файловые коллекции не одинаковы по размеру" if $self->length != $deps->length;
	
	my $i = 0;
	for my $root ($self->files) {
		
		my $froot = $self->one($root);
		
		my $deproot = $deps->{files}[$i];
		#my $fdeproot = $self->one($deproot);
		
		$root = quotemeta $root;
		$deproot = $deproot;
		
		for my $file ($froot->find->files) {
			my $mtime = _mtime $file;
			$file =~ s!$root!$deproot!;
			$deps->{watch}{$file} = $mtime;
		}
		
	}

	my $res = $deps->watch($self);
	
	if(defined $watch) { $deps->{watch} = $watch } else { delete $deps->{watch} }
	
	return wantarray? ($res->{changed}, $res->{new}, $res->{deleted}): $res;
}

# сравнивает один файл со всеми
sub cmp1mtime {
	my ($self, $deps) = @_;
	
	my $watch = $deps->{watch};
	
	my $mtime = $self->mtime;

	for my $dep ($deps->files) {
		$deps->{watch}{$dep} = $mtime;
	}
	
	my ($changed, $new, $deleted) = $deps->watch($self);
	
	if(defined $watch) { $deps->{watch} = $watch } else { delete $deps->{watch} }
	
	return $changed->length || $new->length || $deleted->length;
}

1;