package R::Row::Img;
# добавляет картинку в базу (табл. img) и на диск (каталог html/images, по-умолчанию)

use base R::Model::Row;

use Graphics::Magick;
# http://www.graphicsmagick.org/perl.html - документация по Graphics::Magick
# http://webo.in/articles/habrahabr/69-total-image-optimization/ - оптимизация изображений


# вызывается при создании объекта
sub setup {
	my ($fields) = @_;
	
	# добавляем столбцы в таблицу
	$fields->
	
	col("bitext" => "tinyint")->default(0)->remark("число обозначает расширение файла-картинки")->
	compute("ext" => qw/bitext/)->remark("расширение")->
	compute("body")->remark("бинарный код файла")->
	compute("file" => qw/bitext/)->remark("путь к файлу")->
	
	end
}


our @EXT = qw/jpg png gif/;
our %EXT = Utils::starset(0, @EXT);
$EXT{"jpeg"} = $EXT{"jpg"};

sub ext {
	my ($self, $ext) = @_;
	
	if(@_>1) {
		$self->bitext($EXT{lc $ext})
	} else {
		$EXT[$self->bitext]
	}
}

# возвращает директорию
sub path {
	my ($self) = @_;
	my $path = Utils::to_radix($self->{id}, 62);
	$path =~ s!.!$&/!;
	$self->root . "/" . $path;
}

# путь к репозиторию
sub root {
	"html/images"
}

# вычисляемый столбец
sub body {
	my ($self, $body, $name) = @_;
	if(@_>1) {
		$self->store unless $self->{id};
		my $path = $self->path;
		Utils::mkpath($path);
		$self->erase_files;
		
		$body = $body->body if ref $body eq "R::Utils::File";
		
		if($name) {
		}
		elsif(ref $body) {	# $body - GLOB - file
			Utils::cp($body, $name = $self->file);
		} else {
			Utils::write($name = $self->file, $body);
		}
		
		my $img = _resize($name, 2000, 2000, $self->file);
		$img = _resize($img, 600, 600, $path . "main.jpg");
		_preview($img, 200, $path . "small.png");
		_preview($img, 100, $path . "mini.png");
	} else {
		Utils::read($self->file);
	}
	return $self;
}

# картинку взять из файла, либо вернуть путь к файлу
sub file {
	my ($self, $file) = @_;
	if(@_>1) {
		open my $f, "<", "$file" or die "Не могу открыть `$file`: $!";
		$self->ext(Utils::ext($file));
		$self->body($f);
		close $f;
		$self
	} else {
		# возвращает путь неизменной картинки
		$self->path . "orig." . $self->ext
	}
}

# удаляет файлы картинки
sub erase_files {
	my ($self) = @_;
	my $path = $self->path;
	opendir my $dir, $path or die $!;
	while(my $file = readdir $dir) {
		$file = "$path$file";
		if(-f $path) { unlink $file }
		else { $count++ }
	}
	closedir $dir;
	return $count;
}

# удаляет картинку
sub onErase {
	my ($self) = @_;
	Utils::rmpath($self->path) if $self->erase_files == 0;
}

# удаляются все данные из таблицы
sub onDrop {
	Utils::rmdown(root());
}

sub ASSERT($) {
	die $_[0] if $_[0];
}

# обычный ресайз - формирует main-картинку
sub _resize {
	my ($from, $max_width, $max_height, $path) = @_;
	my $img;
	if(ref $from) {
		$img = $from;
	} else {
		$img = Graphics::Magick->new;
		ASSERT $img->Read($from);
	}
	
	my $width = $img->Get("width");
	
	if($max_width < $width) {
		ASSERT $img->Resize(geometry=>"${max_width}x", filter => Lanczos);	# turn в радианах
	}
	
	my $height = $img->Get("height");
	
	if($max_height < $height) {
		ASSERT $img->Resize(geometry=>"x${max_height}", filter => Lanczos);	# turn в радианах
	}
	
	ASSERT $img->Set(preview => Roll);	# формат в котором показывается картинка при загрузке в браузер
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
		$img = Graphics::Magick->new;
		ASSERT $img->Read($from);
	}
	
	my $width = $img->Get("width");
	my $height = $img->Get("height");
	
	if($width < $w || $height < $w) {
		$width = $width < $w? $w: $width;
		$height = $height < $w? $w: $height;
		my $i = Graphics::Magick->new;
		ASSERT $i->Set(size => "${width}x$height");
		ASSERT $i->ReadImage('xc:white');
		ASSERT $i->Composite(image=>$img, gravity=>"center");
		$img = $i;
	}
	
	if($width > $w || $height > $w) {
		if($width > $height) {
			ASSERT $img->Resize(geometry=>"x${w}", filter => Lanczos);	# turn в радианах
			$width = $img->Get("width");
			ASSERT $img->Crop(geometry => "${w}x$w+".int(($width-$w)/2)."+0");		# обрезает
		} else {
			ASSERT $img->Resize(geometry=>"${w}x", filter => Lanczos);
			ASSERT $img->Crop(geometry => "${w}x$w+0+0");		# обрезает
		}
	}
	
	ASSERT $img->Set(preview => Roll);	# формат в котором показывается картинка при загрузке в браузер
	ASSERT $img->Write($path);
	$img
}

# поворачивает картинку
# sub turn {
	# my ($self, $turn) = @_;
	# my $file = $self->file;
	# my $magick = Image::Magick->new;
	# $magick->Read($file);
	# $magick->Rotate(degrees => $turn);	# turn в радианах
	# $self->erase_files;
	# $magick->Write($file);
	# $self
# }

1;