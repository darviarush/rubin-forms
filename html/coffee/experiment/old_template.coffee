extend CWidget,
	update: (val, request) ->
		if off != @send 'onBeforeUpdate', val
			if /^\{/.test val
				val = fromJSON val
				CTemplate._STASH = val.stash || {}
				CTemplate._PAGE = val.body
				if layouts = val.layout
					in_layout = val.layout_id
					for layout in layouts
						page = val.body[layout]
						@byId(in_layout).html CTemplate.compile(page.template)(page.data || {}, layout)
						in_layout = page.layout_id
					@byId(val.layout_id).runscript()
				else
					@htmlscript CTemplate.compile(val.template)(val.data, @id())
				
				$(w = @window()).clean()
				$(w.document).clean()
				do CRoot.initWidgets
				
				if url=val.url
					title = CTemplate._STASH.title
					
					url = CUrl.from url
					old = CUrl.from w.location.href
					extend frames = {}, CParam.from(old.param._f, /,/), CParam.from url.param._f, /,/
					url.param._f = frames if frames = CParam.to frames, ","
					
					args = [CUrl.to(url), title || @document().title]
					if request.history then args.unshift 0
					@navigate args...
					say 'reload_manipulate', args..., w.history$, w.history_pos$
				this
				
			else if request?.request and ///^text/html\b///i.test request.request.getResponseHeader "Content-Type"
				@htmlscript val.replace ///[\s\S]*?<body[^<>]*>([\s\S]*?)</body\s*>[\s\S]*///i, "$1"
			else @val val
			@send 'onUpdate', val
		this
		
# reload_manipulate: (data) ->		
		# data = fromJSON data if typeof data == 'string'
		# if stash = data['@stash'] then CTemplate._STASH = stash
		# if layout = data['@layout']
			# for i in [1...layout.length]
				# layout_id = data[layout[i-1]].layout_id
				# page = data[act = layout[i]]
				# @byId(layout_id).html CTemplate.compile(page.template)(page.data || {}, act)
			# title = CTemplate._STASH.title
			
		# if frames = data["@frames"]
			# for act, id of frames
				# page = data[act]
				# @byId(page.id).html CTemplate.compile(page.template)(page.data || {}, act)

		# CTemplate._STASH = {}		
				
		# $(window).clean()
		# $(document).clean()
		# do CRoot.initWidgets
		
		# url = CUrl.from data['@url']
		# old = CUrl.from @window().location.href
		# extend frames = {}, CParam.from(old.param._f, /,/), CParam.from url.param._f, /,/
		# url.param._f = frames if frames = CParam.to frames, ","
		
		# args = [CUrl.to(url), title || @document().title]
		# if @request.history then args.unshift 0
		# @navigate args...
		# say 'reload_manipulate', args..., window.history$, window.history_pos$
		# this
	
extend CLoader,	
	ohError: ->
		text = @request?.request.responseText || ""
		err = @request.error
		content = @wrap "<div cview=ajax_error></div>"
		body = content.first(".c-tip-content")
		if ///^application/json\b///.test @request?.request.getResponseHeader 'Content-Type' then body.val fromJSON(text).error
		else body.update text, @request
		if err then content.first("h3").text err
		@request.sender.tooltip ctype: 'tooltip', close: 1, open: 1, html: content, timeout: 5000, class: 'c-error'