#> открывает notepad++ в другом окне

die "Нет файла rubin.session. Смените директорию" unless file("rubin.session");



print `/cygdrive/c/sbin/notepad++/notepad++ -multiInst -nosession -openSession rubin.session`;


