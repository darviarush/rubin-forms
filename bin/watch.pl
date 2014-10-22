#> следит за изменением файлов и перекомпилирует их
#> а именно, применяет команды: stylus, coffee, sprite, action

use R::Watch;

$watch = R::Watch->new;

$watch->on(qr/\.sty$/, ['css'], sub {
	my ($path) = @_;
});

$watch->loop();