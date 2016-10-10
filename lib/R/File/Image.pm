package R::File::Image;
# расширяет файл для работы с картинками

use base R::File;

use common::sense;
use R::App;

use Math::Trig;

#use Graphics::Magick;
#use Magick;
# http://www.graphicsmagick.org/perl.html - документация по Graphics::Magick
# http://webo.in/articles/habrahabr/69-total-image-optimization/ - оптимизация изображений


# возвращает класс графического движка
my $Magick;
sub Magick {
	$Magick = $app->ini->{img}{class} // "Graphics::Magick";
	my $path = $Magick;
	local ($`, $');
	$path =~ s!::!/!g;
	require "$path.pm";
	
	*Magick = sub { $Magick };
	
	$Magick
}

sub ASSERT($) {
	die $_[0] if $_[0];
}

# возвращает картинку или создаёт её из файла
sub Image {
	my ($self, $idx) = @_;
	
	my $image = $self->{images}[$idx];
	return $image if defined $image;
	
	$image = Magick->new;
	my $file = $self->{files}[$idx];
	ASSERT $image->Read($file) if defined $file;
	
	$self->{images}[$idx] = $image;
	
	$image

}

# возвращает картинки соответствующие файлам
sub images {
	my ($self) = @_;
	local $_;
	my $i = 0;
	map { $self->Image($i++) } $self->files;
}

# записывает картинку в свой файл, если не указан другой
sub save {
	my ($self, $path) = @_;
	
	$path = $self->topath($path) if defined $path;
	
	my $i = 0;
	for my $image ($self->images) {
		ASSERT $image->Set(preview => "Roll");	# формат в котором показывается картинка при загрузке в браузер
		ASSERT $image->Write($path // $self->{files}[$i++]);
	}
	
	$self
}

# возвращает свойство 1-й картинки
sub get {
	my ($self, $prop) = @_;
	$self->Image->Get($prop)
}

# возвращает ширину картинки
sub x {
	my ($self) = @_;
	$self->Image->Get("width")
}

# возвращает высоту картинки
sub y {
	my ($self) = @_;
	$self->Image->Get("height")
}

# изменяет размер картинки
sub resize {
	my ($self, $geometry, %opt) = @_;
	
	$opt{filter} //= "Lanczos";
	
	for my $image ($self->images) {
		ASSERT $image->Resize(geometry=>$geometry, %opt);
	}
	
	$self
}

# обрезает картинку
sub crop {
	my ($self, $x, $y, $w, $h) = @_;
		
	for my $image ($self->images) {
		ASSERT $image->Crop(geometry=>"${x}x${y}+${w}+$h");
	}

	$self
}

# поворачивает картинку. Угол от 0 до 1
sub turn {
	my ($self, $turn) = splice @_, 0, 2;
	
	for my $image ($self->images) {
		ASSERT $image->Rotate(degrees => $turn * 2 * pi, @_);
	}
	
	$self
}

# # накладывает на первую картинку указанную
# sub composite {
	# my ($self, $image, $gravity) = splice @_, 0, 3;
	
	# $gravity //= "center";
	# #geometry => 
	
	# $image = $self->from($image);
	
	# ASSERT $self->Image->Composite(image=>$image->Image, gravity=>"center");
	
	# $self
# }

# объединяет картинки в спрайт
sub sprite {
	my ($self) = @_;
	
	
	
	$self
}


# обычный ресайз - формирует main-картинку
sub _resize {
	my ($from, $max_width, $max_height, $path) = @_;
	my $img;
	if(ref $from) {
		$img = $from;
	} else {
		$img = Magick->new;
		ASSERT $img->Read($from);
	}
	
	my $width = $img->Get("width");
	
	if($max_width < $width) {
		ASSERT $img->Resize(geometry=>"${max_width}x", filter => "Lanczos");	# turn в радианах
	}
	
	my $height = $img->Get("height");
	
	if($max_height < $height) {
		ASSERT $img->Resize(geometry=>"x${max_height}", filter => "Lanczos");	# turn в радианах
	}
	
	ASSERT $img->Set(preview => "Roll");	# формат в котором показывается картинка при загрузке в браузер
	ASSERT $img->Write($path);
	$img
}

# формирует превью: изменяет размер картинки к width и записывает её в файл
sub _preview {
	my ($from, $w, $path) = @_;
	my $img;
	if(ref $from) {
		$img = $from;
	} else {
		$img = Magick->new;
		ASSERT $img->Read($from);
	}
	
	my $width = $img->Get("width");
	my $height = $img->Get("height");
	
	if($width < $w || $height < $w) {
		$width = $width < $w? $w: $width;
		$height = $height < $w? $w: $height;
		my $i = Magick->new;
		ASSERT $i->Set(size => "${width}x$height");
		ASSERT $i->ReadImage('xc:white');
		ASSERT $i->Composite(image=>$img, gravity=>"center");
		$img = $i;
	}
	
	if($width > $w || $height > $w) {
		if($width > $height) {
			ASSERT $img->Resize(geometry=>"x${w}", filter => "Lanczos");	# turn в радианах
			$width = $img->Get("width");
			ASSERT $img->Crop(geometry => "${w}x$w+".int(($width-$w)/2)."+0");		# обрезает
		} else {
			ASSERT $img->Resize(geometry=>"${w}x", filter => "Lanczos");
			ASSERT $img->Crop(geometry => "${w}x$w+0+0");		# обрезает
		}
	}
	
	ASSERT $img->Set(preview => "Roll");	# формат в котором показывается картинка при загрузке в браузер
	ASSERT $img->Write($path);
	$img
}

# поворачивает картинку
# sub turn {
	# my ($self, $turn) = @_;
	# my $file = $self->file;
	# my $magick = Magick->new;
	# $magick->Read($file);
	# $magick->Rotate(degrees => $turn);	# turn в радианах
	# $self->erase_files;
	# $magick->Write($file);
	# $self
# }


# обычный ресайз - формирует main-картинку
sub resizing {
	my ($self, $max_width, $max_height) = @_;
	
	for my $img ($self->images) {
	
		my $width = $img->Get("width");
	
		if($max_width < $width) {
			ASSERT $img->Resize(geometry => "${max_width}x", filter=>"Lanczos");
		}
	
		my $height = $img->Get("height");
	
		if($max_height < $height) {
			ASSERT $img->Resize(geometry => "x${max_height}", filter=>"Lanczos");
		}
	}
	$self
}

# формирует превью: изменяет размер картинки к width
sub preview {
	my ($self, $w) = @_;
	
	for my $img ($self->images) {
	
	my $width = $img->Get("width");
	my $height = $img->Get("height");
	
	if($width < $w || $height < $w) {
		$width = $width < $w? $w: $width;
		$height = $height < $w? $w: $height;
		my $i = Magick->new;
		ASSERT $i->Set(size => "${width}x$height");
		ASSERT $i->ReadImage('xc:white');
		ASSERT $i->Composite(image=>$img, gravity=>"center");
		$img = $i;
	}
	
	if($width > $w || $height > $w) {
		if($width > $height) {
			ASSERT $img->Resize(geometry=>"x${w}", filter => "Lanczos");	# turn в радианах
			$width = $img->Get("width");
			ASSERT $img->Crop(geometry => "${w}x$w+".int(($width-$w)/2)."+0");		# обрезает
		} else {
			ASSERT $img->Resize(geometry=>"${w}x", filter => "Lanczos");
			ASSERT $img->Crop(geometry => "${w}x$w+0+0");		# обрезает
		}
	}
	}
	
	$self
}



# выполняет указанную команду
sub do {
	my ($self, $cmd) = splice @_, 0, 2;
	$cmd = ucfirst $cmd;
	for my $image ($self->images) {
		ASSERT $image->$cmd(@_);
	}
	$self
}


# если функция не найдена
use vars '$AUTOLOAD';

sub AUTOLOAD {
	my ($prop) = $AUTOLOAD =~ /([^:]+)$/;
	
	$prop = ucfirst $prop;
	
	eval "sub $AUTOLOAD {
		my (\$self) = shift;
		for my \$image (\$self->images) {
			ASSERT \$image->$prop(\@_);
		}
		\$self
	}";
	die "not make $AUTOLOAD: $@" if $@;
	
	goto &$AUTOLOAD;
}

sub DESTROY {}


1;