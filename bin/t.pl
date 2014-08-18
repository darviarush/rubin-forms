#!/usr/bin/perl

#= add [[file] name|*] | t
#> тесты
#> add - добавить скелетон теста

($cmd, @ARGS) = @ARGV;

# if($cmd eq "add") {
	# $file = $#ARGV == 2? 'app.coffee': $ARGV[1];
	# $file .= ".coffee" unless $file =~ /\.coffee$/;
	# $old_file = $file;
	# die "$old_file не найден" if not -e $file and not -e $file="coffee/$file";
	# open f, $file or die $!;
	# while(<f>) {
		
	# }
	# close f;
	
	# if($ARGV[$#ARGV] eq "*") {
		
	# } else {
		
	# }
	# exit;
# }

$verbosity = 1;
$verbosity = shift @ARGS if $ARGS[0] =~ /^-?\d+$/;

@tests = @ARGS? map { /^\w+$/? (-e "t/$_.t"? "t/$_.t": "../rubin/t/$_.t"): $_} @ARGS: files("t/*.t");

use TAP::Harness;
my $harness = TAP::Harness->new({
	color=>1,
	verbosity => $verbosity,
	lib => ['lib', '../rubin/lib'],
	failures => 1
});
$harness->runtests(@tests);

