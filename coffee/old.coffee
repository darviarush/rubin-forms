class IFrameHttpRequest
	_counter: 0
	constructor: -> @readyState=0 ; @status=0 ; @statusText=''; @responseText = null ; @responseXML = null
	onreadystatechange: ->
	
	onload: -> @status=200 ; @statusText='200 OK'; @responseText = @frame.html(); @responseXML = @frame.content().html(); @loaded()
	onerror: (s)-> @status=404 ; @statusText='404 Not Found' ;  @loaded()
	loaded: ->
		@readyState=3
		@onreadystatechange()
		@readyState=4
		@onreadystatechange()
		@enctype=null
		@frame.remove()
	
	open: (@method, @url, async) ->
		throw new CException "Синхронный IFrameHttpRequest не подерживается" unless async
		name = '__IFrameHttpRequest__'+(++IFrameHttpRequest._counter)
		@frame = frame = CRoot.wrap '<iframe name="'+name+'" id="'+name+'">'
		frame.hideAsTransport()
		document.body.appendChild(frame.element)
		frame.setHandlers 'load', 'error'
		@readyState=1
		@onreadystatechange()
		
	send: (param) ->
		@frame.src(@url, param, @method)
		@readyState=2
		@onreadystatechange()

	setRequestHeader: (name, @enctype) -> 
		throw new CException "Добавление заголовка кроме `Content-Type` не поддерживается" if name!="Content-Type"

unless window.XMLHttpRequest then window.XMLHttpRequest = IFrameHttpRequest


extend CWidget.prototype,
	pos:
		if document.getBoundingClientRect then ->
			box = @element.getBoundingClientRect()
			win = @window()
			doc = win.document
			body = doc.body || {scrollTop: 0, scrollLeft: 0}
			docElem = doc.documentElement   
			scrollTop = docElem.scrollTop || body.scrollTop
			scrollLeft = docElem.scrollLeft || body.scrollLeft
			clientTop = docElem.clientTop || body.clientTop || 0
			clientLeft = docElem.clientLeft || body.clientLeft || 0
			top: box.top +  x = scrollTop - clientTop
			bottom: box.bottom + x
			left: box.left + x = scrollLeft - clientLeft
			right: box.right + x
			width: box.width
			height: box.height
		else ->

			element = this
			body = @body()
			html = @htm()
			x = y = 0
			
			isBody = (e) -> e!=body and e!=html
			
			unless isBody element
			
				while element and not isBody element
					x += element.offsetLeft
					y += element.offsetTop

					if CNavigator.FF
						if 'border-box' != element.css 'box-sizing'
							x += element.px 'border-left-width'
							y += element.px 'border-top-width'

						parent = element.upper()
						if parent and 'visible' != parent.css 'overflow'
							x += parent.px 'border-left-width'
							y += parent.px 'border-top-width'
							
					else if element != this and CNavigator.webkit
						x += element.px 'border-left-width'
						y += element.px 'border-top-width'

					element = @wrap @element.offsetParent
				
				if CNavigator.FF and 'border-box' != element.css 'box-sizing'
					x -= @px 'border-left-width'
					y -= @px 'border-top-width'

			top: y
			bottom: y + h = @offsetHeight()
			left: x
			right: x + w = @offsetWidth()
			width: w
			height: h

