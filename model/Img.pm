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
	compute("ext")->
	compute("body")->
	
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

# возвращает путь неизменной картинки
sub orig {
	my ($self) = @_;
	$self->path . "orig." . $self->ext
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
			Utils::cp($body, $self->orig);
		} else {
			Utils::write($self->orig, $body);
		}
	} else {
		Utils::read($self->orig);
	}
	return $self;
}

# картинку взять из файла
sub file {
	my ($self, $file) = @_;
	open my $f, "<", "$file" or die "Не могу открыть `$file`: $!";
	$self->ext(Utils::ext($file));
	$self->body($f);
	close $f;
	$self
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
sub erase {
	my ($self) = @_;
	$self->SUPER::erase;
	Utils::rmpath($self->path) if $self->erase_files == 0;
	$self
}


# изменяет размер картинки и записывает её в файл name
# sub resize {
	# my ($self, $w, $h, $name) = @_;
	# my $orig = $self->orig;
	# my $magick = Image::Magick->new;
	# $magick->Read($orig);
	# $magick->preview();
	# $magick->Resize(geometry=>geometry, width=>$w, height=>$h);	# turn в радианах
	# $self->erase_files;
	# $magick->Write($orig);
	# $self
# }

# поворачивает картинку
# sub turn {
	# my ($self, $turn) = @_;
	# my $orig = $self->orig;
	# my $magick = Image::Magick->new;
	# $magick->Read($orig);
	# $magick->Rotate(degrees => $turn);	# turn в радианах
	# $self->erase_files;
	# $magick->Write($orig);
	# $self
# }

1;