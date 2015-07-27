package R::Async::File;
# интерфейс для работы с файлами и директориями

use common::sense;
use R::App;

use Text::Glob qw/glob_to_regex/;

use Coro;
use Coro::AIO;


# переустанавливаем хандлеры ошибки
$app->raise->setdie;

# конструктор
sub new {
	my $cls = shift;
	bless {
		file=>$_[0]
	}, ref $cls || $cls;
}

# обходит директории
sub walk {
	my ($self, $code) = @_;

	return unless $self->exists;
	
	my (@dir);
	local ($_);
	
	if(-d $self->stat) {
		@dir = $self->{file};
	} else {
		$_ = $self;
		&$code;
		return;
	}
	
	while(@dir) {
		my $dir = pop @dir;
		for my $file (@{aio_readdir $dir}) {
			next if $file =~ /^\.{1,2}$/;
			$_ = $self->new("$dir/$file");
			push @dir, $_ if -d $_->stat;
			&$code;
		}
	}
}

# создаёт объект для обхода директорий
sub find {
	my ($self, $regex) = @_;
	if(!wantarray) {
		
		if(defined $regex) {
			$regex = glob_to_regex $regex if !ref $regex;
			$self->{action} = closure {
				my ($self, $regex, $code) = @_;
				$self->walk(sub {
					&$code if $_->{file} =~ $regex;
				});
			}, $self, $regex;
		} else {
			$self->{action} = closure \&walk, $self;
		}

		$self
	}
	else {
		my @out;
		$self->walk(sub {
			push @out, $_;
		});
		@out
	}
}

# запускает для каждого
sub then {
	my ($self, $code) = @_;
	$self->{action}->($code);
}

# делает stat и возвращает путь или хандлер файла
sub stat {
	my ($self) = @_;
	my $file = $self->{fh} // $self->{file};
	die((0+$!) . ": " . $!) if aio_stat($file) != 0;
	$file
}

# возвращает путь или описатель файла
sub file {
	my ($self) = @_;
	$self->{fh} // $self->{file};
}

# возвращает путь
sub path {
	my ($self) = @_;
	$self->{file};
}

# возвращает расширение без точки
sub ext {
	my ($self) = @_;
	local ($&, $`, $', $1);
	$self->{file} =~ /[^\/]\.([^\.\/]+)$/? $1: "";
}

# возвращает каталог файла без завершающего слеша. Для рута возвращается "/"
sub dir {
	my ($self) = @_;
	local ($&, $`, $', $1);
	$self->{file} =~ m!(.+)/!? $1: m!^/!? "/": "";
}

# возвращает имя файла
sub name {
	my ($self) = @_;
	local ($&, $`, $', $1);
	$self->{file} =~ m!.*/([^/]+?)(\.[^\./]+)?!? $1: "";
}


# устанавливает или возвращает права файла
sub mod {
	my $self = shift;
	@_? do { aio_truncate($self->file, $_[0]); $self}: -s $self->stat;
}

# устанавливает или возвращает размер файла
sub size {
	my $self = shift;
	@_? do { aio_truncate($self->file, $_[0]); $self}: -s $self->stat;
}

# файл пустой
sub empty { -z shift->stat }

# существует ли файл
sub exists {
	my ($self) = @_;
	my $file = $self->{fh} // $self->{file};
	aio_stat($file) == 0
}

# определяют тип файла:
# b - блоковое устройство
# c - символьное устройство
# d - каталог
# p - именованный канал (FIFO)
# f - обычный файл
# l - символьная ссылка
# s - сокет
# D - дверь (Solaris)
sub isfile { -f shift->stat }
sub isdir { -d shift->stat }
sub islink { -l shift->stat }
sub ispipe { -p shift->stat }
sub issocket { -S shift->stat }
sub isblock { -b shift->stat }
sub ischar { -c shift->stat }
sub istty { -t shift->stat }


# effective
sub isread { -r shift->stat }
sub iswrite { -w shift->stat }
sub isexec { -x shift->stat }
sub isown { -o shift->stat }

# real
sub isrealread { -R shift->stat }
sub isrealwrite { -W shift->stat }
sub isrealexec { -X shift->stat }
sub isrealown { -O shift->stat }

# time
sub mtime {  $^T + 24*60*60 * -M shift->stat }
sub ctime {  $^T + 24*60*60 * -C shift->stat }
sub atime {  $^T + 24*60*60 * -A shift->stat }

# удаляет файл
sub unlink {
	my ($self) = @_;
	die((0+$!) . ": " . $!) if 0 > aio_unlink $self->{file};
	$self
}

# удаляет директорию
sub rmdir {
	my ($self) = @_;
	die((0+$!) . ": " . $!) if 0 > aio_rmdir $self->{file};
	$self
}

# создаёт директорию и не ругается, если она существует
sub mkdir0 {
	my ($self, $mode) = @_;
	$mode = 0644 unless defined $mode;
	die((0+$!) . ": " . $!) if 0 > aio_mkdir( $self->{file}, $mode ) and $! != 17;
	$self
}

# создаёт директорию
sub mkdir {
	my ($self) = @_;
	$self->mkdir0;
	die((0+$!) . ": " . $!) if $!;
	$self
}


# создаёт путь, если его нет
sub mkpath {
	my ($self) = @_;
	local ($_, $1, $&, $`, $');
	$_ = $self->{file};
	$self->new($`)->mkdir0 while m!/!g;
	$self->new(m!/([^/]+)$!? $1: $_)->mkdir0;
	$self
}


# создаёт путь для директории файла
sub mkpath0 {
	my ($self) = @_;
	local ($&, $`, $');
	$self->{file} =~ m!.*/!;
	$self->new( $& )->mkpath;
	$self
}


# удаляет файл или пустую директорию
sub remove {
	my ($self) = @_;
	$self->isdir? $self->rmdir: $self->unlink;
}

# удаляет файл рекурсивно
sub rm {
	my $self = shift;
	my @dir;
	$self->find->then(sub {
		$_->isdir? push(@dir, $_): $_->unlink;
	});
	$_->rmdir for @dir;
	$self
}

# копирует файл
sub copy {
	my ($self, $to) = @_;
	die((0+$!) . ": " . $!) if 0 > aio_copy $self->{file}, $to;
	$self
}

# переносит файл
sub move {
	my ($self, $to) = @_;
	die((0+$!) . ": " . $!) if 0 > aio_move $self->{file}, $to;
	$self
}

# копирует директорию рекурсивно
sub cp {
	my ($self, $to) = @_;
	my @dir;
	my $len = length $self->{file};
	$self->find->then(sub {
		my $to_cp = substr $_->{file}, $len;
		my $to_path = "$to/$to_cp";
		($_->isdir)? do {
			$self->new($to_path)->mkdir;
		}: $_->copy($to_path);
	});
	$self
}

# переносит директорию рекурсивно
sub mv {
	my ($self, $to) = @_;
	my @dir;
	my $len = length $self->{file};
	$self->find->then(sub {
		my $to_cp = substr $_->{file}, $len;
		my $to_path = "$to/$to_cp";
		($_->isdir)? do {
			push @dir, $self->new($to_path)->mkdir;
		}: $_->move($to_path);
		
	});
	$_->rmdir for @dir;
	$self
}

# возвращает реальный путь
sub realpath {
	my ($self) = @_;
	aio_realpath $self->{file};
}

# открывает файл
sub open {
	my ($self, $flags, $mode) = @_;
	die "вначале закройте $self->{file}" if $self->{fd};
	$mode = 0644 unless defined $mode;
	
	$self->{seek} = 0;
	
	if($flags !~ /^\d+$/) {
		
		if($flags eq "r") {
			$flags = Coro::AIO::O_RDONLY();
		}
		elsif($flags eq "w") {
			$flags = Coro::AIO::O_WRONLY() | Coro::AIO::O_CREAT() | Coro::AIO::O_TRUNC();
		}
		elsif($flags eq "a") {
			$flags = Coro::AIO::O_WRONLY() | Coro::AIO::O_CREAT() | Coro::AIO::O_APPEND();
		}
		elsif($flags eq "r+") {
			$flags = Coro::AIO::O_RDWR();
		}
		elsif($flags eq "w+") {
			$flags = Coro::AIO::O_RDWR() | Coro::AIO::O_CREAT() | Coro::AIO::O_TRUNC();
		}
		elsif($flags eq "a+") {
			$flags = Coro::AIO::O_RDWR() | Coro::AIO::O_CREAT() | Coro::AIO::O_APPEND();
		}
		elsif($flags eq "c") {	# создаёт, для записи, но не обрезает
			$flags = Coro::AIO::O_WRONLY() | Coro::AIO::O_CREAT();
		}
		elsif($flags eq "c+") {
			$flags = Coro::AIO::O_RDWR() | Coro::AIO::O_CREAT();
		}
		elsif($flags eq "x") { # не создаёт, обрезает
			$flags = Coro::AIO::O_WRONLY() | Coro::AIO::O_TRUNC();
		}
		elsif($flags eq "x+") {
			$flags = Coro::AIO::O_RDWR() | Coro::AIO::O_TRUNC();
		}
		else {
			die "недопустимые флаги `$flags` для открытия файла $self->{file}. Используйте: r, r+, w, w+, a, a+, c, c+, x, x+";
		}
		
		
	}
	
	
	my $fh = aio_open $self->{file}, $flags, $mode;
	die("ошибка при открытии файла $self->{name} №" . (0+$!) . ": " . $!) unless defined $fh;
	$self->{fh} = $fh;
	$self->{seek} = $flags | &Coro::AIO::O_APPEND? $self->size: 0;
	$self
}


# указывает кодировку файла
# sub codepage {
	# my ($self, $encode) = @_;
	# $self->{encode} = $encode;
# }

# передвигает файловый указатель
sub seek {
	my ($self, $offset, $whence) = @_;
	#die((0+$!) . ": " . $!) if 0>aio_seek($self->{fh}, $offset, $whence // 0);
	if($whence == 0) {
		$self->{seek} = $offset;
	} elsif($whence == 1) {
		$self->{seek} += $offset;
	} else {
		$self->{seek} = $self->size - $offset;
	}
	
	$self
}

# положение в файле указателя
sub tell {
	my ($self) = @_;
	$self->{seek}
}

# возвращает/устанавливает позицию файлового указателя
sub pos {
	my $self = shift;
	if(@_) {
		$self->seek(shift);
	}
	else {
		$self->tell
	}
}


# закрывает файл
sub close {
	my ($self) = @_;
	
	$self->flush;
	
	die((0+$!) . ": " . $!) if 0 > aio_close $self->{fh};
	delete $self->{fh};
	delete $self->{seek};
	$self
}

# размер буфера
my $BUF_SIZE = 1024;

# синхронизирует файл с диском
sub flush {
	my ($self) = @_;
	$self
}

# печатает в файл
sub syswrite {
	my ($self, $data, $seek, $offset, $length) = @_;
	$self->open("w") unless $self->{fh};
	
	$offset //= 0;
	$length //= length($data)-$offset;
	
	die((0+$!) . ": " . $!) if 0 > aio_write $self->{fh}, $seek, $length, $data, $offset;
	
	$self
}

# пишет в файл
sub write {
	my $self = shift;
	
	for my $data (@_) {
		my $size = length $data;
		my $buf_seek = $self->{buf_seek} // 0;
		my $new_buf_seek = $buf_seek + $size;
		if($new_buf_seek > $BUF_SIZE) {	# буфер будет заполнен
			my $space = $BUF_SIZE - $buf_seek; # свободное место в буфере
			# заполняем буфер
			substr($self->{buf}, $buf_seek, $size - $space) = substr($data, 0, $space);
			$data = substr($data, $space);
			# записываем
			$self->syswrite($self->{buf}, $self->{seek} - $buf_seek);
			$self->{buf} = ;
		} else {	# просто добавляем в буфер, коль он ещё не заполнен
			substr($self->{buf}, $buf_seek, $size) = $data;
			$self->{buf_seek} = $new_buf_seek;
		}
		$self->{seek} += $size;
	}
	
	$self
}

# читает из файла
sub sysread {
	my ($self, $seek, $size, $offset) = @_;

	return "" if $size == 0;
	
	$self->open("r") if !$self->{fh};
	
	die((0+$!) . ": " . $!) if 0 > (my $rd = aio_read $self->{fh}, $seek, $size, my $data, $offset // 0);
	
	$data
}

# считывает весь файл, или если указан параметр - часть
sub read {
	my ($self, $size) = @_;
	my $data;
	
	if(!defined $size and !$self->{fh}) {
		die((0+$!) . ": " . $!) if 0 > aio_load $self->{file}, $data;
	} else {
		$size //= $self->size - $self->{seek};
		$self->sysread($size);
		$self->{seek} += $rd;
	}

	$data
}

# считывает строку c завершающим разделителем
sub readln {
	my ($self, $sep) = @_;
	$self->open("r") if !$self->{fd};
	
	$self->read($BUF_SIZE);
}

# считывает строку без завершающего разделителя
sub readline {
	my ($self, $sep) = @_;
	my $line = $self->readln($sep);
	chomp $line if defined $line;
	$line
}

# считывает в переменную и возвращает себя
sub readlineInto {
	my ($self, $var, $sep) = @_;
	$_[1] = $self->readline($sep);
	$self
}

# считывает в переменную и возвращает себя
sub readlnInto {
	my ($self, $var, $sep) = @_;
	$_[1] = $self->readln($sep);
	$self
}


# печатает в файл и добавляет перевод каретки
sub print {
	my $self = shift;
	$self->write(@_, $self->{printSeparator} // "\n");
}

# печатает в файл отформатированную строку и добавляет перевод каретки
sub printf {
	my $self = shift;
	my $fmt = shift;
	$self->write(sprintf($fmt . ($self->{printSeparator} // "\n"), @_));
}

# печатает в файл отформатированную строку
sub writef {
	my $self = shift;
	my $fmt = shift;
	$self->write(sprintf($fmt, @_));
}



# возвращает файловый дескриптор
sub fileno {
	my ($self) = @_;
	fileno $self->{fh};
}

# возвращает файловый описатель Coro::Handle
sub fh {
	my ($self) = @_;
	$self->{fh};
}

# деструктор - закрывает файл, если он открыт
sub DESTROY {
	my ($self) = @_;
	$self->close if $self->{fh};
	$self
}


# возвращает/устанавливает сепаратор для ввода
sub inputSeparator {
	my $self = shift;

	if(@_) {	
		$self->{inputSeparator} = shift;
	}
	else {
		$self->{inputSeparator} // "\n";
	}
}

# возвращает/устанавливает сепаратор для вывода
sub printSeparator {
	my $self = shift;

	if(@_) {	
		$self->{printSeparator} = shift;
	}
	else {
		$self->{printSeparator} // "\n";
	}
}

###################################### watch ######################################
# функции для слежения за изменением файла

# устанавливает функцию, которая вызывается при изменении файла, или его 
sub watch {
	my ($self, $code) = @_;
	$self
}

# возвращает объект сравнения - на него можно повесить обработчики: появился ли файл или каталог
sub cmp {
	my ($self, $file) = @_;
	$self
}


1;
