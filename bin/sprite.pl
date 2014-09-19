#> создаёт спрайты


#use Image::Magick;
use File::Basename;
use POSIX qw/strftime/;

$" = " ";

while(<img/sprite/*>) {

	next unless -d $_;
	$dir = $_;
	$sprite = "$_.png";
	$mtime = mtime($sprite);
	while(<$dir/*>) {
		goto START if $mtime < mtime($_);
	}
	next;
	START:
	
	print $sprite;
	$info = `identify -format "%[fx:w] %[fx:h] %i\n" $dir/*`;

	$max_width = 0;
	$sum = 0;
	@info = sort { $b->{width} <=> $a->{width} } map { /^(\d+) (\d+) /; $max_width = $1 if $max_width < $1; $sum += $1; ({ width => $1, height => $2, file => $' }); } split /\n/, $info;
	
	#print "$sprite $max_width $sum ".($sum / sqrt @info)." ".(sqrt $sum)." ".($max_width * sqrt @info)."\n";
	
	$sum = $sum / sqrt @info;
	$max_width = $sum > $max_width? $sum: $max_width;
	
	open f, ">", "$dir.css" or die $!;
	$add = "";
	@css = ();
	$x = 0;
	$y = 0;
	$max_y = 0;
	for $info (@info) {	
		$file = $info->{file};
		$width = $info->{width};
		$height = $info->{height};
		
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

	print f join(", ", @css)." { background: url(\"/$sprite?update=".strftime("%F_%T", localtime)."\") no-repeat; display: -moz-inline-stack; display: inline-block; *zoom: 1; *display: inline; }\n\n".join("", @img);
	close f;
	
	$add .= " +append \\) \\( ";
	
	$cmd = "convert -background transparent \\( $add \\) -append $sprite";
	print `$cmd`;

}