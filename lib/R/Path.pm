package R::Path;
# возвращает пути к файлам проекта

#use common::sense;
use strict;
use warnings;
use R::App;

# path - массив путей по которым смотрим
Utils::has_array(qw/path/);

# конструктор
sub new {
	my ($cls) = @_;
	bless {path=>["", $::_FRAMEWORK . "/"]}, $cls;
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

# возвращает путь к фреймворку
sub framework {
	my ($self, $path) = @_;
	$::_FRAMEWORK . ($path? "/" . $path: "");
}

# функция to превращает относительный путь в реальный
sub to {
	my ($self, $to, $name) = @_;

	$to = $to =~ /:/? $': "";
	
	
	$self->to($to, "") =~ m!/\.([^/\.]+)$!, return wantarray? ($`, $1): $` unless defined $name;
	
	if($to eq "") {
		"action/$name.html";
	} elsif($to eq "act") {
		"action/$name.act";
	} elsif($to eq "lib") {
		"lib/$name.pm";
	} elsif($to eq "r") {
		$name =~ s![A-Z]!/$&!g;
		"lib/R/" . ucfirst($name) . ".pm";
	} elsif($to eq "bin") {
		"bin/$name.pl";
	} elsif($to eq "t") {
		"t/$name.t";
	} elsif($to eq "html") {
		"html/$name.html";
	} elsif($to eq "js") {
		"html/js/$name.js";
	} elsif($to eq "coffee") {
		"html/coffee/$name.coffee";
	} elsif($to eq "nika") {
		"nika/$name.nika";
	} else {
		die "Неизвестное имя пути: `$to`";
	}
	
}

1;
