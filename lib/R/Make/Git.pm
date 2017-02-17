package R::Make::Git;
# добавляет команды для работы с GIT

use common::sense;
use R::App;
use R::Make;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}


# возвращает текущую ветку
sub current_branch {
	my ($self) = @_;
    
    my $branch = `git branch`;
    ($branch) = $branch =~ /^\s*\*\s+(\S+)/m;
    
	$app->perl->trim($branch)
}

category "GIT";

name "push";
args "";
desc "";
task {
    my ($comment) = @_;

    $comment =~ s!"!\\"!g;
    
    my $cmd = "git commit -am \"$comment\" && git pull --no-edit && git push";
   
    $app->tty->raw;
   
    print "$cmd\n";
   
    print `$cmd`;
};

name "commit";
desc "делает комит, если есть что комитить";
sub commit {

	$app->tty->raw;

	my $s = `git status -s`;
    if($s) {
        print "git status -s\n$s\n";
        if($app->tty->confirm("есть изменения. комитим?")) {
            print "введите комментарий к комиту (save) ";
            my $comment = <> || "save";
            print `git commit -am "$comment"` if $comment !~ /^\s*$/;
        }
    }

}

name "new";
args "ветка";
desc "создаёт новую ветку";
spec "клонирует ветку master";
task {
	my ($name) = @_;
	
    $app->tty->raw;
    
	@_ < 1 && $app->tty->input("введите название ветки", $name);
	
	make "commit";
    
    my $branch = current_branch();
    if($branch ne "master") {
        my $push = "git checkout master";
        print "$push\n";
        print `$push`;
    }
    
    my $push = "git checkout -b $name";
    print "$push\n";
	print `$push`;
    
    
};

name "co";
#args "[-r]";
desc "переключиться на/создать/удалить ветку";
sub co {
    my ($remote) = @_;

    $app->tty->raw;

    my $current;
    my @real = my @branch = grep { length $_ } split /\n/, `git branch`;
	
	use Term::ANSIColor qw/color/;
	
	# если встречается слово 2-ды, то - выделить его
	my %word;
	@branch = map { while(m/[a-z]{3,}/gi) { $word{$&}++ } $_ } @branch;
	
	#delete $word{ED};
	
	# и подсвечиваем цыфры
	@branch = map { s/[a-z]{3,}|\d+/ !exists $word{$&}? color("cyan").$&.color("reset"): $word{$&}>1? color("red").$&.color("reset"): $& /gie; $_ } @branch;

    unshift @branch, $app->perl->qq("добавить"), $app->perl->qq("удалить");
    
    my $nbranch = $app->tty->select(\@branch, "выберите ветку");
    
    my $branch = $real[$nbranch-3];
    
    print("вы остаётесь на ветке $branch"), return if $branch =~ /^\s*\* /;
    
    make("commit");
    
    if($nbranch == 1) {  # добавляем
        $app->tty->input( "Введите название новой ветки (пусто - отмена)", $branch );
        return if $branch =~ /^\s*$/;
		$app->tty->run("git checkout master");
        $app->tty->run("git checkout -b $branch");
    }
	elsif($nbranch == 2) {	# удаляем
		my $n = $app->tty->select([ @branch[2..$#branch] ], "выберите ветку для удаления");
		$branch = $real[$n-1];
		
		$app->tty->run("git checkout master") if $branch eq current_branch();
		
		$app->tty->run("git branch -D $branch");
	}
    else {
        $app->tty->run("git checkout $branch");
    }
    
}

name "mm";
args "";
desc "сливает с мастером и пушит, но остаётся на ветке";
sub mm {
    $app->tty->raw;
   
    make("commit");
    
    my $branch = current_branch();
    
    # my $push = "git pull --no-edit origin $branch";
    # print "$push\n";
    # print `$push`;
    
    # my $push = "git push origin $branch";
    # print "$push\n";
    # print `$push`;
    
    $app->tty->run("git checkout master");
    
    $app->tty->run("git merge --no-ff --no-edit $branch");
    
    $app->tty->run("git pull --no-edit");
    
    $app->tty->run("git push");
    
    $app->tty->run("git checkout $branch");
}



name "dist";
args "";
desc "пушит все из этого каталога и всех каталогов в каталоге выше";
sub dist {
	my $root = $app->file("..")->abs;
	
	$app->tty->raw;
	
	$root->sub("/*")->glob("-d")->then(sub {
		msg1 $_->path;
		$_->chdir, msg1(":red", $_->path), print(`git add .; git commit -am dist; git pull --no-edit && git push`), $root->chdir if $_->sub("/.git")->isdir;
	});
}

name "pullall";
args "";
desc "обновляет все каталоги на каталог выше";
sub pullall {
	my $root = $app->file("..")->abs;
	
	$app->tty->raw;
	
	$root->sub("/*")->glob("-d")->then(sub {
		$_->chdir, msg1(":red", $_->path), print(`git add .; git commit -am pullall; git pull --no-edit`), $root->chdir if $_->sub("/.git")->isdir;
	});
}

1;