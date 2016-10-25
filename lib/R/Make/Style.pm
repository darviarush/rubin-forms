package R::Make::Style;
# задачи по обработке стилей

use common::sense;
use R::App;
use R::Make;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

=pod
СТИЛИ
        css2r файл.css       транслятор с css в R::Css на perl
        sprite               создаёт спрайты
        style                создаёт стили из html/css/style.pass
=cut

category "СТИЛИ";


name "css2r";
args "файл.css";
desc "транслятор с css в R::Css на perl";
spec "R::Css - это библиотека для создания стилей";
sub css2r {
	print $app->css->css2r($app->file($_[0])->read);
}

name "sprite";
desc "создаёт спрайты";
spec "спрайты создаются из картинок в подкаталогах html/sprite";
#deps $app->file("html/sprite/*")->glob->grep() => "";
sub sprite {

	use common::sense;

	#use Image::Magick;
	use File::Basename;
	use POSIX qw/strftime/;

	my $border = " -bordercolor transparent -border 1 ";
	
	$" = " ";

	while(<html/sprite/*>) {

		next unless -d $_;
		my $dir = $_;
		my $sprite = "$_.png";
		my $mtime = $app->file($sprite)->mtime;
		while(<$dir/*>) {
			goto START if $mtime < $app->file($_)->mtime;
		}
		next;
		START:
		
		print $sprite;
		my $info = `identify -format "%[fx:w] %[fx:h] %i\n" $dir/*`;

		my $max_width = 0;
		my $sum = 0;
		my @info = sort { $b->{width} <=> $a->{width} } map { /^(\d+) (\d+) /; $max_width = $1 if $max_width < $1; $sum += $1; ({ width => $1, height => $2, file => $' }); } split /\n/, $info;
		
		#print "$sprite $max_width $sum ".($sum / sqrt @info)." ".(sqrt $sum)." ".($max_width * sqrt @info)."\n";
		
		$sum = $sum / sqrt @info;
		$max_width = $sum > $max_width? $sum: $max_width;
		
		open my $f, ">", "$dir.css" or die $!;
		my $add = "";
		my @css = ();
		my $x = 0;
		my $y = 0;
		my $max_y = 0;
		my $append = 0;
		my @img = ();
		for my $info (@info) {	
			my $file = $info->{file};
			my $real_width = $info->{width};
			my $real_height = $info->{height};
			my $width = $real_width+2;
			my $height = $real_height+2;

			
			if($x+$width >= $max_width) {
				$add .= " $border +append \\) \\( " if $append > 0;
				$y += $max_y;
				$x = 0;
				$max_y = 0;
				$append = 0;
			}

			$add .= ' '.$file;
			my $sel = $app->file($dir)->name . "-" . $app->file($file)->name;
			my $real_x = $x+1;
			my $real_y = $y+1;
			push @img, ".$sel { background-position: -${real_x}px -${real_y}px; width: ${real_width}px; height: ${real_height}px;}\n";
			push @css, ".".$sel;

			$x+=$width;
			$append++;
			$max_y = $height if $height > $max_y;
		}

		my $url = $sprite;
		$url =~ s/^html\///;
		print $f join(", ", @css)." { background: url(\"/$url?update=".strftime("%F_%T", localtime)."\") no-repeat; display: -moz-inline-stack; display: inline-block; *zoom: 1; *display: inline; }\n\n".join("", @img);
		close $f;
		
		$add .= " $border +append \\) \\( ";
		
		my $cmd = "convert -background transparent \\( $add \\) -append $sprite";
		print `$cmd`;

	}
}

#name "style";
#desc "создаёт стили из html/css/style.pass";
# sub style {
	# require "html/css/style.pass";
# }

name "favicon";
desc "создаёт иконки из html/favicon.png";
sub favicon {

	# <square70x70logo src="/favicon-70x70.png"/>
	# <square150x150logo src="/favicon-150x150.png"/>
	# <square310x310logo src="/favicon-310x310.png"/>
	# <wide310x150logo src="/favicon-310x150.png"/>

	my $icon = $app->file("html/img/favicon.png")->image;
	$icon->resize("70x70")->save("html/favicon-70x70.png");
	
	my $bg = $app->file("html/img/favicon-bg.png")->image;
	$bg->crop(0, 0, 150, 150)->composite($icon, "10x10")->save("html/favicon-150x150.png");
	$bg->crop(0, 0, 310, 310)->composite($icon, "10x10")->save("html/favicon-310x310.png");
	$bg->crop(0, 0, 310, 150)->composite($icon, "10x10")->save("html/favicon-310x150.png");
}



1;