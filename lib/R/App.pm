package R::App;
# приложение - через него доступны другие классы

use common::sense;

# подменяем $a и $b
use Exporter 'import';
our @EXPORT = qw/$app app msg todo has closure $a $b/;

# переменная приложения
our $app = bless {}, "R::App";

# возвращает синглетон приложения
sub app () { $app }

# устанавливаем ошибки
$app->raise;

# логирует вывод
# возвращает последний параметр
sub msg (@) {
	$app->log->info(@_);
	return $_[$#_];
}

# функция замещения
#sub todo () {
#	die "метод должен быть написан";
#}


# создаёт функции-свойства в указанном классе
sub has (@) {
	my ($cls) = caller(0);
	for my $name (@_) {
		eval "sub ${cls}::$name { if(\@_>1) { \$_[0]->{'$name'} = \$_[1]; \$_[0] } else { \$_[0]->{'$name'} } }"
	}
}

# порождает параметры для переданного метода
# sub public (@) {
	# my ($class) = caller(0);
	# for(my $i=0; $i < @_; $i+=2) {
		# my ($key, $val) = @_[$i, $i+1];
		# my $name = "${class}::$key";
		# eval "sub $name { if(\@_>1) { \$_[0]->{'$key'} = \$_[1]; \$_[0] } else { \$_[0]->{'$key'} } }";
	# }
	# @_
# }

# замыкание:
#	closure \&{$self->can("method")}, $self
#	closure {print}, 5
sub closure (&@) {
	my ($sub, @args) = @_;
	sub { $sub->(@args, @_) }
}

# подключает и возвращает класс
sub require {
	my ($self, $path) = @_;
	$path =~ s!::!/!g;
	require "$path.pm";
	$path =~ s!/!::!g;
	$path
}


# возвращает группу файлов
# $app->file("f1", "f2"...)
# или $app->file(["f1", "f2"...]) - в этом случае массив становится объектом
sub file {
	require "R/Async/File.pm";
	require "R/Async/Fileset.pm";
	eval q{sub R::App::file {
		shift;
		@_==1? R::Async::File->new(@_): R::Async::Fileset->new(@_);
	}};
	die $@ if $@;
	file(@_);
}


# возвращает текущий процесс, или если указаны имена других процессов, то группу
sub process {
	require "R/Async/Process.pm";
	require "R/Async/Processset.pm";
	eval q{sub R::App::process {
		shift;
		@_==1? R::Async::Process->new(@_): R::Async::Processset->new(@_);
	}};
	die $@ if $@;
	file(@_);
}




# если функция не найдена
use vars '$AUTOLOAD';

sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	eval "sub $AUTOLOAD {
		my \$self = shift;
		if(\@_) { \$self->{'$prop'} = \$_[0]; \$self } else { \$self->{'$prop'} }
	}";
	die "not make $AUTOLOAD: ".($@ // $!) if $@ // $!;
	
	my $self = shift;
	if(@_) {
		$self->{$prop} = $_[0];
		$self
	} else {
		my $base = "R";
		my $load = $prop; $load =~ s![A-Z]!/$&!g;
		my $new = $prop; $new =~ s![A-Z]!::$&!g;
		$load = $base."/".ucfirst($load).".pm";
		$new = $base."::".ucfirst($new);
		require $load;
		$self->{$prop} = $new->new;
	}
}

sub DESTROY {}



1;
