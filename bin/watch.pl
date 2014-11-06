#> следит за изменением файлов и перекомпилирует их
#> настройки в watch::* в main.ini


$app->hung->loop(sub { exit if eof STDIN });


1;