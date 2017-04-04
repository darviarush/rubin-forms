= Введение

`rubin-forms` - это веб-фреймворк на `perl5`.

Он включает как необходимые веб-фреймворку части: `model-ORM` c миграциями, http-сервер `Aura`, веб-формы (`rubin-forms`), - так и различные вспомгательные модули: `File` для работы с файловой системой, построитель лексико-грамматическо-семантических анализаторов `Syntax` и язык программирования `Серебряну` (`Ag`).

== Установка

```sh
$ git clone git@github.com:darviarush/rubin-forms.git
$ cd rubin-forms
$ carton install
```

Установка и запуск тестов:

```sh
$ cd ..
$ git@github.com:darviarush/miu.git
$ cd miu
$ make link
$ cd ../rubin-forms
$ ./rubin-forms man "" -l
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

1. [00-orm](mark/00-orm.markdown)
1. [02-orm-types](mark/02-orm-types.markdown)
1. [03-orm-meta](mark/03-orm-meta.markdown)
1. [04-migration](mark/04-migration.markdown)
1. [09-connect](mark/09-connect.markdown)
1. [10-view](mark/10-view.markdown)
1. [11-view-js](mark/11-view-js.markdown)
1. [11-view-lang](mark/11-view-lang.markdown)
1. [12-syntax](mark/12-syntax.markdown)
1. [13-ag](mark/13-ag.markdown)
1. [15-users-scenaries](mark/15-users-scenaries.markdown)
1. [20-form](mark/20-form.markdown)
1. [21-form-input](mark/21-form-input.markdown)
1. [22-form-tag](mark/22-form-tag.markdown)
1. [23-pages](mark/23-pages.markdown)
1. [24-roles](mark/24-roles.markdown)
1. [30-app](mark/30-app.markdown)
1. [31-perl](mark/31-perl.markdown)
1. [32-file](mark/32-file.markdown)
1. [33-process](mark/33-process.markdown)
1. [34-serverside](mark/34-serverside.markdown)
1. [35-http](mark/35-http.markdown)
1. [36-shiva](mark/36-shiva.markdown)
1. [37-cache](mark/37-cache.markdown)
1. [38-session](mark/38-session.markdown)
1. [39-queue](mark/39-queue.markdown)
1. [40-raise](mark/40-raise.markdown)
1. [41-html](mark/41-html.markdown)
1. [60-css](mark/60-css.markdown)
1. [91-coro](mark/91-coro.markdown)

