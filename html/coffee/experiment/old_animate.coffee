#http://www.linkexchanger.su/2008/61.html
#http://habrahabr.ru/post/43379/
# http://habrahabr.ru/post/104618/ - анимационные эффекты
# http://madrobby.github.io/scriptaculous/combination-effects-demo/
#http://dev.1c-bitrix.ru/api_help/main/js_lib/animation/easing_prototype_animateprogress.php
# width: '[+=|-=]10[em] [[in|io] fn]'

#class CAnimate
#	constructor: (@param) ->
#	compile: ->

# http://cubic-bezier.com/#.34,1.49,.55,-0.57 - сравнение анимации
# http://daneden.github.io/animate.css/ - анимация css

do->
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
	
	extend CWidget,
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
					if to1.length == 1 and (v1 = @getCss(key).split /\s+/).length > 1 then to1 = [x=to1[0], x, x, x]
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