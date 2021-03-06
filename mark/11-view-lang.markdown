# Язык шаблонизатора R::View (*DESTROYED*)

## Инициализация фреймворка

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

$app->man->conf;

my $res;


```

## Операторы

## Выражения

```perl

$res = $app->view->create(q{});

$res;		# 

$res = $app->view->create(q{123});

$res;		# 123

$res = $app->view->create(q{<% GET 5 + 6 * 10 - 12 %>});

$res;	# 53


$res = $app->view->create(q{<% GET (5 + (6)) * 10 %>});

$res;	# 110

$res = $app->view->create(q{<% GET - 6 %>});

$res;	# -6

$res = $app->view->create(q{<% GET 5 + - 6 %>});

$res;	# -1

$res = $app->view->create(q{<% GET -5+(- 6)*10 %>});

$res;	# -65

```

## Переменные и цифры

```perl

$res = $app->view->create(q{<% GET a=10; a %>});

$res;	# 10

$res = $app->view->create(q{<% GET a=1_000_000.65; a %>});

$res;	# 1000000.65

```

## Строки

Строки допускают escape-последовательности:

```perl

$res = $app->view->create(q{<% GET "\r\n" %>});

$res;	# \r\n

```

Строки могут быть многострочными:

```perl

$res = $app->view->create(q{<% GET "1
2" 
%>});

$res;	# 1\n2

```

В строках возможна интерполяция переменных.

```perl

$res = $app->view->create(q{<% GET a=10; "_$a\_$a:" %>});

$res;	# _10_10:

```

Доступ к элементу хэша:

```perl

$res = $app->view->create(q{<% GET x={a=>{b=>5}}; "$x:a:b" %>});

$res;	# 5

```

Вызов методов:

```perl

$res = $app->view->create(q{<% GET "$app.ini:site:name" %>});

$res;	# Rubin Forms
exit;
```

## Методы

```perl

$res = $app->view->create(q{<% GET
	sub plus a, b then a + b
	sub minus a, b
		a - b
	end
	plus 10, minus 10, 5
%>});

$res;	# 15

```

## Массивы

```perl

$res = $app->view->create(q{<% GET 
	c = [
		1,
		2,
	]
	@a = 10, @c, 11
	@a ,= 15, 12
	"," join @a
%>});

$res;	# 10,1,2,11,15,12

```

## Хэши

```perl

$res = $app->view->create(q{<% RAW
	@c = (
		1=>2
	)
	%x = (10, @c, 11); ", " join sort a cmp b from pairmap "$a=>$b" from %x
%>});

$res;	# 10=>1, 2=>11


```

## Условия

```perl

$res = $app->view->create(q{<% GET
	if a = 10 then a+=20
	if 0 then a++ else a--
	if a
		a
	elseif 1
		"не дойдёт"
	else
		0
	end
%>});

$res;	# 29

```

Условия могут быть в выражениях:

```perl

$res = $app->view->create(q{<% GET
	a = join ", ", if 1<0 then 1 elseif 1<-1 then 2 else 3 end, if 1 then 1
	b = join(", ", if 1<0 then 1 elseif 1<-1 then 2 else 3 end, if 1 then 2)
	"$a: $b"
%>});

$res;	# 3, 1: 3, 2

```

## Циклы

### for =

`for` следующего вида перебирает значения указанные за =. Напомню, что в `perl` массивы являются просто набором значений.

```perl

$res = $app->view->create(q{<% GET
	a = 1
	for i = 2,3 then a *= i
	a
%>});

$res;		# 6

```

Иногда требуется знать индекс значения, например, чтобы получить доступ к массиву:

```perl

$res = $app->view->create(q{<% GET
	a = 0
	for i, idx = 2,3 then a += i-idx
	a
%>});

$res;		# 4


```

### for in

`for i in x` разыменовывает ссылку на массив `x`. Он полностью аналогичен циклу `for i = @x`

```perl

$res = $app->view->create(q{<% GET
	a = 0
	b = [5,6]
	for i, idx in [2,3] then a += b[idx]-i
	a
%>});

$res;		# 6

```

### for of

Этот `for` предназначен для обхода хэшей.

```perl

$res = $app->view->create(q{<% GET
	hash = {a=>1, b=>2, c=>3}
	for key of hash then push @a, key
	join ", ", sort(@a)
%>});

$res;		# a, b, c

```

Но хотелось бы получить и значения.

```perl

$res = $app->view->create(q{<% GET
	hash = {a=>1, b=>2, c=>3}
	for key, val of hash then push @a, "$key=$val"
	join ", ", sort(@a)
%>});

$res;		# a=1, b=2, c=3

```

А с индексом, так вообще замечательно:

```perl

$res = $app->view->create(q{<% GET
	hash = {a=>1, b=>2, c=>3}
	%reverse = reverse %hash
	for key, val, idx of hash then push @a, reverse{idx}
	join ", ", sort(@a)
%>});

$res;		# , a, b

```

### while

```perl

$res = $app->view->create(q{<% GET
	i = 10
	a = ""
	while i>0
		a .= --i
	end
	a
%>});

$res;	# 9876543210

```

То же, но в одну строку:

```perl

$res = $app->view->create(q{<% GET
	i = 10;	a = "";	while i>0 then a .= --i end; a
%>});

$res;	# 9876543210

```

### repeat - until

```perl

$res = $app->view->create(q{<% GET
	i = 10
	a = ""
	repeat
		a .= --i
	until i==0
	a
%>});

$res;	# 9876543210



```

## Конвееры

### map

Получаем квадраты чисел от 1 до 3.

```perl

$res = $app->view->create(q{<% GET
	join ", ", map a*a from 1 .. 3
%>});

$res;	# 1, 4, 9

```

### grep

Отберём только числа больше 6.

```perl

$res = $app->view->create(q{<% GET
	join ", ", grep a>6 from 1, 7, 6, 5, 10
%>});

$res;	# 7, 10

```

### reduce

Суммируем все числа.

```perl

$res = $app->view->create(q{<% GET
	reduce a+b from 1, 2, 3
%>});

$res;	# 6

```

### sort

Отсортируем.

```perl

$res = $app->view->create(q{<% GET
	join ", ", map a:a from sort a:a <=> b:a from {a=>4}, {a=>2}, {a=>5}
%>});

$res;	# 2, 4, 5

```

### pairmap

```perl

$res = $app->view->create(q{<% GET
	join ", ", pairmap a:a . b:a from sort a:a <=> b:a from {a=>4}, {a=>2}, {a=>5}
%>});

$res;	# 24, 5

```

### Особенности

В отличие от аналогичных конвертеров в perl здесь они не модифицируют исходный массив.

```perl

$res = $app->view->create(q{<% GET
	array = [-1,-2,-3]
	map map a from 3 from @array
	join ", ", @array
%>});

$res;	# -1, -2, -3



```

## Функции

Однострочная функция:

```perl

$res = $app->view->create(q{<% GET
	sub inline then "Unicorn" 
	inline()
%>});

$res;	# Unicorn

```

Переопреелим функцию inline:

```perl

$res = $app->view->create(q{<% GET
	sub inline then "Capricorn"
	inline()
%>});

$res;	# Capricorn

```

Многострочная функция:

```perl

$res = $app->view->create(q{<% GET
	sub inlines
		"Lines"
	end
	inlines()
%>});

$res;	# Lines

```

Функция с параметрами:

```perl

$res = $app->view->create(q{<% GET
	sub plus a, b then a+b
	plus(10, 3)
%>});

$res;	# 13

```

Параметр "*" обозначает, что хэш нужно разименовать, тоесть его ключи станут локальными переменными функции:

```perl

$res = $app->view->create(q{<% GET
	sub plus a,* then a+b-c
	plus(10, {b=>5, c=>1})
%>});

$res;	# 14

```

### Вызовы функций

При вызове функций и методов можно опустить лишние скобки.

```perl

$res = $app->view->create(q{<% GET
	sub plus a,b then a+b
	plus 10, 12
%>});

$res;	# 22

$res = $app->view->create(q{<% GET
	sub minus a,b then a-b
	plus 10, minus 3, 2
%>});

$res;	# 11

```

Ну и в скобках:

```perl

$res = $app->view->create(q{<% GET
	plus(10, minus 3, 2) + 1
%>});

$res;	# 12

```

### Блок

Блок, это анонимная функция.
Внутри блока можно использовать переменные функции в которой указан блок.

```perl

$res = $app->view->create(q{<% GET
	sub repeats number, subroutine
		ret = nothing
		for i = 1 .. number then ret = subroutine->(i)
		ret
	end
	a = 6
	repeats 10 do num
		a += 1
	end
%>});

$res;	# 16

```

**Внимание!** Блок удерживает ссылку на локальные переменные функции. Это значит, что память не очиститься и деструкторы на них не сработают.

```perl

$res = $app->view->create(q{<% GET
	sub run subroutine then subroutine->()
	a = 6
	run do
		a + 1
	end
%>});

$res;	# 7

```

### Замыкания

Ещё одно интересное свойство блоков заключается в том, что они являются замыканиями.

Это происходят потому, что локальные переменные любой функции хранятся в ассоциативном массиве, который создаётся при каждом выполнении функции.

Когда Вы создаёте блок он замыкает все локальные переменные функции. А при следующем вызове функции, в которой блок объявлен, хэш уже будет другим и блок замкнёт его.

```perl

$res = $app->view->create(q{<% GET
	sub gen x, a
		push @x do then a
	end
	
	x = []
	for i = 1..6 then gen x, i
	
	join ", ", map a->() from @x
%>});

$res;	# 1, 2, 3, 4, 5, 6

```

Это означает, что можно не использовать функцию `closure`, если только в одной функции Вы не используете несколько блоков.

```perl

$res = $app->view->create(q{<% GET
	sub gen x, a
		push @x do then a += 1; ()
		push @x do then a
	end
	
	x = []
	for i = 1..3 then gen x, i
	
	join ", ", map a->() from @x
%>});

$res;	# 2, 3, 4

```

Как мы видим, блоки созданные в одном и том же вызове функции разделяют одни и те же локальные переменные.

### Очистка локальных переменных блока или функции



## Исключения

Вызвать исключительную ситуацию можно обычным die.

А перехватить её - с помощью try ... catch:

```perl

$res = $app->view->create(q{<% GET
	try
		throw "Ещё!"
	catch e
		e
	end
%>});

$res;	#~ Ещё!

```

Обратите внимание, что try ... catch возвращает значение.

```perl

$res = $app->view->create(q{<% GET
	class MyException inherits R::Raise	end
	try
		throw new MyException("ну так...")
	catch e as MyException
		e.message
	catch
		"не так!"
	end
%>});

$res;	# ну так...

```

## Комментарии

Комментарии однострочные. И начинаются на `#` или `REM`.

```perl

$res = $app->view->create(q{<% GET
	rem комментарий0
	sub mysub1 then 6 rem комментарий sub1
	sub mysub rem комментарий sub2
		a = 1 rem комментарий1
		if 1 then return 3  rem комментарий2
	end
	rem комментарий3
	mysub1() . mysub()
%>});

$res;	# 63


```

## Классы

1. Классы не могут быть вложенными.
1. Классы имеют только методы.
1. В методах есть переменная self обозначающая оъект, или класс, если метод запущен от класса.
1. super - обозначает суперкласс.
1. множественное наследование при поиске метода использует обход слева-направо вширину (perl: use mro), а не в глубину, как это принято в perl по умолчанию.
1. метод new сразу создаёт новый объект, независимо от того: запущен он из класса или нет.

```perl

$res = $app->view->create(q{<% GET
	class Animal
		sub new then self
		sub name then "живность"
	end
	
	class Cat inherits Animal
	end
	
	class Ret inherits Animal
		sub name then super.name . " крыса"
	end
	
	class Dog inherits Cat, Ret
	end

	new Dog.name
%>});

$res;	# живность крыса

```

Как Вы можете убедиться метод name вначале ищется в Dog, затем в Cat, а затем в Ret. В perl по-умолчанию принят обход: Dog, Cat, Animal, Ret.	

### super

* `super` - если вызван в `new`, то вызывает конструктор со всеми параметрами и присваивает результат self. Если же в методе с другим названием, то вызывает этот метод из суперкласса со всеми параметрами, если параметры не указаны
* `super.method` - вызывает метод суперкласса

```perl

$res = $app->view->create(q{<% GET
	class AClass
		sub new a then me:a = a; me
	end
	
	class BClass inherits AClass
		sub news a then cls=me; me=super.new; cls . ref me
	end
	
	BClass.news
%>});

$res;	# BClassBClass

```

### Класс возвращает себя

```perl

$res = $app->view->create(q{<% GET
	class SelfyClass
	end
%>});

$res;	# SelfyClass

```

### Объявление метода из другого класса

```perl

$res = $app->view->create(q{<% GET
	class TenClass
	end
	
	sub ten class TenClass then 10
	
	TenClass.ten
%>});

$res;	# 10

```

### Код внутри класса

Код внутри класса оформляется в виде метода `__INIT__CLASS__` и исполняется после загрузки всех классов.

```perl

$res = $app->view->parse(q{<% GET
	class CaseClass
	
		our $A
		$A = 10
	
	end
%>});

eval($res);

$CaseClass::A;		## undef

CaseClass->__INIT__CLASS__;

$CaseClass::A;		# 10

```

`app->view->create` отслеживает появление новых классов и сразу же их выполняет. А вот при загрузке шаблонов за это отвечает `app->view->load`.

```perl

$res = $app->view->create(q{<% GET
	class CaseClass2
	
		our $A
		$A = 10
		
	end
%>});

$CaseClass2::A;		# 10


```

### CLASS_INIT

В классах есть ещё конструктор `CLASS_INIT`. Он так же выполняется после полной загрузки классов, если есть и наследуется.

```perl

$res = $app->view->create(q{<% GET
	class ExSuperClass
		our $A
		sub CLASS_INIT
			$A++
		end
	end
	
	class ExInitClass inherits ExSuperClass
	end
%>});

$ExSuperClass::A;		# 2

```

### Объекты

Объект, это класс, который тут же выполняет конструктор и возвращает объект. 

```perl


$res = $app->view->create(q{<% GET
	class SuperObject
		sub new a then "hi!" . a
	end
	object ExObject inherits SuperObject with " world!"
	end
%>});

$res;		# hi! world!

```

Такой класс ничем не отличается от обычного класса. Порождать другие объекты от него можно так же как и от других.

```perl

$res = $app->view->create(q{<%
	new ExObject(" sea!")
%>});

$res;		# hi! sea!

```

Без параметров тоже работает:

```perl

$res = $app->view->create(q{<%
	object ExObject2 inherits SuperObject end
%>});

$res;		# hi!

```

### Модули

Модуль является вместилищем классов. Все классы начинаются с имени модуля.

```perl

$res = $app->view->create(q{<% GET
	module MyModule
		class Alef
		end
		
		class Bounty::Bottom
		end
		
		sub ten then 10
	end
%>});

```

Модуль возвращает себя и является одноимённым классом.

```perl

$res;								# MyModule

```

Наследует `R::View::Module`.

```perl

$res->isa("R::View::Module");		# 1

```

А так же имеет методы, возвращающие обёрнутые им классы.

```perl

$res->alef;				# MyModule::Alef
$res->bountyBottom;		# MyModule::Bounty::Bottom

```

Все подпрограммы в модуле являются его методами.

```perl

$res->ten;				# 10

```

Если в модуле указан `inherits` то это родитель для всех классов модуля у которых не указан `inherits`.

```perl

$res = $app->view->create(q{<% GET
	module MyModuleInherits inherits MyModule::Alef
		class Beta
		end
		
		class Themphira inherits MyModule::Bounty::Bottom
		end
		
		class Sixta
		end
	end
%>});

$res->isa("MyModule::Alef");							# 

$res->beta;												# MyModuleInherits::Beta

$res->beta->isa("MyModule::Alef");						# 1
$res->sixta->isa("MyModule::Alef");						# 1

$res->themphira->isa("MyModule::Alef");					# 
$res->themphira->isa("MyModule::Bounty::Bottom");		# 1

```

### Дважды класс или модуль описать нельзя

```perl


eval { $app->view->create(q{<% GET
	module MyModule1
	end
	
	class MyModule1
	end
%>}) };

$@;		#~ дважды объявлен класс MyModule1

```

Используйте `sub myName class MyClass`.

### Перегрузка операторов

Для перегрузки операторов оператор указывается в качестве имени подпрограммы. Если он является идентификатором (bool, neg, lt), то он берётся в кавычки.

```perl

$res = $app->view->create(q{<% GET
	class PlusAnimal
		sub new n then me:n = n; me
		sub "" then "животное" . me:n
		sub + other then "$self+$other"
		sub "neg" then "~" . self
	end
	
	a = new PlusAnimal(1)
	b = new PlusAnimal(2)
	
	a+(-b)
%>});

$res;		# животное1+~животное2



```

### Декораторы

TODO

Декоратор представляют собой функцию, которая вызывается после загрузки кода и получает `glob` на метод указанный после него. 
Получить функцию можно префиксом `\&`, a установить префиксом `*`.

Декоратор предваряется `@` и начинается с большой буквы. Этим он отличается от 

Возвращать декоратор может что угодно.

```perl


# $res = $app->view->create(q{<% GET
	# class Math			
		# sub dec fn, decrement
			# *fn = closure \&fname, decrement do code, decrement, selfy
				# selfy:number -= decrement
				# code->()
			# end
		# end
	# end
	# class ExamMath
		# sub new number then me:number = number; me
		
		# +Math.dec 40
		# sub test_dec then me:number
		
	# end
	# exam = new ExamMath(10)
	# exam.test_dec
# %>});

# $res;		# -30

```

## Начало

`begin` выполняется при загрузке шаблона.

Его локальные переменные не совпадают с локальными переменными пространства в котором он указан.

```perl

$res = $app->view->create(q{<% GET
	a = our $A

	begin
		our($A) = 20
	end
	
	a
%>});

$res;	# 20


```

## javascript

### def

Методы начинающиеся на `def` транслируются в **javascript**.

```perl

$res = $app->view->create(q{<% LET
	class EmeraldJs
		#def emerald x, y
		#end
	end
%>});

#$app->js->stringify;		#~ function emerald\(x, y\)

```

### on

Методы начинающиеся на `on` обрабатывают различные события формы и её элементов.
Для захвата тегов не в форме, а в документе используйте `:root` и пробел.
Для установки событий используются `:событие`.
В событиях работы с клавишами (`input`, `keyup` и т.д.) в скобках можно указывать код клавиши.

```perl

$res = $app->view->create(q{<% GET
	class ClickJs inherits RubinForm
		sub fields
			self.add("name" => "line").placeholder("Имя")
		end
	
		# устанвливаем обработку 13-го символа
		#on "name:keyup(13)"
		#	self.name.val( self.name.val()+"-ln!" )
		#end
		
		# устанавливаем обработку нажатия на метках формы с классом `у`
		#on "label.y:click" e, label
		#	label.text("stop!")
		#end
		
		# обработчик сообщения ClickJs.upgrade по вебсокету, где ClickJs - имя формы
		#on upgrade name
		#	self.name.val( name )
		#end
	end
%>});
