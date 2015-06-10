#== Редактор
#= []
#> команда find

#use Getopt::Std;

($name, $find) = @ARGV;

($path, $ext) = $app->path->to($name);

Utils::find(sub {
	return if !/\.$ext$/o;
	$file = Utils::read($_);
	msg $_ if $file =~ /$find/o;
}, $app->path->files($path));

# $app->fs->find($path)->read->then({
	# msg shift->path if /$find/;
# });
