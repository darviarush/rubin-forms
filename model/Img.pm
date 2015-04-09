package R::Rows::Img;
# добавляет картинку в базу (табл. img) и на диск (каталог html/images, по-умолчанию)

use base R::Model::Row;

use Image::Magick;
# http://www.graphicsmagick.org/perl.html


# вызывается при создании объекта
sub setup {
	my ($self) = @_;
	
	# добавляем поля объекту
	$self->{dir} = 'html/images';
	$self->{name} = 'orig.jpg';
	$self->{tab} = 'img';
	
	# добавляем столбцы в таблицу
	#$self->fields->add(ext => 'tinyint')
	#->add_ref();
	
}

# возвращает path
sub path {
	my ($self) = @_;
	my $path = Utils::to_radix($self->{id}, 62);
	$path =~ s!.!$&/!;
	$self->{dir} . "/" . $path;
}

# возвращает путь неизменной картинки
sub orig {
	my ($self) = @_;
	$self->path . $self->{name}
}

# добавляет картинку и устанавливает id
sub add {
	my ($self, $body) = @_;
	my $app = $self->{app};
	$self->{id} = $app->auth->add($self->{tab});
	my $path = $self->path;
	Utils::mkpath($path);
	Utils::write($self->orig, $body);
	return $self;
}

# удаляет файлы картинки
sub erase_files {
	my ($self) = @_;
	my $path = $self->path;
	opendir my $dir, $path or die $!;
	while($file = readdir $dir) {
		$file = "$path$file";
		if(-f $path) { unlink $file }
		else { $count++ }
	}
	closedir $dir;
	return $count;
}

# удаляет картинку
sub erase {
	my ($self) = @_;
	
	Utils::rmpath($self->path) if $self->erase_files == 0;
	$self
}

# заменяет картинку
sub update {
	my ($self, $body) = @_;
	$self->erase_files;
	Utils::write($self->orig, $body);
	$self
}


# изменяет размер картинки и записывает её в файл name
sub resize {
	my ($self, $w, $h, $name) = @_;
	my $orig = $self->orig;
	my $magick = Image::Magick->new;
	$magick->Read($orig);
	$magick->preview();
	$magick->Resize(geometry=>geometry, width=>$w, height=>$h);	# turn в радианах
	$self->erase_files;
	$magick->Write($orig);
	$self
}

# поворачивает картинку
sub turn {
	my ($self, $turn) = @_;
	my $orig = $self->orig;
	my $magick = Image::Magick->new;
	$magick->Read($orig);
	$magick->Rotate(degrees => $turn);	# turn в радианах
	$self->erase_files;
	$magick->Write($orig);
	$self
}

1;