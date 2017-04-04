# Шаблонизатор

## Инициализация фреймворка

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

# добавим логирование
$app->man->conf;

my $res;



```

## Присваивание блоков кода html

```perl

$res = $app->view->create(q{<% SET html %>6<% a+1 %>7<% END %>$html$html}, { a=>10 });

$res;	# 61176117

```

## Блоки

Шаблон компилируется в пакет perl. А блоки - в методы этого пакета, которые тут же вызываются.
В наследуемом шаблоне их можно переопределить.

```perl

$res = $app->view->create(q{
	<html>
	<head>
		<title><% block title %>Название страницы<% end %></title>
	</head>
	<body>
		<% block content %>тело страницы<% end %>
	</body>
	</html>
}, {}, "ex/layout.html");

$res;		#~ Название страницы
$res;		#~ тело страницы

$res = $app->view->create(q{
	<% inherits "ex/layout.html" %>
	<% block title %>Индексная страница<% end %>
	<% block content %>
		<h1>Индекс</h1>
		<p>Приветствуем!</p>
	<% end %>
}, {}, "ex/index.html");

$res;		#!~ Название страницы
$res;		#!~ тело страницы

$res;		#~ <title>Индексная страница</title>
$res;		#~ <p>Приветствуем!</p>

```

## Фильтры

Все фильтры являются методами класса `R::View::Filter`.
Фильтр заменяет сгенерированный шаблоном текст.

### Как написать свой фильтр

Фильтр получает сгенерированный текст, а возвращают - переформатированный.

```perl

$res = $app->view->create(q{
	<% call
		sub mystrip a class R::View::Filter
			app.perl.replace a, "\s+"! do then " "
		end
	%>

	<% filter mystrip %>
		<input 
			type=text
			value="10"
		>
	<% end %>
}, {}, "ex/filter.html");

$res;			#~ <input type=text value="10" >

```

### Стандартные фильтры

TODO...

## Метафильтры

Все фильтры являются методами класса `R::View::Metafilter`.
Метафильтры выполняются после загрузки классов и изменяют сам код шаблона.

## Как написать свой метафильтр

В метафильтр передаётся массив из чередующихся элементов: текст, код perl.
Фильтр может модифицировать его.

```perl

$app->view->create(q{
	<% call
		sub mystrip html, prev_html class R::View::Metafilter
			app.perl.replace html, "\s+"! do then " "
		end
	%>
});


```

Метафильтер должен быть уже скомпилирован и подгружен компиллятором на момент компилляции шаблона.

```perl

$res = $app->view->create(q{
	<% metafilter mystrip %>
		<input 
			type=text
			value="10"
		>
	<% end %>
}, {}, "ex/superfilter.html");

$res;			#~ <input type=text value="10" >

```

### Стандартные метафильтры

Это `sprite`, ``. Они подключаются по умолчанию.

## Гиперфильтры

Не реализовано.

## Классы

Мы используем метод `parse`, т.к. он только компилит.

```perl

$res = $app->view->parse(q{
	<% CLASS ExClass 
	
		our $TEST
	
		$TEST = 10;
	
	%>
	
	<% END %>
});

eval($res);

$ExClass::TEST;			## undef

```

Тело класса оборачивается в метод `__INIT__CLASS__`. Он стартует автоматически после загрузки всех классов.

```perl

ExClass->__INIT__CLASS__;

$ExClass::TEST;			# 10

```

## Объекты

Объект, это класс тут же выполняющий конструктор и возвращающий свой экземпляр. Он бывает полезен при создании форм и пейджеров.

```perl

$res = $app->view->create(q{<% Let
	class SuperObject
		sub new a then "hi!" . a
	end
%><% OBJECT ExObject INHERITS SuperObject WITH " world!"
%><% END %>});

$res;		# hi! world!

```

Такой класс ничем не отличается от обычного класса. Порождать другие объекты от него можно так же как и от других.

```perl

$res = $app->view->create(q{<% new ExObject(" sea!") %>});

$res;		# hi! sea!

```

Без параметров тоже работает:

```perl

$res = $app->view->create(q{<% OBJECT ExObject2 INHERITS SuperObject
		# ну тут какой-то дополнительный код
		1
	%><% END %>});

$res;		# hi!
