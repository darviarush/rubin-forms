class CSelectMenuWidget extends CMenuWidget
	# main; menu ctype=menu; cvalue; main указывает на выбранный элемент, value - выбранное значение
	onCreate: -> @menu.css 'position', 'absolute'; if value=@attr 'cvalue' then @setByValue value else @setByIndex 0
	byValue: (value) -> (for ch, i in @menu.child() when value==ch.attr 'cvalue' then return i); null
	setByValue: (value) -> @setByIndex @byValue value; this
	setByIndex: (i) -> @set @menu.down i
	set: (option) -> (if option then option.activate(); @value = option.attr('cvalue') || option.text(); @main.html('').append option.clone @main.id()); this
	main_onclick: -> @menu.toggle(); off
	menu_onActivate: (frame) -> @menu.toggle(); @set frame; off
	

class CRangeWidget extends CFormWidget
	style$ = left: 'left', offsetX: 'offsetX', mid: 'mid', offsetWidth: 'offsetWidth'
	style_vertical$ = left: 'top', offsetX: 'offsetY', mid: 'center', offsetWidth: 'offsetHeight'

	pos$ = (k) -> (if off != @send 'onBeforeChange', k then val=@val(); @range.relative this, @_pos.mid, k, 'before', 'before'; @send 'onChange', val); this
	
	onCreate: ->
		@_min = parseFloat @attr("min") || 0 ; @_max = parseFloat @attr("max") || 100 ; @_step = parseFloat @attr("step") || 1
		@_pos = if @attr "cvertical" then style_vertical$ else style$
		@val @_min
		
	onmousemove: (e) -> if e.left and e.target() == this then pos$.call this, e[@_pos.offsetX]() / this[@_pos.offsetWidth]()
	onclick: @::onmousemove
	val: (val) ->
		if arguments.length then pos$.call this, val / ((@_max-@_min) / @_step)
		else @_min + @range.px('margin-'+@_pos.left) / (this[@_pos.offsetWidth]() - @range[@_pos.offsetWidth]()) * ((@_max-@_min) / @_step)
	
	
class CIntervalRangeWidget extends CRangeWidget
	onCreate: -> super ; @r_width 0 ; this
	position: (pos) ->
		pos = Math.round pos
		###if pos <= lf=@r_left() then @r_left pos; @r_width lf-pos+@r_width()
		else if pos => lf + w=@r_width() then @r_width pos-lf
		else if pos <= lf + w/2 then @r_left pos; @r_width w-pos+lf
		else @r_width w-pos+lf###
		this
	#val: (val) -> if arguments.length then @position (@_max-@_min) / @_step * val else @position() / ((@_max-@_min) / @_step)
	
	
class CIntervalWidget extends CFormWidget
	# from, to, range

	
extend CView,
	range: [CRangeWidget, """<div id=$-range></div>""", class: 'c-range']
	'interval-range': [CIntervalRangeWidget, """<div id=$-range></div>""", class: 'c-interval-range']
	interval: [CIntervalWidget, """<input id=$-from type=text> <input id=$-to type=text> <div id=$-range class=c-interval-range ctype=interval-range><div id=$-range-range>&nbsp;</div></div>"""]
	select: [CSelectWidget, '''
<div id=$-main></div>
<div id=$-menu ctype=menu>$&</div>
''']