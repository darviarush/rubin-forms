= Введение

`rubin-forms` - это веб-фреймворк на `perl5`.

Он включает как необходимые веб-фреймворку части: `model-ORM` c миграциями, http-сервер `Aura`, веб-формы (`rubin-forms`), - так и различные вспомгательные модули: `File` для работы с файловой системой, построитель лексико-грамматическо-семантических анализаторов `Syntax` и язык программирования `Серебряну` (`Ag`).

== Установка

```sh
$ git clone git@github.com:darviarush/rubin-forms.git
```

Установка и запуск тестов:

```sh
$ cd ..
$ git@github.com:darviarush/miu.git
$ cd miu
$ make link
$ cd ../rubin-forms
$ ./rubin-forms man -l
```

== Использование

Посмотреть список команд:

```sh
$ cd rubin-forms
$ ./rubin-forms help
```

Установить в /bin скрипты `ag`, `age` и `al`. 

```sh
$ ./rubin-forms mkage
```

1. `al` - make вроде `rake`. `al help`
2. `ag` - компилятор программ на `Серебряне` (`Ag`)
3. `age` - интерпретирует строку переданную ему параметром как код `Серебряны`


== Документация



