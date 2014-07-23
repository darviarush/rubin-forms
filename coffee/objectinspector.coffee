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
	
	
CView.objectinspector = [CObjectInspector, """
<>
"""]
