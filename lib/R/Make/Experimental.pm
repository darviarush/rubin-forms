package R::Make::Experimental;
# экспериментальные задания

use common::sense;
use R::App;
use R::Make;

category "ЭКСПЕРИМЕНТ";

name "replace_view";
desc "заменяет текст в директории view";
sub replace_view {
	
	$app->file(qw/view/)->find("*.html")->replace(sub {
		my $file = $_[0];
		my $is = s!\$app\.sign\.(\w+)! my $x=$1; $x=~s/[A-Z]/"-" . lc $&/ge; "&fa-$x;"!ge;
		print ($is? "*  ": "   ") . $file->path . "\n";
	});
}


name "api";
desc "формирует документацию api";
spec "считывает файлы в директории lib/R и сопоставляет их файлу man/50-api.man";
sub api {
	my $man = $app->file("man/50-api.man");
	$man->write("") if !$man->exists;
	my $f = $man->open;
	
	my %class;
	my @class;
	my $last;
	my $begin;
	
	while(<$f>) {
		if(/^==[\t ]+([^\r\n]*)/) {
			$begin = $last if !$last;
			push @class, $class{$1} = $last = {name => $1};
		}
		elsif(/^===[\t ]+([^\r\n]*)/) {
			$begin = $last if !$last;
			$last->{fn}{$1} = {name => $1};
		}
		
		$last->{text} .= $_;
	}
	
	close $f;
	
	my $f = $man->open(">");
	
	$app->file("lib/R")->find("*.pm")->sort->then(sub {
	
		my $path = $_->path;
		$app->log->info(":bold black", $path);
		$_ = $_->read;
		#die "$path: нет package name;\n" if !/\bpackage\s+([\w:]+);\s*(#\s*.*\n)+/;
		
		my $class;
		
		while(/((?:\#.*\n)*) [\ \t]* \b package \s+ ([\w:]+) ;? \s*((?:\#.*\n)*) | ((?:\#.*\n)*) [\ \t]* \b sub [\ \t] ([\w:]+)/gx) {
			my $rem = $1 . $3 . $4;
			my $pack = $2;
			my $name = $5;
			
			die "\$pack и \$name оба установлены: $pack, $name" if defined $pack and defined $name;
			
			$rem =~ s/^#\s*//gm;
			
			if(defined $pack) {
				$class = $class{$pack};
				my $text;
				
				if($class) {
					$text = $class->{text};
					my $re = quotemeta $rem;
					print "$path: изменился комментарий пакета\n" if $text !~ s/^$re/\n/;
				}
				
				print $f "\n\n== $pack\n\n$rem$text";
			}
			else {

				my $sub = $class->{fn}{$name};
				my $text;
				if($sub) {
					$text = $sub->{text};
					my $re = quotemeta $rem;
					print "$path: изменился комментарий sub $name\n" if $text !~ s/^$re/\n/;
				}
				
				print $f "\n\n=== $name\n\n$rem$text";
			}
		}
	
	});
	
	
}


1;