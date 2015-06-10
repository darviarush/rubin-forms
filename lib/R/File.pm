package R::File;
# асинхронный файл

use strict;
use warnings;

#use common::sense;
use R::App;

use AnyEvent;

use base "R::Persistent";

Utils::has qw/path encode fh/;

# конструктор
sub new {
	my ($cls, $path, $encode) = @_;
	my $self = bless {
		path => $path,
		encode => $encode,
		fh => undef,
	}, $cls;
	
	$self
}

# открывает файл
sub open {
	my ($self, $regime) = @_;
	
	CORE::open($self->{in}, )
}

# закрывает файл
sub close {
	my $self = ;
	CORE::close()
}

# считывает файл порциями. Если size не указан - то весь
sub read {
	my ($self, $size) = @_;
	$size //= -s $file;
}

# записывает строку в файл - всю или порциями
sub write {
	my ($self, $buf, $size) = @_;
	
}

# считывает файл построчно
sub readlines {
	my ($self, $sep) = @_;
	$sep //= "\n";
}

# сдвигает указатель в файле
sub seek {
	my ($self, $pos, $direction) = @_;
	seek $self->{fd}, $pos, $direction;
	
}

# размер файла
sub size {
	my ($self) = @_;
	-s $self->{fd}
}

1;
