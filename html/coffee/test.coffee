CTest.category "Расширения встроенных классов" 

new CTest 'key-CFunction-implements', """
`implements Class` - переписывает методы из указанного класса
""", ->
	class ExImplemented
		@implements CNode, constructor: 'const1'

	ex = new ExImplemented()
	ex.const1 document.createTextNode "ps"
	@is "ps", ex.val()
	
	class ExImplemented
		@implements_own CNode
	
	ex = new ExImplemented
	@ok ex.text
	@ok not ex.wrap


CTest.category "эффекты"

new CTest 'key-CEffect-fadeIn', """
`fadeIn` - эффект проявления элемента

Основан на прозрачности. Используется как: `@morph 'fadeIn'`

См. #fadeOut
""", """
<div id=$name class=test-square></div>
""", ->
	@count 1
	@w().on 'click', -> @morph effect: 'fadeIn', timeout: 'fast'
	@w().morph effect: 'fadeIn', timeout: 'fast', end: => @ok 1


new CTest 'key-CEffect-fadeOut', """
`fadeOut` - эффект затухания элемента

Основан на прозрачности. Используется как: `@morph 'fadeOut'`

См. #fadeOut
""", """
<div id=$name class=test-square></div>
""", ->
	@count 1
	self = this
	@w().on 'click', -> @morph effect: 'fadeOut', timeout: 'fast', end: -> @show()
	@w().morph effect: 'fadeOut', timeout: 'fast', end: -> @show(); self.ok 1


new CTest 'key-CEffect-show', """
`show` - эффект появления элемента

Основан на размере шрифта и ширине. Используется как: `@morph 'show'`

См. #fadeOut
""", """
<div id=$name class=test-square>Show is very</div>
""", ->
	@count 1
	@w().on 'click', -> @morph effect: 'show', timeout: 'fast'
	@w().morph effect: 'show', timeout: 'fast', end: => @ok 1


new CTest 'key-CEffect-hide', """
`hide` - эффект ищезания элемента

Основан на прозрачности. Используется как: `@morph 'hide'`

См. #fadeOut
""", """
<div id=$name class=test-square>Hide is very</div>
""", ->
	@count 1
	self = this
	@w().on 'click', -> @morph effect: 'hide', timeout: 'fast', end: -> @show()
	@w().morph effect: 'hide', timeout: 'fast', end: -> @show(); self.ok 1


	
new CTest 'key-CEffect-slideUp', """
`slideUp` - эффект развёртывания элемента

Основан на высоте. Используется как: `@morph 'slideUp'`

См. #fadeOut
""", """
<div id=$name class=test-square>slideUp is very</div>
""", ->
	@count 1
	@w().on 'click', -> @morph effect: 'slideUp', timeout: 'fast'
	@w().morph effect: 'slideUp', timeout: 'fast', end: => @ok 1


new CTest 'key-CEffect-slideDown', """
`slideDown` - эффект свёртывания элемента

Основан на высоте. Используется как: `@morph 'slideDown'`

См. #fadeOut
""", """
<div id=$name class=test-square>slideDown is very</div>
""", ->
	@count 1
	self = this
	@w().on 'click', -> @morph effect: 'slideDown', timeout: 'fast', end: -> @timeout 500, -> @show()
	@w().morph effect: 'slideDown', timeout: 'fast', end: -> self.ok 1 ; @timeout 500, -> @show()

	

CTest.category "потоки"

new CTest "cls-CStream", """
`CStream` - класс реактивного программирования (FRP)

Ссылки:

1. 

""", """
#%name-plus, #%name-minus, #%name-result { text-align: center; display: inline-block; width: 100px; border: solid 1px orange; color: white}

#%name-plus, #%name-minus { background: brown; cursor: pointer}

#%name-result { background: SlateGrey; }
""", """
<div id=$name-plus>1</div>
<div id=$name-minus>-1</div>
<div id=$name-result></div>
""", ->
	plus = @w("plus").stream("click").map(1)
	minus = @w("minus").stream("click").map(-1)
	
	merge = plus.merge minus
	result = merge.reduce 5, (a, b) -> a + b
	
	result.assign @w("result"), "text"
	
	@w("plus").fire("click")
	@is "6", @w("result").text()
	
	@w("minus").fire("click")
	@is "5", @w("result").text()
	
	minus.emit()
	@is "4", @w("result").text()

	
new CTest "obj-CStream-meta", """
`meta emitFunction, [param]` - создаёт новое звено потока

Метод `meta` создаёт экземпляр `CStream`, добавляет его в свойство `@fork`, устанавливает ему функцию реагирующую на данные, движущиеся по потоку и параметры, и возвращает.

См. #maps, #mapAll
""", ->
	@count 4
	self = this
	
	(s = new CStream)
	.meta (channel) -> self.is channel.args[0], 30 ; channel.src = hi: "hello!"; channel.args = [10, 20]; @send channel
	.then (x, y) -> self.is @hi, "hello!"; self.is x, 10 ; self.is y, 20
	
	s.emit 30
	
	
new CTest "obj-CStream-emitter", """
`emitter` - возвращает замыкание с этим потоком, которое используется как слушатель

Аргументы переданные при вызове замыкания передаются далее по потоку, так же как и объект вызвавший замыкание.
От имени этого объекта и вызываются все функции установленные в потоке

""", ->
	@count 1

	stream = new CStream
	fn = stream.emitter()
	stream.then (val) -> @is val, 6
	fn.call this, 6


new CTest "obj-CStream-map", """
`map fn|arg, args...` - замещает передающиеся по потоку аргументы на значение возвращённое функцией fn, либо устанавливает аргументы

См. #maps, #mapAll
""", ->
	@count 4
	(stream = new CStream).map(10, 12).then (arg1, arg2) => @is arg1, 10 ; @is arg2, 12
	stream.emit()
	(stream = new CStream).map((-> 13), 12).then((arg1) => @is arg1, 13 ; @is arguments.length, 1)
	stream.emit 20, 30


new CTest "obj-CStream-flatMap", """
`flatMap fn` - заменяет поток на возвращённый функцией fn

См. #merge, #combine
""", ->
	self = this
	@count 2
	
	CStream::exMap = (f) ->
		@flatMap (x) ->	CStream.unit f(x)

	CStream::exFilter = (f) ->
		@flatMap (x) -> if f(x) then CStream.unit(x) else CStream.nothing()

	(stream = new CStream).exMap((x)-> x+3).then (v)-> @is v, 13
	stream.emits this, 10
	
	(stream = new CStream).exFilter((x)-> x==10).then (v)-> @is v, 10
	stream.emits this, 10
	
	(stream = new CStream).exFilter((x)-> x!=10).then (v)-> @ok false
	stream.emits this, 10
	

new CTest "obj-CStream-combine", """
`combine streams..., [fn]` - комбинирует несколько потоков в один

- fn args, channel - функция для комбинации. Получает массив [{src: this, args: аргументы}...] и последние пришедшие данные (channel), которые есть и в массиве. Должна вернуть {src: ..., args: ...}

См. #merge, #zip
""", ->
	@count 2

	s1 = new CStream()
	s2 = new CStream()
	s3 = new CStream()
	
	s = s1.combine s2, s3
	k = s1.combine s2, s3, (args, channel) -> src: channel.src, args: for ch in args then ch.args[1]
	
	s.then (x...) -> @is String(x), "10,20,30"
	k.then (x...) -> @is String(x), "0,1,2"
	
	s1.emit 10, 0
	s2.emit 20, 1
	s3.emits this, 30, 2


new CTest "obj-CStream-zip", """
`zip n, [fn]` - собирает n отправок в массив, который и отправляет дальше

- n - может быть числом, функцией или строкой. Если это число, то собирает n отправок в массив
- - Если функция, то отправляет 
- - Если строка, то собирает отправки в течение указанного времени, после прихода первой посылки
- fn args, channel - функция для комбинации. Получает массив [{src: this, args: аргументы}...] и последние пришедшие данные (channel), которые есть и в массиве. Должна вернуть {src: ..., args: ...}

См. #merge, #combine
""", ->
	@count 6
	
	s = new CStream
	s.zip(2).then (x, y) -> @is x, 10 ; @is y, 20
	s.zip((args) -> args.length == 3).then (x, y, z) -> @is x, 10 ; @is y, 20 ; @is z, 6
	s.zip("30ms").then (args...) -> @is String(args), "10,20,6"
	
	(x = CStream.sleep(10)).then -> s.emits this, 6
	x.emits this
	s.emit 10
	s.emits this, 20


new CTest "obj-CStream-repeat", """
`repeat n, [ms], [map]` - повторяет данные n раз через ms миллисекунд

- n - номер
- n - объект - должен содержать from, to, by. from и by - необязательны. Заполняются 0-м и 1-й соотвестственно
- ms - интервал в миллисекундах между повторениями
- map - если положителен, то итератор будет мапиться

См. #serial, #from
""", ->
	# @count 6
	
	# count = 0
	
	# s = CStream.unit 10
	# s.repeat(3).then (x) -> count += x
	# s.emit()
	# @is count, 30
	
	# s.repeat(3, 13).then (x) -> count -= x; @is x, 10
	# s.emits this
	# @is count, 20
	
	# count = 0
	# s.repeat(from: 10, to: 5, by: -3, 13).then -> count++
	# .filter -> count == 2
	# .then -> @is count, 2


new CTest "obj-CStream-serial", """
`serial serial, [ms]` - отправляет элементы серии через ms миллисекунд

- serial - номер
- serial - объект - должен содержать from, to, by. from и by - необязательны. Заполняются 0-м и 1-й соотвестственно. Аналог #repeat с установленным параметром ''map''
- serial - массив - отправляет по одному
- ms - интервал в миллисекундах между отправками

См. #repeat, #from
""", ->
	CStream.serial([10, 20]).then (x) -> 
	

new CTest "obj-CStream-from", """
`from n, [ms]` - повторяет данные n раз через ms миллисекунд

- n - массив - отправляет элементы один за другим
- n - объект - отправляет каждое ключ-значение в виде массива [key, val] 
- ms - интервал в миллисекундах между отправками

См. #repeat, #serial
""", ->
	CStream.from([10, 20]).then (x) -> 

	

CTest.category "модель"

new CTest "cls-CModel", """
`CModel properties, compares` - модель имеет свойства и вызывает обработчики событий, если свойство изменилось

Так же модель может обновить свойство, если его запросили

У всех экземпляров класса CWidget или его наследников есть свойство model, которое представляет главную модель

- properties - ключ-значения, где ключ соответствуют названию свойства модели, а значение - начальному значению этого свойства
- compares - функции сравнения. Когда приходит новое значение, то оно сравнивается со старым - если оно не изменилось, то и обработчики не изменяются. Если функция сравнения не указано, то используется жёсткое сравнение javascript (===)

См. #CRouter
""", """
<div id=$name ctype=form>
	<p>Имя: <input id=$name-input model=name>
	<span id=$name-span model=name></span><br>
	То же имя: <input id=$name-i2 model=name></p>
	<p>Фамилия: <input id=$name-family model=family></p>
	<p>Имя и фамилия: <span id=$name-fio model=fullName></span></p>
</div>
""", ->
	w = @w()
	@w("input").val "Hello"
	@w("input").fire "keyup"

	@is @w("span").text(), "Hello"
	@is @w("i2").text(), "Hello"

	@is @w("fio").text(), ""

	w.model.compute "fullName", (name, family) -> name + ' ' + family

	w.model.family "World!"
	@is w.model.family(), "World!"

	@is @w("family").text(), "World!"
	@is @w("fio").text(), "Hello World!"

	
new CTest "obj-CModel-compute", """
`compute key, fn|options` - создаёт вычислимое свойство на модели или заменяет его

- key - имя свойства
- fn - функция чтения из свойства
- options
- - slave - зависимая от других свойств функция. Её параметры должны быть именами свойств от которых она зависит
- - master - функция записи в свойство
- - cmp - функция сравнения
- - val - начальное значение

См. #set, #del
""", """
<div id=$name ctype=form>
	<input id=$name-name model=name>
	<input id=$name-family model=family>
	<input id=$name-fullname model=fullname>
</div>
""", ->
	@w()

	model = CRoot.model
	.compute 'fullname',
		slave: (name, family) -> name + ' ' + family
		master: (val, old, key) -> match = val.match ///^ (\S+) \s+ (.+) ///; @name match[1]; @family match[2]
		val: "abc"
	.name 'Юля'
	.family 'Малышева'

	@is @w("fullname").text(), 'Юля Малышева'
	@w("fullname").text('Вадим Дубровный').fire 'keyup'
	@is @w("name").text(), 'Вадим'
	@is @w("family").text(), 'Дубровный'
	
	
new CTest "obj-CModel-set", """
`set key, [val], [cmp]` - создаёт или заменяет свойство на модели

- key - имя свойства
- val - начальное значение
- cmp - функция сравнения

См. #compute, #del, #has
""", ->
	model = CRoot.model
	@ok not model.has "test_key"
	model.set "test_key", "abc"
	@ok model.has "test_key"


new CTest "obj-CModel-has", """
`has key` - определяет, есть ли в модели свойство key

- key - имя свойства

См. #set, #compute
""", ->
	model = CRoot.model.set 'test_has'
	@ok not model.has "test_key-xxx"
	@ok model.has "test_has" # установлен в тесте obj-CModel-set
	

new CTest "obj-CModel-on", """
`on key, observe` - ставит обозреватель на свойство key

- key - имя свойства
- observe - функция-обозреватель

См. #off, #at
""", ->
	@count 3
	CRoot.model.set 'test_on', "abc"
	.on 'test_on', (val, old, key) => @is val, "a"; @is old, "abc"; @is key, "test_on"
	.test_on "a"
	
	
new CTest "obj-CModel-off", """
`off key, [observe]` - удаляет обозреватель или все обозреватели со свойства key

- key - имя свойства
- observe - функция-обозреватель или свойство _belong обозревателя (не может быть функцией)

См. #off, #at
""", ->
	model = CRoot.model.set 'test_off'
	model.on "test_off", fn = ->
	@is model._on.test_off[0], fn
	model.off "test_off", fn
	@ok not model._on.test_off
	
	model.on "test_off", fn = ->
	fn._belong = 'что-то'
	model.off "test_off", 'что-то'
	@ok not model._on.test_off
	

new CTest "obj-CModel-at", """
`at key, observe` - ставит обозреватель запроса на свойство key

В отличие от #on обозреватель сработает при чтении из свойства

- key - имя свойства
- observe - функция-обозреватель

См. #off, #at
""", ->
	@count 3
	CRoot.model.set 'test_at', 'a'
	.at 'test_at', (key, val) => @is key, "test_at"; @is val, "a"; "b"
	@is CRoot.model.test_at(), "b"
	
	
new CTest "obj-CModel-un", """
`un key, [observe]` - удаляет обозреватель запроса или все обозреватели со свойства key

- key - имя свойства
- observe - функция-обозреватель или свойство _belong обозревателя (не может быть функцией)

См. #off, #at
""", ->
	@count 0
	model = CRoot.model.set "test_key"
	model.at "test_key", fn = -> @ok off
	model.un fn
	model.test_key 1

	
new CTest "obj-CModel-del", """
`del key` - удаляет свойство key

- key - имя свойства

См. #set, #compute, #has
""", ->
	model = CRoot.model
	model.set "test_key"
	model.on 'test_key', ->
	model.at 'test_key', ->
	
	model.compute "test_key", (x, y) ->
	@ok model._on.x
	@ok model._on.y
	
	model.del "test_key"
	@ok not model.has "test_key"
	@ok not model._on.test_key
	@ok not model._at.test_key
	
	@ok not model._on.x
	@ok not model._on.y
	
	
new CTest "obj-CModel-cmp", """
`cmp key, [fn|null]` - устанавливает или возвращает функцию сравнения
""", ->

	
	

CTest.category "служебные методы"


new CTest 'cls-CWidget', """
`CWidget element, [parent]` - класс виджет

element - элемент который оборачивается виджетом
parent - виджет, который будет главным над этим

Порождает циклическую ссылку

См. #CFormWidget
""", ->
	@count 3
	try	new CWidget	catch e then @ok 1
	e = document.createElement 'div'
	w = new CWidget e
	@is w.element, e
	@is e.widget, w


new CTest 'obj-CWidget-raise', """
`raise message` - создаёт экземпляр исключения Error, добавляя к нему объект в котором произошло исключение и stack trace

Использовать: `throw @raise "сообщение"`
""", ->
	@instanceof CRoot.raise("Исключение"), Error


new CTest 'obj-CWidget-warn', """
`warn message...` - выводит отладочную информацию в console.log. Практически не используется, т.к. функция say предоставляет весь необходимый для этого функционал
""", ->
	@ok CRoot.warn


new CTest 'obj-CWidget-className', """
`className` - возвращает строку с именем класса виджета. Так у экземпляра CWidget это будет "CWidget"
""", ->
	@is CRoot.className(), "CRoot$"
	@is CRoot.wrap("1").className(), "CNode"
	@is $("<div></div>").className(), "CWidget"
	@is $("<div></div>123").className(), "CWidgets"
	

CTest.category "методы создания элементов и виджетов"


new CTest 'obj-CWidget-wrap', """
`wrap array|element|string|number|widget|null, [parent]` - создаёт на основе своего аргумента виджет. Если аргументом является виджет или элемент имеющий виджет, то возвращается этот виджет. Возвращает или виджет или коллекцию, если же аргумент undefined или null - то null

2. parent - родительский виджет для порождённого виджета. Родительский виджет, это форма, она позволяет устанавливать обработчики на свои элементы.

См. #createWidget, #CFormWidget
""", ->
	w = CRoot
	@is w.wrap("<td></td>").element.tagName, 'TD'
	@is w.wrap(null), null
	@is w.wrap(10).element.nodeType, 3
	@is w.wrap('#obj-CWidget-wrap').element.data, '#obj-CWidget-wrap'
	@instanceof w.wrap([]), CWidgets
	@is w.wrap([['<i>1</i>', 2, 3], [4, 5]]).length, 5
	@is w.wrap([['<i>1</i>', 2, 3], [4, 5]]).item(4).text(), "5"
	@is w.wrap("<div></div>").wrap(/body/).tag(), "BODY"
	@is w.wrap("").wrap(/body/).tag(), "BODY"


new CTest 'obj-CWidget-unwrap', """
`unwrap` - отключает обёртку CWidget от элемента и элемент от обёртки. Возвращает коллекцию с элементом. В коллекции - отключает все подключённые элементы и возвращает себя
""", ->
	w = CRoot.wrap("<div></div>")
	@instanceof w.element.widget, CWidget
	e = w.element
	w.unwrap()
	@is w.element, null
	@is e.widget, null

	
new CTest 'obj-CWidget-rewrap', """
`rewrap cls|widget` - меняет обёртку виджета на вновь созданный виджет указанного класса или на виджет
""", ->
	w = $ "<div></div>"
	@instanceof w.element.widget, CWidget
	e = w.element
	w = w.rewrap CNode
	@instanceof w, CNode
	@is w.element, e
	@is e.widget, w
	
	w1 = $ "<div></div>"
	@is w1, w.rewrap w1
	@is w1.element, e
	@is w.element, null
	
	
new CTest 'obj-CWidget-createWidget', """
`createWidget element, [cls], [parent]` - определяет класс виджета и создаёт его. Возвращает созданный виджет. Если у элемента уже есть виджет - возвращает его. При этом cls и parent - игнорируются
""", ->
	div = document.createElement 'div'
	div.setAttribute 'ctype', 'img'
	@is CRoot.createWidget(div).className(), 'CImgWidget'


new CTest 'obj-CWidget-ctype', """
`ctype element` - возвращает класс элемента
""", ->
	div = document.createElement 'div'
	div.setAttribute 'ctype', 'img'
	@is CRoot.ctype(div), CImgWidget

	
new CTest 'obj-CWidget-new', """
`new tag, [ctype|cls], [attr]` - создаёт элемент и оборачивает его в виджет

- ctype - строка с названием класса виджета
- cls - класс виджета
- attr - хеш с атрибутами, которые будут установлены до обёртки элемента в виджет

См. #wrap, #xml, #svg, #createWidget, #CFormWidget
""", ->
	@instanceof CRoot.new("div"), CWidget
	@instanceof CRoot.new("div", "input"), CInputWidget
	@instanceof CRoot.new("div", CFormWidget, id: 'ex-test'), CFormWidget
	w = CRoot.new "div", ctype: "form", id: 'ex-test', action: "/test"
	@instanceof w, CFormWidget
	@is w.attr("action"), "/test"


# new CTest 'obj-CWidget-xml', """
# `xml tag, [ctype|cls], [attr]` - создаёт элемент xml и оборачивает его в виджет

# - ctype - строка с названием класса виджета
# - cls - класс виджета
# - attr - хеш с атрибутами, которые будут установлены до обёртки элемента в виджет

# См. #new, #svg, #wrap, #createWidget, #CFormWidget
# """, ->
	# @instanceof CRoot.xml("author"), CWidget
	# @instanceof CRoot.xml("author", "form"), CFormWidget
	# @instanceof CRoot.xml("author", ctype: "form"), CFormWidget


# new CTest 'obj-CWidget-svg', """
# `svg tag, [ctype|cls], [attr]` - создаёт элемент svg и оборачивает его в виджет

# - ctype - строка с названием класса виджета
# - cls - класс виджета
# - attr - хеш с атрибутами, которые будут установлены до обёртки элемента в виджет

# См. #new, #xml, #wrap, #createWidget, #CFormWidget
# """, ->
	# @instanceof CRoot.svg("line"), CWidget
	# @instanceof CRoot.svg("div", "form"), CFormWidget
	# @instanceof CRoot.new("div", ctype: "form"), CFormWidget

	
	
CTest.category "служебные елементы"


new CTest 'obj-CWidget-document', """
`document` - возвращает документ в который вставлен элемент или null, если элемент виджета не принадлежит ни одному документу.
Нужен во фреймах
""", ->
	@is CRoot.document(), document
	
	
new CTest 'obj-CWidget-window', """
`window` - возвращает окно в который вставлен элемент или null, если элемент виджета не принадлежит ни одному окну.
Нужен во фреймах
""", ->
	@is CRoot.window(), window
	

new CTest 'obj-CWidget-htm', """
`htm` - возвращает виджет html-элемента
""", ->
	@is CRoot, CRoot.htm()
	@is CRoot.tag(), 'HTML'
	

new CTest 'obj-CWidget-root', """
`root` - возвращает корневой виджет для документа (Chrome) или иерархии DOM (FF) в котором находится элемент
""", ->
	@is CRoot, CRoot.root()
	div = document.createElement 'div'
	div2 = document.createElement 'div'
	div.appendChild div2
	@is new CWidget(div2).root().element, div


new CTest 'obj-CWidget-viewport', """
`viewport` - возвращает виджет элемента на котором находится прокрутка окна, это html или, в некоторых браузерах, body
""", ->
	@ok CRoot.viewport().vscroll('size')

	
new CTest 'obj-CWidget-body', """
`body` - возвращает виджет элемента body
""", ->
	@ok CRoot.body().element, document.body


new CTest 'obj-CWidget-head', """
`body` - возвращает виджет элемента head
""", ->
	@ok CRoot.head().element, document.getElementsByTagName("head")[0]

	

CTest.category "методы изменения строки url браузера"

new CTest 'obj-CWidget-navigate', """
`navigate [go], [url, [title, [data]]]` - изменяет историю переходов браузера. Без параметров возвращает [url, title, data]

2. если первый параметр - ноль (go), то заменяет текущий элемент истории на указанный последующими параметрами
3. если первый параметр - цифра, то переходит по истории вперёд или назад
1. иначе добавляет новый элемент истории

""", ->
	[url, title, data] = CRoot.navigate()
	
	@is window.history$.length, 1
	@is window.history_pos$, 0
	
	@is CRoot, CRoot.navigate '/example/navigate', 'Эксперимент', {ex: 10}
	
	#say window.history_pos$, window.history$
	
	@is window.history$.length, 2
	@is window.history_pos$, 1
	
	@like CRoot.navigate()[0], /// /example/navigate$ ///
	@is CRoot.navigate()[1], 'Эксперимент'
	@is CRoot.navigate()[2].ex, 10
	
	#@is CRoot, CRoot.navigate -1
	
	#@is (say CRoot.navigate())[0], url
	#@is CRoot.navigate()[1], title
	
	#@is CRoot, CRoot.navigate 1
	#@is CRoot.navigate()[0], 'http://qq/example/navigate'
	
	@is CRoot, CRoot.navigate 0, url, title, data
	
	@is window.history$.length, 2
	@is window.history_pos$, 1
	
	@is CRoot.navigate()[0], url
	@is CRoot.navigate()[1], title

	
CTest.category "методы работы с cookie"

new CTest 'obj-CWidget-cookie', """
`cookie name, [value, [properties]]` - возвращает или устанавливает куку. Если val равен null, то удаляет куку. Если не указана опция path, то устанавливает куку для всех страниц сайта
""", ->
	CRoot.cookie "bsd", null
	@ok not CRoot.cookie("bsd")?
	@is CRoot, CRoot.cookie "bsd", "value"
	@is "value", CRoot.cookie "bsd"
	CRoot.cookie "bsd", null
	@ok not CRoot.cookie("bsd")?


CTest.category "методы установки обработчиков"
	
new CTest 'obj-CWidget-send', """
`send type, args...` - отправляет событие виджетов паренту. Если парента нет - то себе

#Send.setHandler
""", """
<div id=ExSend>
	<div id=ExSend-fld>_</div>
</div>
""", ->
	@count 3
	test = this
	class ExSend extends CFormWidget
		fld_onclick: (param, fld) ->
			test.is fld, @fld
			test.is param, 22

	ex = new ExSend
	@like /CSend/, ex.fld.attr 'onclick'
	ex.fld.send 'onclick', 22
	

new CTest "obj-CWidget-on", """
`on type, listen, [phase]` - ставит обработчик на события

- type - названия одного или нескольких событий. Без префикса "on"
- listen - функция-обработчик
- phase - фаза - добавить в конец или в начало очереди обработчиков. По умолчанию - в конец

См. #one, #off
""", ->
	@count 2

	w = CRoot.new 'div'
	w.on 'MyEvent1 MyEvent2', (a) => @is a, 10 
	w.send 'onMyEvent1', 10
	w.send 'onMyEvent2', 10


new CTest "obj-CWidget-off", """
`off type, [listen], [phase]` - ставит обработчик на события

- type - названия одного или нескольких событий. Без префикса "on"
- listen - функция-обработчик или значение свойства _belong функции-обработчика. Если не указан - удаляется. _belong не может быть функцией
- phase - фаза - удалять из конеца или из начала очереди обработчиков. По умолчанию - из конца

См. #one, #off
""", ->
	w = CRoot.new 'div'
	w.on 'MyEvent1', fn1 = ->
	w.on 'MyEvent1', fn2 = ->
	w.on 'MyEvent1', (fn3 = ->), 1
	
	@is w._sendQueue.onMyEvent1[0], fn3
	@is w._sendQueue.onMyEvent1[1], fn1
	@is w._sendQueue.onMyEvent1[2], fn2
	
	w.on 'MyEvent1', fn3
	@is w._sendQueue.onMyEvent1[3], fn3
	
	w.off 'MyEvent1', fn3, 1
	@is w._sendQueue.onMyEvent1[0], fn1
	
	fn3._belong = 6
	w.off 'MyEvent1', 6
	
	@is w._sendQueue.onMyEvent1.length, 2
	@is w._sendQueue.onMyEvent1[0], fn1
	@is w._sendQueue.onMyEvent1[1], fn2
	

new CTest "obj-CWidget-one", """
`one type, listen, [phase]` - ставит обработчик на события, аналогично #on. Но как только обработчик выполниться на событии он сразу же удаляется
""", ->
	@count 2
	w = CRoot.new 'div'
	w.one 'MyEvent1 MyEvent2', (a) => @is a, 10 
	w.send 'onMyEvent1', 10
	w.send 'onMyEvent2', 10
	w.send 'onMyEvent1', 20
	w.send 'onMyEvent2', 20
	
	
new CTest 'obj-CWidget-defineHandlers', """
`defineHandlers` - пробегает по всем методам объекта и запоминает методы-события

* методы начинающиеся на on и записанные буквами нижнего регистра - устанавливаются на элемент: onclick, onchange
* начинающиеся на имя элемента формы - используется формами (CForm): bt_onclick
* формы могут быть вложенными: `form2__form3__bt_onclick`
* заканчивающиеся на описатель: onscroll_window, onload_window, onmouseleave_parent

См. #setHandler, #send, #getHandlersOnElements, #setListens
""", ->
	class window.Ex extends CWidget
		onclick: ->
		bt_onclick: ->
		form2__form3__bt_onclick: ->
		onscroll_window: ->

	ex=$ "<div ctype=Ex></div>"
	ex.defineHandlers()
	
	@is Ex.selfHandlers[0], "click"
	@is Ex.handlers.bt["@"]["click"], "bt_onclick"
	@is Ex.handlers.form2.form3.bt["@"]["click"], "form2__form3__bt_onclick"
	@is Ex.listens.onscroll_window[0], "window"
	@is Ex.listens.onscroll_window[1], "scroll"


new CTest 'obj-CWidget-setHandler', """
`setHandler handlers...` - устанавливает собственные события, переданные списком параметров

См. #setHandlers, #defineHandlers, #send, #getHandlersOnElements, #setListens
""", ->
	@like $("<div></div>").setHandler("click").attr("onclick"), /CSend/

new CTest 'obj-CWidget-setHandlers', """
`setHandlers` - устанавливает события класса формата on[a-z]+

См. #setHandlers, #defineHandlers, #send, #getHandlersOnElements, #setListens
""", ->
	class window.Ex extends CWidget
		onclick: ->
	@like $("<div ctype=Ex></div>").defineHandlers().setHandlers().attr("onclick"), /CSend/

	
new CTest 'obj-CWidget-setHandlersOnElements', """
`setHandlersOnElements` - устанавливает хандлеры на элементов формы. В поиске таких хандлеров проходит по парентам (вышестоящим формам)
""", ->
	class window.Ex extends CFormWidget
		form2__bt_onclick: ->
		fld_onclick: ->
	
	w = $("<div id=ex ctype=Ex><span id=ex-fld></span></div>")
	@like $("<div id=ex ctype=Ex><span id=ex-fld></span><div id=ex-form2 ctype=form><span id=ex-form2-bt></span></div></div>").form2.bt.attr("onclick"), /CSend/

	class window.Ex extends CWidget
		bt_onclick: ->
	w = $("<div id=ex ctype=Ex><span id=ex-bt></span></div>").defineHandlers().setHandlersOnElements()
	@like w.first().attr("onclick"), /CSend/

	
new CTest 'obj-CWidget-setListens', """
`setListens` - устанавливает описатели определённые defineHandlers на окно, parent и т.д.
""", ->
	@count 1
	self = this
	class window.Ex extends CWidget
		onresize_window: -> $(window).off 'resize', this ; self.ok 1 
	w = $("<div ctype=Ex></div>").defineHandlers().setListens()
	$(window).fire 'resize'
	$(window).fire 'resize'


new CTest 'obj-CWidget-observe', """
`observe method, before, [after], [phase]` - заменяет указанный метод в объекте на замыкание, которое возбуждает исключения и onBeforeMethod и onMethod. На них и устанавливаются обработчики

- обработчик before срабатывает перед методом, а обработчик after - после
- обработчик after получает первым параметром результат метода, а затем - его параметры

Удалить обсерверы можно методом #shut.

См. #shut
""", ->
	before = after = 0
	
	class Ex extends CWidget
		method: (a, b) -> 22 + a * b
	
	onExBefore = (a, b) -> before += a
	onExAfter = (ret, a, b) -> after += b
	onExBefore2 = (a, b) -> before -= a * 2
	onExAfter2 = (ret, a, b) -> after -= b * 2
	
	ex = new Ex document.createElement 'div'
	
	ex.observe 'method', onExBefore
	ex.observe 'method', null, onExAfter
	ex.observe 'method', onExBefore2, onExAfter2
	
	@is ex.method(2, 3), 28
	
	@is before, -2
	@is after, -3
	

new CTest 'obj-CWidget-shut', """
`shut method, [observer]` - удаляет обработчики установленные методом #observer

См. #observer
""", ->
	before = after = 0

	class Ex extends CWidget
		method: (a, b) -> 22 + a * b
	
	onExBefore = (a, b) -> before += a
	onExAfter = (ret, a, b) -> after += b
	onExBefore2 = (a, b) -> before -= a
	onExAfter2 = (ret, a, b) -> after -= b
	
	ex = new Ex document.createElement 'div'
	
	ex.observe 'method', onExBefore, onExAfter
	ex.observe 'method', onExBefore2, onExAfter2
	
	@is ex.method(2, 3), 28
	
	@is before, 0
	@is after, 0
	
	ex.shut 'method', onExBefore
	@is ex.method(2, 3), 28
	
	@is before, -2
	@is after, 0
	
	ex.shut 'method'
	@is ex.method(2, 3), 28
	
	@is before, -2
	@is after, 0


new CTest 'obj-CWidget-listen', """
`listen type, fn, [fase]` - устанавливает обработчик на виджет, используя обычный addEventListener. Использовать нерекомендуется. Лучше использовать стандартный механизм фреймворка - методы начинающиеся на "on"
""", """
<select id=$name></select>
""", ->
	test = 1
	@w().listen("click", -> test = 10).fire "click"
	@is test, 10
	

new CTest 'obj-CWidget-drop', """
`drop type, fn, [fase]` - удаляет обработчик установленный listen
""", """
<select id=$name></select>
""", ->
	test = 1
	fn = (e) -> test = 10
	(w=@w()).listen('click', fn).fire 'click'
	@is test, 10
	test = 1
	w.drop('click', fn).fire 'click'
	@is test, 1

	
new CTest 'obj-CWidget-fire', """
`fire type, [options]` - инициирует событие (в разработке)
""", """
<select id=$name-sel></select>
""", ->
	test = 1 ; (sel=@w("sel")).listen('change', (e) -> test = 10).fire "change"; @is test, 10
	sel.listen('mousemove', (e) -> test = 20).fire "mousemove"; @is test, 20
	sel.listen('keypress', (e) -> test = 30).fire "keypress"; @is test, 30


new CTest 'obj-CWidget-attach', """
`attach name` - подключает элемент к форме.
У формы появляется @$название.
Если название не совпадает со свойствами формы, то создаётся так же и такое свойство
""", ->
	form = $("<div id=obj-CWidget-attach-form ctype=form><div id=obj-CWidget-attach-form-listen></div><div id=obj-CWidget-attach-form-elem></div></div>")
	@is form.elem.name(), "elem"
	@is form.$elem.name(), "elem"
	@is form.$listen.name(), "listen"
	@instanceof form.listen, Function


new CTest 'obj-CWidget-detach', """
`detach name` - отключает элемент от формы
""", ->
	w = $("<div id=obj-CWidget-attach-form ctype=form><div id=obj-CWidget-attach-form-lis></div></div>")
	lis = w.byId "obj-CWidget-attach-form-lis"
	@is lis.parent(), w
	@is w._elements[0], 'lis'
	@is w.lis, lis
	w.detach 'lis'
	@is lis._parent, null
	@is lis.parent(), w
	@is lis._parent, w
	@ok not(lis of w)
	@is w._elements.length, 0
	

new CTest 'obj-CWidget-getElements', """
`getElements` - возвращает элементы формы
""", ->
	form = CRoot.wrap "<div id=obj-CWidget-getElements-form><div id=obj-CWidget-getElements-form-v></div></div>"
	el = form.getElements()
	@is el.length, 1
	@is el[0], "v"



CTest.category "методы поиска элементов"

new CTest 'obj-CWidget-byId', """
`byId id` - ищет в документе и возвращает виджет по id элемента
""", """ <div id=$name></div> """, ->
	@is CRoot.byId("not id"), null
	@is CRoot.byId("obj-CWidget-byId").id(), "obj-CWidget-byId"


new CTest 'obj-CWidget-byName', """
`byName name` - ищет в документе и возвращает виджет по его имени в форме. Аналогично @byId id-формы + тире + имя. Заодно проверяет parent
""", ->
	form = CRoot.wrap("<div id=obj-CWidget-byName-form><div id=obj-CWidget-byName-form-v></div></div>").appendTo /body/
	@is form.byName("v"), form.byId "obj-CWidget-byName-form-v"

	
new CTest 'obj-CWidget-byTag', """
`byTag tag` - ищет и возвращает первый попавшийся вложенный виджет по его тегу
""", ->
	@is CRoot.byTag("head").tag(), "HEAD"

new CTest 'obj-CWidget-byClass', """
`byTag tag` - ищет и возвращает первый попавшийся вложенный виджет по его классу
""", ->
	@is CRoot.byTag("head").tag(), "HEAD"

	
new CTest 'obj-CWidget-byClassAll', """
`byClassAll tag` - ищет и возвращает коллекцию вложенных виджетов по классу
""", ->
	@is CRoot.wrap("<div><b class=m1>1</b><b>0</b><b class=m1>2</b></div>").byClassAll("m1").length, 2
	

new CTest 'obj-CWidget-byTagAll', """
`byTagAll tag` - ищет и возвращает коллекцию вложенных виджетов по тегу
""", ->
	@is CRoot.wrap("<div> x<b class=m1>1</b> <b>0</b> <b class=m1>2</b></div>").byTagAll("b").length, 3


new CTest 'obj-CWidget-first', """
`first [selector]` - возвращает первый потомок, соответствующий селектору
""", ->
	@is (w=CRoot.wrap("<div> <b>0</b> <b class=m1>2</b> <b class=m1>2</b></div>")).first("b[class]").html(), "2"
	@is w.first().html(), "0"

	
new CTest 'obj-CWidget-last', """
`last [selector]` - возвращает последний потомок, соответствующий селектору
""", ->
	@is (w=CRoot.wrap("<div> <b class=m1>2</b> <b class=m1>2</b> <b>3</b> </div>")).last("b[class]").html(), "2"
	@is w.last().html(), "3"
	

new CTest 'obj-CWidget-find', """
`find selector` - возвращает все потомки, соответствующие селектору
""", ->
	@is (w=CRoot.wrap("<div> <b class=m1>2</b> <b class=m1>2</b> <b>3</b> </div>")).find("b[class]").length, 2
	@is w.find(".m1").length, 2


new CTest 'obj-CWidget-byViewXY', """
`byViewXY x, y` - возвращает виджет по его координатам на экране
""", """
<div id=$name style="background: lightblue; width: 40px; height: 40px">&nbsp;</div>
""", ->
	{left, top} = (w=@w()).viewPos()
	@is w, CRoot.byViewXY left, top
	@is w, CRoot.byViewXY left+20, top+20
	@is w, CRoot.byViewXY left+39, top+39


new CTest 'obj-CWidget-byXY', """
`byXY x, y` - возвращает виджет по его координатам в документе
""", """
<div id=$name style="background: lightblue; width: 40px; height: 40px">&nbsp;</div>
""", ->
	{left, top} = (w=@w()).pos()
	@is w, CRoot.byXY left, top
	@is w, CRoot.byXY left+20, top+20
	@is w, CRoot.byXY left+39, top+39


new CTest 'obj-CWidget-byXYAll', """
`byXYAll x, y` - возвращает все виджеты которые лежат в координатах документа x, y
""", """
#%name-2, #%name-3 {width: 40px; height: 40px}
#%name-2 {background: coral; margin-bottom: -20px; margin-left: 20px }
#%name-3 {background: royalblue}
""", """
<div id=$name>
	<div id=$name-2></div>
	<div id=$name-3></div>
</div>
""", ->
	{left, top} = @w().pos()
	all = CRoot.byXYAll left+30, top+30
	@is all.length, 3
	@is all.item(0), @w 3
	@is all.item(1), @w 2
	@is all.item(2), @w()


new CTest 'obj-CWidget-byViewXYAll', """
`byViewXYAll x, y` - возвращает все виджеты которые лежат в координатах экрана x, y
""", """
#%name-2, #%name-3 {width: 40px; height: 40px}
#%name-2 {background: coral; margin-bottom: -20px; margin-left: 20px }
#%name-3 {background: royalblue}
""", """
<div id=$name>
	<div id=$name-2></div>
	<div id=$name-3></div>
</div>
""", ->
	{left, top} = @w().viewPos()
	all = CRoot.byViewXYAll left+30, top+30
	@is all.length, 3
	@is all.item(0), @w 3
	@is all.item(1), @w 2
	@is all.item(2), @w()


new CTest 'obj-CWidget-match', """
`match selector` - возвращает true, если элемент соответствует селектору
""", ->
	@is CRoot.wrap("<b class=m1></b>").match("b.m1"), on

	
	
CTest.category "методы коллекции"

new CTest 'obj-CWidget-all', """
`all` - возвращает массив класса Array, содержащий html-элементы, находящиеся в коллекции
""", ->
	@instanceof CRoot.all(), Array
	@is CRoot.all()[0], CRoot.element
	@instanceof CRoot.find("b#m1"), CWidgets
	@instanceof CRoot.find("b#m1").all(), Array


new CTest 'obj-CWidget-empty', """
`empty` - определяет, что коллекция пуста. Возвращает true/false
""", ->
	@is CRoot.empty(), off
	@is new CWidgets([]).empty(), on


new CTest 'obj-CWidget-length', """
`length` - возвращает длину коллекции
""", ->
	@is CRoot.length, 1
	@is new CWidgets([CRoot.element, CRoot.element]).length, 2


new CTest 'obj-CWidget-item', """
`item index` - возвращает виджет из коллекции по индексу
""", ->
	@is CRoot.item(0), CRoot
	@is CRoot.item(1), undefined
	@is new CWidgets([CRoot.body().element, CRoot.element]).item(-1), CRoot


new CTest 'obj-CWidget-items', """
`items` - возвращает виджеты из коллекции в виде массива
""", ->
	@is CRoot.items()[0], CRoot
	@is new CWidgets([CRoot, CRoot]).items().length, 2


new CTest 'obj-CWidget-slice', """
`slice [from], [to]` - делает вырезку из коллекции

* from и to могут быть не только цифрами, но и селекторами: в этом случае ориентируются от совпадения селектора до совпадения селектора; и виджетами
* если from взять в массив, то элемент исключается из коллекции
* если to взять в массив, то элемент включается в коллекцию
* второй элемент массива [from, 1] или [to, -1] может указывать с какого совпавшего с селектором элемента начинать вырезку. При этом не считается, что элемент взят в массив
* третий элемент массива (1 или 0) указывает - включать или нет элемент: [from, 1, 1] - не включать, [to, 1, 1] - включать
""", ->
	@is CRoot.slice(0).length, 1
	w = CRoot.wrap "0 <i>1</i> 2 <b>3</b> 4 <i>5</i> 6 <i>7</i><em>8</em><u>9</u>"
	@is w.slice(5).length, 5
	@is w.slice(0, 5).length, 5
	@is w.slice(0, [5]).length, 6
	@is w.slice([0], 5).length, 4
	@is w.slice("b", 5).length, 2
	@is w.slice(["b"], 5).length, 1
	@is w.slice(["i", -2], "u").length, 4
	@is w.slice(["i", -2, 1], "u").length, 3
	@is w.slice(["i", -2], ["u"]).length, 5
	@is w.slice(["i", -2], ["u", 0]).length, 4
	@is w.slice(["i", -2], ["u", 0, 1]).length, 5
	x = w.item 1
	@is w.slice(1, [x]).item(0), x


new CTest 'obj-CWidget-invoke', """
`invoke name, args...` - выполняет метод name для каждого виджета в коллекции у котрого он есть. Возвращает себя
""", ->
	@is CRoot.invoke("all"), CRoot
	

new CTest 'obj-CWidget-map', """
`map name, args...` - выполняет метод name для каждого виджета в коллекции у котрого он есть. Возвращает массив результатов
""", ->
	@is CRoot.map("empty")[0], off
	@is CRoot.map("not found method")[0], undefined
	@is CRoot.map("not found method").length, 1

	
new CTest 'obj-CWidget-result', """
`result name, args...` - выполняет метод name для каждого виджета в коллекции у котрого он есть. Возвращает результат для первого виджета
""", ->
	@is CRoot.result("empty"), off

	
new CTest 'obj-CWidget-grep', """
`grep name, args...` - выполняет метод name для каждого виджета в коллекции у котрого он есть. Возвращает новую коллекцию с виджетами, методы к-х вернули положительный результат
""", ->
	@is CRoot.grep("empty").length, 0
	@is CRoot.grep("all"), CRoot

	
new CTest 'obj-CWidget-exists', """
`exists name` - возвращает новую коллекцию с виджетами у которых есть метод name
""", ->
	@is CRoot.exists("empty"), CRoot


new CTest 'obj-CWidget-filter', """
`filter query` - возвращает новую коллекцию с элементами соответствующими query
""", ->
	@is CRoot.filter("html"), CRoot
	@ok CRoot.filter("b").empty()

	

CTest.category "методы клонирования элемента"

new CTest 'obj-CWidget-clone', """
`clone [id], [parent], [cls]` - возвращает клонированный элемент, с новым id, парентом и классом виджета, если последние указаны
""", ->
	w = CRoot.wrap("<div id=exid ctype=img><b id=exid-b></b></div>").clone "exid2", CRoot, CInputWidget
	@is w.id(), 'exid2'
	@is w.child(0).id(), 'exid2-b'
	@is w.parent(), CRoot
	@instanceof w, CInputWidget

	
new CTest 'obj-CWidget-clonehtml', """
`clonehtml [id], [parent], [cls]` - возвращает html клона элемента, с новым id, парентом и классом виджета, если последние указаны
""", ->
	html = CRoot.wrap("<div id=exid><b id=exid-b></b></div>").clonehtml "exid2", CRoot.wrap("<div id=exid3></div>"), CInputWidget
	@is html, '<div id="exid2" cparent=exid3 ctype=CInputWidget><b id="exid2-b"></b></div>'

	

CTest.category "методы атрибутов и содержимого"

new CTest 'obj-CWidget-id', """
`id [id]` - возвращает или устанавливает id элемента
""", ->
	@is (w=CRoot.wrap('<div id=exid></div>')).id(), 'exid'
	@is w.id('exid2').id(), 'exid2'


new CTest 'obj-CWidget-name', """
`name [name]` - возвращает или устанавливает имя элемента формы. Именем элемента формы считается последнее слово в конце идентификатора
""", ->
	@is (w=CRoot.wrap('<div id=exid-name></div>')).name(), 'name'
	@is w.name('ps').name(), 'ps'


new CTest 'obj-CWidget-number', """
`number [number]` - возвращает или устанавливает номер в конце идентификатора элемента
""", ->
	@is (w=CRoot.wrap('<div id=exid3></div>')).number(), '3'
	@is w.number(2).number(), "2"


new CTest 'obj-CWidget-tag', """
`tag [tag]` - возвращает или устанавливает тег элемента
""", ->
	@is (w=CRoot.wrap('<div></div>')).tag(), 'DIV'
	@is w.tag("b").tag(), "B"

	
new CTest 'obj-CWidget-val', """
`val [val]` - возвращает или устанавливает атрибут value элемента
""", ->
	@is (w=CRoot.wrap('<input value="10" />')).val(), '10'
	@is w.val("b").val(), "b"


new CTest 'obj-CWidget-val$f', """
`val$f` - возвращает атрибут value элемента преобразованный в число с плавающей точкой
""", ->
	@is CRoot.wrap('<div>10.5</div>').val$f(), 10.5
	@is CRoot.wrap('<input value="10.5" />').val$f(), 10.5


new CTest 'obj-CWidget-val$i', """
`val$i [radix]` - возвращает атрибут value элемента преобразованный в целое число. radix - база числа: 2, 3, 8, 10, 16 и т.п.
""", ->
	@is CRoot.wrap('<input value="10.5" />').val$i(), 10


new CTest 'obj-CWidget-inc', """
`inc [increment]` - увеличивает атрибут value элемента на increment или 1
""", ->
	@is CRoot.wrap('<input value="10" />').inc(2).val$i(), 12

	
new CTest 'obj-CWidget-dec', """
`inc [increment]` - уменьшает атрибут value элемента на increment или 1
""", ->
	@is CRoot.wrap('<input value="10" />').dec().val$i(), 9


new CTest 'obj-CWidget-text', """
`text [text]` - возвращает или устанавливает текст внутри элемента
""", ->
	@is CRoot.wrap('<div><b>2</b></div>').text(), "2"
	@is CRoot.wrap('<div>2</div>').text(3).text(), "3"
	

new CTest 'obj-CWidget-html', """
`html [html]` - возвращает или устанавливает html внутри элемента
""", ->
	@is $('<div>2</div>').html("<b>3</b>").html(), "<b>3</b>"


new CTest 'obj-CWidget-htmlscript', """
`htmlscript [html]` - устанавливает html внутри элемента и выполняет все теги <script>, без тега type или с type=text/javascript
""", ->
	@is $('<div>2</div>').html("<b>3</b>").html(), "<b>3</b>"

	
new CTest 'obj-CWidget-content', """
`content [content]` - возвращает или устанавливает содержимое элемента - коллекцию нод. При установке можно использовать любой аргумент, который может быть преобразован в ноду или коллекцию
""", ->
	@is CRoot.wrap('<div>2</div>').content("<b>3</b>").content().outer(), "<b>3</b>"

	
new CTest 'obj-CWidget-normalize', """
`normalize` - нормализует текстовые ноды, сливая их, если это возможно, вместе, а так же удаляя пустые
""", ->
	t1 = document.createTextNode "1"
	t2 = document.createTextNode "2"
	w = CRoot.wrap("<div></div>").append [t1, t2]
	@is w.down().length, 2
	@is w.normalize().down().length, 1


new CTest 'obj-CWidget-update', """
`update` - определяет, как будет происходить апдейт виджета. Используется загрузчиком
""", ->
	@is $("<div>2</div>").update("3").html(), "3"


new CTest 'obj-CWidget-outer', """
`outer [content]` - возвращает outerHTML элемента. Если указан content, то заменяет элемент виджета на него
""", ->
	@is $("<div>2</div>").outer("<b>3</b>").outer(), "<b>3</b>"
	@is CRoot.wrap(" <i></i> <u></u>").outer(), " <i></i> <u></u>"
	@is (w=$("<div>2</div>")).outer( x=$("<b>3</b>") ).outer(), "<b>3</b>"
	@is x.element, null


new CTest 'obj-CWidget-before', """
`before content, [timeout], [listen]` - вставляет content перед виджетом
""", ->
	@is $("<i><b>1</b><b>2</b></i>").child(1).before("3").up().outer(), "<i><b>1</b>3<b>2</b></i>"
	@is (new CWidgets [$("<i><b>1</b><b>2</b></i>").child(1).element]).before("3").up().outer(), "<i><b>1</b>3<b>2</b></i>"
	@is (new CWidgets [$("<i><b>1</b><b>2</b></i>").child(1).element]).before(new CWidgets [CRoot.wrap("3").element]).up().outer(), "<i><b>1</b>3<b>2</b></i>"
	@is $("<i><b>1</b><b>2</b></i>").child(1).before(new CWidgets [CRoot.wrap("3").element]).up().outer(), "<i><b>1</b>3<b>2</b></i>"


new CTest 'obj-CWidget-insertBefore', """
`insertBefore content, [timeout], [listen]` - вставляет виджет перед content-ом
""", ->
	$("<i>2</i>").insertBefore (w=$("<i>1<u>3</u></i>")).down(1)
	@is w.outer(), "<i>1<i>2</i><u>3</u></i>"


new CTest 'obj-CWidget-after', """
`after content, [timeout], [listen]` - вставляет content после виджета

#append
""", ->
	@is $("<i><b>1</b><b>2</b></i>").child(-1).after("3").up().outer(), "<i><b>1</b><b>2</b>3</i>"

	
new CTest 'obj-CWidget-insertAfter', """
`insertAfter content, [timeout], [listen]` - вставляет виджет после content-а

#append
""", ->
	$("<i>2</i>").insertAfter (w=$("<i>1<u>3</u></i>")).down(0)
	@is w.outer(), "<i>1<i>2</i><u>3</u></i>"

	
new CTest 'obj-CWidget-append', """
`append content, [timeout], [listen]` - вставляет content в конец виджета

* timeout - время за которое будет осуществляться перемещение
* listen - функция, которая сработает после перемещения. Если timeout не указан, то он станет 'norm'

""", """
#%name-c1, #%name-c2, #%name-c3 { padding: 4px; background: lavender; border: solid 1px orange }
#%name-c2, #%name-c3 {position: absolute; margin: -20px 0 0 400px }
#%name-c3 { margin: -20px 0 0 800px !important }
#%name-1, #%name-2 { background: LightSlateGray }
""", """
<div id=%name-c1>
	
</div>

<div id=%name-c2>
	старт путешественника 1
	<div id=%name-1>путешественник 1</div>
</div>

<div id=%name-c3>
	<div id=%name-2>путешественник 2</div>
	старт путешественника 2
</div>

<a id=%name-b1 href="#">Обратно</a>


""", ->
	@count 2

	@is $("<i>1</i>").append("3").outer(), "<i>13</i>"
	self = this
	(c1=@w("c1")).append (i1=@w("1")).union(i2=@w("2")), "fast", -> self.is i1.up().name(), "c1"
	c2 = @w("c2")
	c3 = @w("c3")
	@w("b1").on "click", -> (if i1.up().name() == 'c1' then c2.append i1, "fast"; c3.append i2, "fast" else c1.append i1.union(i2), "fast"); off
	

new CTest 'obj-CWidget-appendTo', """
`appendTo content, [timeout], [listen]` - вставляет виджет в конец content-а

См. #append
""", ->
	$("<i>1</i>").appendTo w=$("<em>2</em>")
	@is w.html(), "2<i>1</i>"


new CTest 'obj-CWidget-prepend', """
`prepend content, [timeout], [listen]` - вставляет content в начало виджета
""", ->
	@is $("<i>1</i>").prepend("3").outer(), "<i>31</i>"


new CTest 'obj-CWidget-prependTo', """
`prependTo content, [timeout], [listen]` - вставляет виджет в начало content-а
""", ->
	$("<i>1</i>").prependTo w=$("<em>2</em>")
	@is w.html(), "<i>1</i>2"


new CTest 'obj-CWidget-swap', """
`swap content, [timeout], [listen]` - меняет элементы в DOM местами
""", ->
	w = $ "<i><b>1</b><u>2</u></i>"
	w.child(0).swap w.child 1
	@is w.outer(), "<i><u>2</u><b>1</b></i>"
	
	w = $ "<i><b>1</b><u>2</u></i>"
	w.child(1).swap w.child 0
	@is w.outer(), "<i><u>2</u><b>1</b></i>"
	
	w = $ "<i><b>1</b><u>2</u>3</i>"
	w.child(0).swap w.child 1
	@is w.outer(), "<i><u>2</u><b>1</b>3</i>"
	
	w = $ "<i><b>1</b><u>2</u>3</i>"
	w.child(1).swap w.child 0
	@is w.outer(), "<i><u>2</u><b>1</b>3</i>"
	
	w = $ "<i><b>1</b><u>2</u><em>3</em></i>"
	w.child(2).swap w.child 0
	@is w.outer(), "<i><em>3</em><u>2</u><b>1</b></i>"
	
	w = $ "<i>1</i>"
	x=w.down(0).swap "<u>2</u>"
	@is w.outer(), "<i><u>2</u></i>"
	@is x.up(), null
	
	@is (w=CRoot.wrap("1")).swap("2"), w		# ничего не делает, т.к. оба элемента не в DOM-е
	
	w = $ "<i><b>1<u>2<em>3</em></u></b></i>"
	w.swap x=w.child(0).child(0)
	@is x.outer(), "<u><b>1<i>2<em>3</em></i></b></u>"
	
	w = $ "<i><u>1</u>2</i>"
	(x=w.child(0)).swap w
	@is x.outer(), "<u><i>1</i>2</u>"

	w = $ "<i><u>1</u>2</i>"
	w.swap x=w.child(0)
	@is x.outer(), "<u><i>1</i>2</u>"
	
	w = new CWidgets [$("<i><u>1</u>2</i>").element]
	w.swap x=w.child(0)
	@is x.outer(), "<u><i>1</i>2</u>"
	
	w = new CWidgets [$("<i><u>1</u>2</i>").element]
	w.swap x=w.child()
	@is x.outer(), "<u><i>1</i>2</u>"
	

new CTest 'obj-CWidget-wrapIn', """
`wrapIn content` - оборачивает виджет в content. С коллекцией желательно задавать текст, т.к. content не клонируется

Возвращает content преобразованный в виджет
""", ->
	w = $("<i>1</i>").wrapIn "<p><em>2</em><b>3</b></p>"
	@is w.upAll().item(-1).outer(), "<p><em><i>1</i></em><b>3</b></p>"
	w = $(["<i>1</i>", "2", "<i>3</i>"]).wrapIn "<p></p>"
	@is w.outer(), "<p><i>1</i></p><p>2</p><p><i>3</i></p>"


new CTest 'obj-CWidget-wrapInAll', """
`wrapInAll content` - оборачивает виджет или коллекцию виджетов в content

Возвращает content преобразованный в виджет
""", ->
	$(["<i>1</i>", "2", "<i>3</i>"]).wrapInAll(w=$("<p></p>"))
	@is w.outer(), "<p><i>1</i>2<i>3</i></p>"


new CTest 'obj-CWidget-floor', """
`floor` - возвращает элемент расположенный под элементом. Используется в старой функции нахождения координат элемента

См. #floorAll, #domfloor, #up
""", """
#$name, #$name-w { width: 100px; height: 100px; background: green }
#$name {position: absolute; z-index: 1000; background: red; margin-left: 10px; margin-top: 10px; }
""", """
<div id=$name></div>
<div id=$name-w></div>
""", ->
	#@is @w().floor(), @w("w")

	
new CTest 'obj-CWidget-up', """
`up` - возвращает вышестоящую ноду в дереве
""", ->
	@is (w=$("<i>2</i>").down(0)).outer(), "2"
	@is w.up().outer(), "<i>2</i>"

	
new CTest 'obj-CWidget-upper', """
`upper` - возвращает вышестоящий элемент в дереве
""", ->
	f = document.createDocumentFragment()
	f.appendChild((w=$("<i>2</i>")).element)
	@is w.upper(), null
	@is (w=w.down(0)).outer(), "2"
	@is w.upper().outer(), "<i>2</i>"


new CTest 'obj-CWidget-next', """
`next` - возвращает соседний следующий элемент
""", ->
	@is $("<i><b>1</b>_<b>2</b></i>").child(0).next().html(), "2"


new CTest 'obj-CWidget-prev', """
`prev` - возвращает соседний предыдущий элемент
""", ->
	@is $("<i><b>1</b><b>2</b></i>").child(1).prev().html(), "1"


new CTest 'obj-CWidget-nextnode', """
`nextnode` - возвращает соседнюю следующую ноду
""", ->
	@is $("<i><b>1</b>2</i>").child(0).nextnode().text(), "2"


new CTest 'obj-CWidget-prevnode', """
`prevnode` - возвращает соседнюю предыдущую ноду
""", ->
	@is $("<i>1<b>2</b></i>").child(0).prevnode().text(), "1"

	
new CTest 'obj-CWidget-upAll', """
`upAll` - возвращает все вышестоящие ноды в дереве
""", ->
	f = document.createDocumentFragment()
	f.appendChild (w=$("<i><b><em>1</em></b></i>")).element
	@is w.down(0).down(0).down(0).upAll().length, 4
	
	
new CTest 'obj-CWidget-upperAll', """
`upperAll` - возвращает все вышестоящие элементы в дереве
""", ->
	f = document.createDocumentFragment()
	f.appendChild (w=$("<i><b><em>1</em></b></i>")).element
	@is w.down(0).down(0).down(0).upperAll().length, 3


new CTest 'obj-CWidget-nextAll', """
`nextAll` - возвращает все соседние элементы
""", ->
	@is $("<i><b>1</b><b>2</b>_<x>3</x></i>").child(0).nextAll().outer(), "<b>2</b><x>3</x>"


new CTest 'obj-CWidget-prevAll', """
`prevAll` - возвращает все соседние предыдущие элементы
""", ->
	@is $("<i> <b>1</b> <i>2</i> <b>3</b> </i>").child(-1).prevAll().outer(), "<b>1</b><i>2</i>"


new CTest 'obj-CWidget-nextnodeAll', """
`nextnodeAll` - возвращает соседние следующие ноды
""", ->
	@is $("<i><b>1</b>2<em>3</em></i>").child(0).nextnodeAll().outer(), "2<em>3</em>"


new CTest 'obj-CWidget-prevnodeAll', """
`prevnodeAll` - возвращает соседние предыдущие ноды
""", ->
	@is $("<i><em>0</em>1<b>2</b></i>").child(-1).prevnodeAll().outer(), "<em>0</em>1"


new CTest 'obj-CWidget-child', """
`child [index]` - возвращает коллекцию дочерних элементов. С index - возвращает дочерний элемент с таким индексом
""", ->
	@is $("<i><em>0</em>1<b>2</b>3</i>").child(-1).outer(), "<b>2</b>"
	@is $("<i><em>0</em>1<b>2</b>3</i>").child().outer(), "<em>0</em><b>2</b>"


new CTest 'obj-CWidget-down', """
`down [index]` - возвращает коллекцию дочерних нод. С index - возвращает дочернюю ноду с таким индексом
""", ->
	@is $("<i><em>0</em>1<b>2</b>3</i>").down(-1).outer(), "3"
	@is $("<i><em>0</em>1<b>2</b>3</i>").down().outer(), "<em>0</em>1<b>2</b>3"


new CTest 'obj-CWidget-remove', """
`remove` - удаляет виджет. Как из дерева DOM, так и удаляет сам элемент в виджете

См. #free
""", ->
	w = $("<i><em>0</em>1<b>2</b>3</i>")
	x = w.child(-1)
	x.remove()
	@is x.element, null
	@is w.outer(), "<i><em>0</em>13</i>"
	

new CTest 'obj-CWidget-free', """
`free` - удаляет элемент из дерева DOM. Элемент остаётся и его можно добавить обратно в DOM

См. #remove
""", ->
	w = $("<i><em>0</em>1<b>2</b>3</i>")
	x = w.child(-1)
	x.free()
	@is w.outer(), "<i><em>0</em>13</i>"
	@is w.append(x).outer(), "<i><em>0</em>13<b>2</b></i>"


new CTest 'obj-CWidget-focus', """
`focus` - устанавливает фокус на элемент

См. #hasFocus
""", """
<input id=$name>
""", ->
	w=@w().focus()
	@ok w.hasFocus()


new CTest 'obj-CWidget-hasFocus', """
`hasFocus` - проверяет - в фокусе ли элемент

См. #hasFocus
""", """
<input id=$name>
""", ->
	@is @w().hasFocus(), false
	@is @w().focus(), @w()
	@is @w().hasFocus(), true


new CTest 'obj-CWidget-contains', """
`contains [content]` - возвращает дочерние ноды или устанавливает контент как дочерние ноды

См. #down
""", ->
	@is (w=$("<div>1<i>2</i></div>")).content().length, 2
	w.content "<u>3</u>4"
	@is w.content().outer(), "<u>3</u>4"

	
	
CTest.category "Манипулирование таблицей"

new CTest 'obj-CWidget-tab', """
`tab [i, [j, [, content]]]`

* `tab` - возвращает размерность таблицы, например, [5,5]
* `tab i` - возвращает строку new CWidgets [td11, td12...]
* `tab null, j` - возвращает столбец new CWidgets [td11, td21...]
* `tab i, j` - возвращает элемент ячейки
* `tab i, j, content` - устанавливает content в ячейку
* `tab i, j, {row: row, col: col}` - задаёт область, возвращаемую в виде матрицы. Элементы матрицы - виджеты
* `tab i, j, {}` - до конца таблицы
* `tab {}` - всю таблицу
* `tab [i], [j], {cells: матрица}` - устанавливает контент как ячейку или ячейки, если задан массив или матрица
* `tab {row: row, col: col}` - создаёт таблицу заданной размерности и возвращает её элементы в виде матрицы
* `tab i, [content11, content12...]` - устанавливает строку таблицы
* `tab null, j, [content11, content21...]` - устанавливает столбец
* `tab [[content11, content12...]...]` - устанавливает таблицу
* `tab i, j, [[content11, content12...]...]` - устанавливает ячейки с определённого i, j


""", """
#$name-div div { border: solid 1px Cornsilk }
#$name-div span { border: solid 1px lavender; background: MistyRose; *zoom: 1; display: inline; display: -moz-inline-stack; display: inline-block; }
""", """
<table id=$name border=1></table>

<div id=$name-div></div>
""", ->
	
	[row, col] = (w=@w()).tab()
	@is row, 0
	@is col, 0

	w.tab 1, 1, 10
	
	@is w.byTagAll('tr').length, 2
	@is w.byTagAll('td').length, 2
	
	[row, col] = w.tab()
	@is row, 2
	@is col, 2
	
	@is w.tab(0, 1), null
	@is w.tab$(1, 1), "10"
	
	w.tab 0, 1, [[20, 30]]
	@is w.tab(0, 1).html(), '20'
	@is w.tab(0, 2).text(), '30'
	
	w.tab null, 1, [50, 60, 70]
	@is w.tab$i(0, 1), 50
	@is w.tab$i(1, 1), 60
	@is w.tab$i(2, 1), 70
	
	w.tab null, 1, [100]
	@is w.tab$(0, 1), "100"
	@is w.tab$(1, 1), ""
	@is w.tab$(2, 1), ""
	
	w=@w "div"
	w.tab 1, 1, [[10, 20, 30]]
	@is w.tab$(1, 1), "10"
	@instanceof w.tab(1), CWidgets
	
	w.html ""
	matrix = w.tab row: 2, col: 6
	@instanceof matrix, Array
	@is matrix.length, 2
	@instanceof matrix[0], Array
	@is matrix[0][0].html(1).html(), "1"
	
	

new CTest 'obj-CWidget-tab$', """
`tab$ [i, [j, [, content]]]` - полностью аналогично #tab, только возвращает не виджеты, а innerHTML

См. #html
""", ->
	@is $('<div></div>').tab$(0,0), ""

new CTest 'obj-CWidget-tab$i', """
`tab$ [i, [j, [, content]]]` - полностью аналогично #tab, только возвращает не виджеты, а #val$i

См. #val, #val$f
""", ->
	@is $('<div></div>').tab$i(0,0), 0

new CTest 'obj-CWidget-tab$f', """
`tab$ [i, [j, [, content]]]` - полностью аналогично #tab, только возвращает не виджеты, а #val$f

См. #val, #val$i
""", ->
	@is $('<div></div>').tab$f(0,0), 0
	
new CTest 'obj-CWidget-rawstyle', """
`rawstyle [selector], [val], [before]` - работает с таблицами стилей. После первого же вызова - кеширует их. Кеш нужно сбрасывать вручную через `rawstyle 0`

1. `rawstyle` - возвращает все правила, влияющие на элемент. Правила имеют тип CSSStyleRule
1. `rawstyle 0` - сбрасывает кэш. Необходим, если таблицы стилей были изменены не через rawstyle или style
1. `rawstyle selector` - возвращает правила с указанным селектором. Селектор может быть как строкой, так и RegExp - в этом случае возвращает все подходящие под регулярку правила
1. `rawstyle rule` - удаляет правило. rule типа CSSStyleRule
1. `rawstyle selector, {name1: val1...}|text, [beforeRule|styleSheet]` - добавляет правило перед указанным правилом или в конец указанной страницы стилей. Если же ничего не указано - то в конец специальной страницы, создающейся при первом присваивании

Прим. Если необходимо создать страницу стилей, то воспользуйтесь @wrap('<style></style>').appendTo @head(); stylesheet$ = (s=@document().styleSheets)[s.length-1]

См. #style, #css
""", """
.rawstyle-example { background: red }
#$name {background: blue}
""", """
<div id=$name class=rawstyle-example>&nbsp;</div>
""", ->
	w=@w()
	styles = w.rawstyle()
	@is styles.length, 2
	@is styles[0].style.backgroundColor, "red"
	@is styles[1].style.backgroundColor, "blue"
	@is styles[0].selectorText, '.rawstyle-example'
	@is styles[1].selectorText.toLowerCase(), '#'+@name.toLowerCase()
	
	styles = w.rawstyle '.rawstyle-example'
	@is styles[0].selectorText, '.rawstyle-example'
	#styles[0].style.background = 'green'
	#@is styles[0].style.background, "red"
	#w.rawstyle 0
	#@is styles[0].style.background, "green"
	
	w.rawstyle styles[0]
	@is w.rawstyle().length, 1


new CTest 'obj-CWidget-style', """
`style [selector], [name], [val]` - пропускает стили через css-эмулятор, чего не делает rawstyle

1. `style` - возвращает массив селекторов правил стилей в которых участвует элемент
2. `style selector, name` - возвращает стиль из первого правила с указанным селектором
3. `style selector, name, val, [important]` - устанавливает стиль первого правила с таким селектором или создаёт правило
3. `style selector, null` - удаляет все правила с таким селектором
1. `style {name1: val1...}, [important]` - заменяет стили на указанные в первом правиле с селектором #id элемента или создаёт его
2. `style selector, {name1: val1...}` - заменяет стили в первом правиле с указанным селектором или создаёт его
2. `style selector, [name1, name2...]` - возвращает стили из первого правила с указанным селектором
1. `style name` - возвращает стиль из первого правила #id
1. `style [name1, name2...]` - возвращает стили из первого правила #id с указанным селектором

Новые правила создаются в специальной таблице стилей

Также см.: [rawstyle], [css]
""", """
.style-example { background: red }
#$name {background: blue}
""", """
<div id=$name class=style-example>&nbsp;</div>
""", ->

	w=@w()
	styles = w.style()
	@is styles.length, 2
	@is styles[0], '.style-example'
	@is styles[1].toLowerCase(), '#'+@name.toLowerCase()
	
	@is w.style('.style-example', 'background-color'), 'red'
	w.style '.style-example', 'background-color', 'green'
	@is w.style('.style-example', 'background-color'), 'green'
	w.style '.style-example', 'background-color': 'royalblue', color: 'green'
	@is w.style('.style-example', 'color'), 'green'
	
	color = ['royalblue', 'rgb(65, 105, 225)', '#4169e1', 'rgba(65, 105, 225, 1)']
	
	@ok w.style('.style-example', ['background-color'])['background-color'] in color
	w.style '.style-example', null
	@is w.style().length, 1
	@is w.style('.style-example', 'background'), null
	w.style '.style-example', background: 'royalblue', color: 'green'
	@ok w.style('.style-example', ['background-color'])['background-color'] in color
	
	@is w.style().length, 2

	
new CTest 'obj-CWidget-rule', """
`rule selector, [styles]` - возвращает объект со стилями для правил с таким селектором или заменяет их указанными стилями

Если требуется вернуть стили, а правила с таким селектором не существует, то возвращается {}

!important не возвращается

См. #rawstyle, #style
""", """
.rule-example { background: red /* hi! */ !important; float: left }
""", """
<div id=$name></div>
""", ->
	rule = @w().rule '.rule-example'
	@is rule.background, 'red'
	@is rule.float, 'left'
	@ok not('color' of rule)
	
	@w().rule '.rule-example', color: 'red'
	rule = @w().rule '.rule-example'
	@is rule.background, undefined
	@is rule.float, undefined
	@is rule.color, 'red'
	

new CTest 'obj-CWidget-pseudo', """
`pseudo pseudoElementOrClass` - возвращает объект для псевдокласса или псевдоэлемента, который можно использовать для работы с [css]

Примечание. Установка происходит через таблицу стилей

Также см.: #style, #css, #hasCss, #toggle
""", """
<a href="#" id=$name>1</a>
""", ->
	p=(w=@w()).pseudo(':hover')
	p.css 'background', 'royalblue'
	@is w.rgba('background-color')+"", 'rgba(0, 0, 0, 0)'
	@is p.rgba('background-color')+"", 'rgba(65, 105, 225, 1)'


new CTest 'obj-CWidget-hasCss', """
`hasCss style, [val]` - тестирует браузер на наличие указанного стиля. Если указан val, то может ли стиль иметь такое свойство

Также см.: #style, #css, #toggle
""", ->
	@ok CRoot.hasCss 'z-index'
	@ok CRoot.hasCss 'z-index', 1
	@ok not CRoot.hasCss 'z-index', "0px"
	@ok CRoot.hasCss 'background', 'linear-gradient(rgba(5,5,6,0.5), rgba(5,5,7,0.5))'


new CTest 'obj-CWidget-css', """
`css style, [val]` - возвращает или устанавливает стили элемента

1. Если style - объект, то устанавливает пары ключ-значение, как селектор-значение
2. Если style - массив, то возвращает ассоциативный массив со стилями элемента
3. Числовым значениям прибавляется "px", тем стилям где это нужно (width, font-size и т.д.)
4. Стили с бета-префиксами, вроде -webkit-transform, -moz-transform, преобразовываются в стили без префикса: transform
5. У метода css есть свойства:
5.1 with_css_prefix - ассоциативный массив, где ключём выступает 
5.2 toCssCase - преобразует ключ из вида использующегося в JavaScript в вид css
5.3 css_not_px - содержит ключи вида JavaScript, значения которых не нужно переводить в пикселы
5.4 css_px: css_px - содержит ключи вида JavaScript, значения которых нужно переводить в пикселы
5.5 css_set_fn - содержит ключи вида JavaScript и функции установки значения стиля
5.6 css_get_fn - содержит ключи вида JavaScript и функции возврата значения стиля

Также см.: #style, #hasCss
""", """
<div id=$name></div>
""", ->
	w = @w()
	@is w.css('float', 'left'), w
	@is w.css('float'), 'left'
	
	w = $('<div></div>')
	@is w.css('float', 'left'), w
	@is w.css('float'), 'left'

	w = w.pseudo("")
	@is w.css('float', 'left'), w
	@is w.css('float'), 'left'
	
	
new CTest 'obj-CWidget-px', """ 
`px style` - возвращает значение стиля в пикселах

Также см.: #style, #hasCss, #css, #em, #rgba
""", """

<div style="padding:10px; border: solid 1px gray">
<div id=$name class=test-square></div>
</div>
<div id=$name-log></div>

""", ->
	w=@w()
	log = @w "log"
	log.append "viewWidth=" + w.viewWidth() + '<br>'
	log.append "viewHeight=" + w.viewHeight() + '<br>'
	log.append "real.px=" + w.width() + '<br>'
	log.append "px=" + w.px('width') + "=" + w.px(150) + '<br>'
	log.append "vw=" + w.vw('width') + "=" + w.px('150vw') + '<br>'
	log.append "vh=" + w.vh('width') + "=" + w.px('150vh') + '<br>'
	log.append "vmin=" + w.vmin('width') + "=" + w.px('150vmin') + '<br>'
	log.append "pw=" + w.ph('width') + "=" + w.px('150pw') + '<br>'
	log.append "ph=" + w.ph('width') + "=" + w.px('150ph') + '<br>'
	log.append "em=" + w.em('width') + "=" + w.px('150em') + '<br>'
	log.append "rem=" + w.rem('width') + "=" + w.px('150rem') + '<br>'
	log.append "ex=" + w.ex('width') + "=" + w.px('150ex') + '<br>'
	log.append "pt=" + w.pt('width') + "=" + w.px('150pt') + '<br>'
	log.append "mm=" + w.mm('width') + "=" + w.px('150mm') + '<br>'
	log.append "cm=" + w.cm('width') + "=" + w.px('150cm') + '<br>'
	log.append "pc=" + w.pc('width') + "=" + w.px('150pc') + '<br>'
	log.append "in=" + w.in('width') + "=" + w.px('150in') + '<br>'
	
	@is w.px('width'), 150


new CTest 'obj-CWidget-rgba', """
`rgba style` - возвращает объект CColor, который затем можно преобразовать в любой из представления цвета

Также см.: #style, #hasCss, #css, #px
""", ->
	@is CRoot.rgba('#4169E1').name(), 'royalblue'

	

new CTest 'obj-CWidget-vw', """
`vw style` - возвращает значение стиля в процентах от ширины окна

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.vw(150)+'vw'), 150


new CTest 'obj-CWidget-vh', """
`vh style` - возвращает значение стиля в процентах от высоты окна

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.vh(150)+'vh'), 150


new CTest 'obj-CWidget-vmin', """
`vmin style` - возвращает значение стиля в процентах от высоты или, если ширина меньше высоты, ширины окна

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.vmin(150)+'vmin'), 150
	

new CTest 'obj-CWidget-pw', """
`pw style` - возвращает значение стиля в процентах от ширины элемента

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.pw(150)+'pw'), 150


new CTest 'obj-CWidget-ph', """
`ph style` - возвращает значение стиля в процентах от высоты элемента

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.ph(150)+'ph'), 150

	
new CTest 'obj-CWidget-em', """
`em style` - возвращает значение стиля в размерах шрифта элемента

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.em(150)+'em'), 150


new CTest 'obj-CWidget-rem', """
`rem style` - возвращает значение стиля в размерах шрифта элемента HTML

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.rem(150)+'rem'), 150


new CTest 'obj-CWidget-ex', """
`rem style` - возвращает значение стиля в размерах шрифта элемента HTML

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.ex(150)+'ex'), 150
	@ok CRoot.px('150ex') < CRoot.px('150em')


new CTest 'obj-CWidget-pt', """
`pt style` - возвращает значение стиля в пунктах

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.pt(150)+'pt'), 150

	

new CTest 'obj-CWidget-cm', """
`cm style` - возвращает значение стиля в сантиметрах

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.cm(150)+'cm'), 150


new CTest 'obj-CWidget-mm', """
`mm style` - возвращает значение стиля в миллиметрах

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.mm(150)+'mm'), 150
	
	
new CTest 'obj-CWidget-in', """
`in style` - возвращает значение стиля в дюймах

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.in(150)+'in'), 150


new CTest 'obj-CWidget-pc', """
`pc style` - возвращает значение стиля в пиках

Также см.: #style, #hasCss, #css, #px
""", ->
	@is$f CRoot.px(CRoot.pc(150)+'pc'), 150

	
new CTest 'obj-CWidget-toggle', """
* `toggle name, styles...` - переключает стиль name на следующий из styles
* `toggle` - переключает стиль _display_ между 'none' и ''
* `toggle name, style` - переключает стиль name между его значением и ''

Также см.: #style, #hasCss, #css, #px
""", ->
	w=$('<div></div>').toggle()
	@is 'none', w.element.style['display']
	w.css 'color', 'red'
	w.toggle 'color', ['blue', 'green', 'red']
	@is 'blue', w.element.style['color']
	


CTest.category "методы атрибутов и свойств"	


new CTest 'obj-CWidget-attr', """
* `attr name, [val]` - устанавливает, возвращает или удаляет атрибут
* `attr [name1, ...]` - возвращает объект с значениями указанных атрибутов
* `attr name, null` - удаляет атрибут
* `attr {name1: val1 ...}` - множественное присваивание/удаление

'Примечание' - если атрибута нет, то возвращается null

См. #prop, #toggleAttr, #css, #addClass
""", """
<div id="$name"></div>
""", ->
	w = @w()
	@is null, w.attr "attribute"
	@ok not /attribute/.test w.outer()
	w.attr "attribute", "color"
	@is "color", w.attr "attribute"
	w.attr "attribute", null
	@is null, w.attr "attribute"
	

new CTest 'obj-CWidget-toggleAttr', """
`toggleAttr name, [val...]` - переключает атрибут на его следующее значение в списке параметров. Если список не указан - то используется [null, 'disabled']

См. #toggle, #toggleClass
""", ->
	w=$('<input>').toggleAttr()
	@is 'disabled', w.attr('disabled')
	@is null, w.toggleAttr().attr('disabled')
	w.attr 'color', 'red'
	w.toggleAttr 'color', 'blue', 'green', 'red'
	@is 'blue', w.attr('color')	

new CTest 'obj-CWidget-prop', """
* `prop name, [val]` - устанавливает, возвращает или удаляет атрибут
* `prop [name1, ...]` - возвращает объект с значениями указанных атрибутов
* `prop name, null` - удаляет атрибут
* `prop {name1: val1 ...}` - множественное присваивание/удаление

'Примечание' - если атрибута нет, то возвращается null

См. #attr, #css, #addClass
""", ->
	w = $("<div></div>")
	@is undefined, w.prop "property"
	w.prop "property", "color"
	@is "color", w.prop "property"

	
new CTest 'obj-CWidget-toggleProp', """
`toggleProp name, [val...]` - переключает атрибут на его следующее значение в списке параметров. Если список не указан - то используется [null, 'disabled']

См. #toggle, #toggleClass
""", ->
	w=$('<input type=checkbox>').toggleProp()
	@is w.prop('checked'), true
	@is false, w.toggleProp().prop('checked')
	w.prop 'color', 'red'
	w.toggleProp 'color', 'blue', 'green', 'red'
	@is 'blue', w.prop('color')


new CTest 'obj-CWidget-addClass', """
`addClass class, [timeout], [listen]` - добавляет один или несколько классов

См. #toggleClass, #removeClass, #hasClass
""", """
<div id=$name></div>

<a href="#" onclick="$(this).prev().toggleClass('test-square', 'fast'); return false">удалить / добавить класс</a>
""", ->
	w = $("<div></div>").addClass "c1 c2"
	@is w.element.className, "c1 c2"
	w.addClass ["c3", "c1"]
	@is w.element.className, "c1 c2 c3"
	self = this
	@w().addClass "test-square", "fast", -> self.ok @hasClass "test-square"; self.ok not @attr 'style'
	

new CTest 'obj-CWidget-toggleClass', """
`toggleClass classes, [timeout], [listen]` - переключает класс на следующий в списке classes. Если следующий параметр null - то класс удаляется

См. #toggle, #toggleAttr, #toggleProp
""", """
<div id=$name></div>

<a href="#" onclick="$(this).prev().toggleClass('test-square', 'fast'); return false">удалить / добавить класс</a>
""", ->
	@count 8
	w=$('<input class="on">').toggleClass('on off')
	@ok w.hasClass('off')
	@ok !w.hasClass('on')
	w.toggleClass(['on', 'off'])
	@ok !w.hasClass('off')
	@ok w.hasClass('on')
	w.toggleClass(['on', null, 'off'])
	@ok !w.hasClass('off')
	@ok !w.hasClass('on')
	self = this
	@w().toggleClass "test-square", "fast", -> self.ok @hasClass "test-square"; self.ok not @attr 'style'

	
new CTest 'obj-CWidget-show', """
`show [timeout], [listen]` - показывает элемент, устанавливая его свойство css _display_ в !''
""", """
<div class=test-square>тест show / hide</div>
<a id=$name href="#" onclick="p=$(this).prev(); if(p.element.style.display == 'none') p.show('fast'); else p.hide('fast'); return false">скрыть / показать</a>
""", ->
	@is $('<div style="display: none"></div>').show().css('display'), ''


new CTest 'obj-CWidget-hide', """
`hide [timeout], [listen]` - скрывает элемент, устанавливая его свойство css _display_ в !'none'
""", ->
	@is $('<div></div>').hide().css('display'), 'none'


new CTest 'obj-CWidget-vid', """
`vid [timeout], [listen]` - показывает элемент, устанавливая его свойство css _visibility_ в ''
""", """
<div class=test-square>тест vid / novid</div>
<a id=$name href="#" onclick="p=$(this).prev(); if(p.element.style.visibility == 'hidden') p.vid('fast'); else p.novid('fast'); return false">скрыть / показать</a>
""", ->
	@is $('<div style="visibility: hidden"></div>').vid().css('visibility'), ''


new CTest 'obj-CWidget-novid', """
`novid [timeout], [listen]` - скрывает элемент, устанавливая его свойство css _visibility в !'hidden'
""", ->
	@is $('<div></div>').novid().css('visibility'), 'hidden'


new CTest 'obj-CWidget-toggleVid', """
`toggleVid [timeout], [listen]` - меняет visibility элемента, устанавливая его свойство css _visibility в !'hidden'
""", ->
	@is $('<div></div>').toggleVid().css('visibility'), 'hidden'
	@is $('<div style="visibility:hidden"></div>').toggleVid().css('visibility'), ''


new CTest 'obj-CWidget-visible', """
`visible` - проверяет - является ли элемент видимым
""", ->
	@is $('<div></div>').visible(), off
	@is $('<div></div>').appendTo(/body/).visible(), on
	
	
new CTest 'obj-CWidget-absolute', """
`absolute` - как и pos возвращает {left, top, right, bottom, width, height} элемента относительно верхнего левого угла документа и даже если элемент скрыт
""", """
<div>
	<div>
		<div id="$name" style="width:10px; height:10px">show</div>
	</div>
</div>
""", ->
	w = @w()
	p = w.up().up()
	@is 10, w.width()
	@is 10, w.height()
	p.hide()
	@is 0, w.width()
	@is 0, w.height()
	{height, width} = w.absolute()
	@is 10, width
	@is 10, height
	@is 0, w.width()
	@is 0, w.height()

	
CTest.category "методы расположения на экране"

new CTest 'obj-CWidget-vscroll', """
- `vscroll` - возвращает позицию горизонтального скролла
- `vscroll "bar"` - возвращает ширину скроллбара
- `vscroll "size"` - возвращает размер скроллбара
- `vscroll "inner"` - возвращает размер скроллбара без padding-а элемента
- `vscroll "end"` - стоит ли скролл в самом конце
- `vscroll "begin"` - стоит ли скролл в самом начале
- `vscroll val` - устанавливает положение горизонтального скролла в любых единицах: px, pt, in, em, % и т.д.

См. #hscroll
""", """
<div id="$name" style="width:20px; height:20px; overflow: scroll">scroll</div>
""", ->
	w = @w()
	

new CTest 'obj-CWidget-hscroll', """
- `hscroll` - возвращает позицию вертикального скролла
- `hscroll "bar"` - возвращает высоту скроллбара
- `hscroll "size"` - возвращает размер скроллбара
- `hscroll "inner"` - возвращает размер скроллбара без padding-а элемента
- `hscroll "end"` - стоит ли скролл в самом конце
- `hscroll "begin"` - стоит ли скролл в самом начале
- `hscroll val` - устанавливает положение вертикального скролла в любых единицах: px, pt, in, em, % и т.д.

См. #vscroll
""", """
<div id="$name" style="width:20px; height:20px; overflow: scroll">scroll</div>
""", ->
	w = @w()


new CTest 'obj-CWidget-viewPos', """
`viewPos` - возвращает позицию элемента относительно окна

См. #pos, #width, #left
""", """
<div id="$name">pos</div>
""", ->
	w = @w()
	{left, top, right, buttom, width, height} = w.viewPos()
	@ok left
	

new CTest 'obj-CWidget-pos', """
`pos` - возвращает позицию элемента в документе

См. #viewPos, #width, #left
""", """
<div id="$name">pos</div>
""", ->
	w = @w()
	{left, top, right, buttom, width, height} = w.pos()
	r = w.viewPos()

	@gt top, r.top+1
	

new CTest 'obj-CWidget-left', """
`left [val]` - возвразщает/устанавливает смещение элемента по горизонтали в документе

См. #pos, #width, #top
""", """
<div id="$name">pos</div>
""", ->
	w = @w()
	@ok w.left() < w.right()


new CTest 'obj-CWidget-top', """
`top [val]` - возвразщает/устанавливает смещение элемента по вертикали в документе

См. #pos, #width, #left
""", """
<div id="$name">pos</div>
""", ->
	w = @w()
	@ok w.top() < w.bottom()
	

new CTest 'obj-CWidget-right', """
`right [val], [usePos]` - возвразщает/устанавливает смещение границы элемента по горизонтали в документе

- `right val` - увеличивает `width` элемента до `val`
- `right val, true` - устанавливает `top` элемента до `val-width`

См. #pos, #width, #top
""", """
<div id="$name">pos</div>
""", ->
	w = @w()
	@ok w.left() < w.right()


new CTest 'obj-CWidget-bottom', """
`bottom [val], [usePos]` - возвразщает/устанавливает смещение границы элемента по горизонтали в документе

- `bottom val` - увеличивает `width` элемента до `val`
- `bottom val, true` - устанавливает `top` элемента до `val-width`

См. #pos, #width, #top
""", """
<div id="$name">pos</div>
""", ->
	w = @w()
	@ok w.top() < w.bottom()


new CTest 'obj-CWidget-clientWidth', """
`clientWidth` - возвразщает/устанавливает ширину элемента. Если у элемента есть скроллбары, то ширина их не учитывает

См. #pos, #width, #top
""", """
<div id="$name">pos</div>
""", ->
	w = @w()


	
new CTest 'obj-CWidget-width', """
`width [width]` - возвращает или устанавливает ширину элемента
""", """
.$name-text {position: absolute}
.$name-line {background: lavender}
""", """

<div id="name-outer" class="inline-block" style="border: dashed 1px gray">
	<div id="$name-scrollbox" class="$name-text" style="margin: 80px 0px 0px 280px"></div>
	<div class=$name-text>margin: 40px</div>
	<div class=$name-text style="margin: 20px">border: 40px</div>
	<div id="$name" style="padding:20px; margin: 20px; overflow:scroll; border: solid 20px red; width:150px; height:150px; background: lavender">
		<div class=$name-text style="margin: -20px">padding: 40px</div>
		<div id="$name-inner" style="border: dashed 1px gray; width:200px; height: 200px">
			<div style="border-right: dashed 1px gray; border-bottom: dashed 1px gray; width:149px; height: 149px; margin: -1px">
				150x150<br>in 200x200
			</div>
		</div>
	</div>
</div>



""", ->
	w=@w().tooltip("hi!")
	box=@w("scrollbox").html "vscroll-bar: "+w.vscroll("bar")+"px<br>hscroll-bar: "+w.hscroll("bar")+"px<br>hscroll-top: "+w.hscroll()+"px<br>hscroll-size: "+w.hscroll('size')+"px<br>hscroll-inner: "+w.hscroll('inner')+"px"

	cls_line = @name+'-line'
	
	ow1 = w.line 'right', 0, 600, cls_line, 20, 21
	ow2 = w.line 'right', 1, 600, cls_line, 20, 21
	ow3 = ow1.line('bottom', 0.97, w.outerWidth()-20, cls_line).css('margin-top', '10px').arrow('bottom').arrow('top')
	w.wrap("<div>outerHeight<br>"+w.outerHeight()+"px</div>").css('padding', 4).appendTo(w.body()).position ow3, 'right'

	ow1 = w.line 'right', 0, 500, cls_line
	ow2 = w.line 'right', 1, 500, cls_line
	ow3 = ow1.line('bottom', 0.97, w.offsetWidth()-22, cls_line).css('margin-top', '10px').arrow('bottom').arrow('top')
	w.wrap("<div>offsetHeight<br>"+w.offsetHeight()+"px</div>").css('padding', 4).appendTo(w.body()).position ow3, 'right'

	
	ow1 = w.line 'right', 0, 400, cls_line, 0, -20
	ow2 = w.line 'right', 1, 400, cls_line, 0, -20
	ow3 = ow1.line('bottom', 0.97, w.width()-22, cls_line).css('margin-top', '10px').arrow('bottom').arrow('top')
	w.wrap("<div>height<br>"+w.height()+"px</div>").css('padding', 4).appendTo(w.body()).position ow3, 'right'
	
	
	ow1 = w.line 'right', 0, 300, cls_line, 0, -40
	ow2 = w.line 'right', 1, 300, cls_line, 0, -40
	ow3 = ow1.line('bottom', 0.97, w.innerWidth()-22, cls_line).css('margin-top', '10px').arrow('bottom').arrow('top')
	w.wrap("<div>innerHeight<br>"+w.innerHeight()+"px</div>").css('padding', 4).appendTo(w.body()).position ow3, 'right'	

	

CTest.category "методы событий времени и анимации"

new CTest 'obj-CWidget-timeout', """
`timeout time, name, args...` - вызывает метод name c аргументами args единожды, через time миллисекунд

См. #clear, #interval
""", ->
	@count 4
	self = this
	flag = 0
	date = new Date()
	class window.Ex extends CWidget
		realloc: (n, k) -> self.is n, 10 ; self.is k, 30 ; self.ge new Date().getTime() - date.getTime(), 30 ; flag = 1
		
	w = $("<div ctype=Ex></div>").timeout 30, "realloc", 10, 30
	@is flag, 0
	

new CTest 'obj-CWidget-interval', """
`interval time, name, args...` - вызывает метод name c аргументами args через каждые time миллисекунд

См. #clear, #timeout
""", ->
	@count 2
	
	counter = 0
	self = this
	class window.Ex extends CWidget
		realloc: (n, k) -> self.is n, 10 ; if 2 == ++counter then @clear "realloc"
		
	w = $("<div ctype=Ex></div>").interval 30, "realloc", 10, 30


new CTest 'obj-CWidget-clear', """
`clear [name]` - удаляет все установленные #timeout-ом и #interval-ом

См. #clear, #timeout
""", ->
	@ok CRoot.clear


new CTest 'obj-CWidget-animate', """
`animate param, [timeout], [fps], [listener], [progress]` - изменяет с течением времени заданные css-параметры

- param - объект с параметрами css
- timeout - интервал в миллисекундах или строка fast=600, slow=200, norm=400 за который происходит анимация. Если не указана - берётся norm
- fps - частота кадров в секунду с которой будет происходить анимация. По умолчанию - 100. Это значит, что раз в 10 миллисекунд будут изменяться параметры css
- listener - название метода или функция, которая будет вызвана по звершению. По умолчанию посылается метод onAnimate
- progress [start, k, progress] - функция или имя метода - запускается на каждом шаге анимации

значения 'param' должны быть в формате:
[+=|-=] значение_css [in|out|io] [функция]

- значение_css - конечное значение, если не указаны +=|-=, иначе - значение на которое увеличится текущее. Может быть: цветом
- in - #CMath.easeIn - ничего не делает
- out - #CMath.easeOut - искажает функцию так, что она выполняется как бы с конца
- io - #CMath.easeInOut
- функция - название функции из CMath: #CMath.linear, #CMath.elastic, #CMath.bounce и т.п.

- `animate "toggle", [fn]` - возвращает css-параметры к предыдущим значениям с теми же настройками timeout и fps
- `animate "clear"` - останавливает и очищает очередь анимации
- `animate "clear", fn` - удаляет из очереди анимации указанную функцию
- `animate "stop"` - останавливает очередь анимации
- `animate "end"` - мгновенно завершает текущую анимацию и очищает очередь анимации
- `animate` - запускает очередь анимации
- `animate "active"` - возвращает выполняющуюся в данный момент функцию анимации
- `animate "empty"` - возвращает *true* или *false* в зависимости от того - пуста очередь анимации объекта или нет

""", """
.animate-square {position:absolute; background: orange; border: solid 1px brown; cursor:pointer}
""", """

<div id=$name class=animate-square onclick="this.widget.animate('toggle')">margin-left: 100px; margin-top: 50px</div>

<div id=$name-plus class=animate-square><input type=button value="влево" onclick="this.parentNode.widget.animate({'margin-left': '-=150pt'})"> <input type=button value="вправо" onclick="this.parentNode.widget.animate({'margin-left': '+=150pt'})"></div>

<div id=$name-square class=test-square onclick="say('fff'); $('#$name-square').swap('#$name-move', 'fast')">&nbsp;</div>
<div id=$name-move style='border: solid 1px green' class=test-square onclick="$('#$name-square').swap('#$name-move', 'fast')">&nbsp;</div>

""", ->
	@count 6
	self = this
	w = @w()
	w.animate
		'margin-left': 100
		'margin-top': 50
		'background-color': 'rgba(33,12,45,0.6)'
		color: '#fa6'
		'border-color': 'red'
	, -> 
		self.is '100px', @css 'margin-left'
		self.is '50px', @css 'margin-top'
		self.is 'rgba(33, 12, 45, 0.6)', ""+@rgba 'background-color'
		self.is '#FA6', @rgba('color').smallhex()
		self.is 'red', @rgba('border-color').name()
		
	@w("plus").css('margin-left', 10).animate 'margin-left': "+=100pt", 1000, 100, -> self.is$f @pt("10px") + 100, @pt('margin-left'), 0.01


new CTest 'obj-CWidget-morph', """
`morph param` - анимирует виджет. В отличие от #animate принимает набор параметров

Параметры:
- effect - название эффекта из CEffect - расширяет им параметры
- from - начальные значения для анимации
- to - конечные значения для анимации
- easy - in|out|io и/или функция по умолчанию, если не указана в параметре из to
- timeout - время отпущенное на анимацию в миллисекундах или строка fast=600, slow=200, norm=400 или объект. В последнем случае параметры будут расширены этим объектом
- fps - частота кадров в секунду
- css - стили устанавливаются на период анимации, а затем - восстанавливаются
- save - 1 - from и to будут восстановлены после анимации (по умолчанию), 0 - не будут восстановлены
- begincss - css устанавливается до начала анимации, после сохранения
- endcss - css устанавливается после окончания анимации и после восстановления сохранённых стилей
- queue - очередь параметров для morph, которая будет установлена после поставки в очередь анимаций текущей
- begin - функция или имя метода - запускается до начала анимации
- end [param] - функция или имя метода - запускается в конце анимации
- end1 [param] - функция или имя метода - запускается в конце анимации, после end
- progress [start, k, progress] - функция или имя метода - запускается на каждом шаге анимации


Из progress можно получить созданную для анимации функцию anim через arguments.caller

Если стиля из from нет в to, а из to нет в from, то to или from дополняется вычесленным текущим стилем

См. #animate
""", """
<div class=test-square id=$name onclick="$(this).animate('toggle')"></div>
""", ->
	@count 1
	self = this
	@w().morph save: 0, to: { 'background-color': 'gainsboro' }, end: -> self.is @rgba('background-color').name(), 'gainsboro'
	
	
new CTest 'obj-CWidget-shape', """
`shape shape` - добавляет виджет в шейп

Шейп - это виджет-обёртка, которая вставляется на место оборачиваемого виджета и содержит как оборачиваемый виджет, так и привязанные к нему виджеты
При этом тег оборачиваемого виджета изменяется с li и td на div.
И шейп и обёрнутый элемент обслуживаются одним и тем же виджетом, только операции вроде #before работают с верхним элементом, а #content и #append - с нижним.
""", """
""", ->
	w = $ "<div></div>"

	
new CTest 'obj-CWidget-position', """
`position elem, scalex, [scaley], [scaleselfx], [scaleselfy], [addX], [addY]` - абсолютное позиционирование элемента


""", """

#$name-bs, .%name div { position: absolute; width: 10px; height: 10px; border: solid 3px blue; background-color: red; }
.%name div.after { background-color: green }

#$name-bs {margin-left: 800px; margin-top: -100px}

""","""
<div id=$name class=test-square>&nbsp;</div>
<div id=$name-ts class=test-square>&nbsp;</div>

<div id=$name-bs>&nbsp;</div>

<div class=%name>
<div id="%name-lefttop">&nbsp;</div>
</div>

""", ->

	w=@w('lefttop')
	main = @w()
	
	w.addClass('after').position main, 'left', 'top'
	w = w.clone(@name+'-center_top').insertBefore(w).position main, 'center', 'top'
	
	@is$f w.viewPos().bottom, main.viewPos().top
	@is$f (p=w.viewPos()).right - p.left, p.width
	
	w.clone(@name+'-right_top').insertBefore(w).position main, 'right', 'top'
	
	w.clone(@name+'-left_mid').insertBefore(w).position main, 'left', 'mid'
	w.clone(@name+'-center_mid').insertBefore(w).position main, 'center', 'mid'
	w.clone(@name+'-right_mid').insertBefore(w).position main, 'right', 'mid'
	
	w.clone(@name+'-left_bottom').insertBefore(w).position main, 'left', 'bottom'
	w.clone(@name+'-center_bottom').insertBefore(w).position main, 'center', 'bottom'
	w.clone(@name+'-right_bottom').insertBefore(w).position main, 'right', 'bottom'
	
	
	(w=w.clone().insertBefore(w).removeClass('after')).position main, 'left', 'top', 'before', 'before'
	w.clone().insertBefore(w).position main, 'center', 'top', 'before', 'before'
	w.clone().insertBefore(w).position main, 'right', 'top', 'before', 'before'
	
	w.clone().insertBefore(w).position main, 'left', 'mid', 'before', 'before'
	w.clone().insertBefore(w).position main, 'center', 'mid', 'before', 'before'
	w.clone().insertBefore(w).position main, 'right', 'mid', 'before', 'before'
	
	w.clone().insertBefore(w).position main, 'left', 'bottom', 'before', 'before'
	w.clone().insertBefore(w).position main, 'center', 'bottom', 'before', 'before'
	w.clone().insertBefore(w).position main, 'right', 'bottom', 'before', 'before'
	
	main = @w "ts"
	w=w.clone().insertBefore(w).position main, 'left', 'top', 'before', 'before', -10, -10
	w.clone().insertBefore(w).position main, 'center', 'top', 'before', 'before', -10, -10
	w.clone().insertBefore(w).position main, 'right', 'top', 'before', 'before', -10, -10
	
	w.clone().insertBefore(w).position main, 'left', 'mid', 'before', 'before', -10, -10
	w.clone().insertBefore(w).position main, 'center', 'mid', 'before', 'before', -10, -10
	w.clone().insertBefore(w).position main, 'right', 'mid', 'before', 'before', -10, -10
	
	w.clone().insertBefore(w).position main, 'left', 'bottom', 'before', 'before', -10, -10
	w.clone().insertBefore(w).position main, 'center', 'bottom', 'before', 'before', -10, -10
	w.clone().insertBefore(w).position main, 'right', 'bottom', 'before', 'before', -10, -10
	
	
	w=w.clone().insertBefore(w).addClass('after').position main, 'left', 'top', 'after', 'after', 10, 10
	w.clone().insertBefore(w).position main, 'center', 'top', 'after', 'after', 10, 10
	w.clone().insertBefore(w).position main, 'right', 'top', 'after', 'after', 10, 10
	
	w.clone().insertBefore(w).position main, 'left', 'mid', 'after', 'after', 10, 10
	w.clone().insertBefore(w).position main, 'center', 'mid', 'after', 'after', 10, 10
	w.clone().insertBefore(w).position main, 'right', 'mid', 'after', 'after', 10, 10
	
	w.clone().insertBefore(w).position main, 'left', 'bottom', 'after', 'after', 10, 10
	w.clone().insertBefore(w).position main, 'center', 'bottom', 'after', 'after', 10, 10
	w.clone().insertBefore(w).position main, 'right', 'bottom', 'after', 'after', 10, 10

	bs = @w('bs')
	
	main.clone(@name+'-rs').insertBefore(main).css('margin': 0).position bs, 'left', 'top', 'after', 'after'


new CTest 'obj-CWidget-relative', """
`relative elem, scalex, [scaley], [scaleselfx], [scaleselfy], [addX], [addY]` - позиционирование элемента относительно элемента в котором он находится

Элемент перемещается в elem, если он ещё не в нём, и позиционируется путём установки margin-left и margin-top. Ему так же проставляется position: absolute

""", """

.%name { width:150px; height: 150px; background-color: lavender; border-left: 0; border-right: solid 3px red; border-top: solid 5px red; border-bottom: solid 1px red; font-size: 40pt}

.%name div { position: absolute; width: 10px; height: 10px; border: solid 3px blue; background-color: red; }
.%name div.after { background-color: green }

#$name-bs {margin-left: 800px; margin-bottom: 30px; font-size: 40pt; background: goldenrod}
#$name-ts {text-align:center; vertical-align: middle }
.%name-ts-tab { margin-left: 300px; margin-top: -100px; }

""","""

	<div id=$name class="%name">main
		<div id="%name-lefttop">&nbsp;</div>
	</div>

	<table class="$name-ts-tab">
	<tr><td id=$name-ts class="%name">ts
	</table>

	<div id=$name-bs>bs</div>

""", ->

	w=@w('lefttop')
	main1 = main = @w()
	
	w.addClass('after').relative main, 'left', 'top'
	w.clone(@name+'-center_top').relative main, 'center', 'top'
	w.clone(@name+'-right_top').relative main, 'right', 'top'
	
	w.clone(@name+'-left_mid').relative main, 'left', 'mid'
	w.clone(@name+'-center_mid').relative main, 'center', 'mid'
	w.clone(@name+'-right_mid').relative main, 'right', 'mid'
	
	w.clone(@name+'-left_bottom').relative main, 'left', 'bottom'
	w.clone(@name+'-center_bottom').relative main, 'center', 'bottom'
	w.clone(@name+'-right_bottom').relative main, 'right', 'bottom'
	
	
	w=w.clone().removeClass('after').relative main, 'left', 'top', 'before', 'before'
	w.clone().relative main, 'center', 'top', 'before', 'before'
	w.clone().relative main, 'right', 'top', 'before', 'before'
	
	w.clone().relative main, 'left', 'mid', 'before', 'before'
	w.clone(@name+'-center_mid_before').relative main, 'center', 'mid', 'before', 'before', -10
	w.clone().relative main, 'right', 'mid', 'before', 'before'
	
	w.clone().relative main, 'left', 'bottom', 'before', 'before'
	w.clone().relative main, 'center', 'bottom', 'before', 'before'
	w.clone().relative main, 'right', 'bottom', 'before', 'before'
	
	
	main = @w "ts"
	w=w.clone().prependTo(main).relative main, 'left', 'top', 'before', 'before', -10, -10
	w.clone().relative main, 'center', 'top', 'before', 'before', -10, -10
	w.clone().relative main, 'right', 'top', 'before', 'before', -10, -10
	
	w.clone().relative main, 'left', 'mid', 'before', 'before', -10, -10
	w.clone().relative main, 'center', 'mid', 'before', 'before', -10, -10
	w.clone().relative main, 'right', 'mid', 'before', 'before', -10, -10
	
	w.clone().relative main, 'left', 'bottom', 'before', 'before', -10, -10
	w.clone().relative main, 'center', 'bottom', 'before', 'before', -10, -10
	w.clone().relative main, 'right', 'bottom', 'before', 'before', -10, -10
	
	
	(w=w.clone().addClass('after')).relative main, 'left', 'top', 'after', 'after', 10, 10
	w.clone().relative main, 'center', 'top', 'after', 'after', 10, 10
	w.clone().relative main, 'right', 'top', 'after', 'after', 10, 10
	
	w.clone().relative main, 'left', 'mid', 'after', 'after', 10, 10
	w.clone().relative main, 'center', 'mid', 'after', 'after', 10, 10
	w.clone().relative main, 'right', 'mid', 'after', 'after', 10, 10
	
	w.clone().relative main, 'left', 'bottom', 'after', 'after', 10, 10
	w.clone().relative main, 'center', 'bottom', 'after', 'after', 10, 10
	w.clone().relative main, 'right', 'bottom', 'after', 'after', 10, 10

	bs = @w 'bs'
	
	rs = @w().clone(@name+"-rs").css('margin': 0).relative bs, 'left', 'top', 'after', 'after'
	rs.down().grep(-> @element.nodeType == 3).text "rs"
	

CTest.category "методы шейпов"


new CTest 'obj-CWidget-arrow', """
`arrow pos = 'right', scale = 0.5, height = 10, width = 20, scale_corner = 0.5` - добавляет стрелку к блоку

* pos - c какой стороны элемента будет стрелка left|right|top|bottom
* scale - местонахождение стрелки на указанной стороне - 0.5 - посередине. 0..1
* height - высота стрелки в px
* width - ширина основания стрелки (стрелка - треугольник) в px
* scale_corner - сдвиг указующего угла стрелки - 0..1

""", """

<div style='position: absolute; margin-left: 150px; width: 100px; height: 100px; background: white; border: solid 1px orange'>123</div>
<div id=$name class=test-square style="background: #0A0A0A"></div>

""", ->
	w = @w().css opacity: 0.5, 'box-shadow': '3px 4px 5px 6px royalblue'
	w.arrow 'top', 0.5, 10, 50
	@is$f w._arrow.pos().top, w.pos().top - 10
	@is$f w._arrow.pos().left, w.pos().left + (w.offsetWidth() - 50) * 0.5
	w._arrow = null ; w.arrow 'bottom', 0.5, 10, 50
	@is$f w._arrow.pos().bottom, w.pos().bottom + 10
	w._arrow = null ; w.arrow 'left', 0.5, 10, 50
	@is$f w._arrow.pos().left, w.pos().left - 10
	w._arrow = null ; w.arrow 'right', 1, 10, 50
	@is$f w._arrow.pos().right, w.pos().right + 10


new CTest 'obj-CWidget-line', """
line pos = 'right', scale = 0, len = 30, className = '', addx = 0, addy = 0

Создаёт красную линию из div-а. Линия может быть только вертикальной или горизонтальной. Она сразу вставляется в body и выравнивается на 
""", """
<div id="$name" class=test-square></div>
""", ->
	line = @w().line()
	@is line.rgba("background").name(), "red"

	
new CTest 'obj-CWidget-edit', """
edit opt - делает элемент редактируемым (на самом деле просто выводит над ним input или textarea)

Опции:
- line - определяет, будет ли элемент редактироваться в одну строку
- css - дополнительные стили для элемента-редактора

Посылает событие onBeforeEdit до того, как изменит редактируемый элемент. И onEdit после того как изменит.
Для вставки в элемент данных используется метод dataType

""", """
<div id="$name" class=test-square></div>
""", ->
	@count 3
	w=@w()
	w.onBeforeEdit = (edit) => edit.val "123"; @ok CRoot.contains edit
	w.onEdit = => @is w.val(), "123"
	w.edit()
	@is w._edit.hasFocus(), true
	w.append("<input>").last().focus()
	
	

	
CTest.category "методы ajax"

new CTest 'obj-CWidget-dataType', """
`dataType text` - преобразует text в данные. Используется при загрузке методами #load и #submit
""", ->
	

new CTest 'obj-CWidget-param', """
`param` - возвращает параметры для отправки данных виджета на сервер. Используется методами #save и #submit

См. #dataType
""", ->


new CTest 'obj-CWidget-load', """
`load [param], [args...]` - загружает данные в виджет посредством ajax-запроса

* param - дополнительные параметры запроса
* args... - любые аргументы, которые будут переданы в обработчики событий onLoad, onError и onComplete после параметра request

Загрузку осуществляет #loader. Это отдельный виджет, который служит индикатором (показывает пользователю процесс загрузки).
При завершении запроса вызывается метод `onComplete request, args...`. Если запрос вернулся с ошибкой или dataType не смог преобразовать возвращённые данные, то вызывается `onError request, args...`. Иначе - `onLoad request, args...`

'request' - это объект, который содержит поля:

* request - транспорт, обычно экземпляр 'XMLHttpRequest'
* type - название метода инициализировавшего запрос. В данном случае - load
* param - параметры запроса в виде объекта
* customer - виджет инициализировавший загрузку
* args - дополнительные аргументы, переданные в функцию load
* message - сообщение об ошибке. Добавляется, только если произошла ошибка
* exception - исключение приведшее к ошибочке в методе #dataType

url, по которому будет осуществлён запрос, выбирается следующим образом:
- из параметра _act, например: `load _act: 'my_path'`. Причём к пути прибавляется начальный "/": /my_path
- из тега action виджета this или виджета loader
- из атрибута id. Например: `<div id=lod></div>` `CRoot.byId('lod').load()`. Соответственно url = /lod
- используется location.pathname

Специальные параметры:
- _async - должен ли запрос быть асинхронным. На синхронный запрос таймаут не выставляется. По умолчанию все запросы асинхронны
- _method - указывает метод запроса - POST, GET и т.д. Так же может быть указан через атрибут cmethod или переменную объекта @_method

Время таймаута, по которому будет разорвано соедининие указано в переменной @_timeout


См. #submit, #save, #erase, #ping, #loader, #loading, #dataType
""", ->



new CTest 'obj-CWidget-submit', """
`submit [param], [args...]` - обновляет данные в виджете посредством ajax-запроса. Тоесть отправляет данные и загружает. Комбинация #save и #load

* param - дополнительные параметры запроса
* args... - любые аргументы, которые будут переданы в обработчики событий onLoad, onError и onComplete после параметра request

Остальную информацию см. в #load
""", ->


new CTest 'obj-CWidget-save', """
`save [param], [args...]` - сохраняет данные в виджете посредством ajax-запроса. Данные для отправки формируются методом #param

* param - дополнительные параметры запроса
* args... - любые аргументы, которые будут переданы в обработчики событий onLoad, onError и onComplete после параметра request

Остальную информацию см. в #load
""", ->


new CTest 'obj-CWidget-erase', """
`save [param], [args...]` - удаляет данные связанные с виджетом на сервере посредством ajax-запроса

* param - дополнительные параметры запроса
* args... - любые аргументы, которые будут переданы в обработчики событий onLoad, onError и onComplete после параметра request

Остальную информацию см. в #load
""", ->


new CTest 'obj-CWidget-ping', """
`ping [param], [args...]` - просто отправляет ajax-запрос, ничего больше не делая

* param - дополнительные параметры запроса
* args... - любые аргументы, которые будут переданы в обработчики событий onLoad, onError и onComplete после параметра request

Остальную информацию см. в #load
""", ->


new CTest 'obj-CWidget-loader', """
`loader` - возвращает виджет-индикатор загрузки

Загрузчик можно указать установив переменную @_loader, указав атрибут cloader=id_загрузчика. Иначе будет взят загрузчик родителя или его родителя и т.д. Но если ни у кого из родителей нет загрузчика, то в качестве загрузчика будет использован тултип (cм. #tooltip)

См. #loading, #load
""", ->


new CTest 'obj-CWidget-loading', """
`loading` - возвращает true, если виджет ожидает завершения ajax-запроса, иначе - false

См. #dataType
""", ->


CTest.category "методы валидации"


new CTest 'obj-CWidget-setValid', """
`setValid valid` - устанавливает атрибут cvalid в valid

См. #valid, #setValid
""", ->
	w=$("<div>noint</div>")
	@ok w.valid()
	w.setValid 'int'
	@ok not w.valid()
	

new CTest 'obj-CWidget-valid', """
`valid` - возвращает true, если значение виджета (val) соответствует выражению валидации. false - если не соответствует и инициализирует событие onInvalid на виджете

См. #onInvalid, #setValid
""", ->
	@ok (w=$("<div cerr='Ошибка' cvalid=int>10</div>")).valid()
	@is w.tooltip(), undefined


new CTest 'obj-CWidget-onInvalid', """
`onInvalid` - выводит тултип с текстом из атрибута cerr или текстом "Ошибка - невалидное значение"

См. #valid, #setValid
""", ->
	@ok not (w=$("<div cerr='Ошибка' cvalid=int>1.1</div>")).valid()
	@is w.tooltip().text(), 'Ошибка'

	

CTest.category "методы конфигурирования виджета"


new CTest 'obj-CWidget-conf', """
`conf conf` - расширяет @config

См. #cconf
""", ->
	class Ex extends CWidget
		config: {width: 1}

	class Ex1 extends Ex
		config: {width: 2}
		
	ex = new Ex1 document.createElement 'div'
	ex.conf width: 3
	
	@is ex.config.width, 3
	@is ex.constructor.prototype.config.width, 2


new CTest 'obj-CWidget-cconf', """
`сconf conf` - расширяет @::config

См. #conf
""", ->
	class Ex extends CWidget
		config: {width: 1}

	class Ex1 extends Ex
		config: {width: 2}
		
	ex = new Ex1 document.createElement 'div'
	ex.cconf width: 3
	@is ex.config.width, 3
	@is ex.constructor::config.width, 3


CTest.category "Утилиты"

	
new CTest 'key-CTemplate-compile', """
`CTemplate.compile html, handlers` - превращает шаблон в функцию
Полученная функция (`fn dataset, id`) может использоватся затем для формирования текста одиночных форм (передаётся объект) или списков (передаётся список объктов с данными)

- $+ - подставляется id
- $-name - подставляется id-name
- $var - подставляются данные с ключём var из dataset
- #var - подставляются данные с ключём var из dataset и оборачиваются в <span id=id-var></span>
- $*var - обозначает список. Данные для него должны быть типа Array. Дублирует участок шаблона, ограниченный тегами

""", ->
	fn = CTemplate.compile("""
		<div id='$+'>
			#val1
			#val2
		</div>
	""")
	html = fn val1: 'val-1', val2: 'val-2', 'id-test'
	
	@like html, /val-1/
	@like html, /val-2/
	@like html, /id='id-test'/
	
	fn = CTemplate.compile("""
		<div id='$+' ctype=test_class1>
			#val1
			<div id="$*ls" ctype=test_class2>
				#val1
				<p id="$*ls" ctype=test_class3>
					#val1
				</p>
				#val2
			</div>
			#val2
		</div>
	""", forms = {}, form = {})
	html = fn val1: 'val-1', val2: 'val-2', ls: [{val1: 'val-1-0', val2: 'val-2-0', ls: []}, {val1: 'val-1-1', val2: 'val-2-1', ls: [val1: 'val-1-ls-<0>']}], 'id-test'
	
	@instanceof forms[""], Object
	@instanceof forms["-ls"], Object
	@instanceof forms["-ls-ls"], Object
	
	@like html, /val-1/
	@like html, /val-2/
	@like html, /id='id-test' ctype=test_class1/
	@like html, /val-1-0/
	@like html, /val-2-0/
	@like html, /val-1-1/
	@like html, /val-2-1/
	@like html, /val-1-ls-&lt;0&gt;/
	@like html, /"id-test-ls-0-ls" ctype=test_class3/
	@like html, /"id-test-ls-1-ls" ctype=test_class3/
	@unlike html, /id-test-ls-0-ls-0-val1/
	@like html, /id-test-ls-1-ls-0-val1/
	
	fn = CTemplate.compile('
		<table id=$*>
			<tr id=$*tr><td>$f
				<table><tr><td>123</table>
				$x
		</table>
	');
	html = fn [{tr: [{f:'f1', x:'x1'}, {f:'f2', x:'x2'}]}, {tr: [{f:'f3', x:'x3'}, {f:'f4', x:'x4'}]}], 'id_test'

	@like html, /f1/
	@like html, /f2/
	@like html, /f3/
	@like html, /f4/

	@like html, /x1/
	@like html, /x2/
	@like html, /x3/
	@like html, /x4/


	fn = CTemplate.compile('
		<table id=$* cinit>
			<!-- who? -->
			<tr id=$*tr cinit><td>$f
				<table><tr><td>123</table>
				$x
		</table>
	');
	html = fn [{tr:  [{f: 'f1', x: 'x1'}, {f: 'f2', x: 'x2'}]}, {tr:  [{f: 'f3', x: 'x3'}, {f: 'f4', x: 'x4'}]}], 'id_test'

	@like html, /f1/
	@like html, /f2/
	@like html, /f3/
	@like html, /f4/

	@like html, /x1/
	@like html, /x2/
	@like html, /x3/
	@like html, /x4/

	@like html, /<!--/
	@like html, /<!!-- who\? --!>/
	
	fn = CTemplate.compile '- \\$x:bool($y:bool("*", \'Да\\n\'), "Нет"):raw(1) -'
	html = fn {x: 1}, ""
	@is html, "- \\Да\n -"

	html = fn {x: 0}, ""
	@is html, "- \\Нет -"

	r = "${x:bool($y:bool('\\''), 10):raw}\n"
	fn = CTemplate.compile r
	html = fn x: 1, y: 1
	@is html, "'\n"

	html = fn x: 0, y: 1
	@is html, "10\n"

	fn = CTemplate.compile '$xyz:raw:raw'
	html = fn xyz:"<>"
	@is html, "<>"
	
	
	r = """
{% if $x:lt(10) %}
	{% if $y %}1{% fi %}
{% elif $y:eq($z) %}
2
{% else %}
3
{% fi %}
"""

	fn = CTemplate.compile r
	html = fn x:1, y: 1
	@is html, "\n\t1\n"
	html = fn x:10, y:13, z:13
	@is html, "\n2\n"
	html = fn x:10, y:1, z:2
	@is html, "\n3\n"
	
	#code = CTemplate.compile '<div id=$-frame>$@list/index</div>'
	#@like String(code), ///, CTemplate.include_action\(\$data->{'frame'}, "\$id-frame", 'list/index'\),///

	#code = CTemplate.compile '<div id=$-layout>$&</div>', forms, page
	#@like String(code), ///\@///
	#@is page.layout_id, "layout"

	CTemplate._STASH = stash = stash: '"'
	fn = CTemplate.compile '{% a =%}$%stash:raw{% end %} - $%a $"2":raw(2:raw) $\'2\''
	html = fn 'id'
	@is html, " - &quot; 2 2"
	@is stash.a, '"'

	fn = CTemplate.compile '<tr tab="$abc"><div id="x1">'
	html = fn abc: 1
	@is html, '<tr tab="1"><div id="x1">'



	
new CTest 'key-CDate-format', """
`CDate.format format, [date]` - форматирует строку в соответствии с форматом

- format - формат (см. ниже)
- date - дата. Если не указана, берёт this. Благодаря чему можно расширить Date

- *d* - день месяца
- *dd* - двухциферный день месяца
- *ddd* - двухбуквенное обозначение дня недели
- *dddd* - полное имя дня недели
- *m* - месяц
- *mm* - двухциферный месяц
- *mmm* - трёхбуквенная абревиатура месяца
- *mmmm* - полное имя месяца
- *yy* - две последние цифры года
- *yyyy* - год, четыре цифры
- *h* - час. 12-часовое время
- *hh* - час. Две цифры. 12-часовое время
- *H* - час. 24-часовое время
- *HH* - час. Две цифры. 24-часовое время
- *M* - минуты
- *MM* - минуты. Две цифры
- *s* - секунды
- *ss* - секунды. Две цифры
- *l or L* - милисекунды. l - 3 цифры. L - 2 цифры
- *t* - сокращённое обозначение "утра" или "вечера"
- *tt* - обозначение "утра" или "вечера"
- *T* - Uppercase, single-character time marker string: A or P. Uppercase T unlike CF's t to allow for user-specified casing.
- *TT* - Uppercase, two-character time marker string: AM or PM. Uppercase TT unlike CF's tt to allow for user-specified casing.
- *Z* - US timezone abbreviation, e.g. EST or MDT. With non-US timezones or in the Opera browser, the GMT/UTC offset is returned, e.g. GMT-0500. No equivalent in CF.
- *o* - GMT/UTC timezone offset, e.g. -0500 or +0230
- *S* - порядковый суфикс даты (st, nd, rd, or th). Работает с d
- *'…' or "…"* - последовательности символов
- *UTC:* - должен стоять в начале формата. Переключает на UTC из UTC/GMT/Zulu. "UTC:"-префикс удаляется

[CDate.parse]
""", ->
	date = new Date '2014/08/12 13:22:15'
	@is "2014-08-12 13:22:15", CDate.format "yyyy-mm-dd HH:MM:ss", date
	@is "Август", CDate.format "mmmm", date
	@is "Вторник 12 Августа", CDate.format "dddd dd mon", date
	
	
new CTest 'key-CDate-parse', """
`CDate.parse format, [date]` - распознаёт строку в соответствии с форматом

[CDate.format]
""", ->
	date = CDate.parse "yyyy-mm-dd HH:MM:ss", "2013-08-12 13:22:15"
	
	@is "2013-08-12 13:22:15", CDate.format "yyyy-mm-dd HH:MM:ss", date
	
	date = CDate.parse "dddd dd mon yyyy year h h12 tt M min s sec l msec", "Вторник 12 Августа 2013 года 12 часов утра 1 минута 3 секунды 45 миллисекунд"
	@is "2013-08-12 12:01:03.045", CDate.format "yyyy-mm-dd HH:MM:ss.l", date
	
	
	
new CTest 'key-CRadix-to', """
`CRadix.to n, radix, [sep]` - переводит натуральное число в заданную систему счисления

- n - число
- radix - основание числа
- sep - разделитель между цифрами

""", ->
	@is "1/0/", CRadix.to 16, 16, "/"
	@is "F/F/", CRadix.to 16*16-1, 16, "/"
	@is "9g", CRadix.to 600, 62
	@is "G8", CRadix.to 1000, 62
	@is "Щ", CRadix.to 999, 1000


new CTest 'key-CRadix-from', """
`CRadix.from s, radix` - парсит число в указанной системе счисления

- n - число
- radix - основание числа

""", ->
	@is 16*16-1, CRadix.from "FF", 16
	@is 10, CRadix.from "A", 16


new CTest 'key-CRows-from', """
`CRows.from data` - переводит полученные данные из вида {fields: [заголовки столбцов], rows: [[1-я строка], ...]} в [{заголовок1: данные1, ...}, ...]

- data - строка JSON или объект

""", ->
	
	res = CRows.from
		fields: ["id", "name", ["user", "id", ["sess", "id"], "name"]]
		rows: [
			["id1", "name1", [["user.id1", [['user.sess.id1']], "user.name1"], ["user.id2", [['user.sess.id2']], "user.name2"]]]
		]
	
	@is '[{"id":"id1","name":"name1","user":[{"id":"user.id1","name":"user.name1","sess":[{"id":"user.sess.id1"}]},{"id":"user.id2","name":"user.name2","sess":[{"id":"user.sess.id2"}]}]}]' , toJSON res


new CTest 'key-CRows-to', """
`CRows.to data` - превращает набор записей в заголовок и набор значений

- data - массив объектов

""", ->
	data = CRows.to [{id: "id1", name: "name1", user: [{sess: [{id: 'user.sess.id1'}], id: 'user.id1', name: 'user.name1'}, {id: 'user.id2', name: 'user.name2', sess: [{id: 'user.sess.id2'}]}]}]
	@is '{"fields":["id","name",["user",["sess","id"],"id","name"]],"rows":[["id1","name1",[[[["user.sess.id1"]],"user.id1","user.name1"],[[["user.sess.id2"]],"user.id2","user.name2"]]]]}', toJSON data

	
new CTest 'key-CUrl-from', """
`CUrl.from url` - парсит url и возвращает ассоциативный массив c элементами URL
""", ->
	url = CUrl.from "abc#123"
	@is url.pathname, "abc"
	@is url.hash, "123"
	
	url = CUrl.from 'http://rubin/'
	@is url.protocol, 'http'
	@is url.host, 'rubin'
	@is url.pathname, '/'
	
	
new CTest 'key-CUrl-to', """
`CUrl.to url_object` - обращает в url
""", ->
	@is "?a=1", CUrl.to search: CParam.to a: 1
	@is "//rubin", CUrl.to host: 'rubin'
	@is "//rubin/", CUrl.to host: 'rubin', pathname: "/"
	@is "//rubin/abc", CUrl.to host: 'rubin', pathname: "abc"
	@is "//rubin/abc", CUrl.to host: 'rubin', pathname: "/abc"
	
	
	
CTest.category "Виджеты"
	
new CTest 'cls-CTemplateWidget', """
`CTemplateWidget` - форма-темплейт. Метод `@val` формирует её содержимое через шаблон

- класс c-template указывает, что шаблон находится в теле элемента
- атрибут cinit указывает, что шаблон находится в комментарии - первой ноде элемента
- в остальных случаях пробует получить свой шаблон из шаблона parent-ов

См. #CListWidget, #CFormWidget
""", ->
	@is $("<div id=i ctype=template class=c-template>$val1</div>").val(val1: 123).html(), '123'
	@is (w=$("<div id=x ctype=template cinit><!-- #val1 --><span id=x-val1>345</span></div>")).$val1.val(), '345'
	@is w.val(val1: 123).$val1.val(), '123'


new CTest 'cls-CListWidget', """
`CListWidget` - темплейт-список. Генерирует на основе своего шаблона последовательность элементов-форм

Имена элементов-форм - порядковые или @data.id

См. #CTemplateWidget, #CFormWidget
""", ->
	@is (w=$("<lo id=e ctype=list class=c-template><li id=$+ ctype=form>$val1</li></lo>")).val([{val1: 1}, {val1: 2}]).html().replace(///['"]///g, ''), '<li id=e-0 ctype=form onkeyup=return CSend(this, event)>1</li><li id=e-1 ctype=form>2</li>'
	@is w.val([{val1: 1, id: 5}]).html().replace(///['"]///g, ''), '<li id=e-5 ctype=form onkeyup=return CSend(this, event)>1</li>'
	
	w = $("<lo id=e ctype=list class=c-template><li>t: <div id=$* ctype=list>#val1</div> ;</lo>").val [[val1: 6]]
	@is w.html().replace(///['"]///g, ''), '<li>t: <div id=e-0 ctype=list><span id=e-0-0-val1>6</span></div> ;</li>'
	@is (u=w.child(0).child(0)).child(0).val(), '6'
	@is u.val([val1: 7]).child(0).val(), '7'

	
new CTest 'obj-CSortableWidget-dragover', """
`CSortableWidget` - наследует CListWidget
""", """
#%name div { background: blue; border: solid 1px red; color: white; font-waight: bold; width: 400px; height: 20px; text-align: center; text-outline: 40px; margin: 1px }

#%name div.sort { }
""", """
<div id=$name ctype=SortableEx class="c-ts">
	$text
</div>
""", ->		
	class window.SortableEx extends CSortableWidget
		onSorted: (frame, frame_prev_on_start) -> frame.animate(width: '800px').animate(width: '400px')
		
	@w().update fields: ['text'], rows: [[1],[2],[3]]
	

new CTest 'obj-CRangeWidget-onCreate', """
`onCreate` - создаёт ползунок
""", """
.c-range { cursor: pointer }
.c-range div { width: 10px; height: 10px; background: red; -moz-border-radius: 50%; -webkit-border-radius: 50%; border-radius: 50% }
#%name-h, #%name-v { background: Honeydew }
""", """

<div style="width: 400px">
	<div style='float:right'>
		<div id="$name-h">&nbsp;</div>
		<br><br>
		<div id="$name-v">&nbsp;</div>
	</div>
	<div id=$name cview=range style="width: 110px; height: 5px; background: orange; margin-left: 50px "></div>
	<br><br>
	<div id=$name-vertical cview=range cvertical="1" style="width: 5px; height: 110px; background: royalblue; margin-left: 100px"></div>
</div>

""", ->
	self = this
	@w().onChange = -> self.w("h").val @val()
	@w('vertical').onChange = -> self.w("v").val @val()
	@is @w().val(), 0
	@is @w().val(10).val(), 10

###
new CTest 'obj-CSelectWidget-set', """
Устанавливает 
""", """
.c-active { background: pink }
""", """

<div id=$name cview=select>
	<div id=$+ cvalue="$value">$text</div>
</div>

""", ->

	@w().menu.update [{text: '--', value: '' }, {text: 'option 1', value: '1' }, {text: 'option2', value: '2' }, {text: 'option3', value: '3' }]
###


new CTest 'cls-CMonthWidget', """
""", """
.c-othermon {background: #ccc}
.c-current {background: yellow}
.c-week {color: red; }
""", """
<table id=$name ctype="month"></table>
<table id=$name-vertical ctype="month"></table>
""", ->
	@w().create new Date()
	w = @w 'vertical'
	w.conf vertical: on
	w.create new Date()

	
new CTest 'cls-CCalendarWidget', """
`CCalendarWidget` - календарь
""", css_calendar = """
.c-calendar { background: white }
.c-calendar .c-month { border-collapse: collapse }
.c-calendar .c-month td { border: solid 1px gray }
.c-calendar .c-arr {cursor: pointer}

.c-othermon {background: #ccc}
.c-current {background: yellow}
.c-week {color: red; }


.c-clock {width: 250px; border: solid 1px grey; padding: 2px; background: white }
.c-clock * {text-align: center}
.c-clock .c-head { font-size: 32px }
.c-clock .c-hours, .c-clock .c-minsec { font-size: 12px; width: 100%; border-collapse: collapse; margin-top: 2px }
.c-clock td { border: solid 1px grey }
.c-clock .c-current {background: lightblue}
.c-clock .c-zero {color: red}
.c-clock .c-apply { text-decoration: none; font-weight: 700; color: royalblue; border: solid 1px grey; display: -moz-inline-stack; display: inline-block }
.c-clock .c-apply:hover { background: Cornsilk }
""", """
<table id=$name cview="calendar"></table>
<table id=$name-vertical cview="calendar"></table>
<input id=$name-input>
<input id=$name-timeinput>
""", ->
	@w().create new Date()
	@w("vertical").month.conf vertical: on
	@w("vertical").create new Date
	@w("input").element.onclick = ->
		CRoot.wrap("<table cview=calendar></table>").input this.widget
	@w("timeinput").element.onclick = ->
		CRoot.wrap("<table cview=calendar></table>").timeInput this.widget


new CTest 'cls-CClockWidget', """
`CTimeWidget` - виджет для ввода времени
""", css_calendar, """
<div id=$name cview="clock"></div>
""", ->
	@w().create new Date
	
		
###
new CTest 'obj-CSelectableWidget-open', """
""", """
<div id=$name></div>
""", ->


new CTest 'obj-CAutocompliterWidget-open', """
""", """
<div id=$name></div>
""", ->
###


new CTest 'obj-CTooltipWidget-open', """
[com]
""", """

.c-tip {
	box-shadow: #666 0px 2px 3px;
	border: solid 3px red;
	background: white;
}

""", """

<div id=$name class=test-square></div>

""", ->
	w=@w()
	w.tooltip text: "left center", pos: 'left', width: 20, height: 30 ;	w.tooltip().open(); w._tooltip = null
	w.tooltip text: "top center", pos: 'top'; w.tooltip().open(); w._tooltip = null
	w.tooltip text: "right center", pos: 'right', width: 20, height: 30 ; w.tooltip().open(); w._tooltip = null
	w.tooltip text: "bottom center", pos: 'bottom', width: 20, height: 30 ; w.tooltip().open(); w._tooltip = null

	w.tooltip text: "left top", pos: 'left', scale: 'top', width: 20, height: 30 ;	w.tooltip().open(); w._tooltip = null
	w.tooltip text: "right top", pos: 'right', scale: 'top', width: 20, height: 30 ; w.tooltip().open(); w._tooltip = null
	
	w.tooltip text: "left bottom", pos: 'left', scale: 'bottom', width: 20, height: 30 ;	w.tooltip().open(); w._tooltip = null
	w.tooltip text: "right bottom", pos: 'right', scale: 'bottom', width: 20, height: 30 ; w.tooltip().open(); w._tooltip = null
	
	w.tooltip text: "top left", pos: 'top', scale: 'left', width: 20, height: 30 ;	w.tooltip().open(); w._tooltip = null
	w.tooltip text: "top right", pos: 'top', scale: 'right', width: 20, height: 30 ; w.tooltip().open(); w._tooltip = null
	
	w.tooltip text: "bottom left", pos: 'bottom', scale: 'left', width: 20, height: 30 ;	w.tooltip().open(); w._tooltip = null
	w.tooltip text: "bottom right", pos: 'bottom', scale: 'right', width: 20, height: 30 ; w.tooltip().open(); w._tooltip = null
	

	
new CTest 'obj-CModalWidget-open', """
`open` - открывает модальное окно

Создаёт события: 'onBeforeOpen' и 'onOpen'

""", """

<div id=$name style='display:none' ctype=modal>
	
	<div id="$name-fg" class=test-square style='height: 2000px; margin: 0; padding-top: 700px'>
		Ещё одно модальное окно:
		<input id=$name-bt2 type=button value="Открыть">
	</div>
	
	<div style='float:right'>
	[x]
	</div>
	
</div>

<input id=$name-bt type=button value="open modal">

<div id=$name-wmodal cview="modal" cargs="class=test-square style=margin:0" style='display:none'>hi! I am modal number 2</div>

""", ->

	@w("bt").element.onclick = => @w().open()
	@w("bt2").element.onclick = => @w("wmodal").open()

	
CTest.category "ajax-загрузчики"

###
new CTest 'obj-CIncludeWidget-include', """
`include url, [param]` - подгружает страницу html в текущий виджет ajax-запросом один раз.
Если фрагмент уже подгружен, то запрашивает только данные и меняет фрагменты (текущий на скрытый). 
Если в полученном html не было `<script cdata>CRoot.byId("id").update( ... )</script>` , то данные запрашиватся не будут.
Меняет url в строке навигации браузера

- url - url по которому будет загружатся страница
- param - параметры запроса, такие же как в #load

Дополнительные параметры:
- _cut - query-выражение для @find. Указавает тег с которого нужно вставлять данные. По умолчанию это #id виджета

""", ->


new CTest 'obj-CMenuWidget-frame_onclick', """
[com]
""", """
	<div id=$name ctype=CMenuWidget>#x</div>
	""", ->
	list = CWidget::byId(@name).update
		fields: ['x'],
		rows: [[1], [2]]
	frame1 = list.byName 0
	frame2 = list.byName 1

	@ok(!frame1.hasClass('c-active'))
	@ok(!frame2.hasClass('c-active'))
	frame1.x.element.click()
	@ok(frame1.hasClass('c-active'))
	@ok(!frame2.hasClass('c-active'))


new CTest 'obj-CStatusLoader-ohComplete', """
[com]
""", """
	<div id=$name ctype=CStatusLoader cview=status></div>
	<div id="use-$name" action="ajax/value.txt" cloader=#{@name}></div>
	""", ->
	@count(3)
	use = CWidget::byId "use-"+@name
	test=this
	use.onComplete = (req) ->
		console.log('req', req)
		test.is(req.type, 'submit')
		test.is(@data, '!value')
		test.is(req.data, '!value')
	
	use.submit()

new CTest 'obj-CModalWidget-show', """
Показывает элемент. Без параметров
""", """
	<div id=$name ctype=modal>
		<div id=$name-fg>Фореграунд</div>
		<div id=$name-bg></div>
	</div>
	<a class="button">Открыть</a>
	""", ->

###


do CTest.main_loop







