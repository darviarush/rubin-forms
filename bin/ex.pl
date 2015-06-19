use XML::Simple;
use Data::Dumper;

$project = "../unicorn/unicorn.npp.prj";

$simple = XML::Simple->new(ForceArray=>1, KeepRoot=>1);

my $xml = $simple->XMLin(Utils::read($project));


Utils::write($project.".pl", Dumper($xml));
Utils::write($project.".xml", $simple->XMLout($xml));