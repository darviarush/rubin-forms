package R::Make;
# создаёт файл зависимостей и применяет их

use common::sense;
use R::App;

our %EXPORT = map {$_ => 1} qw/category name args desc spec rels deps test task default_task make quit/;

# импортирует символы
sub import {
	my $self = shift;
	my $caller = caller;
	
	for my $name (@_? @_: keys %EXPORT) {
		*{"${caller}::$name"} = \&$name;
	}
	
	$self;
}

# # деимпортирует символы
# sub unimport {
	# my $self = shift;
	# my $caller = caller;
	
	# for my $name (@_? @_: keys %EXPORT) {
		# delete *{"${caller}::$name"}{CODE};
	# }
	
	# $self;
# }


# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

our $CATEGORY = "";
our $NAMESPACE = "";
our @CATEGORY;
our %TASK;
our $LAST;
our $DEFAULT;		# задание по умолчанию

# категория заданий
sub category ($) {
	($CATEGORY) = @_;
	push @CATEGORY, {category => $CATEGORY, tasks => []};
	$LAST = undef;
    $NAMESPACE = "";
	return;
}


# пространство имён
sub namespace ($) {
	($NAMESPACE) = @_;
	category $NAMESPACE =~ /:$/? $`: $NAMESPACE;
	return;
}

# имя задания
sub name ($;$$$) {
	my ($name, $args, $desc, $spec) = @_;
	
	die "команда `$name` уже описана в $TASK{$name}{file}:$TASK{$name}{line}" if exists $TASK{$name};
	
	if($LAST) {
		die "в задаче $LAST->{name} нет task-а" if !$LAST->{code};
	}
	
	my ($package, $file, $line) = caller(0);
	
	$LAST = $TASK{$name} = {
		category => $CATEGORY,
		name => $name,
		file => $file,
		line => $line,
		code => *{"${package}::$name"}{CODE},
	};
	
	push @CATEGORY, {} if !@CATEGORY;
	
	push @{ $CATEGORY[$#CATEGORY]->{tasks} }, $LAST;
	
	args $args if defined $args;
	desc $desc if defined $desc;
	spec $spec if defined $spec;
	return;
}

# аргументы задания
sub args ($) {
	my ($args) = @_;
	
	die "args не в задании" if !defined $LAST;
	
	$LAST->{args} = $args;
	
	return;
}

# описание задания
sub desc ($) {
	my ($desc) = @_;
	
	die "desc не в задании" if !defined $LAST;
	
	$LAST->{desc} = $desc;
	
	return;
}

# спецификация задания - появляется, если набрать myapp help mytask
sub spec ($) {
	my ($spec) = @_;
	
	die "spec не в задании" if !defined $LAST;
	
	$LAST->{spec} = $spec;
	
	return;
}

# зависимости задания
sub rels (@) {
	#my $rel = shift;
	
	die "rels не в задании" if !defined $LAST;
	
	$LAST->{rels} = [@_];
	
	return;
}

# файловые зависимости задания
sub deps ($$) {
	my ($files, $deps) = @_;
	
	die "deps не в задании" if !defined $LAST;
	
	$LAST->{files} = $files;
	$LAST->{deps} = $deps;
	
	return;
}

# тестирует до того как будут применены зависимости 
sub test (&) {
	my ($code) = @_;
	
	die "test не в задании" if !defined $LAST;
	
	$LAST->{test} = $code;
	
	return;
}

# устанавливает дефолтное задание
sub default_task(;$) {
	my ($name) = @_;
	
	$DEFAULT = $name // ($LAST? $LAST->{name}: die "не указан обязательный параметр для default_task");
	
	return;
}

# задание
sub task (&) {
	my ($code) = @_;
	
	die "task не в задании" if !defined $LAST;
	
	$LAST->{code} = $code;
	
	return;
}

# выполняет задание вместе с зависимостями рекурсивно
sub make ($;@) {
	my $name = shift;
	
	my $task = $TASK{$name};
	die "неизвестное задание `$name`" if !$task;
	
	my $test = $task->{test};
	if($test) {
		$test->(@_);
	}
	
	my $deps = $task->{deps};
	if($deps) {
	
		my $files = $task->{files};
	
		$files = $app->file($files)->glob if !ref $files;
		$deps = $app->file($deps)->glob if !ref $deps;
		
		return if $files->cmpmtime($deps);
	}
	
	my $rels = $task->{rels};
	if($rels) {
		for my $rel (@$rels) {
			&make( $rel );
			#return if $@;	# если установлена 
		}
	}
	
	$task->{code}->(@_);
	
	msg "$name вернул код $?" if $? != 0;
	#$app->log->error("задание $name было остановлено") if $@;
	
	return;
}

# используется для тестирования
sub quit (@) {
	$app->log->info(@_);
	exit;
}

# подгружает все источники
sub load {
	my ($self) = @_;

	for my $dir (@INC) {
		my $cat = $app->file("R/Make")->frontdir($dir);
		$cat->find(qr/\.pm$/)->then(sub { require $_->path }) if $cat->exists;
	}

	$self
}

# выполняет указанное в @ARGV задание
sub run {

	my $name = shift @ARGV;
	
	$name //= $DEFAULT;

	if(defined $name and exists $TASK{$name}) {

		my @argv = @ARGV;
		local $_;

		utf8::decode($_) for @argv;

		make $name, @argv;
	} else {
		print "неизвестная команда\n";
	}
	
}

1;