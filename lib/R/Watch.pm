package R::Watch;
# следит за изменениями файлов и папок

use strict;
use warnings;

use File::Find;
use POSIX qw(strftime);

use Msg;

# конструктор: dirs = dir:mtime, watch = file:mtime, file = file:callback, scan = dir: [ext, callback]
sub new { my ($cls) = @_; bless { dirs => {}, watch => {}, file => {} }, $cls }


# указываем за изменением файлов с каким расширением в каких директориях следить
sub on {
	my ($self, $ext, $dirs, $callback) = @_;

	$dirs = [split /\s+/, $dirs] unless ref $dirs;

	for my $dir (@$dirs) {
		$self->{scan}{$dir} = [$ext, $callback];
		$self->scan($dir);
	}
	$self
}

# удаление директории
sub erase {
	my ($self, $dir) = @_;
	for my $key (keys %{$self->{file}}) {
		delete($self->{file}{$key}), delete $self->{watch}{$key} if $dir eq substr $key, 0, length $dir;
	}
	
	for my $key (keys %{$self->{dirs}}) {
		delete $self->{dirs}{$key} if $dir eq substr $key, 0, length $dir;
	}
	$self
}

# создание информации
sub scan {
	my ($self, $dir) = @_;
	my $scan;
	
	unless($scan = $self->{scan}{$dir}) {
		while(my($root, $mtime) = each %{$self->{dirs}}) {
			$scan = $self->{scan}{$root}, last if $root eq substr $dir, 0, length $root;
		}
	}
	
	my ($ext, $callback) = @$scan;
	
	find({
		no_chdir => 1,
		wanted => sub {
			my $path = $File::Find::name;
			if(-d $path) {
				$self->{dirs}{$path} = main::mtime($path);
			}
			elsif($path =~ $ext) {
				$self->{watch}{$path} = main::mtime($path);
				$self->{file}{$path} = $callback;
			}			
		}
	}, $dir);
	$self
}

# проверка
sub run {
	my ($self) = @_;
	while(my($dir, $mtime) = each %{$self->{dirs}}) {
		$self->erase($dir), $self->scan($dir) if $mtime < main::mtime($dir);
	}
	while(my($file, $mtime) = each %{$self->{watch}}) {
		$self->{file}{$file}->($file), $self->{watch}{$file} = main::mtime($file) if $mtime < main::mtime($file);
	}
	$self
}

# цикл слежения
sub loop { my ($self) = @_; for(;;) { $self->run(); sleep 1; } }

1;