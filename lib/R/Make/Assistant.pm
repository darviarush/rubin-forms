package R::Make::Assistant;
# разнообразные вспомогательные задания не вошедшие ни в одну категорию

use common::sense;
use R::App;
use R::Make;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}



        # cp_etc_home          копирует файл проектов в домашний файл проектов
        # help [name]          возвращает список команд
        # kill                 убивает сервер
        # look [тест]          функциональные тесты в папке look
        # man [опции miu] [маска файлов] [маска разделов]... компиллирует файлы man компиллятором miu
        # tags имя_функции     создаёт базу и ищет по ней функцию или класс
        # utf8                 проверка всех модулей на кодировку utf-8
		


category "АССИСТЕНТЫ";


name "help";
args "[задание]";
desc "возвращает список команд";
spec "если указан параметр - распечатывает всю информацию по этому заданию";
sub help {
	my $name = $_[0];
	if(defined $name) {
	
		my $task = $R::Make::TASK{$name};
		quit "нет задачи `$name`" if !$task;
		
		$app->log->info(":bold white", "НАИМЕНОВАНИЕ");
		$app->log->info("    $name - $task->{desc}\n");
		$app->log->info(":bold white", "РЕЗЮМЕ");
		$app->log->info(":bold white space", "    $name", ":reset", "$task->{args}\n");
		$app->log->info(":bold white", "РАСПОЛОЖЕНИЕ");
		$app->log->info("    ФАЙЛ      $task->{file}\n    СТРОКА    $task->{line}\n");
		$app->log->info(":bold white", "КОНЦЕПЦИЯ");
		$app->log->info($task->{spec} // "НЕТ");

		return;
	}

	

	for my $category (@R::Make::CATEGORY) {

		my $cat = $category->{category};
	
		$app->log->info( ":empty", ":bold", "\n", ":bold black", $cat, ":" ) if $cat ne "";

		my $tasks = $category->{tasks};
		
		for my $task (@$tasks) {
			my $name = $task->{name};
			my $args = $task->{args};
			my $help = $task->{desc};
			$name .= " $args" if defined $args;
			my $len = length $name;
			$app->log->info( ":empty", ":bold black", "\t", $name, ":reset", (" " x  (20 - $len)) . ($help? " ".$help: "") );
		}
	}

}

name "cc";
args "[file...]";
desc "компилирует все view или указанные файлы";
sub cc {
	$app->view->recompile(@_);
}


name "utf8";
desc "проверка всех модулей на кодировку utf-8";
sub utf8 {
	
	$app->file($app->project_name, "etc/$app->{project_name}.ini", "task", "view", "model", "lib/R", "man")->find(sub {
		return if -d $_;
		my $file = `file "$_"`;
		print "file $_\n$file\n\n" if $file !~ /UTF-8/;
		0;
	});

}

name "home";
desc "копирует файл проектов в домашний файл проектов";
sub home {

	open my $f, "etc/notepad++.project" or die $!;

	my $flag;
	my @x;
	
	while(<$f>) {

		$flag=1 if /<Project name="miu">/;

		s/C:\\__/C:\\lang/, push @x, $_ if $flag;
	}

	close $f;

	open $f, ">", "etc/notepad++-home.project" or die $!;
	print $f "<NotepadPlus>\n";
	print $f @x;
	close $f;

}

name "del13";
args "";
desc "удаляет 13-й символ";
sub del13 {
	# "etc", "lib", "view", "migrate", "model", "html", "man", $0
	$app->file(".")->encode(undef)->find("*/.gitignore,*.<pm,pl,man,human,%htm%,js,css,coffee,yml,ini,%php%,twig,tmpl,txt>")->replace(sub { print $_[0]->path . "\n" if s/\r//g })
	
}

name "shiva";
args "";
desc "список заданий крона";
sub shiva {
	my $tasks = $app->shiva->{tasks};
	todo;
}



name "replace";
args "[files [exts]] regexp sub";
desc "заменяет текст во всех файлах проекта";
spec "
files - файлы и директории в которых менять через запятую, по умолчанию - в view,html,lib
exts - расширения файлов через точку с запятой, по умолчанию - *.pl;*.pm;*.man;*.human;*.html;*.js;*.css;*.pass
regexp - регулярное выражение для замены в файле
sub - текст для замены, может содержать \$1-10, \$& и \$1:camel
";
sub replace {
	my ($files, $exts, $regexp, $sub);
	
	if(@_ == 2) { ($regexp, $sub) = @_; }
	elsif(@_ == 3) { ($files, $regexp, $sub) = @_; }
	else { ($files, $exts, $regexp, $sub) = @_; }

	my @files = $files? split(/,/, $files): qw/view html lib/;
	
	$exts ||= "*.pl;*.pm;*.man;*.human;*.html;*.js;*.css;*.pass";
	
	$sub =~ s!\\[\w\\]!eval("\"$&\"")!ge;
	
	$app->file(@files)->find($exts)->replace(sub {
		my $file = $_[0];
		my $is = s!$regexp!$sub!g;
		print( ($is? "*  ": "   ") . $file->path . "\n");
	});
}



name "chmod";
args "";
desc "изменяет права файлов на 0600, а директорий на 0744";
sub chmod {

    my $mod = 0600;
    my $grep_chmod = sub { $app->file($_)->mod != $mod };
    my $print_dir = sub { printf "-d %o\t%s", $mod, $_->path . "\n" };
    my $print_file = sub { printf "-f %o\t%s", $mod, $_->path . "\n" };

	if( 0 && $app->file(".git")->isdir ) {

		my @hide = qw/lib migrate model man var view etc ex .gitignore Makefile/;
		my @front = qw/html/;
		
        $mod = 0600;
		$app->file(@hide)->find("-f", $grep_chmod)->mod($mod)->then($print_file);
        $mod = 0744;
		$app->file(@hide, @front)->find("-d", $grep_chmod)->mod($mod)->then($print_dir);
		
        $mod = 0622;
		$app->file(@front)->find("-f", $grep_chmod)->mod($mod)->then($print_file);
        $mod = 0700;
		$app->file($app->project_name)->find("-f", $grep_chmod)->mod($mod)->then($print_file);
		
		$app->log->info("изменены права файлов на стандартные");
	}
	else {
        
        my @any = $app->file("*")->glob->grep(sub { !/^\.git$/ });
        
        $mod = 0644;
		$app->file(@any)->find("-f", $grep_chmod)->mod($mod)->then($print_file);
        $mod = 0755;
		$app->file(@any)->find("-d", $grep_chmod)->mod($mod)->then($print_dir);
        
        $mod = 0764;
		$app->file(".git")->find("-f", $grep_chmod)->mod($mod)->then($print_file);
        $mod = 0775;
		$app->file(".git")->find("-d", $grep_chmod)->mod($mod)->then($print_dir);
	}
	
	
	
}


name "mk";
args "";
desc "создаёт директорию для нового проекта";
sub mk {
	my ($self, $dir) = @_;
	
# Директория	    Описание
# apps/	            Содержит все приложения проекта
# cache/            Кэш фреймворка
# config/           Конфигурационные файлы фреймворка
# lib/              Библиотеки и классы проекта
# log/              Логи фреймворка
# plugins/          Установленные плагины
# test/             Файлы для модульного и функционального тестирования
# web/              Корневая папка с веб-файлами

# modules/          Код приложения (MVC)
# templates/        Глобальные шаблоны приложения
    
	# создаём директорию
	$dir = $app->file($dir)->mkdir;
	
	# имя нового проекта:
	my $name = $dir->file;
	
	# создаём подкаталоги
	$dir->sub("etc")->mkdir;
	$dir->sub("html")->mkdir;
	$dir->sub("html/css")->mkdir;
	$dir->sub("html/js")->mkdir;
	$dir->sub("lib")->mkdir;
	$dir->sub("model")->mkdir;
    $dir->sub("man")->mkdir;
	$dir->sub("var")->mkdir;
	$dir->sub("view")->mkdir;
	
	# копируем 
	my $etc = $dir->sub("etc/$name.ini");
	$app->file("etc/unicorn.sample.ini")->cp($etc);
	
	# создаём коммандер
	$dir->sub($name)->write('#!'.$^X.'
BEGIN { push @INC, "lib" }
use common::sense;
use R::App;
use R::Make;

$app->make->load->run;
');
	
	# отображения
	
	
	# git
	
	#$dir->chdir;
	print `git init` if !$dir->sub(".git")->exists;

}


name "mkage";
args "[dir=/bin]";
desc "создаёт интерпретатор в dir";
spec "Создаёт в указанной директории скрипты al, ag, age, чтобы они были доступны отовсюду";
sub mkage {
	my ($self, $dir) = @_;
	
	$dir //= "/bin";
	
	my $path = $app->file(__FILE__)->file("")->sub("/../../")->abs->path;
	$path =~ s/'/\\'/g;
	
	my $ag = $app->file("$dir/ag");
	my $age = $app->file("$dir/age");
	my $al = $app->file("$dir/al");
	my @is;
	
	push @is, "ag" if $ag->exists;
	push @is, "age" if $age->exists;
	push @is, "al" if $al->exists;
	
	if(@is) {
		return if !$app->tty->confirm("Файлы ". join(", ", @is) ." уже существуют, перезаписать?");
	}
	
	# запустить указанный файл, если без параметров - то запускает сервер
	$ag->write('#!'.$^X. $app->copiright->file . '
BEGIN { push @INC, \''.$path.'\' }
use common::sense;
use R::App;

my $file = @ARGV? shift( @ARGV ): "Aquafile";

$app->syntaxAg->ag($file, @ARGV);

1
')->mod(0744);

	# выполнить выражение с командной строки
	$age->write('#!'.$^X. $app->copiright->file . '
BEGIN { push @INC, \''.$path.'\' }
use common::sense;
use R::App;

$app->log->info( $app->syntaxAg->eval($ARGV[0]) );
')->mod(0744);

	# Assetfile, Rubinfile, Alfile, Aquafile, Asfile, Accfile, Aliasfile
	# Al2O3, al2o3

	# мэйк
	$al->write('#!'.$^X. $app->copiright->file . '
BEGIN { push @INC, \''.$path.'\' }
use common::sense;
use R::App;
use R::Make;

$app->make->load;

if( $app->file("Aquafile")->isfile ) {
	$app->syntaxAg->ag("Aquafile");
}

$app->make->run;
')->mod(0744);

	print "ag, age, al ".(@is? "перезаписаны": "созданы")."\n";
}


# name "trace";
# args "";
# desc "трейс стека последней ошибки";
# sub trace {
	# my $file = $app->file("var/last.raise.trace");
	# print("нет трейса ошибки\n"), return if !$file->exists;
	# my $trace = $file->read;
	# $trace = $app->perl->loader($trace);
	# my $msg = $app->raise->new($trace, "error", undef);
	# $app->log->alert("$msg");
# }

# name "dier";
# args "";
# desc "";
# sub dier {
	# die "для трейса!";
# }

1;