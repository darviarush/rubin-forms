# принимает GET-параметры скрипта в первом параметре, POST - во втором. COOKIE - в третьем

$ENV{QUERY_STRING} = $ARGV[0];
$ENV{HTTP_COOKIE} = $ARGV[2];
$POST = $ARGV[1];

$ENV{CONTENT_LENGTH} = length $POST;


open f, "|+", "a.pl" or die "не открыть pipe c a.pl. $!\n";


