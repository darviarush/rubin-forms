#> следит за изменением файлов и перекомпилирует их
#> настройки в watch::* в main.ini

$app->hung->loop;

#$app->hung->loop(sub {
	#main::msg "time"
#});
#sub { main::msg "time"; exit if eof STDIN }

1;