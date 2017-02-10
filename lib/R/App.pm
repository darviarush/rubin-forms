package R::App;
# приложение - через него доступны другие классы

use common::sense;

use List::Util qw/pairmap pairgrep pairkeys pairvalues pairfirst first reduce all any/;
use Scalar::Util qw/blessed looks_like_number/;
use Time::HiRes qw/sleep/;

# импортирует в вызывавший модуль функции
my %EXPORT = ('$app' => 'app', map {$_=>1} qw/app msg msg1 has has_const Isa Can Num closure todo qsort nsort
in out body invariant RETURN assert
pairmap pairgrep pairkeys pairvalues pairfirst first reduce all any
sleep
/);
sub import {
	my $self = shift;
	
	my $caller = caller;
	
	require warnings;
	
	my $once = $warnings::Offsets{'once'};
	
	my $save = vec(${^WARNING_BITS}, $once, 1);
	
	for my $name (@_? @_: keys %EXPORT) {
		my $v = $EXPORT{$name};
		die "нет такого имени `$name`" if !defined $v;
		
		if($v == 0) {
			*{"${caller}::$v"} = \${$v};
		}
		else {
			*{"${caller}::$name"} = \&$name;
		}
	
	}
	
	vec(${^WARNING_BITS}, $once, 1) = $save;
	
	#${^WARNING_BITS} ^= ${^WARNING_BITS} ^ ;
	vec(${^WARNING_BITS}, $warnings::Offsets{'recursion'}, 1) = 1;
	
	$self;
}

# переменная приложения
our $app = bless {}, "R::App";

# возвращает синглетон приложения
sub app () { $app }

# устанавливаем имя приложения
my $project_name = $0 =~ /([\w-]+)[\.\w-]*$/? $1: "PROJECT_NO_NAME";
$app->project_name( $project_name );

# игнорируем PIPE. Я никогда не буду работать с процессами, которые завершаются из-за того, что сервер закрыл с ним соединение
$SIG{PIPE} = "IGNORE";

# по INT нужно завершаться корректно - вызвать все обработчики завершения
$SIG{INT} = our $SIGINT = sub {
	print STDERR "INT!!! $$ $app->{process_name} $app->{coro} $app->{processManager}\n";
	$app->{coro}->stop if $app->{coro};
	$app->processManager->stop if $app->{processManager};
	print STDERR "INT2 $$ $app->{process_name} stop\n";
	exit;
};

# потоки ввода-вывода приводятся к utf-8
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# устанавливаем ошибки
$app->raise;

# сокращение для объекта-описания ORM-а
sub meta {
	my $self = shift;
	@_? do { $self->{modelMetafieldset}=shift; $self }: ($self->{modelMetafieldset} //= $self->modelMetafieldset->load);
}

# сокращение для сервера
sub server {
	my ($self) = @_;
	$self->{server} //= $app->use($app->ini->{site}{server} // "R::Http::Server::Unicorn")->new;
}

# логирует вывод
# возвращает последний параметр
sub msg (@) {
	my ($pkg, $file, $lineno) = caller(0);
	
	# определяем, что файл совпадает с пакетом
	local ($_, $`, $', $&, $1, $2);
	$_ = $pkg;
	s!::!/!g;
	$_ = quotemeta $_;
	my $f = $file;
	$f =~ s!\.\w+$!!;	# сносим расширение
	$pkg = "$file $pkg" if $f !~ /$_$/;
	
	if($app->log) {
		$app->log->info("$pkg $lineno", @_);
	} else {
		print STDERR "app.panic: $pkg $lineno", @_;
	}
	return $_[$#_];
}

# добавляет =================== перед выводом
sub msg1 (@) {
	unshift @_, ":yellow on_red", "====================", ":reset";
	goto &msg;
}

# функция замещения
sub todo () {
	die "метод должен быть написан";
	#die "метод ещё не написан";
}

# создаёт функции-свойства в указанном классе
sub has (@) {
	my ($cls) = caller(0);
	for my $name (@_) {
		eval "sub ${cls}::$name { if(\@_>1) { \$_[0]->{'$name'} = \$_[1]; \$_[0] } else { \$_[0]->{'$name'} } }"
	}
}

# создаёт функции-константы в указанном классе
sub has_const (@) {
	my ($cls) = caller(0);
	for my $name (@_) {
		eval "sub ${cls}::$name { if(\@_>1) { die 'попытка установить константу' } else { \$_[0]->{'$name'} } }"
	}
}


# проверяет на соответствие isa
sub Isa (@) {
	my $val = shift;
	return unless blessed $val;
	for my $cls (@_) {
		return 1 if $val->isa(ref $cls || $cls);
	}
}

sub Can ($$) {
	my ($val, $cls) = @_;
	return unless blessed $val;
	$val->can($cls);
}

# проверяет: является ли переданный скаляр числом
# будьте осторожней, т.к. inf и nan - так же числа
sub Num ($) {
	goto &looks_like_number;
}

# построчная сортировка
sub qsort (&@) {
	my $code = shift;
	sort {
		$_ = $a; my $x = $code->();
		$_ = $b; my $y = $code->();
		$x cmp $y
	} @_
}

# почисловая сортировка
sub nsort (&@) {
	my $code = shift;
	sort {
		$_ = $a; my $x = $code->();
		$_ = $b; my $y = $code->();
		$x <=> $y
	} @_
}


# замыкание:
#	closure \&{$self->can("method")}, $self
#	closure {print}, 5
sub closure (@) {
	my $sub = pop;
	my @args = @_;
	sub { $sub->(@args, @_) }
}


# подключает и возвращает класс
sub use {
	my ($self, $class) = @_;
	my $path = $class;
	$path =~ s!::!/!g;
	require "$path.pm";
	$class
}


# # возвращает группу файлов
sub file {
	my $self = shift;
	require "R/File.pm";
	R::File->new(@_);
}

# возвращает app->{ini}
sub ini {
	if(@_==1) {
		require R::Ini;
		$app->{ini} = R::Ini->new;
	}
	*ini = sub { @_>1? do { $app->{ini}=$_[1]; $_[0] }: $app->{ini} };
	goto &ini;
}

# объект регулярки - используется в Серебряне
package MatchData {

	# use overload
		# '""' => \&stringify,
		# '.' => \&concat,
		# 'bool' => sub { $_[0]->{'!'} },
		# "0+" => sub { $_[0]->{'!'}? 1: 0 },
		# "qr" => \&stringify,
		# fallback => 1
	# ;

	# конструктор с параметрами: string, @-, @+, %+
	sub new {
		my ($cls, $s, $begin, $end, $test) = splice @_, 0, 5;
		bless { '~'=>$s, '^'=>$begin, '$'=>$end, '!'=>$test, @_ }, ref $cls || $cls;
	}
	
	# группа
	sub g {
		my ($self, $index) = @_;
		my $begin = $self->{'^'}[$index];
		substr $self->{'~'}, $begin, $self->{'$'}[$index] - $begin;
	}
	
	# всё до распознанного $`
	sub left {
		my ($self) = @_;
		substr $self->{'~'}, 0, $self->{'^'}[0]
	}
	
	# всё после распознанного $'
	sub right {
		my ($self) = @_;
		substr $self->{'~'}, $self->{'$'}[0]
	}
	
	# # возвращает строковое представление
	# sub stringify {
		# my ($self) = @_;
		# "<MatchData " . $app->json->to($self->[0]) . ">"
	# }
	
}

### Контрактное программирование ###

# проверяем условие
sub assert ($;$) {
	my ($condition, $message) = @_;
	
	die $message // "ASSERT" if !$condition;
	
	return;
}

# добавляем блок в инвариант
sub invariant (&) {
	my ($code) = @_;
	
	return if !$app->ini->{site}{test};
	
	my $package = caller;

	die "уже один инвариант установлен" if *{"${package}::__INVARIANT__"}{CODE};
	
	${"${package}::__CONTRACT__"}{INVARIANT} = $code;
	
	return;
}

# возвращаемое значение
sub RETURN() {}
my $EMPTY_RETURN = \&RETURN;
my $EMPTY_INVARIANT = sub(&) {};


# устанавливает предусловие подпрограммы
sub in (&) {
	my ($code) = @_;
	
	return if !$app->ini->{site}{test};
	
	my ($package, $file, $lineno, $ref) = caller(1);
	
	$package = $ref;
	local ($`, $', $&);
	$package =~ s/::\w+$//;
	
	${"${package}::__CONTRACT__"}{$ref}{IN} = $code;
	
	return;
}

# устанавливает постусловие подпрограммы
sub out (&) {
	my ($code) = @_;
	
	return if !$app->ini->{site}{test};
	
	my ($package, $file, $lineno, $ref) = caller(1);
	
	$package = $ref;
	local ($`, $', $&);
	$package =~ s/::\w+$//;
	
	${"${package}::__CONTRACT__"}{$ref}{OUT} = $code;
	
	return;
}

# возвращает аргументы предпредпоследнего вызова
package DB {
	sub __CONTRACT__ARGS__ {
		my @a = caller(2);
		return @DB::args;
	}
}

# устанавливает тело подпрограммы
sub body (&) {
	my ($code) = @_;
	
	my ($package, $file, $lineno, $ref) = caller(1);
	
	if(!$app->ini->{site}{test}) {
	
		*$ref = $code;
		
	}
	else {
	
		my ($package, $file, $lineno, $ref) = caller(1);
	
		$package = $ref;
		local ($`, $', $&);
		$package =~ s/::\w+$//;
	
		my $contract = \%{"${package}::__CONTRACT__"};
		my $return = $ref;
		$return =~ s/\w+$/RETURN/;
	
		*$ref = (sub {
			my ($return, $contract, $in, $out, $body) = @_;
			sub {

				# берётся тут, т.к. может быть установлен после
				my $invariant = $contract->{INVARIANT} // $EMPTY_INVARIANT;
				
				if(wantarray) {
					()=$in->(@_);
					()=$invariant->(@_);
					my $RETURN = [ $body->(@_) ];
					*$return = (sub { my ($args) = @_; sub() { @$args } })->($RETURN);
					()=$invariant->(@_);
					()=$out->(@_);
					*$return = $EMPTY_RETURN;
					return @$RETURN;
				}
				else {
					scalar $in->(@_);
					scalar $invariant->(@_);
					my $RETURN = scalar $body->(@_);
					*$return = (sub { my ($arg) = @_; sub() { $arg } })->($RETURN);
					scalar $invariant->(@_);
					scalar $out->(@_);
					*$return = $EMPTY_RETURN;
					return $RETURN;
				}
			}
		})->(
			$return,
			$contract,
			$contract->{$ref}{IN} // $EMPTY_INVARIANT,
			$contract->{$ref}{OUT} // $EMPTY_INVARIANT,
			$code
		);
	}
	
	#msg1 "args:", &DB::__CONTRACT__ARGS__;
	
	@_ = &DB::__CONTRACT__ARGS__;
	goto &$ref;
}



# если функция не найдена
use vars '$AUTOLOAD';

sub AUTOLOAD {
	my ($prop) = $AUTOLOAD =~ /([^:]+)$/;
	
	# ВНИМАНИЕ! Не использовать msg, msg1, app->log!, т.к. это приводит к зацикливанию!
	
	eval "sub $AUTOLOAD {
		my \$self = shift;
		if(\@_) { \$self->{'$prop'} = \$_[0]; \$self } else { \$self->{'$prop'} }
	}";
	die "not make $AUTOLOAD: $@" if $@;
	
	my $self = shift;
	if(@_) {
		$self->{$prop} = $_[0];
		$self
	} else {
	
		my $base = "R";		
		my $new = $prop; $new =~ s![A-Z]!::$&!g;
		$new = $base."::".ucfirst($new);
		
		#print STDERR "load: $load\n";
		
		#if($Nil::INC && @$Nil::INC > 1) {
		if($app->{syntaxAg}) {
			$app->syntaxAg->include($new);
		} else {
			my $load = $prop; $load =~ s![A-Z]!/$&!g;
			$load = $base."/".ucfirst($load).".pm";
			require $load;
		}
		
		my $ini = $app->ini;
		my @param;
		if(my $param = $ini->{service}{$prop}) {
			local $_;
			@param = map {
				my $isApp = s/^&//;
				if($isApp) {
					$app->$_
				} else {
					my $isInline = s/^%//;
					my $res = $ini;
					$res = $res->{$_} for split /\./;
					$isInline? %$res: $res;
				}
				
			} split /\s*,\s*/, $param;
		}
		
		$self->{$prop} = $new->new(@param);
	}
}

sub DESTROY {}



1;
