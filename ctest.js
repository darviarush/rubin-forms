

if(!window.console) {
	document.writeln("<div id=_console_log></div>")
	setInterval((function() {
		var log = document.getElementById('_console_log')
		if(!log.firstChild || log.firstChild && log.firstChild.separator) return;
		var div = document.createElement('div')
		div.separator = 1
		div.innerHTML = '&nbsp;'
		log.insertBefore(div, log.firstChild)
	}), 1000)
	console = {
		log: function() {
			var log = document.getElementById('_console_log')
			if(document.body) document.body.appendChild(log)
			var msg = Array.prototype.slice.call(arguments).join(' | ')
			var div = document.createElement('div')
			div.style.border = 'solid 1px gray'
			div.style.background = window.CView? CView._color(): 'pink'
			div.innerText = msg
			log.insertBefore(div, log.firstChild)
		},
		notFound: 1
	}
	window.onerror = document.onerror = function(msg, url, line) { console.log('error: '+url+':'+line, msg, arguments.callee.caller) }
}


//if(location.host === 'darviarush.narod.ru') document.body.firstChild.style.display = 'none'

function CTest(name, manual, css, write, fn) {
	
	var hash = location.hash
	if(hash && hash != "#" && "#CTest-"+name !== hash) return;
	
	//if(CTest.stop) return;
	//CTest.stop = 1

	if(typeof css === 'function') { fn = css; css = ''; write = ''; }
	else if(typeof write === 'function') { fn = write; write = css; css = '' }

	this.name = name
	this._count = 0
	this._counter = 0
	this.isFail = false
	this.indicator = document.getElementById('fortest-'+name)
	if(!this.indicator) this.indicator = CTest.add_indicator(name, document.getElementById('CTest-container-no-ind'))

	if(name in CTest.is_test) { console.log("Тест "+name+" уже существует"); this.color("red", "Тест уже существует"); return }
	CTest.is_test[name] = this
	
	this.color('DeepSkyBlue')
	
	if(!CTest.is_functional) {
		var match = name.match(/^(cls|obj|var|key)-([$\w]+)(?:-([$\w]+))?/)
		if(!match) throw new Error("new CTest(name, ...) - name не подходит под шаблон "+name)
		var type = match[1]
		var cls = match[2]
		var method = match[3] || ''
		
		this.max_name = cls+(type=='cls'? '::': type=='var'? '': '.')+method
		this.add_to_category()

		if(!document.getElementById('h1-'+cls)) document.write('<h1 id=h1-'+cls+'>'+cls+'</h1>')
		
		document.writeln('<h3><a id="CTest-'+name+'" name="CTest-'+name+'" href="#CTest-'+name+'"><i># </i>'+this.max_name+'</a></h3>')
		
		var repl = function(s) { return s.replace(/[\$%](name\b|\{name\})/g, name) }
		
		if(Function.prototype.rename) fn = fn.rename(name.replace(/-/g, "_"));
		
		this.write(manual, repl(write), repl(css), fn)
	}
	
	if(!console.notFound) { this.retValue = fn.call(this); this.end() }
	else
	
	try {
		this.retValue = fn.call(this)
		this.end()
	} catch(e) {
		if(e.stack) console.log(e, e.stack)
		else console.log(e)
		this.color('red', e.message)
		//this.fail(e)
	}
	
}

CTest.is_test = {}
CTest.extend = function(b) { var a = CTest.prototype; for(var i in b) a[i]=b[i] }

CTest.Goto = "onclick='location = this.href'"
CTest.category_counter = 0
CTest.category = function(category) { CTest._category = category }
CTest.toggleCategory = function(self) {
	var x=self.nextSibling, display, ch
	if(x.style.display === "none") { display = ""; ch = "&#9660;" } else { display = "none"; ch = "&#9654;" }
	x.style.display = display
	self.firstChild.innerHTML = ch
}

CTest.queue = []
CTest.queue_idx = 0
CTest.old_name = ""
CTest.old_test = null
CTest.test = function(name, fn) {
	CTest.queue.push({run: 'test', name: name, fn: fn})
	CTest.old_name = name
	CTest.queue_idx = 0
	return CTest
}
CTest.ajax = function(fn) {
	CTest.queue.push({run: 'ajax', name: CTest.old_name+'-ajax-'+(++CTest.queue_idx), fn: fn})
	return CTest
}
CTest.open = function(name, url) {
	/*var a = document.createElement("a")
	a.setAttribute('href', url)
	a.setAttribute('target', name)
	document.body.appendChild(a)
	a.click()*/
	
	var win = window.open('', name)
	if(!win || win.location == 'about:blank') throw 'Не открыто окно '+name
	CRoot = win.CRoot
	$ = win.$
	return CTest
}
CTest.run = function() {
	CTest.queue_idx = 0
	var queue = CTest.queue, add_indicator = CTest.add_indicator
	for(var i=0, n=queue.length; i<n; i++) add_indicator(queue[i].name);
	
	CTest.is_functional = true
	CTest.loop()
}
CTest.loop = function() {
	for(; CTest.queue_idx < CTest.queue.length; CTest.queue_idx++) {
		var test = CTest.queue[CTest.queue_idx]
		var run = test.run
		if(run === 'test') {
			CTest.old_test = new CTest(test.name, "", test.fn)
		} else if(run === 'ajax') {
			var widget = old_test.retValue
			var loader = widget.loader()
			var request = loader._request
			if(request) {
				return setTimeout(CTest.loop, 10)
			}
		} else if(run === 'open') {
			if(test.win.location == 'about:blank') return setTimeout(CTest.loop, 100)
		} else {
			console.log(test)
			throw "Неизвестный queue: "+test.name
		}
	}
}

CTest.extend({
	add_to_category: function() {
	
		var category
		if(CTest._category) {
			category = escapeHTML(CTest._category)
			document.write("<h2><a name=category-"+CTest.category_counter+">"+category+"</a></h2>")

			var menu = document.getElementById('CTest-category')
			var div = document.createElement('div')
			div.innerHTML = "<span class=category-ch onclick='location = \"#category-"+(CTest.category_counter++)+"\"'>&#8669;</span> <span onclick='CTest.toggleCategory(this)'><span class=category-ch>&#9654;</span> "+escapeHTML(category)+"</span><ul style='display:none'></ul>"
			menu.appendChild(div)

			CTest._category = ''
		}
	
		category = document.getElementById('CTest-category')
		var div = category.lastChild
		var ul = div.lastChild
		var li = document.createElement('li')
		li.innerHTML = "<a href='#CTest-"+this.name+"'"+CTest.Goto+">"+this.max_name+"</a>"
		ul.appendChild(li)
	},
	_ok: function(err, ok) {
		if(ok) {
			if(++this._counter == this._count) this.sucess()
			else if(this._count && this._counter > this._count) this.fail("Количество указанных тестов "+this._count+" меньше выполнившихся "+this._counter)
		} else {
			var msg = ''+this.name+':'+this._counter+' '+err
			this.color('red', msg)
			this.isFail = true
			throw new Error(msg)
		}
	},
	stringify: function(a) {
		return JSON.stringify(a, function(key, val) {
			var s
			if(typeof val === 'function') return "(function "+(val.getName() || "[anonimous]")+")"
			if(typeof val === 'object' && !(val instanceof Array) && (s=String(val))!="[object Object]") return s
			return val
		})
	},
	focusin: function(widget) {
		var active = CRoot.document().activeElement
		if(active) $(active).fire('focusout')
		widget.focus()
		widget.fire('focusin')
		return widget
	},
	keys: function(widget, keys) {
		this.focusin(widget)
		var ctrlKey = false, altKey = false, shiftKey = false, metaKey = false, res
		while(res = /\{.\}|\n|./g.exec(keys)) {
			var key = res[0]
			if(key[0] == "{") {
				var f = true, sim = key[1]
				if(sim == '/') { f = false; sim = key[2] }
				if(sim == '+') altKey = f
				else if(sim == '^') ctrlKey = f
				else if(sim == '~') shiftKey = f
				else if(sim == '-') metaKey = f
				else key = sim
				if(key.length>1) continue;
			}
			var e = {ctrlKey: ctrlKey, altKey: altKey, shiftKey: shiftKey, metaKey: metaKey, keyCode: key, charCode: key}
			widget.fire('keydown', e).fire('keypress', e.event).fire('keyup', e.event)
		}
		return widget
	},
	click: function(widget) {
		this.focusin(widget)
		widget.element.click()
		return widget
	},
	ok: function(ok) { this._ok('ok '+this.stringify(ok), ok) },
	is: function(a, b) { this._ok('is '+this.stringify(a)+', '+this.stringify(b), a === b) },
	is$f: function(a, b, prec) { this._ok('is float '+this.stringify(a)+', '+this.stringify(b)+(prec? " "+prec: ""), Math.abs(a - b) < (prec || 1E-10)) },
	isnt: function(a, b) { this._ok('isnt '+this.stringify(a)+', '+this.stringify(b), a !== b) },
	isnt$f: function(a, b, prec) { this._ok('isnt float '+this.stringify(a)+', '+this.stringify(b)+(prec? " "+prec: ""), Math.abs(a - b) >= (prec || 1E-10)) },
	ge: function(a, b) { this._ok('ge '+this.stringify(a)+', '+this.stringify(b), a>=b) },
	gt: function(a, b) { this._ok('gt '+this.stringify(a)+', '+this.stringify(b), a>b) },
	le: function(a, b) { this._ok('le '+this.stringify(a)+', '+this.stringify(b), a<=b) },
	lt: function(a, b) { this._ok('lt '+this.stringify(a)+', '+this.stringify(b), a<b) },
	"instanceof": function(a, b) { this._ok(this.stringify(a)+' instanceof '+this.stringify(b), a instanceof b) },
	like: function(a, b) { this._ok(this.stringify(a)+' like '+this.stringify(b), (a instanceof RegExp)? a.test(b): b.test(a)) },
	unlike: function(a, b) { this._ok(this.stringify(a)+' unlike '+this.stringify(b), !((a instanceof RegExp)? a.test(b): b.test(a))) },
	raise: function(a, b) {
		var fn, msg
		if(typeof a === "function") { fn = a; msg = b } else { fn = b; msg = a }
		try {
			fn()
			this._ok("raise "+this.stringify(a)+', '+this.stringify(b)+' no exception', false)
		} catch(e) {
			this._ok("raise "+this.stringify(a)+', '+this.stringify(b), e.message === msg)
		}
	},
	sucess: function() { this.color('green') },
	fail: function(e) { if(!this.isFail) this._ok(typeof e=='string'? e: e.message, false); throw e; },
	count: function(count) { this._count=count },
	color: function(color, title) {
		this.indicator.style.backgroundColor = color
		if(title) this.indicator.title = this.indicator.title.replace(/^.*?([\w-]+)$/, title+" $1")
	},
	end: function() {
		//if(this._count && this._counter != this._count) this.fail("Количество указанных тестов "+this._count+" меньше выполнившихся "+this._counter)
		if(this._count && this._count != this._counter) {}
		else if(this._counter) this.sucess()
		else this.color('SlateBlue', 'Тест не завершён')
	},
	write: function(manual, html, css, caller) {
	
		var match = this.name.match(/^obj-([\$\w]+)-([\$\w]+)$/)
		if(match) {
			var cls = window[match[1]], fn
			if(!cls) throw new Error("Нет класса "+match[1])
			
			if(!(fn = cls.prototype[match[2]])) throw new Error("Нет метода "+match[1]+"::"+match[2])
			var type = fn.type$ || "$result", s = "В коллекции операция производится "
			var a = s + 'над первым элементом', m = s + "над всеми элементами"
			manual += fn.type$===0? "\n\n*Используется и для коллекции*": "\n\n*"+(type==='$result'? a: type==='$any'? a+', а если коллекция пуста - то над CRoot': type==='$range'? m+'. Возвращает новую коллекцию из результатов операций': type==='$join'? m+'. Возвращает объединение строк результатов': type==='$all'? m+'. Возвращает себя': type==='$attr'? 'В коллекции, если аргументов меньше двух или первый элемент не массив, то применяется к первому элементу. Иначе применяется ко всем и возвращает себя': 'Неизвестная операция')+". См. [" + type + "](#CTest-obj-CWidget-"+type+")*";
		}
	
		document.write("<div class=markdown>")
		document.write( CTest.manual(manual) )
		document.write("</div>")
		
		document.write("<div class=comm>Комментариев: </div>")

		if(css) document.write('<style type=text/css>\n'+css+'\n</style>\n')
		document.write(html)
		
		if(css) {
			var id='css-code-'+this.name
			document.write('<pre><code id="'+id+'" class=css>'+escapeHTML(css)+'</code></pre>')
			hljs.highlightBlock(document.getElementById(id))
		}
		
		if(html) {
			var id='html-code-'+this.name
			document.write('<pre><code id="'+id+'" class=html>'+escapeHTML(html)+'</code></pre>')
			hljs.highlightBlock(document.getElementById(id))
		}
		
		var coffee
		if(coffee = CTest.coffee[this.name]) {
			var id = 'coffee-code-'+this.name
			document.write('<div><a href="#" class="js-coffee-check" onclick="return CTest.js_coffee_check(this)">js</a></div><pre><code id="'+id+'" class=coffeescript>'+escapeHTML(coffee)+'</code></pre>')
			hljs.highlightBlock(document.getElementById(id))
		}
		
		id = 'js-code-'+this.name
		document.write('<pre'+(coffee? ' style="display:none"': '')+'><code id="'+id+'" class=javascript>'+escapeHTML(caller || arguments.callee.caller)+'</code></pre>')
		hljs.highlightBlock(document.getElementById(id))
	},
	w: function(s) {
		return CRoot.byId(this.name + (s? '-'+s: ''))
	}
})

CTest.manual = function(manual) {
	manual = manual.replace(/`[^`]*`|#(!|[\$\w]+)(?:\.([\$\w]+))?/g, function(a, b, c) { if(a[0] == '`' || b == '!') return a; if(!c) {word=c=b; b="CWidget"} else {word=b+"."+c} return "["+word+"](#CTest-obj-"+b+"-"+c+")" })
	
	var converter = new Showdown.converter()
	manual = converter.makeHtml(manual)
	
	manual = manual.replace(/<p>/g, "<div class=ph>")
	manual = manual.replace(/<\/p>/g, "</div>")
	
	var div = document.createElement('div')
	
	manual = manual.replace(/(<div class=ph>\s*)?<code>((?:.|\n)*?)<\/code>/gm, function(a, def, b) {
		div.innerHTML = b
		b = div.textContent || div.innerText || ''
		var lang = /^\s*</.test(b)? 'xml': 'coffeescript'
		var result = hljs.highlight(lang, b, true)
		return (def||'')+'<pre'+(/\n/.test(b) || def? '': ' class=inline-pre')+'><code lang='+lang+'>'+result.value+'</code></pre>'
	})
	
	return manual
}

CTest.js_coffee_check = function(a) {
	var coffee = a.parentNode.nextSibling
	var js = coffee.nextSibling
	if(js.style.display === 'none') {
		js.style.display = ''
		coffee.style.display = 'none'
		a.innerHTML = 'coffee'
	} else {
		js.style.display = 'none'
		coffee.style.display = ''
		a.innerHTML = 'js'
	}
	return false
}

CTest.add_indicator = function(name, where) {
	if(!where) where = document.getElementById('CTest-container')
	var a = document.createElement('a')
	a.className = "CTest"
	a.id = 'fortest-'+name
	a.title = name
	a.href = '#CTest-'+name
	a.innerHTML = '&nbsp;'
	where.appendChild(a)
	return a
}

CTest.build_indicators = function() {
	var t1 = document.getElementById('json-container'),
	add_indicator = CTest.add_indicator,
	x = {}, i, j,

	r = function (cls, j, p) {
		var v=cls[j]
		if(v instanceof Function) {
			var match=String(v).match(/function(?:\s+[\$\w]*)?\s*(\([^\)]*\))/)
			p[j] = match[1]
		} else p[j] = ''
	};
	
	for(i in window) {
		var val = CTest.win[i]
		if(!val) {
			var cls = window[i]
			if(cls instanceof Function && cls.constructor) {
				var pcls = {}, pobj = {}, s=cls.__super__, incls = CTest.cls[i], fn = Function.prototype
				
				add_indicator('cls-'+i)
				
				if(!incls) { for(j in cls) if((s && !j in s.constructor || !s) && !j in fn) { r(cls, j, pcls); add_indicator('cls-'+i+'-'+j) }}
				
				incls = incls || {}
				var p = cls.prototype
				for(j in p) if(!incls[j] && p.hasOwnProperty(j)) { r(p, j, pobj); add_indicator('obj-'+i+'-'+j) }
				
				x[i] = {cls: pcls, obj: pobj}
			} else if(cls instanceof Object) {
				var pcls={}
				for(j in cls) if(cls.hasOwnProperty(j) && cls[j] instanceof Function) { r(cls, j, pcls); add_indicator('key-'+i+'-'+j) }
				x[i] = { key: pcls }
			} else {
				x[i] = 1
				add_indicator('var-'+i)
			}
		}
	}
	
	/*for(i in CTest.cls) {
		var incls = CTest.cls[i], cls = window[i].__proto__ || window[i].prototype
		console.log(i, window[i], window[i].__proto__, window[i].constructor, window[i].prototype);
		for(j in cls) if(!j in incls) { console.log(i+'-'+j); r(cls, j, pcls); add_indicator('key-'+i+'-'+j) }
		x[i] = { key: pcls }
	}*/
		
	t1.value = toJSON(x)
}


CTest.start = function(url) {
	
	CTest.build_indicators()
	if(console.notFound) CInit('cons_')

	CTest.coffee = {}
	try {
		var load = CRoot.body().prepend("<div id=CTest-load cloader=CTest-loader curl='"+url+"'></div><div id=CTest-loader cview=status style='position:absolute'></div>").first()
		load.onLoad = function(request) {
			var code = request.data, coffee = {}
			var split = code.split(/^(?:new|CTest.category)\b/m)
			for(var i=0, n=split.length; i<n; i++) {
				var match = split[i].match(/['"]([\w\$-]+)['"]/)
				if(match) {
					var s = split[i].split(/(?:"""|'''),\s*->/)
					coffee[match[1]] = "->"+s[1].replace(/\s*$/, "").replace(/\t/g, '  ')
				}
			}
			CTest.coffee = coffee
		}
		load.ping({act: null, _method: 'GET', _async: false})
	} catch(e) {}
}


CTest.check_cls = {Array: 1, String: 1, Function:1, Date:1}
CTest.cls = {}
CTest.win = {};
(function() {
	for(var i in window) CTest.win[i] = 1
	for(var i in CTest.check_cls) {
		delete CTest.win[i]
		var p = window[i].prototype, r
		CTest.cls[i] = r = {}
		for(var j in p) r[j] = 1
	}
	
	if(location.hash.slice(1) === "") {
		var fn = function() { scrollTo(0, 0); } //: function() { console.log('location='+location.hash); location.href = location.hash };
		
		var fnx = function() {
			setTimeout(fn, 100);
		}
		
		if(document.addEventListener) document.addEventListener("DOMContentLoaded", fnx, false)
		else document.body.attachEvent("onload", fnx)
	}
	
})();

