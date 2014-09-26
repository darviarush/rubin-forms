unless window.console
	document.writeln "<div id=_console_log></div>"
	setInterval (->
		log = document.getElementById('_console_log')
		if !log.firstChild || log.firstChild && log.firstChild.separator then return
		div = document.createElement('div')
		div.separator = 1
		div.innerHTML = '&nbsp;'
		log.insertBefore(div, log.firstChild)
		), 1000
	console =
		log: (args...) ->
			log = document.getElementById('_console_log')
			if document.body then document.body.appendChild(log)
			msg = args.join ' | '
			div = document.createElement('div')
			div.style.border = 'solid 1px gray'
			div.style.background = CView._color()
			div.innerText = msg
			log.insertBefore(div, log.firstChild)

	window.onerror = document.onerror = (msg, url, line) -> console.log('error: '+url+':'+line, msg)



class CObjectInspector extends CWidget
	constructor: ->
		@wrap(///body///).listen 'click', -> 
	




class CConsoleWidget extends CFormWidget
	onCreate: ->
		@css "position", "fixed"
		console.log = (args...) => @log.append('<div>'+"info".fontcolor('blue')+": "+escapeHTML(args.join(", "))+'</div>'); @count.inc()
	count_onclick: -> @log.width @body().clientWidth; @log.toggle()
	onerror_window: (msg, url, line, dop='') -> (if msg instanceof Object then url=msg.filename; line=msg.lineno; dop=' '+toJSON(msg); msg=msg.message); @log.append('error'.fontcolor('red')+': '+msg+' '+String(url).fontcolor('green')+':'+String(line).fontcolor('royalblue')+dop); @count.inc()

	
extend CView,
	console: [CConsoleWidget, """<div id=$+>
<div id=$-count style='color: red; border:solid 4px gray; width:auto; cursor:pointer'>0</div>
<div id=$-log style='display:none; background:white; border:solid 4px gray; width: 100%; height: 500px; overflow:auto'></div>
</div>"""]
	objectinspector: [CObjectInspector, """
<>
"""]