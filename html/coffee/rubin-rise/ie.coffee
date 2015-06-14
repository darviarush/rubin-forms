# 1. кросс-браузерные трансформации http://www.useragentman.com/blog/2010/03/09/cross-browser-css-transforms-even-in-ie/
# 2. трансформации css: http://www.useragentman.com/IETransformsTranslator/
# 3. утечки памяти: http://webo.in/articles/habrahabr/18-solving-internet-explorer-memory-leaks/


# for IE < 9 ONLY!


unless window.XMLHttpRequest then do ->
	if X = window[(['Active'].concat('Object').join('X'))]
		for version in ["MSXML2.XMLHttp.5.0", "MSXML2.XMLHttp.4.0", "MSXML2.XMLHttp.3.0", "MSXML2.XMLHttp", "Microsoft.XMLHttp"]
			try
				if new (req = X version) then window.XMLHttpRequest = req; break
			catch
				null
	else CInit.require "old"

# CSend
extend CSend,
	load_type: 'onreadystatechange'
	error_type: 'onreadystatechange'
	readystatechange: ->
		if @readyState=='loaded' then @_onreadystatechange_timer = setTimeout (=> @onerror?()), 10
		if @readyState=='complete'
			clearTimeout @_onreadystatechange_timer if @_onreadystatechange_timer
			@onload?()
		null

	setHandler: (element, type) ->
		@outer @outer().replace /// ^(<\w+) ///, "$1 "+CSend.type(type)+"='return CSend(this, event)'"	
		this

	
# CEvent
extend CEvent.prototype,
	cancel: -> @event.cancelBubble = true
	stop: -> @event.returnValue = false
	target: -> CWidget::wrap(@event.srcElement)
	relatedTarget: -> CWidget::wrap(if @event.fromElement == @event.target then @event.toElement else @event.fromElement)
	mouseLeft: -> @event.button is 1
	mouseMiddle: -> @event.button is 4
	mouseRight: -> @event.button is 2
	x: -> @event.clientX + document.body?.scrollLeft+ document.documentElement?.scrollLeft
	y: -> @event.clientY + document.body?.scrollTop	+ document.documentElement?.scrollTop

		
# CWidget
CStyle.check().add "body", "background: url('about:blank') no-repeat; background-attachment: fixed"
CWidget::css.with_css_prefix.float = 'styleFloat'
setCss = CWidget::setCss
toCssCase = CWidget::css.toCssCase
extend CWidget.prototype,
	window: -> @element.ownerDocument.parentWindow
	# http://handynotes.ru/2010/02/css3-ie-border-radius-box-shadow.html - можно реализовать и http://habrahabr.ru/post/94799/
	setCss: (key, val) -> 
			if key == "position" and val == "fixed" then val='relative'; setCss.call(@, 'top', 'expression(parseInt(document.body.scrollTop,10)+"px")')
			else if key == 'clip' then val = val.replace /,\s+/g, ' '
			else if key == "opacity" 
				#then key = 'filter'; val='alpha(opacity='+parseInt(val*100, 10)+')'
				oAlpha = @element.filters['DXImageTransform.Microsoft.alpha'] || @element.filters.alpha
				if oAlpha then oAlpha.opacity = val
				else elem.style.filter += " progid:DXImageTransform.Microsoft.Alpha(opacity="+nOpacity+")" # ƒл€ того чтобы не затереть другие фильтры используем "+="
			else if key == 'transform'
				# http://htmlbook.ru/css/filter/matrix
				#val - matrix scale screwXY translate
				matrix = @element.filters['DXImageTransform.Microsoft.matrix'] || @element.filters.matrix
				if matrix then matrix.opacity = val
				else elem.style.filter += 'progid:DXImageTransform.Microsoft.Matrix(M11=a, M12=b, M21=c, M22=d, Dx=tx, Dy=ty)'
			setCss.call @, key, val
	
	getCss: (key) ->
		elem = @element
		val = elem.currentStyle[toCssCase key] || 0

		# we use 'left' property as a place holder so backup values
		leftCopy = elem.style.left
		runtimeLeftCopy = elem.runtimeStyle.left

		# assign to runtimeStyle and get pixel val
		elem.runtimeStyle.left = elem.currentStyle.left
		elem.style.left = if prop == "fontSize" then "1em" else val
		val = elem.style.pixelLeft + "px"

		# restore values for left
		elem.style.left = leftCopy
		elem.runtimeStyle.left = runtimeLeftCopy 

		#return value

		#val = @element.currentStyle[toCssCase key]
		#if key == 'clip' then val = val.replace ///\s+///g, ','
		val
	
	# http://bortvlad.ru/js/opredelyaem-razmer-okna-brauzera-javascript-jquery/
	viewWidth:
		if num = (typeof window.innerWidth == 'number') then CWidget::viewWidth
		else if max=(document.documentElement && (document.documentElement.clientWidth || document.documentElement.clientHeight)) then -> document.documentElement.clientWidth #IE 6+ in 'standards compliant mode'
		else -> @body.element.clientWidth
    
	viewHeight:
		if num then CWidget::viewHeight
		else if max then -> document.documentElement.clientHeight
		else -> @body.element.clientHeight

	pageWidth:
		if maxy=(window.innerHeight && window.scrollMaxY) then -> @body().element.scrollWidth
		else if so=((body=document.body) && body.scrollHeight > body.offsetHeight) then -> @body().element.scrollWidth # all but Explorer Mac
		else if rso = ((doc=document.documentElement) && doc.scrollHeight > doc.offsetHeight) then -> @root().scrollWidth # Explorer 6 strict mode
		else -> @body().offsetWidth() # Explorer Mac...would also work in Mozilla and Safari

	pageHeight: 
		if maxy then -> window.innerHeight + window.scrollMaxY
		else if so then -> @body().element.scrollHeight # all but Explorer Mac
		else if rso then -> @root().element.scrollHeight # Explorer 6 strict mode
		else -> @body().offsetHeight() # Explorer Mac...would also work in Mozilla and Safari

	viewLeft: -> document.body.scrollLeft || document.documentElement.scrollLeft
	viewTop: -> document.body.scrollTop || document.documentElement.scrollTop

	arrow_creat = CWidget::arrow_border
	CWidget::arrow_border = (args...) ->
		arrow = arrow_creat args...
		pos = args[0]
		arrow.css 'border-'+@position.rotate[pos]+'-color', 'pink'
		arrow.css 'border-'+@position.rotate_back[pos]+'-color', 'pink'
		arrow.css filter: 'chroma(color=pink)', 'font-size': '0', 'line-height': '0'

	listen: (type, fn, element=@element) -> [type, fn] = listen type, fn; element.attachEvent('on'+type, fn)
	drop: (type, fn, element=@element) -> element.detachEvent 'on'+type, fn; this
	fire: (type, o) -> @element.fireEvent 'on'+type, extend document.createEventObject(), o; (if type of {click:1, mouseup:1} and not evt.cancelBubble then @element.click()); this
	fireMouse: (type, x=0, y=0) -> fire type, w.element
	fireKeyboard: ->
	

	
### CInputWidget ###
extend CInputWidget.prototype,
	setAttr: (name, val) -> 
		if name == 'type'
			if @element.type != val
				@outer @outer().replace ///^ ( <\w+ (?: \s+ \w+=(?:'[^']*'|"[^"]*"|\S+) )*? ) (?: \s+ type=['"]?(?:\w+)['"]? | (\s*/?>)) ///i, '$1'+' type='+val+'$2'
		else @element.setAttribute(name, val)
		this

