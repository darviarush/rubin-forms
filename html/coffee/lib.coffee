#- 1. Стили на элементы label1_css: {}, label1_attr: {}, label1_className: "abc dcd", label1: { attr: {}, css: {}, className: {}, onclick: ->, onLoad: -> } - не соответствует философии. Лучше пусть устанавливают в onCreate.
#* Добавить onCreate
#* 2. load - не отправляет параметры, (кроме act, acn и pk как id в data в форме), зато вызывает update. save - доб. параметры и не вызывает update. submit - и параметры, и update. Ping - просто отправляет запрос. Заменить так же onLoad на onSubmit, onSucess на onLoad, а в @request добавить type=submit|load|save|ping|erase
# 3.* cview='status' args='url: http://ico.ps.ru/ico.png; error: ...'
# 4.* CTooltipWidget
# 5.* CModalWidget
# 6. CSelectWidget
# 7. CTabsWidget
# 8.* byClass
# 9.* byQuery

# -----------------------
# 10. CMenuWidget - подключить др. элемент и получить CLoadTabsWidget
# 11. drag&drop on CListWidget
 
#- 12. CSend всегда возвращает false. Другое значение можно передать по event.ret - в coffeescript всё равно нужно следить за возвратом после массива
#- act='onclick: load; onkeydown: submit; onmousemove: save' - отправляет хандлер на любую функцию
#- inject и create - не соотвествуют философии
#* 13. attr, css, prop могут принимать {}
#* 14. onload, onerror на CImgWidget
#* 15. Консоль для IE
#* 16. @fire - @send? - @fire - для listen

# -----------------------
# 17. objectinspector for old browser
# 18. lint - ваше приложение может работать под браузерами: IE6+, FF1+, ...

#* 19. tagName -> ctype
#* 20. form сделать функцией и смотреть по id

# -----------------------
# 20.а. При изменении form изменять и обработчики событий на нём

#* 21. css - key - проверять на существование функции, если есть - запустить
#* 22. css - rgb, rgba. css цвета возвращает в hex. @rgba 'background-color' - в массиве 

# -----------------------
# 23. shapes

#* 24. load - информация с модели данных сервера о валидации и типе данных - html или text
#* 25. формат загрузки страниц через ajax: json \f page1 \f page2 ... . json = {pages: [{данные1}, ["menu", {данные}], ["layout", {данные}]]}
#		данные1 - для первой страницы. Ключи данных - id виджетов, значения - данные для метода .update такого виджета
#		"menu", "layout" - id элемента без "$" которому производится update: $menu, $layout
#		тег meta заменяется update-ом на page
#* 26. ошибки серверной валидации
#* 27. загрузка страниц с форм - CIncludeWidget и CApplicationWidget

# -----------------------
# 27. загрузка и отображение фотографий

#* 28. шаблонизатор - вложенность виджетов + шаблон в комментариях. А include byId сделать по url
#* 29. слайсы для статики
#* 30. автозагрузка класса, если есть указанный id через ready - метод класса init

# -----------------------
# 31. Добавить model в любой json-ответ
# 32. autocompleter

#* 33. переделать link-и для инклудов на обычные, иначе поисковики индексировать не смогут. Установить onclick на body и перехватывать от <a>. -Для этого устанавливать обработчики всех событий на body и делать event.target().send и event.target().form?().send
#* 34. history

# -----------------------
# 35. Разбить на мелкие файлы библиотеку и сделать сборщик по запросу js/CWidget+CApplicationWidget+CInit.js. 
#	Не так: файлы разбить на мелкие. Затем вывести дерево разбора coffee, взять из него функции и классы и подключить их модули

# *36. animate на after, before, append, prepend 
#- 37. убрать upper: заменить на up - нарушит работу swap
#- 38. Ввести ret-методы - есть last и first. Может какое-то ret-свойство в котором остаётся значение операции. @append(1).$.text 2

# -----------------------
# 39. WebSocket и longpull-socket. * Заменить FCGI на http
# 40. Модель через IoRepository - чтобы была соединена с базой
# 41. RPC (?) - а нужна ли?

#- 42. Ввести для тестов пакеты - отказ в связи с 

# -----------------------
# 43. Плагины
# 44. Сделать плагин для комментариев
# 45. Разместить на heroku test

#* 46. В темплейт добавить хелперы
#* 47. Переделать send - вызывать обработчики для всех уровней. Обработчики вызываются начиная от верхнего form-а. Если нужно остановить - то @stopHandlersQueue = on. Значение от предыдущего обработчика передаётся в @return - не сделано, т.к. зачем?

# -----------------------
#* 48. сделать в CInit параметр для создания стилей .w\d+ и .mobile, .pad, .computer
#* 49. @submit - как в обычной форме. Предусмотреть target=id
#* 50. предусмотреть изменение при изменении формы и url-а
# 60. Локализация (перевод) на другие языки
#? 61. accept в div-ах
# 62. Взять для описания документации из http://enepomnyaschih.github.io/jwidget/1.0/index.html#!/guide/ruphilosophy и подправить
#* 63. узнать произошло ли изменение адреса из history или добавлением элемента через history.length - она увеличится, а если позиция истории - посредине - уменьшиться при добавлении. Иначе - она в истории
#* 64. @init id, ... - регистрирует объект в массиве и привязывает его при пересоздании страниц
# 65. Добавить в темплейт выделение в функцию {% def fn $x, $y, $z %} $x $y $z {% end def %}   Использование: $"fn":print(1,2,3)
#* 66. Оптимизировать send и добавить очередь слушателей, которые должны иметь метод emit - вместо слушателей - замыкания с _belong указывающим на поместившего замыкание в очередь объект
#* 67. CListen заменить на слушатели виджетов $(window) и $(document)
#* 68. Добавить потоки
# 69. Переделать animate - через css. @keyframes. В old - старую или переделать на классах или на потоках. Добавить в setCss и css. Использовать options
#* 70. В модель добавить функции для сравнения данных
#- 71. Переопределить __bind на нормальное наследование метаклассов - невозможно
# 72. Протестировать удаление элементов из памяти, так как все они имеют перекрёстные ссылки
# 73. Отложенное выполнение в модели. Как сработал send - пока из него не выйдет - другие обновления этого ключа не выполняются. А добавляются в очередь и начинают отправляться после. Добавить значение для ключа - нет - очередь будет отправлять для всех значений последовательно, 0 - очередь игнорируется, 1 - выполнится последнее значение из очереди
# 74. update: keyup - для модели, style {...} anim?, разработать свой мини-язык
# 75. списки для модели (?)
#* 76. Избавиться от методов onKey на модели
# 77. :load("where $user_id order by 1 limit 10") - limit, если не указан - 10. count - если есть - доп. запрос. Так же - уникальное id для кеша (можно взять формы)
#* 78. Перейти на http://learnboost.github.io/stylus/. В main.ini создать секцию watch с описанием таких штук
#	Добавить команду qq compile - которая будет перекомпиливать всё - stylus, coffeescript, шаблоны и спрайты: qq css + qq sprite + qq coffee + qq action
#	qq watch - висит и перекомпиливает. qq с test в ini - добавляет qq watch
# 79. встроенный crontab - R::Cron->new->on(1, sub {}); и для сигналов: 
# 80. form заменить на form. Исключить установку _form в конструкторе, использовать атрибут cform (?)
# 81. использовать в проекте: http://www.git-tower.com/blog/css3-transforms/
# 82. new as emmet
# 83. функция options, для опций. Если тип следующего операнда не подходит, то он пропускается: options "x:io y:s f:f", (opt) ->
# 84. создать в CInit параметр для средств разработчика: висящая (fixed) менюха с цветами html. Пипеткой и возможностью закрашивать всё (?). Панелька может сворачиваться. Показывает стили на выбранном элементе.
# 85. функция options которая вернёт параметры: animate: (param, duration, ease, complete) -> options arguments, 'param duration:si ease:si complete:f - сделать кешируемую. То есть в методе обернуть метод: x:-> $O arguments, 'p:i ...' -> ... Когда вызывается оптионс, то она генерит метод и заменяет метод "x:->".
# 86. загрузчик в 1-м лайоуте: создаёт iframe в котором проходит индикатор загрузки. Индикатор можно реализовать как 
#* 87. one
#- 88. в stream добавить все методы widget. widget.stream() - выдаёт поток с этим виджетом(и). eventStream(obj) - для on - кто установил
# 89. form target=id - указывает до какого id разворачивать layout. Сервер смотрит: если id принадлежит инклуду, то возвращает одну страницу и указатель - изменить только параметр _f=id=url,...
# 90. css - распознавание префиксов срабатывает только при запросе: get/set/hasCss. Префиксы на обработчики событий
# 91. widget.type - createWidget должен короткие имена классов собирать в ассоциативный массив (?). C*Widget и html-xs = HtmlXs
# 92. fly - делает виджет плавающим в окне. @fly [элементы-top|bottom], [расстояние_остановки_до_элемента]. @fly() - без ограничений
# 93. переделать CTemplate.compile: /// ///: (m) -> ... . Так же использовать kitty->coffee в серверной части
# 94. CBox в stream - написать тесты
# 95. Растягивающиеся тултипы и окошки через таскание мышкой границы
# 96. Подумать над архитектурой фреймворка. В частности:
#	1. обработка событий на document. Когда человек тыкает где-то ещё, вне элемента, то последнему элементу приходит завершающее событие
#	2. регистрация виджетов и их удаление для старых браузеров через регистрацию событий
#	3. onModel<Имя>: - вызывается при изменении свойства модели
#	4. onRepo<Имя репозит.><Имя переменной> - переменная добавляется в репозиторий
# 97. preloader на animation
# 98. удалять из body[act].data неиспользуемые в темплейтах param и stash. Для этого модифицировать param
# 99. i18n - @html и @text переводят автоматически. Секции для переводов по тегу clang
# 100. main.ini:watch:run - запускает процесс и main.ini:watch:cascad - каскадирует с другим watch
# 101. подумать над названиями фреймворков: ka - жизненная сила, ba - чувства (эмоции), ax (ah) - дух, su (shu) - тень (тёмная сторона)
# 102. $ и wrap сделать одинаковыми, т.к. before(1) и $(1) - разные. И разный язык запросов. $ привести к jquery виду
# 103. в nika-css ввести параметр для сжатия, который удаляет пробелы после { } ; и %...
# 104. несколько раз повторяется тест модели. Запомнить при изменении и выполнить по timeout(0) события модели
# 105. подтянуть ie6+ до уровня браузера html5 (по крайней мере с поддержкой defineProperty)): http://habrahabr.ru/post/133328/, :
 
# Ссылки:
# библиотеки для добавления функциональности html5 - https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-Browser-Polyfills
# индикатор загрузки на css3: http://evgeniy.pakalo.name/post/67
# behavior ie6-ie7 - https://msdn.microsoft.com/en-us/library/ms531079(v=vs.85).aspx . Запрещает быстро обновлять: lightweight=true
# библиотеки для исправления старых версий js: https://github.com/Raynos/DOM-shim, https://github.com/es-shims/es5-shim
# http://caniuse.com/ - в каком браузере что работает
# https://sites.google.com/site/moispargalkicss/home/spisok-standartnyh-media-queries - стандартные медиа-запросы css
# http://habrahabr.ru/post/237671/ - слепой набор
# https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf - справочник мозилла на русском
# http://docs.ractivejs.org/latest/observers - фреймворк с моделью данных и темплейтами
# http://jsfiddle.net/C3WeM/5/ - анимация основанная на css3 - http://habrahabr.ru/post/209140/
# http://todomvc.com/ - блог на разных фреймворках
# http://topobzor.com/13-servisov-dlya-testirovaniya-sajta-v-raznyx-brauzerax/.html - сайты-тестеры
# *** http://www.javascripting.com/ - библиотеки js
# http://habrahabr.ru/post/174987/ - редактор http://ace.c9.io
# http://rubaxa.github.io/Sortable/ - библиотечка для сортировки, внизу другие ссылки: http://rubaxa.github.io/Pilot/, http://mailru.github.io/FileAPI/ и т.д.
# http://experiment.net.ru/dirs.php.html - подробная документация по DOM, js, css2, html4
# http://msdn.microsoft.com/ru-ru/library/htbw4ywd(v=vs.94).aspx - докуметация по объектам javascript в IE
# http://frontender.info/customelements/ - о html5 document.register
# http://learn.javascript.ru/pre-coding - справочники
# http://www.html5rocks.com/ru/tutorials/dnd/basics/ - руководства html5. Перетаскивание
# http://handynotes.ru/2010/10/cheatsheet-25-plus-ie6-fix.html - фиксим ie6
# https://github.com/jashkenas/coffee-script/wiki/List-of-languages-that-compile-to-JS - по названию ясно
# http://www.jstoolbox.com/2008/04/18/mootools-dlya-nachinayushhix-rabota-s-elementami-i-sobytiyami/ - интересные статьи
# Cross-Browser.com - ясно по названию. Кроссбраузерная библиотека
# http://rotorweb.ru/htmlcss-verstka/ssylki-na-skype-i-icq.html - ссылки skype, icq
# http://osxdev.ru/blog/ios/9.html - ссылки на тел. tel:+7000, callto:+8000, sms:+7123456789
# http://www.xiper.net/learn/bonus-books/programming-the-mobile-web/coding-markup/links.html - фичи тел., mailto, sms, mms
# http://fstrange.ru/coder/mobile/aktivnaya-html-razmetka-dlya-mobilnyx.html - hcalendar, hcard
# http://topobzor.com/13-servisov-dlya-testirovaniya-sajta-v-raznyx-brauzerax/.html - инструменты кроссбраузерной вёрстки
# http://www.avalon.ru/OpenLessons/WebDev/Lessons/testing-tools/ - инструменты кроссбраузерной вёрстки


unless window.console then window.console = notFound:1, log:->



IE = if '\v'=='v' or document.documentMode?
	if window.MSStream					then 11
	else if window.atob 				then 10
	else if document.addEventListener	then 9
	else if document.querySelector		then 8
	else if window.XMLHttpRequest		then 7
	else if	document.compatMode			then 6
	else 5

	
CTraceback = -> f = arguments.callee; i=0 ; [f.name || '<anonimous function>' while (f = f.caller && i++ < 10)].reverse().join(' → ')

$A = (n, sep) ->
	if n instanceof Array then n
	else if typeof n == 'object' then Array::slice.call n
	else String(n).split sep || /\s+/
$H = (n, sep = /s*;\s*/, eq = /\s*:\s*/) ->
	if n instanceof Object then n
	else if n instanceof Array then x={}; (for i in [0...n] when i % 2 == 0 then x[n[i]] = n[i+1]); x
	else x = {}; (for i in String(n).split sep then m=i.split eq; x[m[0]]=m[1]); x
say = (args...) -> console.log(args...); args[args.length-1]
escapeHTML = (s) -> String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\"/g, '&quot;').replace(/\'/g, '&#39;')
unescapeHTML = if (escapeHTML.div$ = document.createElement 'div').textContent? then (s) -> (div=escapeHTML.div$).innerHTML = s; x=div.textContent; div.innerHTML = ''; x else (s) -> (div=escapeHTML.div$).innerHTML = s; x=div.innerText; div.innerHTML = ''; x
escapeJS = (s) -> String(s).replace(/([\'\"\\])/g, '\\$1').replace(/\r/g, '\\r').replace(/\n/g, '\\n')
escapeString = (s) -> ['"', escapeJS(s), '"'].join ""
fromJSON = (s) -> try eval r=["(", s, ")"].join("") catch e then say 'fromJSON error: ', e, r; throw "fromjson error"
toJSON = if window.JSON then JSON.stringify else (s) ->
	switch
		when !s? then "null"
		when s instanceof Array then ["[", (toJSON a for a in s).join(","), "]"].join ""
		when s instanceof Object then ["{", ([escapeString(k), ":", toJSON v].join "" for k,v of s).join(","), "}"].join ""
		when typeof s=="string" then escapeString s
		when isNaN s then "null"
		else s

$isNode = (x) ->
	if typeof x.nodeType == 'number'
		n = x.nodeType
		try
			x.nodeType = ''
			if x.nodeType != '' then return true
			x.nodeType = n
		catch e
			return true
	false
		
extend = (obj, args...) -> (for arg in args then for k, v of arg then (if v? then obj[k]=v else delete obj[k])); obj
extend_uniq = (obj, args...) -> (for arg in args then for k, v of arg then (if v? then (if not(k of obj) then obj[k]=v) else delete obj[k])); obj
extend_deep = (obj, args...) ->
	for arg in args
		for k,v of arg
			if v == o=obj[k] then
			else if v instanceof Object and o instanceof Object 
				if v instanceof Array and o instanceof Array then obj[k]=v
				else if $isNode(v) and not $isNode(o) then extend_deep o, v
				else obj[k]=v
			else obj[k]=v
	obj
extend_deep_uniq = (obj, args...) ->
	for arg in args
		for k,v of arg
			if k of obj then
			else if v == o=obj[k] then
			else if v instanceof Object and o instanceof Object 
				if v instanceof Array and o instanceof Array then obj[k]=v
				else if $isNode(v) and not $isNode(o) then extend_deep o, v
				else obj[k]=v
			else obj[k]=v
	obj



extend_uniq String.prototype, CString =
	trim: -> String(this).replace /^\s+|\s+$/g, ""
	ucFirst: -> @charAt(0).toUpperCase() + @slice(1)
	lcFirst: -> @charAt(0).toLowerCase() + @slice(1)
	uc: -> @ucFirst().toCamelCase()
	lc: -> @lcFirst().fromCamelCase()
	toCamelCase: -> @replace /-(\w)/g, (a, b)-> b.toUpperCase()
	fromCamelCase: -> @replace /[A-Z]/g, (a)-> '-'+a.toLowerCase()

# https://github.com/kriskowal/es5-shim/blob/master/es5-shim.js
extend_uniq Array.prototype, CArray =
	indexOf: (e, from) -> (for a, i in (if from then this.slice from else this) when a == e then return i); -1
	map: (fn, thisp = this) -> (for r, i in (res = new Array this.length) when i of this then res[i] = fn.call thisp, this[i], i, this); res
	forEach: (fn, thisp = this) -> (for r, i in this when i of this then fn.call thisp, this[i], i, this); undefined

extend_uniq Function.prototype, CFunction =
	code: (name, args...) -> a = (String(this).replace /// \$(\d+)\$ ///g, (a, idx) -> if typeof (x=args[parseInt idx])=='function' then String(x).replace /// function (\s+ [\$\w]+)? \s* \( [^\)]* \) \s* \{ | \} $ ///, '' else x); a=a.replace ///function(\s+[\$\w]+)?///, 'code$=function '+name+"$inline"; a
	inline: (args...) -> code$=null; eval @code args...; code$
	rename: (name) -> code$=null ; eval String(this).replace ///function(\s+[\$\w]+)?///, 'code$=function '+name; code$
	getName: if escape.name then -> @name else -> String(this).match(/// function\s+(\w+) ///)?[1] || ""
	getMethodName: (obj) -> (for name, fn of obj when fn == this then return name); null
	init: (args...) -> CRoot._init_widgets.push [this, args || [this.getName().lc()]]
	implements: (args...) ->
		replace = if typeof args[args.length-1] != 'function' then args.pop() else {}
		n = @prototype
		for interFace in args
			p = interFace.prototype
			for i of p then n[replace[i] || i] = p[i]
		this
	implements_own: (args...) ->
		replace = if typeof args[args.length-1] != 'function' then args.pop() else {}
		n = @prototype
		for interFace in args
			p = interFace.prototype
			for own i of p then n[replace[i] || i] = p[i]
		this
	extend: (param) -> extend @prototype, param



# http://browserhacks.com/
CNavigator = do ->
	w = window
	d = document
	Nav = window.navigator || {}

	n = {}
	r = {}
	_summary = []
	summary = -> (for i,v of n when v and not(i of r) then r[i]=1 ; _summary.push(if typeof v == 'number' then i+v else i)); null
	
	Ag = Nav.userAgent || ''
	Platform = Nav.platform || ''
	
	n.ieMode = d.documentMode
	n.ie = IE
	
	n.opera = if w.opera then (opera.version && opera.version() || if d.addEventListener then 7 else if d.getElementsByTagName then 6 else if d.getElementById then 5 else 4)
	if w.chrome && !w.chrome.webstore then n['opera15+'] = true
	n.operamini = String(window.operamini) == '[object OperaMini]'
	n.FF = typeof InstallTrigger != 'undefined'
	n.chrome = !!w.chrome
	n.chromium = /cros i686/i.test(Platform)
	n.webkit = 'webkitURL' of w #.webkitURL != null
	#isWebkit = 'WebkitAppearance' in document.documentElement.style;
	n.safari = w.WheelEvent && !n.FF && !n.chrome && !IE && (/a/.__proto__!='//' && 6 || !d.head && 5 || d.hasFocus && 4 || d.adoptNode && 3 || 2)
	#/constructor/i.test(w.HTMLElement)
	#n.webkit = n.safari or n.chrome
	n.khtml = Nav.vendor == 'KDE'
	n.konqueror = n.khtml || d.childNodes && !d.all && !Nav.taintEnabled && !n.chrome && !n.safari
	
	do summary
	
	n.ios = /iP(ad|hone|od)/i.test(Ag)
	n.linux = /linux/i.test(Platform) && !/android|cros/i.test(Platform)
	n.bsd = /bsd/i.test(Platform)
	n.qnx = /qnx/i.test(Platform)
	n.mac = /mac/i.test(Platform)
	n.win = /win/i.test(Platform)
	n.android = /android/i.test(Platform)
	
	do summary
	
	n.touch = ('ontouchstart' in w) || Nav.msMaxTouchPoints
	n.retina = w.devicePixelRatio >= 1.5
	n.fileapi = !!w.FileReader
	
	do summary
	
	n.summary = _summary.join " "
	n.agent = Ag
	n.platform = Platform
	
	v = ''
	s = ''
	
	n.vendor = if IE>8 then s = "ms"; v = "MS"; "-ms-"
	else if n.FF then s = "Moz"; v = "moz"; "-moz-"
	else if n.khtml then s = "Khtml"; v = "Khtml"; "-khtml-"
	else if n.webkit then s = "webkit"; v = "webkit"; "-webkit-"
	else if n.opera then s = "O"; v = "o"; "-o-"
	else ""
	
	n.onvendor = v
	n.cssvendor = s
	
	n
	

CRows$st = (arr) ->
	st = [arr]
	while st.length
		[out, fields, rows] = st.pop()
		out[fields.key] = outrows = []
		for row in rows
			outrows.push outrow = $3$
			for field, i in fields.fields
				if field instanceof Object then st.push [outrow, $2$]
				else outrow[$0$] = row[$1$]
	undefined

CRows =
	from$st: CRows$st.inline 'from$st', 'field', 'i', 'field, row[i]', '{}'
	to$st: CRows$st.inline 'to$st', 'i', 'field', '{key: i, fields: field.fields}, row[field.key]', '[]'
	from: (data) -> # переводит полученные данные из вида [[заголовки столбцов], [1-я строка], ...] в [{заголовок1: данные1, ...}, ...]
		data = fromJSON(data) if typeof data == "string"
		
		toFields = (fld) ->
			fields = []
			for field in fld
				fields.push if field instanceof Array then key: field[0], fields: toFields field.slice 1 else field
			fields
		fields = toFields data.fields
		
		CRows.from$st [ret = [], key: 0, fields: fields, data.rows]
		ret[0]

	to: (rows) -> # превращает набор записей в заголовок и набор значений
		if rows.length == 0 then return rows: [], fields: []
		
		toFields = (rows, key) ->
			fields = [key]
			fld = []
			row = rows[0]
			for field of row
				fields.push if (val = row[field]) instanceof Array then f = toFields val, field; fld.push f[1]; f[0] else fld.push field; field
			[fields, key: key, fields: fld]
		
		[fields, fld] = toFields rows, 0
		fields.splice 0, 1
		CRows.to$st [ret = [], fld, rows]
		{fields: fields, rows: ret[0]}


CRadix =
	to: (n, radix, sep = "") -> # переводит натуральное число в заданную систему счисления
		x = y = ""
		A = "A".charCodeAt(0) - 10
		a = "a".charCodeAt(0) - 36
		loop
			y = n % radix
			x = (if y < 10 then String y else String.fromCharCode(y + (if y<36 then A else if y<62 then a else 128-62))) + sep + x
			break unless n = parseInt n / radix
		return x

	from: (s, radix) -> # парсит число в указанной системе счисления
		i = x = 0

		_9 = "9".charCodeAt(0)
		_0 = "0".charCodeAt(0)
		Z = "Z".charCodeAt(0)
		A = "A".charCodeAt(0) - 10
		z = "z".charCodeAt(0)
		a = "a".charCodeAt(0) - 36

		len = (s = String s).length
		while i < len
			ch = s.charCodeAt i
			x = x*radix + ch - if ch <= _9 then _0 else if ch <= Z then A else if ch <= z then a else 128-62
			i++

		return x

CUrl =
	from: (uri) -> if m=uri.match ///^ (?: (?:(\w+):)? // ([^/:?#]+) (?::(\d+))? )? (?: ([^\?#]*) )? (?: \?([^#]*) )? (?: \#(.*) )? $/// then href: uri, protocol: m[1] || "", host: m[2] || "", port: m[3] || "", pathname: m[4] || "", search: m[5] || "", hash: m[6] || "", param: (if m[5] then CParam.from m[5] else {}) else null
	to: (a) -> 
		s = if a.host then (if p=a.protocol then p+":" else "") + "//" + a.host + (if p=a.port then ":" + p else "") else ""
		if p=a.pathname then s = (if s then s+(if p[0]!="/" then "/" else "")+p else p)
		search = CParam.from a.search
		extend search, a.param
		search = CParam.to search
		if search then s+="?"+search
		if p=a.hash then s+="#"+p
		s

CParam =
	get: (url=document.location) -> if match = String(url).match /// \?(.*) /// then CParam.from(match[1]) else {}
	add: (url, param) -> url + (if /\?/.test url then "&" else "?") + CParam.to param
	to: (param, sep="&") -> if param instanceof Object then ([escape(key), escape(if val instanceof Object then toJSON val else String(val))].join("=") for key, val of param when val?).join sep else param
	from: (param, sep=/&/) -> return {} unless param; x={}; (for i in param.split sep then a=i.match /// ([^=]+)=?(.*) ///; x[unescape a[1]]=(if a[2] then unescape a[2] else "")); x


# https://github.com/gka/chroma.js/blob/master/src/conversions/rgb2lab.coffee
class CColor

	@rgbToHsl: rgbToHsl$ = (r, g, b) ->
		r /= 255 ; g /= 255 ; b /= 255 ; max = Math.max(r, g, b); min = Math.min(r, g, b); l = (max + min) / 2
 
		if max == min then h = s = 0
		else
			d = max - min
			s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
			switch max
				when r then h = (g - b) / d + (if g < b then 6 else 0)
				when g then h = (b - r) / d + 2
				when b then h = (r - g) / d + 4
			h /= 6
		[ h, s, l ]
		
	@hslToRgb: hslToRgb$ = (h, s, l) ->
		if s == 0 then r = g = b = l
		else
			hue2rgb = (p, q, t) -> (if t < 0 then t += 1 else if t > 1 then t -= 1); if t < 1/6 then p + (q - p) * 6 * t else if t < 1/2 then q else if t < 2/3 then p + (q - p) * (2/3 - t) * 6 else p
 
			q = if l < 0.5 then l * (1 + s) else l + s - l * s
			p = 2 * l - q
			r = hue2rgb p, q, h + 1/3 ;	g = hue2rgb p, q, h; b = hue2rgb p, q, h - 1/3
		[ parseInt(r * 255), parseInt(g * 255), parseInt(b * 255) ]

	constructor: (r, g, b, a) -> @r = parseInt r; @g = parseInt g; @b = parseInt b; @a = parseFloat a

	#px: 'rgba'
	toHsl: -> rgbToHsl$ @r, @g, @b
	toHsla: -> (h=@toHsl()).push @a; h
	toRgb: -> [@r, @g, @b]
	toRgba: -> [@r, @g, @b, @a]
	toNumber: -> @r*256*256*256+@g*256*256+@b*256+parseInt @a*255
	@fromHsl: (h, s, l) -> new CColor hslToRgb$(h, s, l)..., 1
	@fromRgb: (r, g, b) -> new CColor r, g, b, 1
	@fromRgba: (r, g, b, a) -> new CColor r, g, b, a
	@fromHsla: (h, s, l, a) -> rgb = hslToRgb$ h, s, l; new CColor rgb..., a
	@fromNumber: (color) -> new CColor r=parseInt(color/256/256/256), g=parseInt((color-r=r*256*256*256)/256/256), b=parseInt((color-r-g=g*256*256)/256), (color-r-g-b*256) / 255
	@fromHex: (hex) -> if hex.length == 4 then new CColor hex[1]*16, hex[2]*16, hex[3]*16, 1 else new CColor hex.slice(1,3), hex.slice(3,5), hex.slice(5), 1
	rgba: rgba$ = -> "rgba(#{@r}, #{@g}, #{@b}, #{@a})"
	rgb: -> "rgb(#{@r}, #{@g}, #{@b})"
	hex: -> pad=CMath.pad; to=CRadix.to; "##{pad to @r, 16}#{pad to @g, 16}#{pad to @b, 16}"
	smallhex: -> to=CRadix.to; "##{to parseInt(@r/16), 16}#{to parseInt(@g/16), 16}#{to parseInt(@b/16), 16}"
	hsl: -> x=@toHsl(); "hsl(#{x[0]}, #{x[1]*100}%, #{x[2]*100}%)"
	hsla: -> x=@toHsl(); "hsla(#{x[0]}, #{x[1]*100}%, #{x[2]*100}%, #{@a})"
	name: -> n=@constructor.build_names() unless n=@constructor.names; n[@hex()]
	iname: ->	# приблизительное имя
		n=@constructor.build_names() unless n=@constructor.names
		return name if name=n[@hex()]
		min = Number.POSITIVE_INFINITY; fhex = @constructor.fromHex
		for color, name of n when min > dis=@distance fhex color then min = dis; c = name
		c
	
	red: (x)-> if arguments.length then @r = x; this else @r
	green: (x)-> if arguments.length then @g = x; this else @g
	blue: (x)-> if arguments.length then @b = x; this else @b
	alpha: (x)-> if arguments.length then @a = x; this else @a
	
	hue: (x)-> h=@toHsl(); if arguments.length then [@r, @g, @b] = hslToRgb$ x, h[1], h[2]; this else h[0]
	saturate: (x)-> h=@toHsl(); if arguments.length then [@r, @g, @b] = hslToRgb$ h[0], x, h[2]; this else h[1]
	lightness: (x)-> h=@toHsl(); if arguments.length then [@r, @g, @b] = hslToRgb$ h[0], h[1], x; this else h[2]

	sqr = (x)-> x*x
	distancea: (color) -> Math.sqrt sqr(@r - color.r)+sqr(@g - color.g)+sqr(@b - color.b)+sqr((@a - color.a)*255)
	distance: (color) -> Math.sqrt sqr(@r - color.r)+sqr(@g - color.g)+sqr(@b - color.b)
	
	copy: -> new CColor @r, @g, @b, @a
	
	valueOf: valueOf$ = -> if @px then @[@px]() else if @a==1 then @name() || @hex() else @rgba()
	toString: valueOf$
	
	
	
	@build_names: -> @names = n = {}; (for name, hex of @colors then n[hex] = name); n
	
	@colors: {aliceblue: "#F0F8FF", antiquewhite: "#FAEBD7", aqua: "#00FFFF", aquamarine: "#7FFFD4", azure: "#F0FFFF", beige: "#F5F5DC", bisque: "#FFE4C4", black: "#000000", blanchedalmond: "#FFEBCD", blue: "#0000FF", blueviolet: "#8A2BE2", brown: "#A52A2A", burlywood: "#DEB887", cadetblue: "#5F9EA0", chartreuse: "#7FFF00", chocolate: "#D2691E", coral: "#FF7F50", cornflowerblue: "#6495ED", cornsilk: "#FFF8DC", crimson: "#DC143C", cyan: "#00FFFF", darkblue: "#00008B", darkcyan: "#008B8B", darkgoldenrod: "#B8860B", darkgray: "#A9A9A9", darkgreen: "#006400", darkkhaki: "#BDB76B", darkmagenta: "#8B008B", darkolivegreen: "#556B2F", darkorange: "#FF8C00", darkorchid: "#9932CC", darkred: "#8B0000", darksalmon: "#E9967A", darkseagreen: "#8FBC8F", darkslateblue: "#483D8B", darkslategray: "#2F4F4F", darkturquoise: "#00CED1", darkviolet: "#9400D3", deeppink: "#FF1493", deepskyblue: "#00BFFF", dimgray: "#696969", dodgerblue: "#1E90FF", firebrick: "#B22222", floralwhite: "#FFFAF0", forestgreen: "#228B22", fuchsia: "#FF00FF", gainsboro: "#DCDCDC", ghostwhite: "#F8F8FF", gold: "#FFD700", goldenrod: "#DAA520", gray: "#808080", green: "#008000", greenyellow: "#ADFF2F", honeydew: "#F0FFF0", hotpink: "#FF69B4", indianred: "#CD5C5C", indigo: "#4B0082", ivory: "#FFFFF0", khaki: "#F0E68C", lavender: "#E6E6FA", lavenderblush: "#FFF0F5", lawngreen: "#7CFC00", lemonchiffon: "#FFFACD", lightblue: "#ADD8E6", lightcoral: "#F08080", lightcyan: "#E0FFFF", lightgoldenrodyellow: "#FAFAD2", lightgray: "#D3D3D3", lightgreen: "#90EE90", lightpink: "#FFB6C1", lightsalmon: "#FFA07A", lightseagreen: "#20B2AA", lightskyblue: "#87CEFA", lightslategray: "#778899", lightsteelblue: "#B0C4DE", lightyellow: "#FFFFE0", lime: "#00FF00", limegreen: "#32CD32", linen: "#FAF0E6", magenta: "#FF00FF", maroon: "#800000", mediumaquamarine: "#66CDAA", mediumblue: "#0000CD", mediumorchid: "#BA55D3", mediumpurple: "#9370DB", mediumseagreen: "#3CB371", mediumslateblue: "#7B68EE", mediumspringgreen: "#00FA9A", mediumturquoise: "#48D1CC", mediumvioletred: "#C71585", midnightblue: "#191970", mintcream: "#F5FFFA", mistyrose: "#FFE4E1", moccasin: "#FFE4B5", navajowhite: "#FFDEAD", navy: "#000080", oldlace: "#FDF5E6", olive: "#808000", olivedrab: "#6B8E23", orange: "#FFA500", orangered: "#FF4500", orchid: "#DA70D6", palegoldenrod: "#EEE8AA", palegreen: "#98FB98", paleturquoise: "#AFEEEE", palevioletred: "#DB7093", papayawhip: "#FFEFD5", peachpuff: "#FFDAB9", peru: "#CD853F", pink: "#FFC0CB", plum: "#DDA0DD", powderblue: "#B0E0E6", purple: "#800080", red: "#FF0000", rosybrown: "#BC8F8F", royalblue: "#4169E1", saddlebrown: "#8B4513", salmon: "#FA8072", sandybrown: "#F4A460", seagreen: "#2E8B57", seashell: "#FFF5EE", sienna: "#A0522D", silver: "#C0C0C0", skyblue: "#87CEEB", slateblue: "#6A5ACD", slategray: "#708090", snow: "#FFFAFA", springgreen: "#00FF7F", steelblue: "#4682B4", tan: "#D2B48C", teal: "#008080", thistle: "#D8BFD8", tomato: "#FF6347", turquoise: "#40E0D0", violet: "#EE82EE", wheat: "#F5DEB3", white: "#FFFFFF", whitesmoke: "#F5F5F5", yellow: "#FFFF00", yellowgreen: "#9ACD32"}


CMath =
	round: (x, round) -> Math.round(x * (r=Math.pow(10, round))) / r
	ceil: (x, round) -> Math.ceil(x * (r=Math.pow(10, round))) / r
	floor: (x, round) -> Math.floor(x * (r=Math.pow(10, round))) / r	
	uniqid: () -> arguments.callee.i ||= 0 ; 'uniqid' + (++arguments.callee.i)
	# http://mathhelpplanet.com/static.php?p=javascript-operatsii-nad-matritsami
	transpose: (matrix) -> A = []; (for i in [0...(matrix[0] || []).length] then A[i] = a = []; (for j in [0...matrix.length] then a[j] = matrix[j][i])); A
	
	pad: (x, n = 2) -> if 0 < n = n - String(x).length then (for i in [0...n] then x="0"+x); x else x
	
	eq: (a, b, p=Number.MIN_VALUE*10) -> a-b < p
	equal: (a, b) ->
		i = j = 0
		for k in a
			if a[k] != b[k]
				x = a[k]; y = b[k]
				if typeof x == 'object' 
					if x.prototype == y.prototype and CMath.equal x, y then continue
				return off
			i++
		for k in b then j++
		i == j
	
	# http://habrahabr.ru/company/nordavind/blog/209462/
	# http://htmlbook.ru/css/transition-timing-function
	'cubic-bezier': cubicBezier = (p0, p1, p2, p3) -> do(p0, p1, p2, p3)-> (t)-> t_1=1-t; t2_1 = t_1*t_1; t3_1=t2_1*t_1; t2=t*t; t3=t2*t; t3_1*p0 + 3*t*t2_1*p1 + 3*t2*t_1*p2 + t3*p3
	
	ease: cubicBezier 0.25,0.1,0.25,1
	'ease-in': cubicBezier 0.42,0,1,1
	'ease-out': cubicBezier 0,0,0.58,1
	'ease-in-out': cubicBezier 0.42,0,0.58,1
	
	

	
		
	#resize: (root) ->
	#	root.interval -> @clear()
	
	
CInit =
	requires: {}
	path: null
	pack: []
	check: (path) -> x = not(name of CInit.requires); CInit.requires[path] = 1 ; x
	require: (name) ->
		if name[0]!='/' then name = CInit.path+'/'+name
		if CInit.check name+='.js' then document.writeln('\n<script src="'+name+'" type="text/javascript"></script>'); on else off
	link: (name, media) ->
		if name[0] != '/' then path = CInit.path.replace ///\w+$///, 'css'; name = path+'/'+name
		if CInit.check name+='.css' then document.writeln('\n<link rel="stylesheet" href="'+name+'" type="text/css"'+(if media then ' media="'+media+'"' else '')+'>'); on else off
		
	init_from_param: ->
		src = if a=document.getElementById "_app_" then a.src else (document.getElementsByTagName('body') || document.getElementsByTagName('head'))[0].innerHTML.match(/// src=['"]?( [^\s'"<>]+ ) [^<>]+> (\s*</\w+>)+ \s* $ ///i)[1].replace(/&amp(?:;|\b)/g, '&')
		CInit.path = src.replace /// /? [^/]+? \.js\b.*///, ''
		param = src.replace /// .*? \? ///, ''
		param = CParam.get(src)
		if IE < 9 then CInit.require "ie"
		CInit.param = extend {}, param
		CInit.init param
		
	init: (param) ->
		for key of param
			switch key
				when 'name' then window.name = param.name
				when 'post' then CInit.post = param.post
				when 'url' then CInit.url = param.url
				when 'css' then
				when 'style'
					for i in param.style.split ',' then CInit.style i
				when 'link'
					for i in param.link.split(",") then CInit.link i
				when 'theme' 
					if param.theme == "blueprint"
						CInit.link "screen", "screen, projection"
						CInit.link "print", "print"
						if IE < 8 then CInit.link "ie", "screen, projection"
					else if param.theme == "app"
						CInit.link "style", "screen, projection"
					else throw CRoot.raise "Нет темы #{param.theme}"
				when 'pack'
					for i in CInit.pack = param.pack.split(",") then CInit.require i
				else throw CRoot.raise "Нет параметра #{key} в инициализаторе библиотеки"
		undefined


unless window.XMLHttpRequest and not IE then CInit.require "old"


class CSocket
	# bufferedAmount - сколько данных передано через send
	constructor: -> 
		if arguments.length then @connect.apply this, arguments
		@reconnect = 0

	connect: (url, protocol) ->
		@reconnect++
		@url = url
		sock = @socket = new WebSocket url, protocol
		sock.$sock = this
		sock.onopen = @onopen
		sock.onclose = @onclose
		sock.onmessage = @onmessage
		sock.onerror = @onerror
		this

	onopen: ->
		if @reconnect == 1 then @$sock.onConnect() else @$sock.onReconnect()
		this
		
	onclose: (e) ->
		if e.wasClean then @$sock.onClose e.code, e.reason
		else @$sock.onDisconnect e.code, e.reason
		@$sock.socket = null
		delete @$sock
		this

	onmessage: (e) -> @$sock.onMessage fromJSON e.data
		
	onerror: (e) -> @$sock.onError e.message; delete @$sock
		
	onConnect: -> say "Соединение установлено"
	onDisconnect: (code, reason) -> say 'Обрыв соединения. Код: ' + code + ' причина: ' + reason
	onReconnect: -> say "Пересоединение установлено"
	onMessage: (data) -> say 'Сообщение:', data
	onClose: (code, reason) -> say 'Код: ' + code + ' причина: ' + reason
	onError: (message) -> say 'Ошибка '+message
	emit: (data) -> @send toJSON data; this
	send: (data) -> @socket.send data; this
	
	
class CLongPoll extends CSocket
	id_counter: 0
	sockets: {}
	
	connect: (url) ->
		@url = url
		url = escapeHTML url
		id_counter = @constructor::id_counter++
		id = @constructor.className() + 'Emitter' + id_counter
		CRoot.body().append @form = CRoot.wrap "<form method=POST action='#{url}' target=#{id} accept-charset=utf-8 style='display:none'><textarea name=d></textarea></form>"
		.append @iframe = CRoot.wrap "<iframe name=#{id} src='about:blank'></iframe>"
		CRoot.head().append @script = CRoot.wrap "<script src='#{url}?n=#{id_counter}&t=#{new Date().getTime()}' type='text/javascript' charset=utf-8></script>"
		@sockets[id_counter] = this
		this
	
	send: (data) ->
		@form.first().val data
		@form.element.submit()
		this
		
	close: ->
		delete @sockets[@id_counter]
		@script.union(@form, @iframe).remove()
		@onClose 0, "Программное закрытие"
		this
		

# class CRPC extends CSocket
	# onMessage: (data) -> 
	# eval: (code) -> @emit act: 'eval', code: code
	# call: ()

# http://help.dottoro.com/larrqqck.php - список event-ов
CSend = (element, event) ->
	unless widget = element.widget then widget = CRoot.createWidget element
	e = new CEvent event, event.type
	ret1 = CSend[e.type]?.call widget, e, widget
	ret2 = widget.send 'on'+e.type, e, widget
	ret3 = CSend[e.type+"_end"]?.call widget, e, widget
	if ret2? then ret2 else if ret3? then ret3 else ret1

extend CSend,
	
	setHandler: (element, type) -> element.setAttribute 'on'+(CSend[type+'_type'] || type), "return CSend(this, event)"
	removeHandler: (element, type) -> element.removeAttribute 'on'+(CSend[type+'_type'] || type)
	
	mousedown: (e) -> which=e.event.which; p = CEvent.prototype; (if which == 1 then p.left = on); (if which == 2 then p.mid = on); (if which == 3 then p.right = on)
	mouseup: (e) -> which=e.event.which; p = CEvent.prototype; (if which == 1 then p.left = off); (if which == 2 then p.mid = off); (if which == 3 then p.right = off)
	click: -> CEvent::left = on ; return
	click_end: -> CEvent::left = off ; return


unless 'onmouseenter' of document then extend CSend,
	mouseenter_type: 'mouseover'
	mouseover: (e, widget) ->
		to=e.relatedTarget()
		while to and to != widget then to = to.up()
		if to != widget then e.type='mouseenter'; widget.send 'on'+e.type, e, widget
	mouseleave_type: 'mouseout'
	mouseout: (e, widget) ->
		to=e.relatedTarget()
		while to and to != widget then to = to.up()
		if to != widget then e.type='mouseleave'; widget.send 'on'+e.type, e, widget

do ->
	style = document.createElement('div').style
	unless 'transition' of style then CSend['transitionend_type'] = CNavigator.onvendor+'TransitionEnd'
			
	unless 'animation' of style
		vendor = CNavigator.onvendor
		for event in ['Start', 'Iteration', 'End']
			name = vendor+'Animation'+event
			CSend['animation'+event.lcFirst()+'_type'] = name
	return
		

# http://habrahabr.ru/post/118318/
# http://unixpapa.com/js/mouse.html - mouse buttons
class CEvent
	constructor: (@event, @type) ->
	
	left: off
	mid: off
	right: off
	
	keys$ = 38: 'up', 40: 'down', 37: 'left', 39: 'right', 27: 'esc', 8: 'backspace', 9: 'tab', 46: 'delete', 13: 'enter'
	
	for key$, val$ in keys$ then @::['press'+key$.upFirst()] = do(val$)-> -> @code() == val$
	
	stop: -> @event.stopPropagation()		# отключает всплывание
	cancel: -> @event.preventDefault()		# отключает событие по умолчанию
	break: -> @stop(); @cancel()
	target: unless CNavigator.safari <= 3 then -> CRoot.createWidget @event.target else -> CRoot.createWidget(if (targ=@event.target).nodeType == 3 then targ.parentNode else targ) # safari3
	relatedTarget: -> (target = @event.relatedTarget) and CRoot.createWidget target
	code: -> @event.charCode || @event.keyCode || @event.which
	key: -> keys$[code=@code()] || String.fromCharCode code
	x: -> @event.pageX
	y: -> @event.pageY
	viewX: -> @event.clientX
	viewY: -> @event.clientY
	offsetX: -> (CEvent::offsetX = if @event.offsetX? then -> @event.offsetX else -> @event.clientX - (t=@target()).viewPos().left - t.px 'border-left-width'); @offsetX()
	offsetY: -> (CEvent::offsetY = if @event.offsetY? then -> @event.offsetY else -> @event.clientY - (t=@target()).viewPos().top - t.px 'border-top-width'); @offsetY()
	

# Модели
class CModel
	# _: {} - данные
	# _cmp: {} - функции сравнения
	# !_queue: {} - очереди обрабатывающихся ключей
	# _on: {} и on... - обработчики при изменении данных
	# _at: {} и at... - обработчики при запросе данных
	# _name: string - имя модели в ::_models
	# _compute: {} - вычислимые ключи
	#! _models: {} # все модели по имени (@_name)
	#!_counter: 0
	constructor: (data = {}, cmp = {}, @_name) ->
		@_ = data
		@_cmp = cmp ||= {}
		@_on = {}
		@_at = {}
		#@_queue = {}
		@_compute = {}
		for key of data then @set key, data[key], cmp[key]
	
	has: (key) -> key of @_
	
	free_compute$ = (key) ->
		c = @_compute[key]
		if c.slave
			for k in c.slave then @off k, c.fn
		if c.master then @off key, master
		delete @_compute[key]
		this
		
	
	set: (key, val, cmp) ->
		if key of @_compute then free_compute$.call this, key
		
		fn = do(key)-> (val) -> if arguments.length then @change key, val else @retrive key
		@_[key] = val
		if cmp then @_cmp[key] = cmp
		@["$"+key] = fn
		@[key] = fn unless key of this and not @hasOwnProperty key
		this
	
	compute: (key, opt) ->
		if typeof opt == 'function' then opt = slave: opt
		@set key, opt.val, opt.cmp
		if slave = opt.slave
			match = String(slave).match /// ^function\s*[\$\w]*\s*\( ([^\(\)]*) \) ///
			keys = match[1].split /// ,\s* ///
			@on keys, fn = do(key, slave, keys)-> (v, old, key1)->
				ret = new Array((len=keys.length)+2)
				ret[len] = old
				ret[len+1] = key1
				for name, i in keys then ret[i] = @retrive name
				@change key, slave.apply this, ret
		if master = opt.master then @on key, master
		@_compute[key] = master: master, slave: keys, fn: fn
		this
		
		
	del: (key) -> (if key of @_compute then free_compute$.call this, key); @un key; @off key; delete @_[key]; delete @_cmp[key]
	
	cmp: (key, cmp) ->
		if arguments.length == 1
			if typeof key == 'string' then @_cmp[key]
			else (for i of key then @_cmp[i] = key[i]); this
		else if cmp then @_cmp[key] = cmp
		else delete @_cmp[key]
		this
	
	_on = (key, fn) -> (for key in $A key then (@$0$[key] ||= []).push fn); this
	_off = (key, fn) ->
		if arguments.length == 1
			for key in $A key
				delete @$0$[key]
		else if typeof fn == 'function'
			for key in $A key
				if (ons = @$0$[key]) and -1 != idx=ons.indexOf fn
					if ons.length == 1 then delete @$0$[key] else ons.splice idx, 1
		else
			for key in $A key
				if ons = @$0$[key]
					for i, idx in ons when i._belong == fn then ons.splice idx, 1 ; break
					if ons.length == 0 then delete @$0$[key]
		this
	
	on: _on.inline "on", "_on"
	off: _off.inline "off", "_on"
	at: _on.inline "at", "_at"
	un: _off.inline "un", "_at"
	
	change: (key, val) ->
		#throw CRoot.raise "Нет ключа `#{key}` в модели #{@constructor.getName()}.#{@_name}" unless key of @_
		if arguments.length == 1 then val = !@_[key]
		old=@_[key]
		if (if cmp=@_cmp[key] then !cmp.call this, val, old else val != old) then @_[key] = val; @send val, old, key
		this

	send: (val, old, key) ->
		#if q = @_queue[key] then q.push 
		#else
		#	@_queue[key] = []

		if ons = @_on[key]
			for fn in ons then fn.call this, val, old, key
		#delete @_queue[key]
		this
			
	retrive: (key) ->
		if at = @_at[key] then for fn in at then @change key, fn.call this, key, @_[key]
		@_[key]


class CRepository	# Abstract, _: {} - ключи
	constructor: (model, @_ = {}) ->
		@model = model
		for key of @_
			unless key of model._ then model.set key, @_[key]
			if @save then model.on key, fn = ((val, old, key) => @save key, val); fn._belong = this
			if @load then model.at key, fn = ((key) => @load key); fn._belong = this
			
	sync: -> (for key of @_ when (val = @load key) != undefined then @model.change key, val); this

	
class CCookieRepository extends CRepository
	constructor: (model, fields, @props = {}) -> super model, fields
	load: (key) -> if (val=CRoot.cookie key)? then fromJSON val else undefined
	save: (key, val) -> CRoot.cookie key, toJSON(val), @props


class CAjaxRepository extends CRepository
	constructor: (model, fields, @widget) -> super model, fields; @widget.onLoad ||= (req) => @save = (->); (for key, val of req.data then @model.change key, val); delete @save; this
	save: (key, val) -> if @_ajax_save then @_ajax_save[key]=val else @_ajax_save = x = {}; x[key] = val; setTimeout (=> @widget.ping save: toJSON @_ajax_save; @_ajax_save = null), 0


class CAjaxIoRepository extends CAjaxRepository
	load: (key) -> (if @_ajax_load then @_ajax_load.push key else @_ajax_load = [key]; setTimeout (=> @widget.ping load: @_ajax_load; @_ajax_load = null), 0); @_[key]
	

# работает с socket.io
# пример:
# socket = io.connect('http://wsidx')
# CIoRepository model, fields, socket
class CIoRepository extends CRepository
	constructor: (model, fields, @iosocket) -> super model, fields; @iosoket.on 'load', (x) => @model.change x[0], x[1]
	save: (key, val) -> @iosocket.emit 'save', [key, val]

	
class CIoLoadRepository extends CIoRepository
	load: (key) -> @iosocket.emit 'load', key; @_[key]
	
	
CTemplate =

	_STASH: {}

	compile: (i_html, forms = {}, form = {}) ->

		code_begin = """function(dataset, id1, start) {
	if(!dataset) dataset = []
	var res = []
	start = start || 0
	for(var i=0, n=dataset.length; i<n; i++) {
		var data = dataset[i]
		var id = id1+'-'+(('id' in data)? data.id: start+i)
		res.push('"""
		
		code_end = """')
	}
	var html = res.join('')
	return html
}"""

		code_begin1 = "function(data, id) { if(!data) data = {}; return ['"
		code_end1 = '\'].join("") }'
		
		RE_TYPE = "(\"(?:\\\\\"|[^\"])*\"|'(?:\\\\'|[^'])*'|-?\\d+(?:\\.\\d+)?(?:E[+-]\\d+)?)"
		CALL_FN = new RegExp "^\\{%\\s*(\\w+)\\s+#{RE_TYPE}(?:\\s*,\\s*#{RE_TYPE})?(?:\\s*,\\s*#{RE_TYPE})?(?:\\s*,\\s*#{RE_TYPE})?(?:\\s*,\\s*#{RE_TYPE})?\\s*%\\}"
		PARSE_VAR = new RegExp "^(?:\\$(\\{\\s*)?(?:(%)?(\\w+)|#{RE_TYPE})|(#)(\\{\\s*)?(%)?(\\w+))"
		PARSE_CONST = new RegExp "^#{RE_TYPE}"
		RE_IF = new RegExp "^\\{%\\s*if\\s+(?:\\$(%)?(\\w+)|#{RE_TYPE})"
		RE_ELIF = new RegExp "^\\{%\\s*elif\\s+(?:\\$(%)?(\\w+)|#{RE_TYPE})"
		
		RE_FORM = new RegExp "^\\$([+*])(\\w+)?(?::(?:(noload)|(load|model)\\((?:(\\w+),\\s*)?(?:(%?\\w+)|(#{RE_TYPE}))\\)))?"
		
		re_type = (s) -> if s? then s.replace(/\n/g, '\\n').replace /\r/g, '\\r'
		_NO_ESCAPE_HTML = CHelper._NO_ESCAPE_HTML
		
		_tags = ///(?:input|meta)///i
		tags =
			th: ///^(?:tr|table|tbody|tfoot|thead)$///
			td: ///^(?:tr|table|tbody|tfoot|thead)$///
			tr: ///^(?:table|tbody|tfoot|thead)$///
			option: ///^select$///
			li: ///^(?:ol|ul)$///

		form.fields = {}
		form.forms = []
			
		T = []; html = []; pos = 0 ; s = i_html; ifST = []
		
		var_x = (_type, _var) ->
			if _type
				if _var == '_DATA' then "data"
				else if _var == "_STASH" then "CTemplate._STASH"
				else if _var == 'i' then "i"
				else if _var == 'i0' then "(i-1)"
				else if _var == 'id' then "id"
				else "CTemplate._STASH.#{_var}"
			else "data['#{_var}']"
		
		helper = (_type, _var, _const, open_braket) ->
			braket = 0
			VAR = undefined
			html.push _const || var_x _type, _var
			fn_idx = html.length-1
			fn_idxs = [fn_idx]
			while 1

				if not VAR and m = s.match ///^:(\w+)(\()?///
					html[fn_idx] = "CHelper.#{m[1]}(" + html[fn_idx]
					html.push (if m[2] then ++braket; ", " else VAR = not VAR; ")")
				else if VAR and m = s.match PARSE_CONST then fn_idxs.push fn_idx; fn_idx = html.length; html.push re_type m[0]
				else if VAR and m = s.match ///^\$(%)?(\w+)/// then fn_idxs.push fn_idx; fn_idx = html.length; html.push var_x m[1], m[2]
				else if not VAR and m = s.match ///^,\s*/// then fn_idx = fn_idxs.pop(); html.push m[0]
				else if m = s.match ///^\)/// then VAR=1 ; --braket; fn_idx = fn_idxs.pop(); html.push ")"
				else if m = s.match ///^\}/// then (throw "нет `{` для `}`" unless open_braket); open_braket = 0 ; pos++; s = s.slice 1 ; break
				else break
				pos += len = m[0].length
				s = s.slice len
				VAR = !VAR

			throw "не закрыта `}`" if open_braket
			throw "не закрыты скобки (#{braket})" if braket
			
			return fn_idx
		
		
		pop = ->
			tag = T.pop()
			if tag.length > 2
				[open_tag, begin, name, type, cinit, idx, _form] = tag
				template = i_html.slice begin, pos
				if cinit then html[idx] = [html[idx], "<!--", template.replace(/!/g, '!!').replace(/-->/g, '--!>'), "-->"].join ""
				html.push (if type then code_end else code_end1)
				form.template = template
				#form.code = html.slice(idx+2).join ""
				_form.forms.push form
				id = "id" + (if name then "+'-#{name}'" else "")
				data = "data" + (if name then "['#{name}']" else "")
				html.push ")(", data, ", ", id, "), '"
				form = _form
			tag[0]
		
		while 1

			if not NO and m = s.match ///^<(\w+)///
				open_pos = pos
				TAG = open_tag = m[1]
				open_tag = open_tag.toLowerCase()
				NO = 1 if /^(?:script|style)$/.test open_tag
				if re = tags[open_tag]
					pop() while T.length and not re.test T[T.length-1][0] 
				html.push m[0]
			else if not NO and m = s.match ///^>///
				if _tags.test TAG then TAG = open_id = undefined ; html.push ">"
				else
					if t
						frm = t
						t = [open_tag, pos+1, name=t.name, type=t.is_list, ///\bcinit\b///i.test(i_html.slice open_pos, pos), html.length, form]
						id = if name? then form.id + "-" + name else ''
						forms[id] = form = extend frm, id: id, fields: {}, forms: []
						html.push ">", "', (", (if type then code_begin else code_begin1)
					else t = [open_tag]; html.push ">"
					T.push t; t = open_tag = undefined
			else if not NO and m = s.match ///^/>/// then TAG = open_id = undefined ; html.push m[0]
			else if not NO and m = s.match ///^</(\w+)\s*>/// then TAG = open_id = undefined ; tag = m[1]; (while T.length and pop() != tag then null); html.push m[0]
			else if not NO and m = s.match ///^<\!--.*?-->/// then m[0].replace ///'///g, "\\'"
			else if NO and (m = s.match ///^</(\w+)\s*>///) and m[1] == TAG then TAG = open_id = open_tag = NO = undefined ; html.push m[0]
			else if open_tag and m = s.match ///^\$-(\w+)/// then open_id = m[1]; html.push "', id, '-" + m[1]
			
			else if m = s.match ///^\$@([/\w-]+)/// then html.push "', CTemplate.include('#{m[1]}'), '"
			else if m = s.match ///^\$&/// then 
			else if m = s.match ///^{%\s*(\w+)\s*=%\}/// then html.push "', (function() { CTemplate._STASH.#{m[1]} = ['"
			else if m = s.match ///^{%\s*end\s*%\}/// then html.push "'].join(''); return '' })(), '"
			
			else if m = s.match RE_IF then s = s.slice len = m[0].length; pos += len; html.push "', ("; helper(m[1], m[2], m[3]); throw "Нет закрывающей `%}` для if" unless m = s.match ///^\s*%\}///; ifST.push 1 ; html.push "? ['"
			else if m = s.match RE_ELIF then s = s.slice len = m[0].length; pos += len; html.push "'].join(''): "; helper(m[1], m[2], m[3]); throw "Нет закрывающей `%}` для elif" unless m = s.match ///^\s*%\}///; throw "Нельзя использовать elif" if (n=ifST.length)==0 or ifST[n-1] != 1 ; html.push "? ['"
			else if m = s.match ///^\{%\s*else\s*%\}/// then throw "Нельзя использовать else" if (n=ifST.length)==0 or ifST[n-1] != 1 ; ifST[n-1] = 2 ; html.push "'].join(''): ['"
			else if m = s.match ///^\{%\s*fi\s*%\}/// then throw "Нельзя использовать fi" if (n=ifST.length)==0 ; html.push "'].join('')" + (if ifST[n-1] == 1 then ": ''" else "") + "), '"
			
			else if m = s.match CALL_FN then
			else if m = s.match ///^&#?\w+;?/// then html.push m[0]
			else if m = s.match PARSE_VAR
				open_span = m[5]
				open_braket = m[1] || m[6]
				_type = m[2] || m[7]
				_var = m[3] || m[8]
				_const = if m[4]? then re_type m[4]
				
				if open_span and (open_tag or /^(?:script|style)$/i.test TAG) then html.push m[0]
				else
					s = s.slice len = m[0].length; pos += len
					
					form.fields[_var] = 1 if _var and not type
					
					html.push "<span id=', id, '-#{_var}>" if open_span
					html.push "', "
					
					fn_idx = helper _type, _var, _const, open_braket
					
					unless (m=html[fn_idx].match /^CHelper\.(\w+)/) and _NO_ESCAPE_HTML[m[1]] then html[fn_idx] = "CHelper.html(" + html[fn_idx]; html.push ")"
					
					html.push ", '" + (if open_span then "</span>" else "")
					continue

			else if open_tag and m = s.match RE_FORM
				t = name: m[2], is_list: m[1]=='*'
				load = m[4]
				t.load = if m[3] then 0 else if load and load == "load" then 1 else if form.load then 2 else 0
				html.push "', id, '" + (if m[2] then "-" + m[2] else "")
			else if m = s.match ///^[\\']/// then html.push "\\"+m[0]
			else if m = s.match ///^\n/// then html.push "\\n"
			else if m = s.match ///^\r/// then html.push "\\r"
			else if s.length then html.push s[0]; m = [s[0]]
			else break
			
			s = s.slice len = m[0].length
			pos += len
			
		pop() while T.length
		
		if form.is_list then code_begin1 = code_begin; code_end1 = code_end
		html.unshift "fn=", code_begin1
		html.push code_end1
		code = html.join ""
		fn = null
		eval code
		fn

	# $@ - innerHTML before, $& - innerHTML after
	apply: (element, cls) ->
		id = element.id ||= CMath.uniqid()
		cview = CView[element.getAttribute "cview"]
		if v=cview[2]
			if c=v.class then element.className += " " + c
			if element.tagName != c=v.tag then if w = element.widget then w.tag c else (new CWidget element).tag(c).unwrap()
		html = cview[1]
		content=element.innerHTML
		html = html.replace /\$@/, content
		html = CTemplate.compile(html)($H(element.getAttribute('cargs'), ///\s+///, ///=///), id)
		html = html.replace /\$&/, content
		element.removeAttribute "cview"
		element.removeAttribute "cargs"
		element.setAttribute 'ctype', CWidget::className.call constructor: cls || cview[0]
		element.innerHTML = html
		
	#fromArgs: (s) -> x={}; fromArg = ((v) -> [key, val] = v.split("="); x[key]=val); s=String s; (while (pos=s.search(/\s+\w+=/)) != -1 then v=s.slice 0, pos; s=s.slice(pos).replace /^\s+/, ''; fromArg v); fromArg s.replace /\s+$/, ''; x
	_color: ['Cornsilk', 'lavender', 'Ivory', 'LavenderBlush', 'LemonChiffon', 'MistyRose', 'Seashell', 'Honeydew', 'MintCream', 'Azure', 'AliceBlue']
	color: (n=parseInt(Math.random()*CTemplate._color.length)) -> CTemplate._color[n]
	
	include: (name, data, id)->
		page = CTemplate._PAGE[name]
		unless code = page.code
			template = CTemplate._PAGE[name].template
			code = CTemplate.compile template
		code data, name


CHelper =
	_NO_ESCAPE_HTML: raw: 1, html: 1, json: 1, dump: 1, style: 1
	json: toJSON
	raw: (x) -> x
	html: escapeHTML
	nbsp: (x) -> if x? and x!="" then "&nbsp;" else escapeHTML x
	bool: (x, a, b) -> if x then (if a? then a else "+") else (if b? then b else "-")
	dump: (x) -> "<pre>"+escapeHTML(toJSON x, undefined, 4)+"</pre>"
	join: (x, sep=", ", args...) -> x.concat(args).join sep
	at: (x, i) -> x[i]
	odd: (x, a='odd', b='') -> if x % 2 then a else b
	even: (x, a='even', b='') -> if x % 2==0 then a else b
	oddeven: (x, a='odd', b='even') -> if x % 2 then a else b
	# логические операторы
	and: (a, b) -> a and b
	or: (a, b) -> a or b
	not: (a) -> not a
	lt: (a, b) -> a < b
	gt: (a, b) -> a > b
	le: (a, b) -> a <= b
	ge: (a, b) -> a >= b
	eq: (a, b) -> a == b
	ne: (a, b) -> a != b
	# атрибуты, классы, стили
	visible: (a) -> if a then "" else 'display:none'
	style: (a) -> if a then "style=\"#{a}\"" else ''
	img: (a) -> if !a or !(a = parseInt a) then "/img/" else "/images/#{CRadix.to(a, 62, '/')}"
	
	
CValid =
	int: /^-?\d+$/
	uint: /^\d+$/
	number: /^-?\d+(\.\d+)?$/
	unumber: /^\d+(\.\d+)?$/
	email: /@/


CEffect =
	show:
		css: {overflow: 'hidden'}
		from: {width: 0, height: 0, 'font-size': 0}
		begincss: { display: '' }
	hide:
		css: {overflow: 'hidden'}
		to: {width: 0, height: 0, 'font-size': 0}
		endcss: { display: 'none' }
	slideUp:
		css: {overflow: 'hidden'}
		from: {height: 0}
		begincss: { display: '' }
	slideDown:
		css: {overflow: 'hidden'}
		to: {height: 0}
		endcss: { display: 'none' }
	fadeIn:
		from: {opacity: 0}
		begincss: { display: '' }
	fadeOut:
		to: {opacity: 0}
		endcss: { display: 'none' }


CRoot = null
unless window.$ then $ = (e) ->
	if typeof e == 'function' then CRoot._ready_functions.push e
	else if typeof e == 'string' && !/^</.test e then CRoot.find e
	else if !e? then new CWidgets
	else CRoot.wrap e

	
class CWidget

	model: new CModel({}, {}, "main")

	constructor: (element, @_form) ->
		throw @raise "element не HTMLElement", element unless element and element.tagName
		throw @raise "element уже имеет виджет ", element.widget if element.widget
		@element = element
		element.widget = this

	_slice$ = Array::slice
		
	div$ = document.createElement "div"
	wdiv$ = new CWidget div$
		
	_type$ = (type, names) -> (for name in names.split /\s+/ then CWidget::[name].type$ = type); this
	type$: type$ =
		nothing: (names) -> _type$ 0, names
		attr: (names) -> _type$ '$attr', names
		any: (names) -> _type$ '$any', names
		range: (names) -> _type$ '$range', names
		rangeAll: (names) -> _type$ '$rangeAll', names
		all: (names) -> _type$ '$all', names
		join: (names) -> _type$ '$join', names
		
	
	# служебные методы
	form: (form) ->
		if arguments.length
			# удаляем эвенты - можно не удалять
			#if @_form then 
			# устанавливаем эвенты
			#if prev = @form() then prev.detach this
			@_form = form
			this
		else
			unless @_form
				element = @element
				@_form = if cform = element.getAttribute "cform" then @byId cform
				else if element.id and match=element.id.match(/^(.+)-\w+$/) then @byId match[1]
				else null

			throw @raise "form не CWidget: "+@_form unless !@_form or @_form && @_form instanceof CWidget
			@_form
	formAll: -> p = this ; while p = p.form() then p
	
	valueOf: -> '<'+@className()+' '+(@element && (@element.id && "#"+@element.id || @element.className && '.'+@element.className.split(' ').join(".") || @element.tagName))+'>'
	toString: CWidget::valueOf

	raise: (message) -> new Error this+": "+message
	warn: (args...) -> say this, arguments.callee.caller.getName(), args...
	
	className: if this.name then -> @constructor.name else -> @constructor.getName()
	
	type$.nothing 'raise warn className'
	type$.join 'valueOf toString'
	type$.attr 'form'
	
	# методы создания елементов и виджетов
	createWidget: (element, form) ->
		if widget=element.widget then return widget
		cls = @ctype element
		if cview = element.getAttribute? 'cview' then CTemplate.apply element, cls
		new cls element, form

	ctype: (element) ->
		return CNode if element.nodeType != 1
		return window['C'+ctype.uc()+'Widget'] || window[ctype] if ctype = element.getAttribute 'ctype'
		return CView[cview][0] if cview = element.getAttribute 'cview'
		if id = element.id
			if (a=id.match /// (?:^|-) ([a-z_]\w*) $ ///i) and (a=window[a[1]]) instanceof Function and /^C\w+Widget$/.test CWidget::className.call( constructor: a) then return a
		if (tag = element.tagName) == "INPUT" and cls=window['C'+element.type.uc()+'Widget'] then cls else if (cls=window["C"+tag.toLowerCase().ucFirst()+"Widget"]) instanceof Function and CWidget::className.call( constructor: cls ) then cls else	CWidget

	toElements$ = (e) ->
		x = []
		for i in e when i?
			if i.getElementsByTagName then x.push i
			else if (w=@wrap i).element then x.push w.element
			else x=x.concat w._all
		new CWidgets x
			
		
	wrapMap$ =
		option: [ 1, "<select multiple=multiple>", "</select>" ]
		thead: [ 1, "<table>", "</table>" ]
		col: [ 2, "<table><colgroup>", "</colgroup></table>" ]
		tr: [ 2, "<table><tbody>", "</tbody></table>" ]
		td: [ 3, "<table><tbody><tr>", "</tr></tbody></table>" ]

	wrapMap$.optgroup = wrapMap$.option
	wrapMap$.tbody = wrapMap$.tfoot = wrapMap$.colgroup = wrapMap$.caption = wrapMap$.thead
	wrapMap$.th = wrapMap$.td
	wrapDiv$ = document.createElement 'div'
		
	text2elem$ = (element) ->
		if (x = element.match ///^<(\w+)///) and x=wrapMap$[x[1]]
			(div = wrapDiv$).innerHTML = [x[1], element, x[2]].join ""; i = x[0]
			while i-- then div = div.firstChild
		else (div = wrapDiv$).innerHTML = element
		div
	
	wrap: (element, form) ->
		if element instanceof CWidget then element
		else unless element? then null
		else if widget=element.widget then widget
		else if (type=typeof element) == "string"
			div = text2elem$ element
			if div.childNodes.length==1 then element = div.firstChild; div.innerHTML = ""; @createWidget element, form
			else widget = new CWidgets _slice$.call div.childNodes; div.innerHTML = ""; widget
		else if element instanceof Array then toElements$.call this, element
		else if type == "number" then new CNode document.createTextNode(element), form
		else if element instanceof RegExp then @wrap(@document()).find String(element).slice 1, -1
		else @createWidget element, form
	
	unwrap: -> @send 'onDestroy', 'unwrap'; @form()?.detach this ; e=@element; @element = @element.widget = null ; new CWidgets [e]
	rewrap: (cls) -> p = @form(); e = @unwrap()._all[0]; w = (if typeof cls == 'function' then new cls e, p else cls.unwrap(); cls.element = e; e.widget = cls; cls.form p); (if p and p.id()+'-'+w.name() == w.id() then p.attach w); w
	
	new$ = (tag, ctype, param) ->
		if typeof ctype == 'object' then param = ctype; ctype = undefined
		param || = {}
		if typeof ctype == 'string' then param.ctype = ctype; ctype = undefined
		if ctype then param.ctype = ctype.getName()
		e = $0$
		if param then for k of param then e.setAttribute k, param[k]
		@createWidget e

	new: new$.inline "new", "document.createElement(tag)"
	#svg: new$.inline "svg", "document.createElementNS('http://www.w3.org/2000/svg', tag)"
	#xml: new$.inline "xml", "document.createElementNS('http://www.w3.org/1999/xhtml', tag)"
	
	#emmet: (e) ->	
	
	type$.nothing 'createWidget ctype new'
	type$.all 'rewrap unwrap'
	type$.any 'wrap'
	
	
	# служебные элементы
	class CRoot$ extends CWidget
		_ready_functions: []
		_init_widgets: []
		initialize: ->
			CInit.init_from_param()
			@defineHandlers().setListens()
			$(document).setHandler 'mousedown', 'mouseup'
		onready_dom: ->
			if init = CInit.param.init
				for id in init.split /,/ then @byId id
			if init = CInit.param.form
				for id in init.split /,/ then new (window[id.uc()])()
			do @initWidgets
			for ready in @_ready_functions then ready.call this
			this
		initWidgets: ->
			doc = @document()
			for x in @_init_widgets
				cls = x[0].getName()
				for id in x[1] when (e = doc.getElementById id) and not e.widget then e.setAttribute 'ctype', cls; @createWidget e
			this
	
	CRoot = new CRoot$ document.documentElement || document.firstChild
	
	document: if ownerDocument$ = div$.ownerDocument then -> @element.ownerDocument else -> @element.ownerDocument || document
	window: -> @document().defaultView
	htm: if document.documentElement then -> @wrap @document().documentElement else -> @wrap @document().firstChild
	root:
		if ownerDocument$
			-> if (htm=@htm()).element.contains @element then htm else e=@element; (while e.parentNode then e = e.parentNode); @wrap e
		else -> if @element.ownerDocument then @htm() else e=@element; (while e.parentNode then e = e.parentNode); @wrap e
	body: -> @wrap(@document().body) || (htm=@htm()).byTag('body') || htm
	head: -> @wrap(@document().head) || (htm=@htm()).byTag('head') || htm
	viewport: if CNavigator.chrome then @::body else @::htm #-> @wrap if (d=@document()).compatMode=="CSS1Compat" then d.documentElement else d.body

	
	type$.any 'document window htm body head'
	
	# методы изменения строки url браузера
	# http://habrahabr.ru/post/123106/
	if his$=history.pushState
		pushState$ = (w, data, title, url) -> w.history.pushState null, title, url
		replaceState$ = (w, data, title, url) -> w.history.replaceState null, title, url
		gotoState$ = (w, n) -> w.history.go n
	else
		pushState$ = (w, data, title, url) -> w.location.hash = "#"+url
		replaceState$ = pushState$
		gotoState$ = (w, n) -> w.location.hash = "#"+w.history$[w.history_pos$+=n][0]
		
	init_his$ = (w) -> w.history$ = [[w.location.href, w.document.title, null]]; w.history_pos$ = 0 ; w.history_before$ = w.history.length - 1
	
	navigate: (args...) ->
		init_his$ w unless (w=@window()).history$
		if arguments.length
			if args[0] instanceof Array then return w.history$[w.history_pos$+args[0][0]]
			if typeof args[0] == 'number' then n = args.shift()
			[url, title, data] = args
			title = w.document.title unless title?
			w.document.title = title
			unless n?
				pushState$ w, null, title, url
				args[0] = w.location.href
				(w.history$ = w.history$.slice w.history_pos$++)[w.history_pos$] = args
			else if n == 0 then replaceState$ w, null, title, url; args[0] = w.location.href; w.history$[w.history_pos$] = args
			else if (t=w.history$[w.history_pos$+=n])? then w.document.title = t[1]; gotoState$ w, n
			else throw @raise "Переход по истории на несуществующий элемент"
			
			if w.history_before$ + w.history$.length > w.history.length then w.history_before$ = w.history.length - w.history$.length
			
			this
		else w.history$[w.history_pos$]
	
	history: (n) ->
		init_his$ w unless (w=@window()).history$
		if arguments.length == 0 then w.history$[w.history_pos$]
		else if typeof n == 'number' then w.history$[w.history_pos$+n]
		else if n == on then w.history_pos$
		else if n == off then w.history$.length
		else 
			i = j = w.history_pos$
			h = w.history$
			len = h.length
			while i>=0 or j<len
				if --i>=0 and h[i][0] == n then return i
				if ++j<len and h[j][0] == n then return j
			return null
	
	history_change: (data) ->
		init_his$ w unless (w=@window()).history$
		
		real = w.history.length
		len = w.history$.length + w.history_before$
		
		if len == real - 1 then w.history$.push [w.location.href, w.document.title, data]
		else if len == real
			if null == n = @history w.location.href then w.history$.unshift [w.location.href, w.document.title, data]
			w.history_pos$ = n
		else
			w.history_pos$ = len - real
			
		#say 'end', w.history$.length
		this

	# методы работы с cookie
	cookie: (name, value, props) ->
		if arguments.length>1
			props = {} unless props
			props.path = '/' unless 'path' in props
			props.expires = -1 unless value?	# удаляем
			
			if typeof (exp = props.expires) == "number" && exp then d = new Date(); d.setTime(d.getTime() + exp*1000); exp = props.expires = d
			if exp and exp.toUTCString then props.expires = exp.toUTCString()
			
			cookie = name + "=" + encodeURIComponent value
			for name, val of props
				cookie += "; " + name + if val is on then '' else "=" + val
			@document().cookie = cookie
			this
		else
			@document().cookie.match( new RegExp("(?:^|; )" + name.replace(/// ([\.$?*|{}\(\)\[\]\\\/\+^]) ///g, '\\$1') + "=([^;]*)") )?[1]
		
	cookdef: (name, def) -> if typeof name == 'string' then (if (x=cookie(name))? then x else def) else y={}; (for i of name then y[i] = (if (x=cookie(i))? then x else name[i])); y


	# методы установки обработчиков
	send: (type, args...) ->
		return unless type?
		if typeof type == 'function' then return type.apply this, args
		if @_sendQueue and q = @_sendQueue[type]
			for w in q then w.apply this, args
		@[type]? args...
		
	on: (type, listen, phase) ->
		@_sendQueue ||= {}
		for type in $A type 
			if /^[a-z0-9]+$/.test type then @setHandler type
			q = @_sendQueue['on'+type] ||= []
			if phase then q.unshift listen else q.push listen
		this
	one: (type, listen, phase) ->
		for type in $A type
			@on type, (do(type, listen, phase)->-> @off type, arguments.callee, phase; listen.apply this, arguments), phase
		this

	rmEventAndHandler$ = (type) -> delete @_sendQueue[t='on'+type]; if not t of this and /^[a-z]+$/.test type then @removeHandler type
	rmEvent$ = (type) -> delete @_sendQueue['on'+type]
	rmHandler$ = rmEventAndHandler$
	
	rmEvt$ = (type, listen, phase) ->
		phase ||= -1
		for type in $A type when ons = @_sendQueue['on'+type]
			for fn, i in ons by phase when $0$ == listen then ons.splice i, 1 ; break
			if ons.length == 0 then rmHandler$.call this, type
		this
	code$ = null
	eval rmEvt$.code 'rmEvtByListen$', 'fn'; rmEvtByListen$ = code$
	eval rmEvt$.code 'rmEvtByListen$', 'fn._belong'; rmEvtByBelong$ = code$
	
	off: (type, listen) ->
		unless listen?
			for type in $A type then rmHandler$.call this, type
		else if typeof listen != 'function' then rmEvtByBelong$.apply this, arguments
		else rmEvtByListen$.apply this, arguments
		this
	
	clean: ->
		return unless @_sendQueue
		for type, events of @_sendQueue
			type = type.replace /^on/, ''
			ws = (for event in events when not document.contains (w = event._belong).element then [type, w])
			for [type, w] in ws then @off type, w
		this
	
	# export_handlers = {'name-name-name': types}
	defineHandlers: ->
		handlers = {}
		listens = {}
		selfHandlers = []
		for key of this when match = key.match /^(?:(.+)_)?on([a-z0-9]+)(?:_([a-z0-9]+))?$/i
			[a, names, type, who] = match
			if names and who then throw @raise "Устанавливать listens на элементы нельзя"
			if who then listens[key] = [who, type]
			else unless names
				if type!='e' and /^[a-z]+$/.test type then selfHandlers.push type
			else
				h = handlers
				for name in names = names.split /__/
					unless x=h[name] then h[name] = x = {}
					h = x
				unless h = x["@"] then h = x["@"] = {}
				h[type] = key
		extend @constructor, handlers: handlers, listens: listens, selfHandlers: selfHandlers
		this
		
	# http://forum.vingrad.ru/forum/topic-32350.html
	setHandlers: -> (if @constructor.selfHandlers.length then @setHandler @constructor.selfHandlers...); this
	setHandler: -> (if arguments.length == 0 then throw @raise "укажите хоть один аргумент для setHandler"); (for type in arguments then CSend.setHandler @element, type); this
	removeHandler: -> (for type in arguments then CSend.removeHandler @element, type); this
	
	setHandlersOnElements: (list) ->
		path = []
		p = this
		while p and (p instanceof CListWidget or p.element.id) and h = p.constructor.handlers
			for name, i in path when not h = h[name] then break
			if i==path.length then for name of h when a=h[name]["@"]
				widget = if name == 'frame' then list || @child() else @byName name
				for type of a
					main_type = a[type]
					listener = do(p, main_type)-> (args...)-> p[main_type] args..., this
					listener._belong = p
					widget.on type, listener
			path.unshift if /^\d+$/.test name = @name() then 'frame' else name
			p = p.form()
		this		

	readyRun$ = 0
	ready$: ready$ = (e) -> (if readyRun$ < 2 then readyRun$ = 2 ; (w=$(window)).send 'onReadyDom'; w.off 'load ReadyDom', ready$); this
	
	listens$ =
		onready_dom: (listener) ->
			if readyRun$ == 2 then #listener()
			else 
				$(window).on 'ReadyDom', listener
				if readyRun$ == 0
					readyRun$ = 1
					if document.addEventListener then document.addEventListener "DOMContentLoaded", ready$, false
					else @wrap("<script defer>\nCWidget.prototype.ready$()\n</script>").appendTo @body()
					$(window).on 'load', ready$
			this
	
	setListens: ->
		self = this
		for key, [who, type] of @constructor.listens
			listener = do(self, key)-> (args...)-> self[key] args...
			listener._belong = this
			if fn = listens$[key] then fn.call this, listener
			else if typeof @[who] != 'function' then @[who].on type, listener
			else @wrap(@[who]()).on type, listener
		this

	_default_assign: 'text'
	_default_update: undefined
	assign: (key, type, update) ->
		model = @model
		[type, attr...] = $A type
		model.set key, @[type] attr... unless model.has key
		if update then @on update, do(key, type, attr)-> -> @model.change key, @[type] attr...
		model.on key, fn = do(type, attr) => (val) => @[type] attr..., val
		fn._belong = this
	setModel: ->
		if attr = @attr 'model'
			for ass in $A attr, /;\s*/
				ass = $A ass, /:/
				@assign ass[0], ass[1] || @_default_assign, ass[2] || @_default_update
		this
	setModelOnElements: (elem=@_elements) -> (for e in elem then @byName(e).setModel()); this
	
	observe: (methods, before, after, phase) ->
		for method in $A methods
			After = method.ucFirst()
			onBefore = "on" + Before = "Before"+After
			onAfter = "on" + After
			unless '_observe' of @[method]
				@[method] = fn = do(method, onBefore, onAfter)-> (args...)-> @send onBefore, args...; ret = @constructor::[method].apply this, args; @send onAfter, ret, args...; ret
				fn._observe = 1
			if before then @on Before, before, phase
			if after then @on After, after, phase
		this
	shut: (methods, observe) ->
		rmHandler$ = rmEvent$
		for method in $A methods when @[method]._observe
			After = method.ucFirst()
			onBefore = "on" + Before = "Before"+After
			onAfter = "on" + After
			@off Before, observe
			@off After, observe
			unless onBefore of @_sendQueue and onAfter of @_sendQueue then delete @[method]
		rmHandler$ = rmEventAndHandler$
		this
	
	listen: (type, fn, phase) -> @element.addEventListener type, fn, phase || off ; this
	drop: (type, fn, phase) -> @element.removeEventListener type, fn, phase || off ; this

	# https://github.com/eduardolundgren/jquery-simulate/blob/master/jquery.simulate.js - симулятор
	# https://developer.mozilla.org/en-US/docs/Web/API/Event?redirectlocale=en-US&redirectslug=DOM%2Fevent
	# http://www.w3.org/TR/DOM-Level-3-Events/#event-types-list
	# http://www.w3.org/TR/2009/WD-DOM-Level-3-Events-20090908/ - предыдущая спецификация
	# http://html5blog.ru/manual/ - по html5 события
	
	fire_mouse$ = bubbles: true, cancelable: true, view: null, detail: 0, screenX: 0, screenY: 0, clientX: 0, clientY: 0, ctrlKey: false, altKey: false, shiftKey: false, metaKey: false, button: 0, relatedTarget: null
	fire_key$ = bubbles: true, cancelable: true, view: null, ctrlKey: false, altKey: false, shiftKey: false, metaKey: false, keyCode: 0, charCode: 0
	fire_html$ = bubbles: false, cancelable: true
	
	fire: (type, e = {}) ->
		if /^mouse(over|out|down|up|move)|(dbl)?click$/.test type
			evt = document.createEvent "MouseEvents"
			extend_uniq e, cancelable: type != "mousemove", relatedTarget: @htm().element, view: @window(), fire_mouse$
			evt.initMouseEvent type, e.bubbles, e.cancelable, e.view, e.detail, e.screenX, e.screenY, e.clientX, e.clientY, e.ctrlKey, e.altKey, e.shiftKey, e.metaKey, e.button, e.relatedTarget
		else if /^key(up|down|press)$/.test type
			extend_uniq e, view: @window(), fire_key$
			try
				evt = document.createEvent "KeyEvents"
				evt.initKeyEvent type, e.bubbles, e.cancelable, e.view, e.ctrlKey, e.altKey, e.shiftKey, e.metaKey, e.keyCode, e.charCode
			catch err
				evt = document.createEvent "Events"
				evt.initEvent type, e.bubbles, e.cancelable
				delete e.bubbles
				delete e.cancelable
				extend evt, e
			if CNavigator.ie or CNavigator.opera
				evt.keyCode = if e.charCode > 0 then e.charCode else e.keyCode
				evt.charCode = undefined
		else
			extend_uniq e, fire_html$
			evt = document.createEvent "HTMLEvents"
			evt.initEvent type, e.bubbles, e.cancelable
		@element.dispatchEvent evt
		this
	extend @::fire,
		fire_mouse$: fire_mouse$
		fire_key$: fire_key$
		fire_html$: fire_html$
	
	attach: (name) -> this["$"+name] = w = @byName name; (if !(x=this[name]) or x instanceof CWidget then this[name] = w); @_elements.push name 
	detach: (name) -> (if typeof name != 'string' then x=name; name = name.name()); (if (x?=this[name]) instanceof CWidget then delete this[name]); x?.form null ; (if -1 != idx=(e=@_elements).indexOf name then e.splice idx, 1); delete this["$"+name]; this

	getElements: ->
		id = @element.id
		regexp = new RegExp '^'+id+'-(\\w+)$'
		for element in @root().find("[id^="+id+"-]")._all when match = element.id.match(regexp) then match[1]
	attachElements: ->
		unless @_elements then @_elements = []
		elem = if arguments.length then Array::slice.call arguments else @getElements()
		for name in elem then @attach name
		this	

	type$.all 'defineHandlers setHandler setHandlers setHandlersOnElements setListens setModel setModelOnElements observe fire listen drop attach detach attachElements on off'
		
	# методы поиска элементов
	byName: (name) ->
		widget = @byId id = @element.id+'-'+name, this
		unless widget
			if (root=@root()) == @htm() then throw @raise "byName к неизвестному name="+name
			unless widget = root.first "[id=#{id}]", this then throw @raise "byName('"+name+"') - "+this+" не вставлен в документ. Его id недоступны"
		if this != p=widget.form() then throw @raise "У элемента `"+id+"`"+widget+" указан неверный form `"+p+'`'
		widget

	unless qs$ = document.querySelector && IE!=8 then CInit.require "lib/nwmatcher-1.2.5"
	# https://github.com/jquery/sizzle/wiki/Sizzle-Documentation
	
	byXYAll$ = (x, y) ->
		k = -1000
		self = widget = @$0$ x, y
		c=[]; e=[]
		while widget
			e.push z=widget.element
			c.push [z.style.zIndex, z.style.position]
			widget.css 'z-index': k--, position: 'relative'
			widget = @$0$ x, y
			break if self==widget
		for z, i in c then e[i].widget.css 'z-index': z[0], position: z[1]
		new CWidgets e
		
	byXY: (x, y) ->
		vl=@viewLeft(); vt=@viewTop()
		@wrap if not(vl <= x <= @viewRight()) or not(vt <= y <= @viewBottom())
			v=@viewport(); vx = v.vscroll(); vy = v.hscroll()
			x -= vl; y -= vt
			@window().scrollTo x, y
			x += vx - v.vscroll(); y += vy - v.hscroll()
			e = @document().elementFromPoint x, y
			v.vscroll vx; v.hscroll vy
			e
		else
			@document().elementFromPoint x - vl, y - vt
	byViewXY: (x, y) -> @byXY x + @viewLeft(), y + @viewTop()
	#byXYAll$ = (x, y) -> (new CWidgets (while m = @$0$ x, y then m.novid())).vid()
	byXYAll: byXYAll$.inline 'byXYAll', 'byXY'
	byViewXYAll: byXYAll$.inline 'byViewXYAll', 'byViewXY'
	
	byId: (id) ->
		if e=(d=@document()).getElementById id then @createWidget e
		else if d.contains @element then null
		else if id == (root=@root()).element.id then root
		else root.first "[id=#{id}]"
	byTag: if tn$=(document.getElementsByTagName && IE!=5) then (name) -> @wrap @element.getElementsByTagName(name)[0] else (name) -> @wrap NW.Dom.byTag(name, @element)[0]
	byTagAll: if tn$ then (name) -> new CWidgets @element.getElementsByTagName(name) else (name) -> new CWidgets NW.Dom.byTag name, @element
	byClass: if cn$=document.getElementsByClassName then (classes) -> @wrap @element.getElementsByClassName(classes)[0] else (classes) -> @wrap NW.Dom.byClass(classes, @element)[0]
	byClassAll: if cn$ then (classes) -> new CWidgets @element.getElementsByClassName(classes) else (classes) -> new CWidgets NW.Dom.byClass(classes, @element)
		
	first: if qs$ then ((query) -> if query then @wrap @element.querySelector query else @child 0) else (query) -> if query then @wrap NW.Dom.first query, @element else @child 0
	find: if qs$ then (query) -> new CWidgets @element.querySelectorAll query else (query) -> new CWidgets NW.Dom.select query, @element
	last: (query) -> if query then @find(query).item -1 else @child -1
	
	matchesSelector$ = div$.matchesSelector || div$.webkitMatchesSelector || div$.mozMatchesSelector || div$.msMatchesSelector || div$.oMatchesSelector
	
	match: if matchesSelector$ then (query) -> matchesSelector$.call(@element, query) else (query) -> NW.Dom.match(@element, query)
	
	type$.range 'byId byName byTag byClass first last'
	type$.rangeAll 'byTagAll byClassAll find'
	
	# методы коллекции
	all: -> [@element]
	length: 1
	empty: -> off
	item: (n) -> if n == 0 || n == -1 then this
	items: -> [this]
	each: (fn) -> fn.call this, 0, this
	invoke: (name, args...) -> this[name]? args...; this
	map: (name, args...) -> [(if typeof name == 'function' then name.apply this, args else this[name]? args...)]
	reduce: (op, name, args...) -> 
		if typeof op!='function' then a=null; eval "a=function(a, b) { return a "+op+" b }"
		if ls = @exists(name).map name, args... then [a, any...] = ls; (for b in any then a = op a, b);	a
	result: (name, args...) -> this[name]? args...
	grep: (name, args...) -> if (if typeof name == 'function' then name.apply this, args else this[name]? args...) then this else new CWidgets []
	exists: (name) -> if name of this then this else new CWidgets []
	filter: (query) -> if @match query then this else new CWidgets []
	union: (u...) -> x = []; x.splice x.length, 0, @all()...; (for i in u then x.splice x.length, 0, i.all()...); new CWidgets x
	queryIndex: (query, k=0) -> if (k==0 or k==-1) and @match query then this else null
	
	sliceW$ = (from, all) ->
		i = k = 0
		if from instanceof Array then i = from[1] || 0 ; (unless (k = from[2])? then k = (if from.length == 1 then 1 else 0)); from = from[0]
		if from instanceof CWidget then from = from.element
		if typeof from == 'object' then from = all.indexOf from, i; (if from == -1 then from=null)
		else if typeof from == 'string' then from = @queryIndex from, i
		if from? then from += k
		from

	slice: (from, to) ->
		all = @_all || [@element]
		new CWidgets _slice$.call all, sliceW$.call(this, from, all), sliceW$.call(this, to, all)
		
	type$.nothing 'all empty length item items invoke map reduce result grep exists filter union slice queryIndex'

	# методы клонирования элемента
	clone: (id, form, cls) ->
		element = @element.cloneNode true
		element.widget = null

		tmp = wdiv$.element
		wdiv$.element = element
		for e in (es = wdiv$.byTagAll("*").all()) when e.widget then e.widget=null
		wdiv$.element = tmp
		
		if id
			element.id = id
			regexp=new RegExp '^'+@id()+'-'
			replace=id+"-"
			for e in es when id and e.id then e.id=e.id.replace regexp, replace
			
		new (if cls then (if typeof cls == 'string' then window[cls] else cls) else @constructor)(element, form)


	clonehtml: (id, form, cls) ->
		id ||= CMath.uniqid()
		html=@outer().replace new RegExp('\\b([Ii][Dd]=[\'"]?)'+@id()+'([\\s>\'"-])', 'g'), '$1'+id+'$2'
		if form || cls then html=html.replace new RegExp('\\b([Ii][Dd]=[\'"]?'+id+'[\\s>\'"])'), '$1'+(if form then ' cform='+form.id() else '')+(if cls then ' ctype='+(if cls instanceof Function then cls.getName() else cls) else '')
	
	type$.all 'clone'
	
	# методы атрибутов и содержимого
	id: (id) -> if arguments.length then (if id==null then @attr "id", null else @element.id = id); this else @element.id
	name: (name) -> if arguments.length then @id @element.id.replace(/-\w+$/, '')+'-'+name; this else (match = @element.id.match /-(\w+)$/) and match[1]
	number: (n) -> if arguments.length then @id @element.id.replace(/\d+$/, '')+n; this else (match = @element.id.match /(\d+)$/) and match[1]
	tag: (name) -> if arguments.length then @outer @outer().replace /^<\w+/, '<'+name else @element.tagName

	text:
		if div$.innerText? then (val) ->
			if arguments.length then @element.innerText = val; this else @element.innerText
		else (val) ->
			if arguments.length then @element.textContent = val; this else @element.textContent
	html: (val) -> if arguments.length then @element.innerHTML = val; this else @element.innerHTML
	htmlscript: (val) ->
		@element.innerHTML = val
		@runscript()
		this
	runscript: ->
		win = @window()
		for script in @find("script").all() then win.eval script.innerHTML
		this
	val: @::text
	val$f: -> parseFloat @val()
	val$i: (base=10) -> parseInt @val(), base
	inc: (i=1) -> @val @val$f()+i; this
	dec: (i=1) -> @inc -i
	content: (content) -> if arguments.length then @down().free(); @append content else new CWidgets @element.childNodes
	normalize: -> @element.normalize(); this
	update: (val, request) ->
		if off != @send 'onBeforeUpdate', val	
			if request?.request and ///^text/html\b///i.test request.request.getResponseHeader "Content-Type"
				@htmlscript val.replace ///[\s\S]*?<body[^<>]*>([\s\S]*?)</body\s*>[\s\S]*///i, "$1"
			else @val val
			@send 'onUpdate', val
		this

	outer: (val) ->
		if arguments.length
			focus=@hasFocus()
			if (type=typeof val) == "string" or type == "number"
				val = text2elem$ val
				if val.childNodes.length!=1 then throw @raise "html содержит несколько нод"
				val = val.firstChild
			if val instanceof CWidget then val = val.element || (if val._all.length != 1 then throw @raise "невозможно заменить одну ноду на несколько" else val._all[0])
			e=@element
			if p=e.parentNode then p.insertBefore val, e; p.removeChild e
			val.widget?.element = null
			e.widget = null
			val.widget = this
			@element = val
			if focus then @focus()
			this
		else (div = document.createElement 'div').appendChild @element.cloneNode true ; div.innerHTML

	append_anim$ = (method, val, timeout, listen) ->
		its = []
		if typeof timeout == 'function' then listen = timeout; timeout = 'norm'
		for i in items=val.items()	# i - путешественник, i1 - убывающий, i2 - прибывающий
			x = i.css ['float', 'position', 'display', 'margin']
			i.before i1=@wrap("<div></div>").css(visibility: 'hidden', display: 'none')
			its.push [x, i1, i.pos()]
		this[method] val
		for i, k in items then its[k][3] = i.pos()
		counter = items.length
		for i, k in items
			[x, i1, s1, s2] = its[k]
			i.before i2=@wrap("<div></div>").css visibility: 'hidden', width: 0, height: 0
			save = i.saveCss ['position', 'margin', 'left', 'top']
			{left, top} = i.css(position: 'absolute', margin: 0, left: 0, top: 0).pos()
			i.css(left: s1.left - left, top: s1.top - top).animate left: s2.left - left, top: s2.top - top, timeout, do(i1, i2, i, save, listen) => => i.css save; i1.union(i2).free(); if listen and --counter == 0 then @send listen
			i1.css(x).css(width: s1.width, height: s1.height).css(x).animate width: 0, height: 0, timeout
			i2.animate width: s2.width, height: s2.height, timeout

	insert$ = (val, timeout, listen) ->
		val = @wrap val
		if timeout? then append_anim$.call this, $0$, val, timeout, listen
		else p=(e=@element).parentNode; a = val.all(); (if p then $1$; (for v in a then p.insertBefore v, e) else (for v in a when p=v.parentNode then p.removeChild v))
		this

	before: insert$.inline "before", "'before'", ""
	after: insert$.inline "after", "'after'", "e=e.nextSibling"
	insertBefore: (val, args...) -> @wrap(val).before this, args...; this
	insertAfter: (val, args...) -> @wrap(val).after this, args...; this
	append: (val, timeout, listen) ->
		val = @wrap val
		if timeout? then append_anim$.call this, 'append', val, timeout, listen
		else e=@element; (for v in val.all() then e.appendChild v)
		this
	appendTo: (val, args...) -> @wrap(val).append this, args...; this
	appendRet: (val, args...) -> @append val = @wrap val, args...; val
	prepend: (val, timeout, listen) ->
		val = @wrap val
		if timeout? then append_anim$.call this, 'prepend', val, timeout, listen
		else f=(e=@element).firstChild; (for v in val.all() then e.insertBefore v, f)
		this
	prependTo: (val, args...) -> @wrap(val).prepend this, args...; this
	prependRet: (val, args...) -> @prepend val = @wrap val, args...; val
	wrapIn: (val) -> @before val=@wrap val; (while r=val.child 0 then val=r); val.content this
	wrapInAll: @::wrapIn.inline('wrapInAll')
	swap_arr$ = ['prevnode', 'nextnode', 'up']
	swap_append$ = prevnode: 'after', nextnode: 'before', up: 'append'
	swap: (val, timeout, listen) ->
		if @nextnode() == val=@wrap val then @before val, timeout, listen
		else if @prevnode() == val then @after val, timeout, listen
		else
			counter = 0
			fn = if timeout? then do(listen)->-> if listen and --counter == 0 then @send listen
			ex = [this, val]; em = [val, this]
			er = for k, j in ex then p = null ; (for i in swap_arr$ when p=k[i]() then break); [k, em[j], i, p]
			for k in ex when k.up() then counter++; k.free timeout, fn
			for [k, m, i, p] in er when p then (if m.contains p then counter++; ch=m.down(); m.append k.down(), timeout, fn; k.content ch); counter++; p[swap_append$[i]] m, timeout, fn
		this
	

	nes$ = 'nextElementSibling' of div$
	nextElem = (e, x) -> e = e[x]; (while e and e.nodeType!=1 then e=e[x]); e
	dir = -> e=@element; r=[]; (while e=$0$ then r.push e); new CWidgets r
	dirprev = -> new CWidgets if e=(r=@element).parentNode then e=e.firstChild; x=[]; (while e != r then $0$; e = e.nextSibling); x else []
	
	floor: -> @wrap @element.offsetParent
	upper: -> @wrap nextElem @element, "parentNode"
	next: if nes$ then -> @wrap @element.nextElementSibling else -> @wrap nextElem @element, 'nextSibling'
	prev: if nes$ then -> @wrap @element.previousElementSibling else -> @wrap nextElem @element, 'previousSibling'
	up: -> @wrap @element.parentNode
	prevnode: -> @wrap @element.previousSibling
	nextnode: -> @wrap @element.nextSibling
	code$ = null
	floorAll: dir.inline 'floorAll', 'e.offsetParent'
	upperAll: eval dir.code 'upperAll', 'nextElem(e, "parentNode")'; code$
	nextAll: if nes$ then dir.inline 'nextAll', 'e.nextElementSibling' else eval dir.code 'nextAll', 'nextElem(e, "nextSibling")'; code$
	prevAll: dirprev.inline 'prevAll', 'if(e.nodeType==1) x.push(e)'
	upAll: dir.inline 'upAll', 'e.parentNode'
	nextnodeAll: dir.inline 'nextnodeAll', 'e.nextSibling'
	prevnodeAll: dirprev.inline 'prevnodeAll', 'x.push(e)'
	
	siblings: -> @prevAll().union @nextAll()
	siblingnodes: -> @prevnodeAll().union @nextnodeAll()
	level: (args...) -> @up().child args...
	nodes: (args...) -> @up().down args...

	child:
		if nes$ then (i) -> (if arguments.length then @wrap @element.children[if i<0 then @element.children.length+i else i] else new CWidgets @element.children)
		else (i) ->
			if arguments.length
				e = @element
				e = if i<0 then i=-i; k = 1; p='previousSibling'; e.lastChild else k = 0; p='nextSibling'; e.firstChild
				while e
					if e.nodeType==1 and k++ == i then return @wrap e
					else e = e[p]
				null
			else e=@element.firstChild; new CWidgets [while r=e when r.nodeType==1 then e=e.nextSibling; r]
	down: (i) -> if arguments.length then @wrap @element.childNodes[if i<0 then @element.childNodes.length+i else i] else new CWidgets @element.childNodes
	
	remove: -> @send 'onDestroy', 'remove'; e = @element; @unwrap(); e.parentNode.removeChild e; new CWidgets []
	free: (timeout, listen) -> (if timeout? then @hide timeout, do(listen)->-> @free(); @send listen else @element.parentNode?.removeChild @element); this
	
	focus: -> @element.focus(); this
	hasFocus: -> @document().activeElement == @element
	contains: (w) -> a=w.all(); (return off unless a.length); (for e in a when not @element.contains e then return off); on
	
	type$.range 'floor upper prev next up prevnode nextnode child down wrapIn'
	type$.rangeAll 'floorAll upperAll nextAll prevAll upAll nextnodeAll prevnodeAll siblings'
	type$.all 'inc dec content update insertAfter insertBefore appendTo prependTo swap remove free'
	type$.attr 'tag number val'
	type$.join 'outer html text'
	type$.nothing 'wrapInAll'
	
	# методы таблиц и колонок
	tab: (i, j, html) ->
		if @tag() == "TABLE" then tbody = (@byTag("tbody") || @wrap("<tbody></tbody>").appendTo this); return tbody.tab.apply tbody, arguments
		
		if 0 == len = arguments.length then max = 0 ; (for tr in (rows=@child()).items() when max < len=tr.child().length then max = len); return [rows.length, max]
		
		o = i:0, j:0, set: null
		if len == 1
			if 'number' == typeof i then o.i = i; o.row = 0 else if i instanceof Array then o.set = i else o = i
		else if len == 2
			o.i = i
			if 'number' == typeof j then o.j = j; o.col=o.row=0 else if j instanceof Array then o.col=0 ; o.set = ([k] for k in j) else extend o, j
		else
			o.i = i; o.j = j
			unless i? then o.i = 0 ; @child().child(j).content ""; o.set = ([k] for k in html) else if html instanceof Array then o.set = html else if html instanceof Object then extend o, html else o.set = [[ html ]]

		if o.cells then o.set = o.cells; cells = 1

		row = o.row; col = o.col
		if len == 1 and row > 0 and col > 0 and not o.set? then cell=o.cell || ""; extend o, ret: 1, i: 0, j: 0, set: (for i in [0...row] then for j in [0...col] then cell)
		
		if o.set?
			if len == 1 then @content ""
			else if len == 2 then @child(i).child().content ""

			i = o.i || 0 ; j = o.j || 0 ; set = o.set; to_i = i + set.length
			trs = @child()
			isTab = /^(TBODY|THEAD|TFOOT)$/.test @tag()
			tr_wrap = @_TR_wrap || (if isTab then '<tr></tr>' else '<div></div>')
			td_wrap = @_TD_wrap || (if isTab then '<td></td>' else '<span></span>')
			if (len=trs.length) < to_i then (for f in [len...to_i] then @append tr_wrap); trs = @child()
			
			for tr, k in trs.slice(i, to_i).items()
				tds = tr.child()
				to_j = j + set[k].length
				if (len=tds.length) < to_j then (for f in [len...to_j] then tr.append td_wrap); tds = tr.child()
				for td, n in tds.slice(j, to_j).items()
					if cells then td.before(set[k][n]).free() else td.content set[k][n]
			return this unless o.ret
			
		if row == 0 and col == 0 then @child(i)?.child(j)	# ячейка
		else if row==0 then row=@child().items(); new CWidgets (for x, k in row when x=x.child j then x.element) 	# столбец
		else if col==0 then @child(i).child()		# строка
		else rows = @child().slice(i, row).items(); (rows[k] = x.child().slice(j, col).items() for x, k in rows); rows
	
	tab = -> if (x=@tab.apply this, arguments) instanceof Array then (if x[0] instanceof Array then (for i in x then for j, n in i then i[n] = (if j then j.$0$() else $1$)) else (for i, k in x then (x[k]=if i then i.$0$() else $1$)); x) else (if x then x.$0$() else $1$)
	tab$: tab.inline 'tab$', 'html', '""'
	tab$i: tab.inline 'tab$i', 'val$i', '0'
	tab$f: tab.inline 'tab$f', 'val$f', '0'
	
		
	# методы колонок ...
	
	
	# методы стилей (правила css)
	# http://www.quirksmode.org/dom/w3c_css.html
	# http://www.quirksmode.org/dom/tests/stylesheets.html

	styles$ = false
	style$ = null
	stylesheets$ = 0
	stylesheet$ = null
	
	set_styles$ = ->
		stylesheets$ = 0
		styles$ = []
		style$ = {}
		j = 0
		stylesheets = Array::slice.call @document().styleSheets
		stylesheets$ = stylesheets.length
		while stylesheets.length
			sheet = stylesheets.pop()
			for rule, i in sheet.cssRules
				if s=rule.styleSheet then stylesheets.push s else rule.idx$ = j++; rule.indexInSheet$ = i; styles$.push rule; (if r=style$[t=rule.selectorText] then r.push rule else style$[t.toLowerCase()] = [rule])
		this
	
	rawstyle = -> for rule in styles$ when @match rule.selectorText then rule
	rawstyle_mask_re = (mask) -> for rule in styles$ when rule.selectorText.search(mask) != -1 then rule 
	
	rawstyle: (selector, val, before) ->
		set_styles$.call this unless styles$ and stylesheets$ == @document().styleSheets.length
		if (len=arguments.length) == 0 then rawstyle.call this
		else if len > 1
			if typeof val == 'object' then val = (for k, v of val then k+": "+v).join ";"
			val = selector + " {" + val + "}"
			idx = null
			sheet = if before then (if before.cssRules then	before else idx=before.indexInSheet$; before.parentStyleSheet)
			else unless stylesheet$ then @wrap("<style></style>").appendTo @head(); stylesheets$++; stylesheet$ = (s=@document().styleSheets)[s.length-1]
			else stylesheet$
			sheet.insertRule val, if idx? then idx else if len=sheet.cssRules.length then len-1 else 0
			set_styles$.call this
		else
			if selector == 0 then set_styles$.call this
			else if typeof selector == 'string' then style$[selector.toLowerCase()] || []
			else if selector instanceof RegExp then rawstyle_mask_re.call this, selector
			else selector.parentStyleSheet.deleteRule selector.indexInSheet$; set_styles$.call this

	new_pseudo_element$ = (w, pseudoElement) -> (fn=->); fn.prototype = w.constructor.prototype; o = new fn; extend o, w; o._pseudoElement = pseudoElement; o
	ex_uniq$ = (a) -> x={}; z=0 ; (for i in a when not((t=i.selectorText) of x) then x[t] = z++); r=[]; (r[x[k]]=k for k of x); r
	goal_selector$ = -> (@id id=CMath.uniqid() unless id=@id()); "#"+id
	goal_rule$ = (pseudoElement) -> rules = @rawstyle selector = goal_selector$.call(this)+(pseudoElement || ''); (unless rules.length then @rawstyle selector, {}; rules = @rawstyle selector); rules

	pseudo: (pseudoElement) -> rules = goal_rule$.call this, pseudoElement; new_pseudo_element$ this, rules[0]

	style: (selector, name, val, important) ->
		if 0 == len = arguments.length then return ex_uniq$ @rawstyle()
		if len == 1 then name = selector; selector = goal_selector$.call this
		
		rules = @rawstyle selector
		
		unless rules.length
			if len == 2 and not(typeof name == 'object') or name instanceof Array then return null
			if name == null then return this
			@rawstyle selector, {}
			rules = @rawstyle selector
		
		ex_style$ = new_pseudo_element$ this, rules[0]
		
		if name == null then (for rule in rules then @rawstyle rule)
		else if name instanceof Array then return ex_style$.css name
		else if name instanceof Object then ex_style$.css name, val
		else if len == 2 then return ex_style$.getCss name
		else ex_style$.setCss name, val, important
		this
		
	rule: (selector, styles) ->
		s = @rawstyle selector
		if arguments.length==2 then @rawstyle selector, styles, s[0]; (for r in s then @rawstyle r); this
		else
			res = {}
			for r in s
				ex_style$ = new_pseudo_element$ this, r
				r = r.cssText.replace(/// /\* .*? \*/ ///g, ' ').replace /// ^[^\{\}]+ \{ (.*) \} $ ///, "$1"
				for i in r.split /;/ when m = i.match ///^\s* ([^:]+?) \s*: ///
					name = m[1].replace ///^(?:webkit|moz|khtml|ms|O|Apple|icab|epub|wap|Xv|Prince|ro)-///i, ''
					res[name] = ex_style$.getCss name
			res
		
	
	# методы стилей (свойства css)
	isCase$ = typeof div$.style['background-color'] == 'string'
	vendor$ = CNavigator.vendor
	real_vendor$ = CNavigator.cssvendor
	with_vendor_prefix = {}
	css_good = {float: "cssFloat"}
	css_bad = {}
	css_px = {}
	css_color = {}
	css_not_px = {}
	css_fn =
		vscroll: (key, val) -> if arguments.length > 1 then @vscroll val else @vscroll()+"px"
		hscroll: (key, val) -> if arguments.length > 1 then @hscroll val else @hscroll()+"px"
	addCss: (prop, fn) -> css_fn[prop] = fn; this
	
	toCssCase = (key) -> 
		unless real = css_good[key]
			unless key of css_bad
				z = key.toCamelCase()
				if 'string' == typeof div$.style[z] then css_good[key] = real = z
				else if 'string' == typeof div$.style[z=real_vendor$+z.ucFirst()]
					css_good[key] = real = z
					with_vendor_prefix[key] = vendor$+key
				else css_bad[key] = 1 ; real = ""
			else real = ""
		real
		
	hasCss: (key, val) ->
		real=toCssCase key
		if arguments.length == 1 then 'string' == typeof div$.style[real]
		else div$.style[real] = ''; div$.style[real] = val; !!div$.style[real]

	toCssStyle: (key, val, important) ->
		pe = @_pseudoElement
		@_pseudoElement = {style: style={}}
		@setCss key, val
		@_pseudoElement = pe
		for real of style then null
		val = (with_vendor_prefix[key] || key) + ": " + style[real]
		if important then val += " !important"
		val
		
	setCss: (key, val, important) ->
		if (fn=css_fn[key]) and off != fn.call this, key, val, important then return this
		return this unless real = toCssCase key
		if typeof val == 'number' 
			if key of css_px then val+='px'
			else if key of css_color then val = CColor.fromNumber val
			else if key of css_not_px then val
			else if @hasCss key, '1px' then val+='px'; css_px[key] = 1
			else if @hasCss key, '#AAAAAA' then val = CColor.fromNumber val; css_color[key] = 1
			else css_not_px[key] = 1
		style = (@_pseudoElement || @element).style
		if important then style.setProperty with_vendor_prefix[key] || key, val, "!important" else style[real] = val
		this
	getCssStyle: (key, pseudoClass) ->
		if @_pseudoElement then @_pseudoElement.style
		else if @document().contains @element then getComputedStyle @element, pseudoClass
		else @element.style
	getCssValue: (key, pseudoClass) ->
		toCssCase key
		@getCssStyle(key, pseudoClass).getPropertyCSSValue with_vendor_prefix[key] || key
	getCss: (key, pseudoClass) ->
		if (fn=css_fn[key]) and off != ret=fn.call this, key, pseudoClass then return ret
		@getCssStyle(key, pseudoClass)[ toCssCase key ]
	saveCss: -> if @_pseudoElement? then @css.apply this, arguments else @_pseudoElement = @element; ret = @css.apply this, arguments; delete @_pseudoElement; ret
		
	css: (name, val, important) ->
		if arguments.length==0
			r={}
			for k in @element.style then r[k] = @getCss k
			r
		else if name instanceof Array
			r={}
			for k in name then r[k] = @getCss k
			r
		else if name instanceof Object
			for k of name then @setCss k, name[k], val
			this
		else if arguments.length >= 2 and val != null
			@setCss name, val, important
		else @getCss name
	extend @::css,
		css_good: css_good
		css_bad: css_bad
		with_vendor_prefix: with_vendor_prefix
		toCssCase: toCssCase
		css_not_px: css_not_px
		css_px: css_px
		css_color: css_color
		css_fn: css_fn
		
	cssRet: (name) -> ret = (if typeof name == 'object' then @css Object.keys(name) else @css name); @css.apply this, arguments; ret
	
	# http://www.js-doc.ru/documentation/dhtml_doc/dhtml10.docs
	
	rgba$ = (color) ->
		if color == '' or color == 'transparent' then [0,0,0,0]
		else if (c=CColor.colors[color.toLowerCase()]) or ///^#[\dA-F]+$///i.test(c=color) then [parseInt(c.slice(1, 3), 16),  parseInt(c.slice(3, 5), 16), parseInt(c.slice(5), 16), 1]
		else if m=color.match /// rgba?\(([^\)]+)\) /// then r=m[1].split /// ,\s+ ///; [parseInt(r[0]), parseInt(r[1]), parseInt(r[2]), if r[3]? then -(-r[3]) else 1]
		else if m=color.match /// hsla?\(([^\)]+)\) /// then r=m[1].split /// %?,\s+ ///; a=(if r[3]? then -(-r[3]) else 1); r=CColor.hslToRgb parseInt(r[0]), parseInt(r[1]), parseInt r[2]; r[3]=a; r
	
	rgba: (color) ->
		if typeof color == 'number' then return CColor.fromNumber color
		if /^[\w-]+$/.test color then color = @getCss color
		new CColor(rgba$(color)...) ? throw @raise "Неизвестный науке цвет: " + color
	
	testpx$ = CRoot.append("<div>&nbsp;</div>").last().css position: 'absolute', top: -10000, width: '10000pt', height: '10px'
	pt$ = testpx$.element.clientWidth / 10000
	testpx$.css 'width', '10000ex'
	ex$ = testpx$.element.clientWidth / 10000 / parseFloat testpx$.css 'font-size'
	testpx$.free()
	
	mm$ = 72 * 2.54 / 100 * pt$
	cm$ = 72 * 2.54 * pt$
	pc$ = 12 * pt$
	in$ = 72 * pt$
	Number$ = ///^(-?(?:\d+|\d*\.\d+)(?:[Ee][+-]?\d+)?)([a-z%]*)$///
	
	px: (val, percent_val) ->
		if typeof val == 'number' then return val
		if val == "" then return 0
		if from = val.match Number$ then val = parseFloat from[1]; (return val unless from = from[2])
		else
			val = @getCss key = val
			if val == '' then return 0
			if val == 'auto' and key of {left:1, top:1, width:1, height:1} then return this[key]()
			if val == 'inherit' then (for i in @upperAll().union(@wrap @window()) when 'inherit' != val = i.getCss(key) then break)
			if Number$.test val then return (if /%$/.test val then @getCssValue(key).getFloatValue 'px' else @px val)
			if (color=rgba$ val)? then return (new CColor color...).toNumber()
			throw @raise "Неизвестная единица `"+val+"` для @px "+key
		
		switch from
			when 'px' then val
			when 'vw' then val * @viewWidth() / 100
			when 'vh' then val * @viewHeight() / 100
			when 'vmin' then Math.max(val * @viewHeight(), val * @viewWidth()) / 100
			when 'pw' then val * @width() / 100
			when 'ph' then val * @height() / 100
			when 'em' then val * @px('font-size')
			when 'rem' then val * @htm().px('font-size')
			when 'ex' then val * ex$ * @px('font-size')
			when 'pt' then val * pt$
			when 'mm' then val * mm$
			when 'cm' then val * cm$
			when 'pc' then val * pc$
			when 'in' then val * in$
			when '%' then val * percent_val / 100
			else throw @raise "Неизвестная единица измерения `"+from+"`"

	vw: (key) -> @px(key) / @viewWidth() * 100
	vh: (key) -> @px(key) / @viewHeight() * 100
	vmin: (key) -> Math.min((px=@px key) / @viewHeight(), px / @viewWidth()) * 100
	pw: (key) -> @px(key) / @width() * 100
	ph: (key) -> @px(key) / @height() * 100
	em: (key) -> @px(key) / @px('font-size')
	rem: (key) -> @px(key) / @htm().px('font-size')
	ex: (key) -> @px(key) / ex$ / @px('font-size')
	pt: (key) -> @px(key) / pt$
	mm: (key) -> @px(key) / mm$
	cm: (key) -> @px(key) / cm$
	pc: (key) -> @px(key) / pc$
	in: (key) -> @px(key) / in$
	
	pxvector: (val, percent_val, ci='px') -> (if /^[a-z]/i.test val then val = @getCss val); for v in val.split /\s+/ then @[ci] v, percent_val
	
	#cssText: (text) -> if arguments.length then @element.style.cssText = text else @element.style.cssText
	
	fly: (widgetTop, widgetBottom) ->
		doc = @wrap document
		doc.off 'scroll', @_fly if @_fly
		@_fly_position = @css 'position'
		if @_fly_position == 'fixed' then @_fly_position = 'absolute'
		@_fly_fixed = null
		doc.on 'scroll', @_fly = do(widgetTop, widgetBottom)=> =>
			if widgetTop and widgetTop.bottom() >= @top() or widgetBottom and widgetBottom.top() >= @bottom()
				@css 'position', @_fly_position
				@_fly_fixed = 0
			else if not @_fly_fixed then @_fly_position = @cssRet 'position', 'fixed'; @_fly_fixed = 1
			this
		@_fly()
	
	toggle$ = (args, s) -> args[if (i=args.indexOf s) != -1 then (i+1) % args.length else 0]
	
	toggle: (name, args) ->	# переключает css-стили
		args = $A args
		unless arguments.length then name = 'display'; args = ['none', '']
		else if args.length == 1 then args.push ''
		@setCss name, toggle$ args, @getCss name
	
	type$.all 'setCss'
	
	# методы атрибутов и свойств
	
	attr: (name, val) -> e=@element; if arguments.length == 2 then (if val? then e.setAttribute name, val else e.removeAttribute name); this else if name instanceof Array then a={}; (a[i]=e.getAttribute i for i in name); a else if name instanceof Object then (for k of name then @attr k,name[k]); this else e.getAttribute name
	prop: (name, val) -> e=@element; if arguments.length == 2 then e[name] = val; this else if name instanceof Array then a={}; (a[i]=e[i] for i in name); a else if name instanceof Object then (for k of name then e[k]=name[k]); this else e[name]
	
	toggleAttr: (name, args...) ->
		unless arguments.length then name = 'disabled'; args = [null, 'disabled']
		else if args.length == 1 then args.push null
		@attr name, toggle$ args, @attr name

	toggleProp: (name, args...) ->
		unless arguments.length then name = 'checked'; args = [true, false]
		else if args.length == 1 then args.push null
		@prop name, toggle$ args, @prop name
	
	#classList = window.classList
	get_rules_by_class$ = (names) ->
		to = {}
		for s in @style() when new RegExp('(?:^|[\\s\\.#,])(?:'+names.join("|")+')(?:[\\s:\\.#,]|$)').test s then extend to, @rule s
		to
	
	hasClass: (name) -> new RegExp('(^|\\s)'+name+'(\\s|$)').test @element.className
	addClass: (names, timeout, listen) ->
		names = $A names
		if timeout?
			@addClass names = (name for name in names when not @hasClass name)
			to = get_rules_by_class$.call this, names
			@removeClass names
			@morph save: 1, to: to, end1: listen, timeout: timeout, end: do(names)->-> @addClass names
		else (for name in names then @element.className += (if @element.className == '' then name else unless new RegExp('(^|\\s)'+name+'(\\s|$)').test @element.className then ' ' + name else ''))
		this
	removeClass: rmClass$ = (names, timeout, listen) ->
		names = $A names
		if timeout?
			from = get_rules_by_class$.call this, names
			@removeClass names
			@morph save: 1, from: from, timeout: timeout, end: listen
		else
			cls = @element.className
			for name in names then cls = cls.replace new RegExp('(^|\\s+)'+name+'(\\s+|$)'), (a, b, c) ->
				if b and c then ' ' else ''
			if cls then @element.className = cls else @attr "class", null
		this
	rmClass: rmClass$
	toggleClass: (names, timeout, listen) ->
		names = $A names
		if names.length == 1 then names.push null
		idx = 1
		for name, i in names when @hasClass name then idx = i; break
		name = names[idx]
		new_name = toggle$ names, name
		if timeout?
			if name then from = get_rules_by_class$.call this, [name]; @removeClass name else from = {}
			if new_name then @addClass new_name; to = get_rules_by_class$.call this, [new_name]; @removeClass new_name else to = {}
			@morph save: 1, from: from, to: to, timeout: timeout, end1: listen, end: (if new_name then do(new_name)->-> @addClass new_name)
		else @removeClass name if name; @addClass new_name if new_name
		this

	show: (timeout, listen) ->
		if timeout? then @morph effect: 'show', timeout: timeout, end: listen
		else @element.style.display = ''
		this
	hide: (timeout, listen) -> 
		if timeout? then @morph effect: 'hide', timeout: timeout, end: listen
		else @element.style.display = 'none'
		this

	vid: (timeout, listen) -> 
		if timeout? then @morph save: 1, from: {opacity: 0}, begincss: { visibility: '' }, timeout: timeout, end: listen
		else @element.style.visibility = ''
		this
	novid: (timeout, listen) ->
		if timeout? then @morph save: 1, to: {opacity: 0}, endcss: { visibility: 'hidden' }, timeout: timeout, end: listen
		else @element.style.visibility = 'hidden'
		this
	toggleVid: (args...) -> if @element.style.visibility == 'hidden' then @vid args... else @novid args...

	visible: -> !!@element.offsetWidth
	
	setAbsolute: -> @saveAbsoluteCss = s = @css ['position', 'display', 'visibility']; (if s.display == 'none' then @css position: 'absolute', visibility: 'hidden', display: 'block'); this
	unsetAbsolute: -> @css @saveAbsoluteCss; delete @saveAbsoluteCss; this
	
	absolute: ->
		x = []
		it = for i in @upperAll().union(this).items() when not i.visible() then x.push i.css 'display'; i.css 'display', ''
		r=@pos()
		for i, k in it then i.css 'display', x[k]
		r
		###
		if (pos=@pos()).width then return pos
		if @up().visible() then @setAbsolute(); r=@pos(); @unsetAbsolute(); return r
		@addClass cls='c-actual-absolute-size'
		clone = @body().clone().css(position: 'absolute', visibility: 'hidden', left: 0, top: 0).appendTo @root()
		clone.upperAll().show()
		r=clone.first("."+cls).pos()
		clone.free()
		@removeClass cls
		r
		###

	type$.all 'toggle toggleAttr toggleProp removeClass addClass hide show vid novid toggleVid'
	
	# методы расположения на экране
	vscroll: (v) ->
		if arguments.length==0 then @element.scrollLeft else switch v
			when 'bar'		then @element.offsetWidth - @element.clientWidth - @px('border-left-width') - @px('border-right-width')
			when 'size'		then @element.scrollWidth
			when 'inner'	then @element.scrollWidth - @px('padding-left') - @px('padding-right')
			when 'end'		then @element.scrollWidth - @element.scrollLeft == @width()
			when 'begin'	then @element.scrollLeft == 0
			else @element.scrollLeft = @px v, @element.scrollWidth; this
	hscroll: (v) ->
		if arguments.length==0 then @element.scrollTop else switch v
			when 'bar'		then @element.offsetHeight - @element.clientHeight - @px('border-top-width') - @px('border-bottom-width')
			when 'size'		then @element.scrollHeight
			when 'inner'	then @element.scrollHeight - @px('padding-top') - @px('padding-bottom')
			when 'end'		then @element.scrollHeight - @element.scrollTop == @height()
			when 'begin'	then @element.scrollTop == 0
			else @element.scrollTop = @px v, @element.scrollHeight; this
	
	
	# http://learn.javascript.ru/metrics-window
	# http://javascript.ru/ui/offset
	
	unless div$.getBoundingClientRect then CInit.require 'old'
	
	viewPos: -> @element.getBoundingClientRect()
	# возвращает прямоугольники в к-х расположена нода
	#getClientRects: -> @element.getClientRects()
		
	pos: -> win=@window(); r=@element.getBoundingClientRect(); left: r.left + x=win.pageXOffset, right: r.right + x, top: r.top + y=win.pageYOffset, bottom: r.bottom + y, width: r.width, height: r.height
	
	
	left: (left) -> if arguments.length then @css "left", left else @pos().left
	top: (top) -> if arguments.length then @css "top", top else @pos().top
	bottom: (bottom, usePos) -> if arguments.length then (if usePos then @css "top", bottom - @offsetHeight() else @offsetHeight bottom - @top()) else @pos().bottom
	right: (right, usePos) -> if arguments.length then (if usePos then @css "left", right - @offsetWidth() else @offsetWidth right - @left()) else @pos().right
	
	clientWidth: (width) -> if arguments.length then @css "width", width - @vscroll 'bar' else @element.clientWidth
	clientHeight: (height) -> if arguments.length then @css "height", height - @hscroll 'bar' else @element.clientHeight

	width: (width) -> if arguments.length then @css "width", width else @element.clientWidth + @vscroll 'bar'
	height: (height) -> if arguments.length then @css "height", height else @element.clientHeight + @hscroll 'bar'
	
	offsetLeft: -> @element.offsetLeft
	offsetTop: -> @element.offsetTop
	
	offsetWidth: (width) -> if arguments.length then @css "width", width-@px('border-left-width')-@px('border-right-width') else @element.offsetWidth
	offsetHeight: (height) -> if arguments.length then @css "height", height-@px('border-top-width')-@px('border-bottom-width') else @element.offsetHeight
	
	innerWidth: (width) -> if arguments.length then @css "width", width+@px('padding-right')+@px('padding-left') else @width()-@px('padding-right')-@px 'padding-left'
	innerHeight: (height) -> if arguments.length then @css "height", height+@px('padding-top')+@px('padding-bottom') else @height()-@px('padding-top')-@px 'padding-bottom'
	
	outerWidth: (width) ->  if arguments.length then @css "width", width-@px('margin-right')-@px('margin-left')-@px('border-left-width')-@px('border-right-width') else @offsetWidth()+@px('margin-right')+@px 'margin-left'
	outerHeight: (height) -> if arguments.length then @css "height", height-@px('margin-top')-@px('margin-bottom')-@px('border-top-width')-@px('border-bottom-width') else @offsetHeight()+@px('margin-top')+@px 'margin-bottom'

	viewTop: -> @window().pageYOffset
	viewLeft: -> @window().pageXOffset
	
	viewRight: -> @viewLeft() + @viewWidth()
	viewBottom: -> @viewTop() + @viewHeight()
	
	viewWidth: -> @window().innerWidth
	viewHeight: -> @window().innerHeight
	
	pageWidth: -> Math.max (root=@root().element).scrollWidth, @body().element.scrollWidth, root.clientWidth
	pageHeight: -> Math.max (root=@root().element).scrollHeight, @body().element.scrollHeight, root.clientHeight
	
	
	# методы позиционирования
	relativing: (w) -> r = @positioning.apply this, arguments; m = @absolute(); left: r.left - m.left, top: r.top - m.top
	relative: (w) -> (w.prepend this unless w.contains this); @css position: 'absolute', 'margin-left': 0, 'margin-top': 0 ; r = @relativing.apply this, arguments; @css 'margin-left': r.left, 'margin-top': r.top
	position: -> @css 'position', 'absolute'; @css @positioning.apply this, arguments
	extend @::position, position$ =
		invert: {top: 'bottom', bottom: 'top', left: 'right', right: 'left'}
		rotate: {left: 'top', top: 'right', right: 'bottom', bottom: 'left'}
		rotate_back: {left: 'bottom', bottom: 'right', right: 'top', top: 'left'}
		scalex: {left: 0, right: 1, center: 0.5}
		scaley: {top: 0, bottom: 1, mid: 0.5}
		scalexy: {left: 'top', right: 'bottom', center: 'mid', top: 'left', bottom: 'right', mid: 'center'}
		scale: {before: 0, after: 1, center: 0.5, mid: 0.5}
		normalize: (pos, scale) -> p = position$; if pos of p.scalex and scale of p.scalex or pos of p.scaley and scale of p.scaley then p.scalexy[scale] else scale
		wh: (pos, width, height) -> if pos == 'top' or pos == 'bottom' then [width, height] else [height, width]
				
	
	# scalexy - 0..1|(x:left|right|center)|(y:top|bottom|mid), scalexyself - 0..1|before|after|mid
	positioning: (widget, scalex=0.5, scaley=0.5, scalexself=1, scaleyself=1, addx=0, addy=0) ->
	
		scaleyparam = position$.scaley
	
		if typeof scalex == 'string'
			if /\s/.test scalex
				a = scalex.split /\s+/
				a[0]?=scalex; a[1]?=scaley; a[2]?=scalexself; a[3]?=scaleyself; a[4]?=addx; a[5]?=addy
				for x, i in a when /^[^a-z]/.test x then a[i] = parseFloat x
				scalex = a[0]; scaley = a[1]; scalexself = a[2]; scaleyself = a[3]; addx = a[4]; addy = a[5]
			if scalex of scaleyparam then [scalex, scaley, scalexself, scaleyself, addx, addy] = [scaley, scalex, scaleyself, scalexself, addy, addx]
			if typeof scalex == 'string' then scalex = position$.scalex[scalex]
		if typeof scaley == 'string' then scaley = scaleyparam[scaley]
		
		if typeof scalexself == 'string' then scalexself = position$.scale[scalexself]
		if typeof scaleyself == 'string' then scaleyself = position$.scale[scaleyself]

		{left, right, top, bottom} = widget.absolute()
		{width, height} = @absolute()
		
		scalexself *= scalex*2-1
		scaleyself *= scaley*2-1

		left: left + (right-left) * scalex + width * (scalexself - scalex) + if 0.5-1e-10 <= scalex <= 0.5+1e-10 then 0 else if scalex < 0.5 then -addx else addx
		top: top + (bottom-top) * scaley + height * (scaleyself - scaley) + if 0.5-1e-10 <= scaley <= 0.5+1e-10 then 0 else if scaley < 0.5 then -addy else addy

		
	
	# методы событий времени и анимации
	_timeout = (set, clear) -> do (set, clear) -> (time, name, args...) ->
		unless @_timers then @_timers = {}
		@_timers[name]?()
		fn = do(name, args) => => @send name, args...
		ret = set fn, time
		@_timers[name] = do(ret, clear)-> -> clear ret
		this
	timeout: _timeout setTimeout, clearTimeout
	interval: _timeout setInterval, clearInterval
	clear: (name) -> t=@_timers || {}; (if name then t[name]?(); delete t[name] else (for i in t then t[i]()); @_timers = {}); this

	speeds$ = slow: 200, fast: 600, norm: 400

	anime_style$ = count: 'animation-iteration-count', ease: 'animation-timing-function', state: 'animation-play-state', direction: 'animation-direction', delay: 'animation-delay'
	anime_on$ = end: 1, start: 1, iteration: 1
	anime_off$ = timeout:1, duration:1, name:1
	
	
	if wdiv$.hasCss 'animation-name'
		animationVendor$ = if with_vendor_prefix['animation-name'] then CNavigator.vendor else ""
	else CInit.require "animate" # эмуляция
	
	anime: (p, end) ->
		if p == 'paused' || p == 'running' then @setCss anime_style$.state, p
		else if p == 'toggle' then @setCss anime_style$.direction, 'alternate'; @setCss anime_style$.state, 'running'
		else if p == 'remove'
			@_anime?.style.free()
			for k, v of anime_style$ then @css v, null
			@css 'animation', null
			@off 'animationend'
		else
			@_anime ||= {}
			if typeof p == 'string' then p = $H p
			if p.effect then p = extend {}, CEffect[p.effect], p
			
			duration = p.duration || p.timeout
			duration = speeds$[duration] || duration || 400
			if typeof duration == 'number' then duration += 'ms'
			name = p.name || @id() || CMath.uniqid()
			
			cssp = animation: [name, duration].join(" ")
			css = []
			to = null
			
			add = (k, val) =>
				css.push k, "{"
				for k, v of val then css.push @toCssStyle(k, v), ";"
				css.push "}"
			
			css.push '@', animationVendor$, 'keyframes ', name, '{'
			for key, val of p
				if r = anime_style$[key] then cssp[r] = val
				else if key of anime_on$ then @on 'animation'+key, val
				else if key of anime_off$ then
				else if val instanceof Object
					k = key
					if typeof k == 'number' or typeof k == 'string' and /^-?\d+\.\d+$/.test k then k += '%'
					add k, val
				else
					(to ||= {})[key] = val
			if to then add 'to', to
			css.push "}"
			
			(@_anime.style ||= @head().appendRet "<style></style>").html css.join ""
			
			# http://www.sitepoint.com/css3-animation-javascript-event-handlers/ - про анимации
			if end then @on 'animationend', end
			
			@css cssp
			
		this

	animate$ = ->
		anim = @_animqueue[0]
		if anim.this_param then @_animqueue[0] = anim = anim.call this ; next_animate$.call this 
		unless anim.start
			anim.start = start = {}
			for k, ci of anim.stubs then start[k] = this[ci] k
		if anim.i >= anim.timeout
			anim.call this, anim.start, 1
			@_animprev = anim
			@_animqueue.splice 0, 1
			next_animate$.call this
			@send anim.listen
		else
			anim.call this, anim.start, anim.i / anim.timeout, anim.progress
			anim.i += anim.step
	
	next_animate$ = -> @clear animate$; (if @_animqueue.length then @interval @_animqueue[0].step || 0, animate$); this
	
	anim_css_set$ = (key, val) -> #(if /// ^border ///.test key then say 'anim set', key, val; @setCss key, val else say 'anim:', key, val); this
	
	mod$ = in: 'easeIn', out: 'easeOut', io: 'easeInOut'
	speeds$ = slow: 200, fast: 600, norm: 400
	default_timeout$ = 400
	default_fps$ = 1000 / 13
	
	animation: (param, timeout, fps, listen, progress) ->
		if typeof timeout == 'function' then listen = timeout; progress = fps; timeout = fps = null
		if typeof fps == 'function' then progress = listen; listen = fps; fps = null
		timeout = speeds$[timeout] || timeout || default_timeout$
		fps = default_fps$ unless fps
		
		stubs = {}
		fn = []
		
		for key, v of param
			k = escapeString key
			unless s = String(v).match ///^ ( [+-]= )? \s* 
				(?: ( -?(?:\d*\.)?\d+(?:[Ee][+-]\d+)? (?:[a-z%]+)? (?: \s+ -?(?:\d*\.)?\d+(?:[Ee][+-]\d+)? (?:[a-z%]+)? ) {0,3} )
				| ( [a-zA-Z#]\w* (?:\( [^\(\)]+ \))? ) )
				(?:\s+ (?:(in|out|io)\s+)? (\w+))? $/// then anim_css_set$.call this, key, v; continue
			[a, step, to, color, mod, formula] = s
			px = undefined
			
			if to
				to1 = to.split /\s+/
				if to1.length == 1 and (v1 = @getCss(key)?.split /\s+/)?.length > 1 then to1 = [x=to1[0], x, x, x]
				if to1.length > 1 then to = []; ci = []; (for t, i in to1 then m = t.match ///^(.*?)([a-z%]+)$///; to[i]=m[1]; ci[i]=m[2]); px = 'pxvector'
				else
					if ci = to.match ///[a-z%]+$/// then px = ci = ci[0]; to = to.slice 0, to.length-ci.length; (if px == '%' then px = "pv")
					else if @hasCss key, '1px' then ci = px = 'px'
					else if @hasCss key, '1' then ci = ''; px = 'px'
					else anim_css_set$.call this, key, v; continue
			else
				to = color
				color = undefined
				if v == 'toggle' then to = @_animprev.start[key]; px = @_animprev.stubs[key]; (if px == 'rgba' or px == 'hsla' then color = 1)
				else if @hasCss key, '#fff' then color = 1 ; (if px = to.match /// ^([a-z]+) \( ///i then px = px[1]; (if px.length == 3 then px+='a') else px = 'rgba')
				else anim_css_set$.call this, key, v; continue

			#to = wdiv$.setCss(key, val)[px] key
			
			formula = if mod then 'CMath.'+mod$[mod]+'(CMath.'+formula+', k)' else if formula then 'CMath.'+formula+'(k)' else 'k'
			
			if color
				to = wdiv$.setCss(key, to)[px] key
				Px = px.ucFirst()
				To = 'to'+Px
				if step then abs = Math.abs; c = @rgba(key)[To](); x = to[To](); to = (if step == '+=' then new CColor c[0]+x[0], c[1]+x[1], c[2]+x[2], c[3]+x[3]  else new CColor abs(c[0]-x[0]), abs(c[1]-x[1]), abs(c[2]-x[2]), abs(c[3]-x[3]))
				F = if formula == 'k' then 'k' else formula="(f=#{formula})"; 'f'
				formula = 'CColor.from'+Px+'((x=start['+k+'].'+To+'())[0]+((c=['+to[To]()+'])[0]-x[0])*' + formula + ', x[1]+(c[1]-x[1])*'+F+', x[2]+(c[2]-x[2])*'+F+', x[3]+(c[3]-x[3])*'+F+')'
			else if px == 'pxvector'
				f = []
				for t, i in to
					if step then r=@pxvector key; to[i] = r[i] - (if step == '+=' then -t else t)
					f.push (if i==0 then '(x=start['+k+'])' else 'x')+'['+i+']+('+t+'-x)*'+formula+"+'"+ci[i]+"'"
				formula = ["[", f.join(", "), "].join(' ')"].join ""
			else
				if step then to = this[px](key) - (if step == '+=' then -to else to)
				formula = '(x=start['+k+'])+('+to+'-x)*'+formula+(if ci then "+'"+ci+"'" else '')

			fn.push 'this.setCss('+k+', '+formula+')'
			stubs[key] = px
		fn.splice 0, 0, 'fn=function anim$(start, k){\nvar x,c,f' + if progress then ', e = arguments.callee' else ''
		if typeof progress == 'function' then fn.push 'e.progress.call(this, k, e)' else if progress then fn.push 'this.send(e.progress, k, e)'
		fn.push '}'
		code = fn.join '\n'
		eval code
		extend fn, stubs: stubs, i: 0, fps: fps, step: 1000 / fps, timeout: timeout, listen: listen, progress: progress
		
	animate: (param, timeout, fps, listen, progress) ->
		if (len=arguments.length) == 0 then next_animate$.call this
		else if param == 'toggle' then param = {}; (for key of (anim = @_animprev).start then param[key] = 'toggle'); @animate param, anim.timeout,anim.fps, timeout
		else if param == 'clear' then (if len==1 then @_animqueue = []; @clear animate$ else if -1 != idx=@_animqueue.indexOf timeout then @_animqueue.splice idx, 1)
		else if param == 'stop' then @clear animate$
		else if param == 'end' then (if @_animqueue?.length then @_animqueue[0].i = @_animqueue[0].timeout; animate$.call this ; @_animqueue = []; @clear animate$)
		else if param == 'active' then return @_timers[animate$]
		else if param == 'empty' then return not @_animqueue?.length
		else
			anim = if typeof param == 'function' then param else @animation param, timeout, fps, listen, progress
			unless @_animqueue then @_animqueue = [anim] else @_animqueue.push anim
			next_animate$.call this
			animate$.call this
		this
		
	morph: (param) ->
		if typeof param == "string" then (if param of CEffect then param = CEffect[param] else throw @raise "Нет эффекта #{param}")
		if typeof param.timeout == 'object' then extend param, param.timeout; (delete param.timeout if typeof param.timeout == 'object')
		if 'effect' of param then extend_deep_uniq param, CEffect[param.effect] || throw @raise "Нет эффекта #{param.effect}"
		
		anim = do(param)->->
			from = param.from || {}
			to = param.to || {}
			
			save = if not('save' of param) or param.save == 1 then (x=Object.keys(from)).push Object.keys(to)...; x else if param.save == 0 then [] else param.save
			if param.css? then save.push Object.keys(param.css)...
			save = if save.length then @saveCss save else {}
			@css param.css if param.css?
		
			@send param.begin
			
			for i of from then (unless i of to then to[i] = @getCss i)
			for i of to then (unless i of from then from[i] = @getCss i)
			@css param.begincss if param.begincss?
			@css from
		
			if easy=param.easy
				for i of to when not /\s[a-z]\w*$/i.test to[i] then to[i] = to[i] + ' ' + easy
		
			listen = do(param, save)->-> @saveCss save; (@css param.endcss if param.endcss?); @send param.end, param; @send param.end1, param
			anim = @animation to, param.timeout, param.fps, listen, param.progress
			anim.param = param
			anim.to = to
			anim.from = from
			anim
		anim.this_param = 1
		anim = @animate anim
		if param.queue
			for q in param.queue then @morph q
		anim
			
		
	
	type$.all 'timeout interval clear animate morph anime'

	
	# методы шейпов
	shape: (shape) ->	# добавляет в шейп элемент
		unless @_shape ||= @up().filter('[cshape]').item 0 then @wrapIn @_shape = @new(@tag(), shape: "shape").insertBefore this
		@_shape.prepend shape
		
		this
	
	modal: (msg) -> @_modal ||= @wrap("<div cview=modal cargs='class=c-modal'></div>").appendTo @body(); if arguments.length then @_modal.html(msg).open(); this else @_modal
	
	tooltip: (msg) ->
		if arguments.length
			if msg == null then @_tooltip?.free(); @_tooltip = null ; return this
			if msg instanceof CTooltipWidget then @_tooltip?.free(); @_tooltip = msg; return this
			if typeof msg == 'string' then msg = text: msg
			else if msg instanceof CWidget then msg = html: msg
			if not @_tooltip or msg.ctype and @_tooltip.config.ctype != msg.ctype
				@_tooltip?.free()
				t = @_tooltip = @wrap "<div ctype="+(msg.ctype ||= "tip")+" style='display:none'></div>", this
				if msg.append then @[msg.append] t
				else if /^TBODY|TFOOT|THEAD$/.test tag=@tag() then @up().before t
				else if tag == 'TR' then @up().up().before t
				else if this instanceof CNode or /^INPUT|TEXTAREA|SELECT|META|OL|UL|TABLE|BR|HR|IMG$/.test tag then @before t
				else @prepend t
			@_tooltip.conf msg
			this
		else
			@_tooltip
	
	
	arrow_border: (pos, color, height, width, scale = 0.5) ->
		arrow = @wrap "<div></div>"
		arrow.css border: 'solid transparent', width: 0, height: 0, 'pointer-events': 'none'
		if CNavigator.FF then arrow.css 'border-style', 'inset solid inset solid' 
		else if CNavigator.chrome then arrow.css 'transform', 'rotate(360deg)'
		#arrow.css 'border', 'solid rgba(255,255,255,0)'
		arrow.css 'border-'+@position.rotate[pos]+'-width', width*(1-scale)
		arrow.css 'border-'+@position.rotate_back[pos]+'-width', width*scale
		arrow.css 'border-'+pos+'-width', 0
		arrow.css 'border-'+@position.invert[pos], height+'px solid '+color
		arrow
	
	arrow: (pos = 'right', scale = 0.5, height = 10, width = 20, scale_corner = 0.5) ->
		borderWidth = @px 'border-'+pos+'-width'
		backgroundColor = @rgba 'background-color'
		
		height += borderWidth
		
		[w, h] = @position.wh pos, width, height

		arrow = @_arrow = @wrap("<div></div>").appendTo(@body()).css 'overflow': 'hidden', width: w, height: h
		
		#if shadow=@css 'box-shadow'
			
		if borderWidth
			arrow.append(border = @arrow_border pos, @css('border-'+pos+'-color'), height, width, scale_corner)
			.append(main = @arrow_border pos, backgroundColor, height, width, scale_corner)
			l = borderWidth / Math.sin(Math.atan(scale_corner*width / height))
			main.css
				position: 'absolute'
				'margin-top': -main.offsetHeight() + if pos=='top' then l else if pos=='bottom' then -l else 0
				'margin-left': if pos=='left' then l else if pos=='right' then -l else 0
		else arrow.append border = @arrow_border pos, backgroundColor, height, width, scale_corner
		
		arrow.relative this, pos, scale, 'after', 'before', -borderWidth
		this
	
	line: (pos = 'right', scale = 0, len = 30, className = '', addx = 0, addy = 0) ->
		[w, h] = @position.wh pos, '1px', len
		line = @wrap("<div></div>").appendTo(@body()).css width: w, height: h
		if className then line.addClass(className) else line.css 'background', 'red' 
		line.position this, pos, scale, 'after', 'before', addx, addy
		line

	edit: (opt = {}) ->
		self = this
		
		edt = do(self)->->
			return if off == self.send 'onBeforeEdit', this
			self.val self.dataType @val()
			self._edit = null
			self.send "onEdit"
		
		@_edit = @wrap(if opt.line then "<input>" else "<textarea></textarea>").val @val()
		.css @css 'display font text-align vertical-align border width height padding vertical-align'.split ' '
		.css 'position', 'absolute'
		.css opt.css || {}
		.on 'keydown', (e) -> (if e.code() == 13 then @send 'onblur'); this
		.on 'blur', edt
		.prependTo(this).focus().relative this, 'left top before before'
		this
	
	type$.all 'edit arrow arrow_border'
	
	# методы ajax и валидации
	setValid: (valid, err) -> (@attr 'cerr', err if err!=undefined); @attr 'cvalid', valid
	valid: ->
		if regexp=@attr "cvalid"
			fn = CValid[regexp] || new RegExp regexp
			if (if typeof fn=='function' then fn.call this else fn.test @val()) then on else @send 'onInvalid'
		else on
	onInvalid: -> @tooltip(escapeHTML(@attr("cerr") || "Ошибка - невалидное значение")).tooltip().open(); off
	dataType: (val) -> val
	param: -> x={}; x[@name() || 'val'] = @val(); x
	#buildQuery: -> [(p=@form())._tab || p.name(), @name(), p.data?.id || p.$id?.val()]
	add_ref$ = (param={}, p2={}) -> (if form=@form() then p2.ref$ = id: form.data.id, tab: form._tab || form.name()); extend p2, param
	load: (param, args...) -> @loader()._load 'load', add_ref$.call(this, param), this, args; this
	submit: (param, args...) -> (if @valid() then @loader()._load 'submit', add_ref$.call(this, @param(), param), this, args); this
	save: (param, args...) -> (if @valid() then @loader()._load 'save', add_ref$.call(this, @param(), param), this, args); this
	ping: (param, args...) -> @loader()._load 'ping', param, this, args; this
	erase: (param, args...) -> @loader()._load 'erase', add_ref$.call(this, @param(), param), this, args; this
	
	loader: (loader) ->
		if arguments.length then @_loader = loader; this
		else
			@_loader ||= if cloader = @element.getAttribute "cloader" then @byId cloader
			else
				form = this
				while not form._loader and form = form.form() then null
				if form then form._loader
				else @tooltip(html: '<div cview=loading></div>', ctype: 'tooltip').tooltip().last()

	loading: -> !!@loader().request

	# методы конфигурирования виджета
	#conf: (conf) -> (unless @hasOwnProperty 'config' then extend c = {}, @config || {}; @config = c); extend_deep @config, conf; @send 'onConf'; this
	cconf: (conf) -> extend_deep @constructor::config, conf; @send 'onConf', 1 ; this
	conf: (conf) ->
		unless @hasOwnProperty 'config'
			A_config = ->
			A_config.prototype = @config
			@config = new A_config
		extend_deep @config, conf; @send 'onConf'; this


# класс коллекции
class CWidgets extends CWidget
	
	for name, prop of CWidget.prototype when prop instanceof Function and prop.type$ != 0 then this::[name] = ((args...) -> @$0$ "$1$", args...).inline name, [prop.type$ || '$result'], name

	_slice$ = Array::slice
	
	constructor: (a) -> @length = a.length; @_all = if a instanceof Array then a else _slice$.call a
	
	all: -> @_all
	empty: -> !@length
	item: (i) -> @wrap @_all[if i<0 then @_all.length+i else i]
	items: -> e.widget || @createWidget e for e in @_all
	each: (fn) -> fn.call (w=e.widget || @createWidget(e)), idx, w for e, idx in @_all
	
	$result: (name, args...) -> if @_all.length then ((e=@_all[0]).widget || @createWidget e)[name] args...
	$any: (name, args...) -> (if @_all.length then (e=@_all[0]).widget || @createWidget e else CRoot)[name] args...
	$range: -> widgets = @$rangeAll.apply this, arguments; if widgets.length == 0 then null else if widgets.length == 1 then widgets.item 0 else widgets
	$rangeAll: (name, args...) -> all=[]; (for e in @_all then (if ret=(e.widget || @createWidget e)[name] args... then (if ret instanceof CWidgets then all.push ret._all... else all.push ret.element))); new CWidgets all
	$join: (name, args...) -> if args.length then @$all.apply this, arguments else (for e in @_all then (e.widget || @createWidget e)[name] args...).join ""
	$all: (name, args...) -> (for i in @items() then i[name] args...); this
	$attr: (name) -> (if arguments.length <= 2 or arguments[0] instanceof Array then @$result else @$all).apply this, arguments

	invoke: (name, args...) -> for e in @_all then (e.widget || @createWidget e)[name]? args...; this
	map: (name, args...) -> if typeof name == 'function' then (for e in @_all then name.apply (e.widget || @createWidget e), args) else (for e in @_all then (e.widget || @createWidget e)[name]? args...)
	grep: (name, args...) -> new CWidgets if typeof name == 'function' then (for e in @_all when name.apply (e.widget || @createWidget e), args then e) else (for e in @_all when (e.widget || @createWidget e)[name]? args... then e)
	exists: (name) -> new CWidgets(for e in @_all when name of CRoot.ctype(e).prototype then e)
	
	_widget$ = new CWidget document.createElement 'div'
	queryIndex: (query, k=0) -> (if k<0 then i=-k-1; a=_slice$.call(@_all).reverse() else i=k; a=@_all); (for e, j in a when e.tagName then _widget$.element=e; if _widget$.match(query) and i--==0 then return (if k<0 then a.length-j-1 else j)); null
	filter: (query) -> new CWidgets(e for e in @_all when _widget$.element=e; _widget$.match query)
	unwrap: -> (for e in @_all when w=e.widget then w.unwrap()); this


# виджеты нод
class CNode extends CWidget
	constructor: (@element, @_form) -> throw @raise "element уже имеет виджет ", @element.widget if @element.widget; @element.widget = this
	text: (text) -> if arguments.length then @element.data = text else @element.data
	html: @::text
	val: @::text
	outer: @::text
	form: (form) -> if arguments.length then @_form=form; this else @_form
	tag: (tag) -> if arguments.length then throw @raise "Для CNode.tag изменение ноды по имени не определено" else @element.nodeName
	
	Send$ = (event) -> CSend this, event
	Empty$ = ->
	
	setHandler: (handlers...) -> (for handler in handlers then @element['on'+handler] = Send$); this
	removeHandler: (handlers...) -> (for handler in handlers then @element['on'+handler] = Empty$); this


class CButtonWidget extends CWidget
	constructor: -> super ; @setHandler "click"
	val: ->
	onclick: (e) -> (if act=@attr 'act' then this[act]()); e.stop(); off

	
class CSubmitWidget extends CButtonWidget
	onclick: (e) -> @form().submit(); e.stop(); off
class CLoadWidget extends CButtonWidget
	onclick: (e) -> @form().load(); e.stop(); off
class CUploadWidget extends CButtonWidget
	onclick: (e) -> @form().upload(); e.stop(); off
class CSaveWidget extends CButtonWidget
	onclick: (e) -> @form().save(); e.stop(); off
class CEraseWidget extends CButtonWidget
	onclick: (e) -> @form().erase(); e.stop(); off
class CPingWidget extends CButtonWidget
	onclick: (e) -> @form().ping(); e.stop(); off

class CResetWidget extends CButtonWidget
	onclick: (e) -> @form().reset(); e.stop(); off

	
class CInputWidget extends CWidget
	_default_update: 'keyup'
	constructor: ->
		super
		if valid = @attr "cvalid" then @on 'keyup', ->
			if @valid() then @clear 'onInvalid'; @tooltip null else @timeout 1500, 'onInvalid'
			this
	
	val: (val) -> if arguments.length then @element.value = val; this else @element.value
	html: @::val
	text: @::val


class CTextareaWidget extends CInputWidget
	
class CSelectWidget extends CInputWidget
	_default_update: 'change'
	#text: (text) -> if arguments.length then @element.options[@element.selectedIndex].text = text else @element.options[@element.selectedIndex].text

class CRadioWidget extends CInputWidget
	_default_update: 'change'
	
class CCheckboxWidget extends CRadioWidget

class CImgWidget extends CInputWidget
	_default_update: undefined
	_default_assign: 'src'
	val: (val) -> undefined
	src: (val) -> if arguments.length then @element.src = val; this else @element.src


class CScriptWidget extends CImgWidget


class CLinkWidget extends CImgWidget


class CIframeWidget extends CImgWidget
	contentWindow: if (iframe=document.createElement('iframe')).contentWindow then -> @element.contentWindow else -> @attr name, name=CMath.uniqid() unless name=@element.name; window.frames[name]
	contentDocument: if iframe.contentDocument then -> @element.contentDocument else if iframe.document then -> @element.document else -> @contentWindow().document
	content: if document.documentElement then -> new CWidget @contentDocument().documentElement else -> new CWidget @contentDocument().firstChild
	html: (html) -> root=@content(); if arguments.length==1 then root.html(html) else root.html()
	text: (text) -> root=@content(); if arguments.length==1 then root.text(html) else root.text()
	hideAsTransport: ->
		@left(0); @top(0); @width(1); @height(1)
		@css 'visibility', "hidden"
		#if !browser.isSafari then
		@css "position", "absolute"
		this
	src: (url, param, method, enctype) ->
		if arguments.length==0 then return @document().location.href
		if !method || (method=method.toUpperCase()) == "GET"
			if param then url = CParam.add(url, param)
			@document().location.replace(url)
		else if method == "POST"
			form = @wrap("<form method=POST target='"+@frame.attr('name')+"'></form>").attr('action', url).hide().appendTo @body()
			form.attr('enctype', enctype) if enctype
			unless param then null
			else if typeof param == 'string' then for i in param.split /&/
				name = decodeURIComponent i.replace ///=.*///, ''
				val = decodeURIComponent i.replace ///^[^=]*=///, ''
				form.wrap("<input type=hidden />").attr('name', name).val(val).appendTo(form)
			else for i of param
				form.wrap("<input type=hidden />").attr('name', i).val(param[i]).appendTo(form)
			form.element.submit()
			form.remove()
		else throw @raise "Неизвестный науке метод "+method


# элементы
class CElementWidget extends CWidget
	constructor: ->
		super
		counter = if @constructor::hasOwnProperty '_counter' then ++@constructor::_counter else @constructor::_counter = 0
		@send "onBeforeCreate", counter
		do @defineHandlers if 0 == counter
		do @setHandlers
		do @setListens
		do @setModel
		@send 'onCreate', counter

# формы
class CFormWidget extends CWidget
	_default_assign: 'val'
	_method: 'POST'
	
	constructor: ->
		if arguments.length == 0 then super document.getElementById((cn=@className()).lc()) || document.getElementById cn else super
		counter = if @constructor::hasOwnProperty '_counter' then ++@constructor::_counter else @constructor::_counter = 0
		@send "onBeforeCreate", counter
		do @defineHandlers if 0 == counter
		do @setHandlers
		do @setListens
		do @setModel
		do @initialize
		#@attr "ctype", @className()
		@send "onCreate", counter

	initialize: ->
		do @attachElements
		do @setHandlersOnElements
		do @setModelOnElements
	dataType: (data) ->
		if typeof data == 'string' then data = fromJSON data
		if data.rows and data.fields
			rows = CRows.from data
			extend rows, data
			delete rows.rows; delete rows.fields
			rows
		else data
	param: ->
		param = {}
		for name in @_elements when not (x=@byName(name)).attr 'nodata' then param[name] = x.val()
		param
		
	# buildQuery: ->
		# view = []
		# join = []
		# for name in @_elements
			# if (e=@["$"+name]) instanceof CFormWidget then join.push ['LEFT_JOIN', e.buildQuery()...]
			# else view.push name
		# [@_tab || @name(), view, id: (if id=p.$id then id.val$i() else @data?.id), join...]
		
	update: (val) ->
		if val instanceof Array then val = val[0]
		if off != @send 'onBeforeUpdate', val then @val val; @send 'onUpdate', val
		this
	
	val: (val) ->
		if arguments.length == 0 then @param()
		else
			@data = val
			for name in @_elements then @["$"+name].val val[name]
			do @setValid
			this
	valid: -> err = []; (for i in @_elements then unless (e=this["$"+i]).valid() then err.push e); if err.length == 0 then on else @send 'onInvalid', err; off
	
	setValid: (valid = @data?._valid) ->
		if valid
			id = @id()
			for name, v of valid then @["$"+name].setValid v
		this
		
	onkeyup: (e) -> if e.code() == 13 then e.stop(); @submit()


class CTemplateWidget extends CFormWidget
	#initializeContent: @::initialize
	#initialize: ->

	getTemplate: ->
		if @hasClass 'c-template' then @removeClass 'c-template'; html = @html(); @html ""
		else if @attr('cinit')? then html = @down(0).html().replace ///!(!)|!///g, "$1"
		else
			p = this ; n = []
			while p
				if (t=p._templates) or p.attr('cinit')? and t=p.initTemplate()._templates
					html = t[if n.length then "-"+n.join "-" else ""].template
					break
				unless /^\d+$/.test name = p.name() then n.unshift name
				p = p.form()
		html
	initTemplate: ->
		html = @getTemplate()
		@_template = CTemplate.compile html, @_templates = {}
		this
	
	clone: -> super.addClass "c-novid"
	val: (data) ->
		if arguments.length
			do @initTemplate unless @_template
			@element.innerHTML = @_template @data=@dataType(data), @element.id
			@removeClass "c-novid"
			do @initialize
			do @setValid
		else @param()
		
	#buildQuery: -> extend {}, @_query
		
		
		

class CListWidget extends CTemplateWidget
	_tag_frame_add: "ctype=form"
	
	tag_up$ = TABLE: 'tr', TBODY: 'tr', THEAD: 'tr', TFOOT: 'tr' , TR: 'td', SELECT: 'option', UL: 'li', LO: 'li', P: 'span'
	
	initTemplate: ->
		if @hasClass('c-ls') or ts = @hasClass('c-ts')
			@removeClass (if ts then 'c-ts' else 'c-ls')
			if ts then html=@html(); @html "" else html=@getTemplate()
			tag = tag_up$[@tag()] || 'div'
			html = ["<", tag, " id=$+", (if @_tag_frame_add then " "+@_tag_frame_add else ""), ">", html, "</", tag, ">"].join ""
		else html = @getTemplate()
		@_template = CTemplate.compile html, @_templates = {}, is_list: 1

	attachElements: -> @_elements = []; this # специально оставлена пустой. Т.к. только формы должны иметь элементы
	setValid: -> # специально оставлена пустой. Т.к. списки не имеют элементов
	detach: (name) -> (if @frame == name || @frame == this[name] then delete @frame); super
		
	valid: -> @child().reduce "and", "valid"

	param: -> CRows.to (for ch in @child().items() then ch.val())
	
	val: (data) ->
		if arguments.length
			do @initTemplate unless @_template
			@element.innerHTML = @_template @data=@dataType(data), @element.id
			@child().setValid data.valid || @data.valid
			do @setHandlersOnElements
		else for ch in @child().items() when ch.form() == this then ch.val()

	upload: (param, args...) -> @loader()._load('upload', param, this, args);	this
	add: (data) ->
		if off isnt @send 'onBeforeAdd', data
			last = @last()
			d = @data || = []
			@append @_template data, @element.id, d.length
			data.push.apply d, data
			do @setHandlersOnElements add=last.nextAll()
			add.setValid data.valid || d.valid
			@send 'onAdd', data, add
		this


class CMenuWidget extends CListWidget

	initialize: -> super ; @frame = @child().filter(".active").item(0); this

	frame_onclick: (e, frame) -> @activate frame, e.ctrlKey

	activate: (new_frame, add) ->
		if old_frame = @frame
			if @send("onDeactivate", new_frame) is off then return this
			old_frame.removeClass "active"
		@frame = new_frame.addClass "active"
		@send "onActivate", old_frame
		this


class CSelWidget extends CMenuWidget
	frame_onclick: (e) -> super ; off
	

class CScrollWidget extends CListWidget
	onscroll_window: ->
		if @body().hscroll 'end' then @upload()
		this

		
class CSelectableWidget extends CListWidget
	config: {class: {active: 'active', select: 'c-select', unactive: 'c-unactive'}}
	
	frame_onclick: (e, frame) -> 
	
	
class CAutocompleteWidget extends CTemplateWidget



	

# http://habrahabr.ru/company/mailru/blog/207048/
class CSortableHTML5Widget extends CListWidget
	_tag_frame_add: "ctype=form draggable=true"

	ondragstart: (e) ->
		#say 'dragstart'
		if (t=e.target()).form() == this
			@_sortable = t
			@timeout 0, => @_sortable.addClass 'sort'
			e.event.dataTransfer.effectAllowed = 'move'
			e.event.dataTransfer.dropEffect = 'move'
			e.event.dataTransfer.setData 'text/html', t.html()
		this
	
	ondragover: (e) ->
		#say 'dragover', e.target() == this
		if this == t=e.target() then e.cancel()
		if t.form() == this
			e.cancel()
			if t != @_sortable
				if t.next() == @_sortable then t.before @_sortable else @_sortable.before t
		this
	
	ondrop: (e) ->
		#say 'drop', e.target() == this, e.target().form() == this
		if (t=e.target()) == this or t.form() == this
			e.cancel()
			#@_sortable.removeClass 'sort'
			@send "onSorted", @_sortable
			#@_sortable = null
		this

	ondragend: (e) ->
		if @_sortable
			@_sortable.removeClass 'sort'
			@_sortable = null
		this
		
		# cursor: no-drop
class CSortableWidget extends CListWidget
	frame_onmousemove: (e, frame) -> (if not @_sortable and e.left then @dragstart e, frame); this
	onmousemove_document: (e) -> (if @_sortable then @dragover e); this

	dragstart: (e, sortable) ->
		#say 'dragstart'
		@_distance_x = e.x() - left = sortable.left() 
		@_distance_y = e.y() - top = sortable.top()
		style = sortable.element.style
		@_sortable_css = width: style.width, height: style.height, left: style.left, top: style.top, position: style.position, 'z-index': style.zIndex, cursor: style.cursor
		@_sortable = sortable.addClass('sort').css position: 'absolute', width: (w=sortable.width()), height: (h=sortable.height()), top: top, left: left, cursor: 'move', 'z-index': 1000
		@_sortable_prev = @_sortable.prev()
		tag = sortable.tag()
		sortable.before @_void = @wrap("<#{tag}>&nbsp;</#{tag}>").width(w).height(h).novid()
		
	dragover: (e) ->
		sort = @_sortable.hide()
		target = @byViewXY e.viewX(), e.viewY()
		sort.show()
		floor = target.union target.upperAll()
		#say 'dragover', floor
		self = off
		if e.left
			sort.left e.x() - @_distance_x
			sort.top e.y() - @_distance_y
			for item in floor.items() when item.form() == this then self = item; break
			if self
				if self.next() == @_void then self.before @_void else @_void.before self
		else do @dragend
		this
	
	dragend: ->
		#say 'dragend', @_void.left(), @_void.top()
		sort = @_sortable
		@_sortable = null
		vleft = @_void.left(); vtop = @_void.top(); sleft = sort.left(); stop = sort.top()
		timeout = Math.abs(Math.sqrt(vleft*vleft + vtop*vtop) - Math.sqrt(sleft*sleft + stop*stop)) * 2
		sort.animate left: vleft, top: vtop, timeout, =>
			@_void.before(sort.css(@_sortable_css).removeClass 'sort').remove()
			if @_sortable_prev != sort.prev() then @send "onSorted", sort, @_sortable_prev
			@_sortable_css = @_void = @_distance_x = @_distance_y = @_sortable_prev = null
	

class CModalWidget extends CFormWidget
	zIndex = 1500000
	_modals: []
	opacity: 0.5
	_toTop: 1
	
	onclick: (e) -> @close(); e.stop(); off
	fg_onclick: (e) -> e.stop(); off	
	
	get_prev_modal: -> if len=@_modals.length then @_modals[len-1] else @body()
	
	open: ->
		if off isnt @send 'onBeforeOpen'
			zIndex+=2
			prev=@get_prev_modal()
			prev.prop 'c-overflow', prev.saveCss 'overflow'
			prev.css 'overflow', 'hidden'
			
			@constructor::fog = @body().append("<div style='background: black; display: none'></div>").last() unless @fog
			@fog.css position: 'absolute', width: '100%', height: '100%', top: t=@viewTop(), left: l=@viewLeft(), 'z-index': zIndex-1, opacity: @opacity, display: 'block'
			
			@css position: 'absolute', left: l, top: t, overflow: 'auto', width: '100%', height: '100%', 'z-index': zIndex
			
			if @_toTop then @vscroll 0 ; @hscroll 0 
			@show()
			
			@_modals.push this
			@send 'onOpen'
		this
	close: ->
		if off isnt @send 'onBeforeClose'
			@hide()
			zIndex-=2
			@_modals.pop()
			prev = @get_prev_modal()
			prev.css 'overflow', prev.prop 'c-overflow'  #'auto'
			if @_modals.length == 0 || this.hasOwnProperty 'fog' then @fog.hide()
			else @fog.css 'z-index', zIndex-1
			@send 'onClose'
		this
	

class CCenterModalWidget extends CModalWidget
	center: ->
		{width, height} = @fg.absolute()
		if 300 < h=@viewHeight() - height then @fg.css 'margin-top': h / 2 else @fg.css 'margin-top': 150, 'margin-bottom': 150
		if 300 < h=@viewWidth() - width then @fg.css 'margin-left': h / 2 else @fg.css 'margin-left': 150, 'margin-right': 150
		this
	onBeforeOpen: -> @center()
	
	
class CTooltipWidget extends CElementWidget
	
	config: { pos: 'top', scale: 'center', scalex: 'after', scaley: 'mid', height: 10, width: 30, corner: 'mid', focus: 1, mouse: 1, open: 'fadeIn', close: 'fadeOut', class: 'c-tip', turn: 1, close_button: "<div class='ico-close-red' onclick='$(this).up().close()'></div>" }
	
	constructor: ->
		super
		@addClass @config.class if @config.class
		@css 'overflow', 'visible'

	owner: (owner) -> if arguments.length then @_owner = owner; this else @_owner ||= @byId(@attr('cowner')) || @form()

	conf: (msg = {}) ->
		if msg.display == 1 then display = 1 ; delete msg.display
		if msg.open == 1 then open = 1 ; delete msg.open
		if msg.close == 1 then close = 1 ; delete msg.close
		super msg
		p = @config
		p.scale = @position.normalize p.pos, p.scale
		p.corner = @position.normalize p.pos, p.corner
		if msg.text then @text msg.text
		if msg.html then @content msg.html
		if close then @prepend p.close_button
		{pos, scale, height, width, scalex, scaley, corner, turn}=p
		position = if (owner=@owner()).contains this then 'relative' else 'position'
		@[position] owner, pos, scale, scalex, scaley, height
		if turn
			vw = @viewWidth()
			vh = @viewHeight()
			@display()
			{left, top, right, bottom} = @viewPos()
			#say right, bottom, vw, vh
			if left < 0 or top < 0 or right > vw or bottom > vh
				for i in [0..2]
					pos = @position.rotate[pos]
					scale = @position.normalize pos, scale
					corner = @position.normalize pos, corner
					@[position] owner, pos, scale, scalex, scaley, height
					{left, top, right, bottom} = @viewPos()
					#say right, bottom, vw, vh, pos, scale, scalex, scaley, height
					if left >= 0 and top >= 0 and right <= vw and bottom <= vh then break
			@hidden()
		
		@arrow @position.invert[pos], corner, height, width
		do @display if display
		do @open if open
		this
	
	open: -> @show(); @css transition: 'opacity 1s', opacity: 1 #@animate "end"; @morph @config.open
	close: -> @css opacity: 0 #@animate "end"; @morph @config.close
	ontransitionend: -> @hide()
	display: -> @show()
	hidden: -> @hide()
	#onAnimate: -> @timeout @config.timeout, 'close' if @config.timeout


class CTipWidget extends CTooltipWidget
	onmouseenter: (e) -> if @config.mouse then @open()
	onmouseleave: (e) -> if @config.mouse and not(@owner().left() <= e.x() <= @owner().right() and @owner().top() <= e.y() <= @owner().bottom()) then @close()
	onmouseenter_owner: @::onmouseenter
	onmouseleave_owner: @::onmouseleave

	
class CTipFocusWidget extends CTooltipWidget
	onfocus: (e) -> if @config.focus then @open()
	onblur: (e) -> if @config.focus then @close()
	onfocus_owner: @::onfocusin
	onblur_owner: @::onfocusout
	#for ie: onfocus_form: @::onfocusin
	#onblur_form: @::onfocusout

	
# загрузчики
class CLoaderWidget extends CWidget
	constructor: ->
		super
		form._loader = this if (form=@form()) and not form._loader
		do @initialize
		
	initialize: -> @novid()

	val: -> null
		
	_method: 'POST'
	_timeout: 5000

	_onReadyStateChange: =>
		request = @request.request
		if request.readyState == 4 # @html q.statusText # показать статус (Not Found, ОК..)
			if request.status == 200 or request.statusText=='' then @loaded() # q.statusText=='' - для протоколов file или ftp
			else @loaded_error "Ошибка Ajax: "+request.status+" "+request.statusText
		undefined

	_onTimer: =>
		@request.request.abort()
		@loaded_error "Закончилось время ожидания ответа запроса `#{@request.url}`"

	_load: (type, param={}, customer, args) ->
		if (req=@request) and not req.end
			req.request?.abort()
			say "Поступил load до того, как закончился предыдущий. old_customer: " + req.customer + " new_customer: " + customer
		
		@request = type: type, param: param, args: args
		return this if customer.send("onSubmit", param) is off or off is @ohSubmit param

		request = new XMLHttpRequest()

		throw @raise "Браузер не поддерживает Ajax" if request is off

		timer = setTimeout @_onTimer, @_timeout
		request.onreadystatechange = @_onReadyStateChange
		
		url = param._act || customer.attr("action") || @attr("action") || (if id=customer.id() then (if not param.id and pk=customer.data?.id then param.id = pk); "/"+id else @document().location.pathname)
		delete param._act
		
		method = param._method || customer._method || customer.attr("cmethod") || @attr("cmethod") || @_method
		delete param._method

		if '_async' of param then async=param._async; delete param._async else async=on
		
		headers = Vary: 'Ajax', Ajax: type
		if CInit.post == 'json' then headers['Content-Type'] = 'application/json'
		
		for key of param when key[0] == '$' then headers[key.slice(1).upFirst()] = param[key]; delete param[key]
			
		extend @request, timer: timer, request: request, headers: headers, url: url, sender: customer, customer: (if t = customer.attr 'target' then @byId t else if type=='submit' then @byId 'main' else customer)
		
		params = if method != "POST" then (if params then url = CUrl.from url; extend url.param, param; url = CUrl.to url); null
		else if CInit.post == 'json' then toJSON param
		else CParam.to param

		request.open method, url, async
		for key of headers then request.setRequestHeader key, headers[key]
		request.send params
		this

	loaded: ->
		do @end_request
		request = @request.request
		customer = @request.customer
		try
			@request.data = data = customer.dataType request.responseText
		catch e
			return @loaded_error "Ошибка в ответе сервера", e
		do @ohComplete
		args = @request.args
		customer.send "onComplete", data, @request, args...

		switch @request.type
			when "upload"
				customer.add data
			when "submit", "load"
				customer.update data, @request
			when "erase"
				customer.remove()
		do @ohLoad
		customer.send "onLoad", data, @request, args...
		@request = null
		this

	loaded_error: (ajax_error, e) ->
		do @end_request
		@warn "loaded_error", ajax_error, e
		
		@request.error = error = if err=@request?.request.getResponseHeader("Error") then unescape err else ajax_error
		@request.ajax_error = ajax_error
		@request.exception = e
		args = @request.args
		customer = @request.customer
		customer.send "onComplete", error, @request, args...
		customer.send "onError", error, @request, args...
		unless @request.abort_error
			do @ohComplete
			do @ohError
		@request = null

	end_request: ->
		@request?.request.onreadystatechange = null
		clearTimeout @request.timer
		@request.end = on
		

	ohSubmit: -> @vid()
	ohComplete: -> 
	ohLoad: -> @novid()
	ohError: -> @text @request.error		


class CStatusWidget extends CLoaderWidget
	constructor: ->
		super
		@attachElements "main", "preloader", "sucess", "error", "error_msg"
		
	initialize: ->

	ohSubmit: -> @main.hide(); @sucess.hide(); @error.hide(); @preloader.show()
	ohComplete: -> @preloader.hide()
	ohLoad: -> @sucess.show()
	ohError: ->
		@error_msg.text @error.element.title = @request.error
		@error.show()


class CRouterWidget extends CWidget
	#config:
	#	loader: off	# для якорей - если нет - то используется loader якоря

	constructor: ->
		super
		@defineHandlers() unless @constructor.handlers
		@setListens()
		
	onclick_document: (e) ->
		if (a=e.target()).tag() == "A"
			url = CUrl.from a.attr "href"
			if not url.host or url.host == a.document().location.host
				e.cancel()
				@loader a.loader()
				@load _act: url
		return
	
	
	prev_url$ = null
	
	# history.length
	pop$ = (e) ->
		@history_change()
		href = @window().location.href
		href = href.replace ///\#.*$///, ''
		say 'popstate', href, e
		if prev_url$ != href then @load _act: href
		prev_url$ = href
		
	onhashchange_window: pop$
	onpopstate_window: pop$


CView =
	modal: [CCenterModalWidget, '''<div id=$-fg class='$class' style='$style'>$&</div>''']
	loading: [CLoaderWidget, '''
<div id=$-error style='display:none'></div>
<img id=$-preloader src='/img/fanding_lines.gif'>
'''],
	status: [CStatusWidget, '''
<img id=$-main src="img/preloader.gif">
<img id=$-preloader src="img/loader_loading.gif" style="display:none">
<img id=$-sucess src="img/loader_sucess.gif" style="display:none">
<div id=$-error style="display:none; background-color:MistyRose">
<img src="img/loader_error.gif"> #error_msg
</div>
'''],
	ajax_error: [CWidget, '''
<div class='ico-ajax-error'></div><h3>Ошибка</h3><div class=c-tip-content></div>
	''']
	
	
CRoot.initialize()
