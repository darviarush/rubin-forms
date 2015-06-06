package R::Path;
# возвращает пути к файлам проекта

use common::sense;
use R::App;

# path - массив путей по которым смотрим
Utils::has_array(qw/path/);

# конструктор
sub new {
	my ($cls) = @_;
	bless {path=>[""]}, $cls;
}


# возвращает первый попавшийся файл
sub file {
	my ($self, $path) = @_;
	for my $p (@{$self->{path}}) {
		$p .= $path;
		return $p if -e $p; 
	}
}

# возвращает пути со всеми директориями из path
sub dirs {
	my ($self, @path) = @_;
	map { my $path = $_; map { glob("$_$path") } @{$self->{path}} } @path;
}

# возвращает пути, котрые есть
sub files {
	my ($self, @path) = @_;
	grep { -e $_ } $self->dirs(@path);
}

1;
