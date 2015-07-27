package R::Qq;
# доступны из командной строки - для сокращения времени разработки

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}

#= выражение
#> вычисляет выражение в контексте фреймворка
#> имеет сокращение: qq -e "выражение"
sub eval {
	my ($self, $code) = @_;
	eval($code);
	die $@ // $! if $@ // $!;
}

# вычисляет и распечатывает результат
sub eval_and_print {
	my ($self, $code) = @_;
	my @res = eval($code);
	die $@ // $! if $@ // $!;
	msg ":red nonewline", "> ";
	msg @res;
}


#== Редактор
#= [-] модуль [функция [аргументы...]]
#> создаёт файл модуля
#> тип модуля:
#>	make html - шаблон html
#>	make action - шаблон ModelView
#>	make mod - шаблон библиотеки в lib/R
#>	make mio - шаблон mio
#>	make qq - сниппет-команда, для командной строки
#>	make model - сниппет-команда, для командной строки
#> добавление :
#> 
sub make {
	my ($self, $type, $name, $method, @args) = @_;
	
	my %types = (
		action => sub { $app->patternAction },
		html => sub { $app->patternHtml },
		mio => sub { $app->mio },
		#mod => sub { },
	);
	
	my $maker = $types{$type};
	die "нет такого типа $type для создания модуля" unless $maker;
	
	$maker = $maker->();
	my $path = $maker->path;
	
	if(!defined $method) {
		die "файл создаваемого модуля уже есть" if $app->file->exists($path);
		my $snippet = $app->$type->snippet($name);
	} else {
		die "вначале создайте файл модуля" if !$app->file->exists($path);
		my $snippet = $app->$type->snippetMethod($name, $method, @args);
	}
}


#> создаёт спрайты
sub sprite {
	my ($self) = @_;


	#use Image::Magick;
	use File::Basename;
	use POSIX qw/strftime/;

	$" = " ";

	while(<html/img/sprite/*>) {

		next unless -d $_;
		my $dir = $_;
		my $sprite = "$_.png";
		my $mtime = mtime($sprite);
		while(<$dir/*>) {
			goto START if $mtime < mtime($_);
		}
		next;
		START:
		
		print $sprite;
		my $info = `identify -format "%[fx:w] %[fx:h] %i\n" $dir/*`;

		my $max_width = 0;
		my $sum = 0;
		my @info = sort { $b->{width} <=> $a->{width} } map { /^(\d+) (\d+) /; $max_width = $1 if $max_width < $1; $sum += $1; ({ width => $1, height => $2, file => $' }); } split /\n/, $info;
		
		#print "$sprite $max_width $sum ".($sum / sqrt @info)." ".(sqrt $sum)." ".($max_width * sqrt @info)."\n";
		
		my $sum = $sum / sqrt @info;
		my $max_width = $sum > $max_width? $sum: $max_width;
		
		open my $f, ">", "$dir.css" or die $!;
		my $add = "";
		my @css = ();
		my $x = 0;
		my $y = 0;
		my $max_y = 0;
		my $append = 0;
		my @img;
		my @sel;
		for my $info (@info) {	
			my $file = $info->{file};
			my $width = $info->{width};
			my $height = $info->{height};
			
			if($x+$width >= $max_width) {
				$add .= " +append \\) \\( " if $append > 0;
				$y += $max_y;
				$x = 0;
				$max_y = 0;
				$append = 0;
			}

			$add .= ' '.$file;
			@sel = $file =~ m!([\w-]+)\.[^/]+$!;
			push @img, ".$sel[0] { background-position: -${x}px -${y}px; width: ${width}px; height: ${height}px }\n";
			push @css, ".".$sel[0];

			$x+=$width;
			$append++;
			$max_y = $height if $height > $max_y;
		}

		print $f join(", ", @css)." { background: url(\"/$sprite?update=".strftime("%F_%T", localtime)."\") no-repeat; display: -moz-inline-stack; display: inline-block; *zoom: 1; *display: inline; }\n\n".join("", @img);
		close $f;
		
		$add .= " +append \\) \\( ";
		
		my $cmd = "convert -background transparent \\( $add \\) -append $sprite";
		print `$cmd`;

	}
}


1;
