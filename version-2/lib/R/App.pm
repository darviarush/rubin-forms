package R::App;
# приложение - через него доступны другие классы

# устанавливаем ошибки
BEGIN {
	use R::Raise;
	R::Raise->new;
}

use common::sense;

use Exporter 'import';
our @EXPORT = qw/$app app msg todo has closure/;

# переменная приложения
our $app = bless {}, "R::App";

# возвращает синглетон приложения
sub app () { $app }

# логирует вывод
# возвращает последний параметр
sub msg (@) {
	$app->log->info(@_);
	return $_[$#_];
}

# функция замещения
sub todo () {
	die "метод должен быть написан";
}

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

# возвращает 
sub require {
	my ($self, $path) = @_;
	require "$path.pm";
	$path =~ s!/!::!g;
	$path
}




# если функция не найдена
use vars '$AUTOLOAD';

sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	eval "sub $AUTOLOAD {
		my \$self = shift;
		if(\@_) { \$self->{'$prop'} = \$_[0] } else { \$self->{'$prop'} }
	}";
	die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	
	if(@_==1) {
		my ($self) = @_;
		my $base = "R";
		my $load = $prop; $load =~ s![A-Z]!/$&!g;
		my $new = $prop; $new =~ s![A-Z]!::$&!g;
		$load = $base."/".ucfirst($load).".pm";
		$new = $base."::".ucfirst($new);
		require $load;
		$self->{$prop} = $new->new;
	} else {
		my $sub;
		{no strict "refs"; $sub = *{$AUTOLOAD}{CODE} };
		goto &$sub;
	}
}

sub DESTROY {}



1;
