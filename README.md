# Введение

`rubin-forms` - это веб-фреймворк на `perl5`.

Он включает как необходимые веб-фреймворку части: `model-ORM` c миграциями, http-сервер `Aura`, веб-формы (`rubin-forms`), - так и различные вспомгательные модули: `File` для работы с файловой системой, построитель лексико-грамматическо-семантических анализаторов `Syntax` и язык программирования `Серебряну` (`Ag`).

## Установка

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

## Использование

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


## Документация

1. [ORM - объектно-реляционная модель](mark/00-orm.markdown)
1. [Типы полей](mark/02-orm-types.markdown)
1. [Метаинформация о структуре модели](mark/03-orm-meta.markdown)
1. [Миграции](mark/04-migration.markdown)
1. [Коннект к базе](mark/09-connect.markdown)
1. [Шаблонизатор (*DESTROYED*)](mark/10-view.markdown)
1. [Шаблонизатор (код Javascript) (*DESTROYED*)](mark/11-view-js.markdown)
1. [Язык шаблонизатора R::View](mark/11-view-lang.markdown)
1. [Построитель лексико-грамматико-семантических анализаторов](mark/12-syntax.markdown)
1. [Язык *Серебряна* (лат. Argentum)](mark/13-ag.markdown)
1. [Сценарии пользователя](mark/15-users-scenaries.markdown)
1. [Формы](mark/20-form.markdown)
1. [Поля ввода в формах](mark/21-form-input.markdown)
1. [Теги в формах](mark/22-form-tag.markdown)
1. [Пейджеры](mark/23-pages.markdown)
1. [Роли](mark/24-roles.markdown)
1. [Главный класс приложения R::App](mark/30-app.markdown)
1. [Вспомогательные функции](mark/31-perl.markdown)
1. [Файлы](mark/32-file.markdown)
1. [Процессы](mark/33-process.markdown)
1. [Сервера](mark/34-serverside.markdown)
1. [35-http](mark/35-http.markdown)
1. [Шива](mark/36-shiva.markdown)
1. [Кэши](mark/37-cache.markdown)
1. [Сессии](mark/38-session.markdown)
1. [Очереди заданий](mark/39-queue.markdown)
1. [Трейсбэк](mark/40-raise.markdown)
1. [R::Html и R::Htmlquery](mark/41-html.markdown)
1. [css-фреймворк](mark/60-css.markdown)
1. [Coro](mark/91-coro.markdown)

