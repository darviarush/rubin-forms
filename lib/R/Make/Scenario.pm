package R::Make::Scenario;
# задачи для сценариев

use common::sense;
use R::App;
use R::Make;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}


=pod
СЦЕНАРИИ
        sc [сценарий1...]    запускает сценарии
        scserver             запускает сервер сценариев
        t [маска]            тестирование заданий
=cut

category "СЦЕНАРИИ";


name "man";
args "[-] | [опции miu] [маска файлов] [маска разделов]...";
desc "компиллирует файлы man компиллятором miu";
sub man {
	
	# список тестов
	if($_[0] eq "-") {
		$app->file("man/*")->glob->then(sub {
			$app->log->info( $_->file );
		});
		
		return;
	}
	
	# добавляем каталог
	@ARGV = @_;
	$ARGV[0] = join ":", map { "man/$_" } split /:/, $ARGV[0];
	$ARGV[0] = "man" if $ARGV[0] eq "";

	unshift @ARGV, "-o", "var/.MAN";

	$app->tty->raw;
	
	require "/bin/miu";
}

name "men";
args "[mask]";
desc "распечатывает тесты";
sub men {
    my ($file_mask) = @_;

    $file_mask ||= "*";
    
    $app->file("man")->find("man/$file_mask", "*.man,*.human", sub {
        $app->log->info( $app->file($_)->subdir("man/") );
        0;
    });
}

name "sec";
args "[mask]";
desc "распечатывает тесты c регуляркой по главам";
sub sec {
    my ($glava_mask) = @_;

    $glava_mask ||= "*";
    
    $glava_mask = $app->perl->like("(=; )$glava_mask");
    
    $app->file("man")->find("*.man,*.human", sub {
        my $file = $app->file($_);
        my $man = $file->read;
        
        my $once;
        
        while($man =~ /^=+.*/gm) {
            my $g = $&;
            if($g =~ $glava_mask) {
                $once = 1, $app->log->info(":empty", "\n", ":yellow on_red", $app->file($_)->subdir("man/") ) if !$once;
                $app->log->info($g);
            }
        }
        0;
    });
}


name "t";
args "[маска]";
desc "тестирование заданий";
spec "задания помещаются в директории task";
sub t {

	$app->tty->raw;

	my @test_files;
	my $dir = "task";
	@test_files = $app->file($dir)->find("-f")->files;

	if(@ARGV) {
		
		my $num = "0*(?:" . join("|", grep { /^\d+$/ } @ARGV) . ")-";
		my $cat = "\d+-(?:" . join("|", grep { /^[\w-]+$/ } @ARGV) . ")-";

		@test_files = grep { /^$dir\/(?:$num|$cat)/o } @test_files;
	}


	if(!@test_files) {
		print "Ничего не выбрано\n";
	} else {
		require Test::Harness;
		Test::Harness->execute_tests(tests => \@test_files);
	}


}



name "scserver";
desc "запускает сервер сценариев";
sub scserver {

	$app->man->scenario;
	
	msg1 $app->ini->{site};
	
	die "app.meta уже есть" if $app->{modelMetafieldset};
	#$app->meta->drop;
	$app->meta->sync;


	die "img root == html/images. Это означает, что root в сценариях не применился" if $app->model->img(undef)->root eq "html/images";

	# создаём директорию картинок, если её нет
	$app->file($app->model->img(undef)->root)->mkpath->mkdir;
	
	# сценарии выполняются последовательно
	$app->connect->pool;					# получаем dbh
	$app->connect->{transaction} = 1;		# всё в одной транзакции
	$app->connect->dbh->{AutoCommit} = 0;	# никогда не комитим

	$app->server->controllers("/__" => "Sc")->dispatchers("/__/start__scenario" => sub {

		die "транзакция потеряна!" if $app->connect->{transaction} <= 0;
	
		# откатываем предыдущую транзакцию
		eval { $app->connect->dbh->rollback };
		msg1 "rollback: $@" if $@;
		
		# делаем реконнект, если соединение с базой потеряно
		$app->connect->reconnect;
		$app->connect->dbh->{AutoCommit} = 0;
		
		# чистим директорию картинок
		my $root = $app->file($app->ini->{img}{root});
		if($root->exists) {$root->rmdown} else {$root->mkdir}
		
	})->loop;

}


name "sc";
args "[сценарий1...]";
desc "запускает сценарии";
sub sc {

	$app->tty->raw;

	$app->man->scenario;
	
	$app->view->scenario(@_);
	
	# use App::Prove;

	# $app->log( $app->log->new(log => "std", log_as_is=>"") );

	# my $app = App::Prove->new;
	# $app->process_args("--lib", @av);
	# exit( $app->run ? 0 : 1 );

}





1;