package R::Row::Img;
# добавляет картинку в базу (табл. img) и на диск (каталог html/images, по-умолчанию)

use base R::Model::Row;

#use Image::Magick;
# http://www.graphicsmagick.org/perl.html


# вызывается при создании объекта
sub setup {
	my ($fields) = @_;
	
	# добавляем столбцы в таблицу
	$fields->
	
	col("bitext" => "tinyint")->default(0)->remark("число обозначает расширение файла-картинки")->
	compute("ext")->remark("расширение")->
	compute("body")->remark("бинарный код файла")->
	compute("file")->remark("путь к файлу")->
	
	end
}


our @EXT = qw/noname png jpg gif/;
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
	my ($self, $body) = @_;
	if(@_>1) {
		$self->store unless $self->{id};
		my $path = $self->path;
		Utils::mkpath($path);
		$self->erase_files;
		if(ref $body) {
			Utils::cp($body, $self->file);
		} else {
			Utils::write($self->file, $body);
		}
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
		$self->path . "file." . $self->ext
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

# изменяет размер картинки и записывает её в файл name
# sub resize {
	# my ($self, $w, $h, $name) = @_;
	# my $file = $self->file;
	# my $magick = Image::Magick->new;
	# $magick->Read($file);
	# $magick->preview();
	# $magick->Resize(geometry=>geometry, width=>$w, height=>$h);	# turn в радианах
	# $self->erase_files;
	# $magick->Write($file);
	# $self
# }

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