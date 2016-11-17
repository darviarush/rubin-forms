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
desc "добавляет все файлы и делает комит";
sub commit {

	$app->tty->raw;

	my $save = join(" ", @_) || "save";

	print `git add .`;
	my $s = `git commit -am "$save" 2>&1`;
	print $s if $? == 0;

}


# name "merge";
# desc "сливает текущую ветку в master";
# rels "commit";
# sub merge {
	
	# $app->tty->raw;

	# my $s = `git branch`;
	# my ($branch) = $s =~ /^\*\s+([\w-]+)/;

	# print qq{git checkout master && git merge --no-edit --no-ff "$branch" && git branch -D "$branch"};

	# print `git checkout master && git merge --no-edit --no-ff "$branch" && git branch -D "$branch"`

# }

name "new";
args "ветка [сообщение]";
desc "создаёт новую ветку";
task {
	my ($name, $message) = @_;
	
	quit "введите название ветки\n" if @_ < 1;
	
	$app->tty->raw;
	make "commit", $message;
	print `git checkout -b "$name"`;
};



name "to";
args "ветка";
desc "переключается на ветку";
sub to {
	my ($name, $message) = @_;

	quit "введите название ветки\n" if @_ < 1;
	
	$app->tty->raw;

	make "commit", $message;
	
	print `git checkout "$name"`;
	
}

name "branch";
args "[-r]";
desc "переключиться на ветку";
sub branch {
    my ($remote) = @_;

    $app->tty->raw;

    my $current;
    my @branch = grep { length $_ } split /\n/, `git branch`;
    push @branch, $app->perl->qq("добавить");
    
    my $nbranch = $app->tty->select(\@branch, "выберите ветку")-1;
    
    my $branch = $branch[$nbranch];
    
    print("вы остаётесь на ветке $branch"), return if $branch =~ /^\s*\* /;
    
    my $s = `git status -s`;
    if($s) {
        print "git status -s\n$s\n";
        if($app->tty->confirm("есть изменения. комитим?")) {
            print "введите комментарий к комиту (save) ";
            my $comment = <> || "save";
            print `git commit -am "$comment"` if $comment !~ /^\s*$/;
        }
    }
    
    if($nbranch == $#branch) {  # добавляем
        print "Введите название новой ветки (пусто - отмена): ";
        $branch = <>;
        $branch = $app->perl->trim($branch);
        return if $branch =~ /^\s*$/;
        print `git checkout -b "$branch"`;
    }
    else {
        $branch = $app->perl->trim($branch);
        print `git checkout "$branch"`;
    }
    
}

name "dist";
args "";
desc "пушит все из этого каталога и всех каталогов в каталоге выше";
sub dist {
	my $root = $app->file("..")->abs;
	
	$app->tty->raw;
	
	$root->sub("/*")->glob("-d")->then(sub {
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