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


	# CWidget. listens$
	#onerror_window: (f) -> (w=@window()).onerror = w.document.onerror = f
	#scroll_window: (f) -> @window().onscroll = f
	#pageshow_window: (f) -> @window().onpageshow = f #@window().addEventListener? "pageshow", f, false
	#pagehide_window: (f) -> @window().onpagehide = f #@window().addEventListener? "pagehide", f, false
	#resize_window: (f) -> @window().onresize = f
	#orientationchange_window: (f) -> @window().onorientationchange = f #@window().addEventListener? "orientationchange", f, false
	#unload_window: (f) -> @window().onunload = f
	#beforeunload_window: (f) -> @window().onbeforeunload = f

	# hashchange_window: if "onhashchange" in window then ((f) -> @window().onhashchange = f) else (f) ->
		# win = @window()
		# win._c_old_hash = win.location.hash
		# setTimeout (=> win = @window(); if win._c_old_hash != h=win.location.hash then f h, win._c_old_hash; win._c_old_hash = h), 200
	# http://learn.javascript.ru/onload-onerror
	# http://snipplr.com/view/6029/domreadyjs/

class CInputWidget extends CInputWidget
	constructor: ->
		super
		say "CInputWidget ====> old!!!"
		if @attr "placeholder" then @setHandler 'blur', 'focus'; @send 'onblur'
		
	val_: (val) -> if arguments.length then @element.value = val; this else @element.value
	val: (args...) -> if @_save_type then (if arguments.length then @onfocus(); @val_ args...; @onblur() else "") else @val_ args...
		
	onblur: -> if @val_() == "" then @_save_type = @attr "type"; @attr "type", "text"; @val_ @attr "placeholder"; @addClass 'c-placeholder'
	onfocus: -> if @_save_type then @attr "type", @_save_type; @removeClass 'c-placeholder'; @_save_type = null ; @val_ ""