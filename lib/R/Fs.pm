package R::Fs;
# работа с файловой системой через AnyEvent и R::Persistent

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}


# считать файл
sub read {
	my ($self, $path, $encode) = @_;
	$encode //= "UTF-8";
	my $file = $new->file($path, "<:encoding($encode)");
	my $read = $file->read;
	$file->bad($read);
	$read
}

# записать текст в файл
sub write {
	my ($self, $path, $body, $encode, $append) = @_;
	$encode //= "UTF-8";
	my $file = $new->file($path, "$append>:encoding($encode)");
	my $write = $file->write($body);
	$file->bad($write);
	$write
}

# добавить текст в файл
sub append {
	push @_, ">";
	goto &write;
}

# удалить файлы или директории рекурсивно
sub rm {
	
}

# удалить в директории все файлы и поддиректории рекурсивно
sub clean {
}

# перенести файл или директорию
sub mv {
	
}

# копировать файл или директорию рекурсивно
sub cp {
	
}

1;
