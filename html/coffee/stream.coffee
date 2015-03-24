# Потоки
# http://pozadi.github.io/kefir/
# http://baconjs.github.io/api.html
# https://rxjs.codeplex.com/
# http://xgrommx.github.io/rx-book/index.html
# http://habrahabr.ru/post/237495/
# http://dimoneverything.blogspot.ru/2013/11/blog-post.html - пример подробный
# http://habrahabr.ru/post/237733/ - трансдьюсеры
class CStream

	# создаём аналогичные 
	callback$ = (channel) ->
		if (ret = channel.src[@_name] @_args...) instanceof CWidget then channel.src = ret
		else channel.args = [ret]
		@send channel

	if window.CWidget
		for name, prop of CWidget.prototype when prop instanceof Function
			@::[name] = do(name)-> (args...) -> @meta callback$, _name: name, _args: args
		
	# конструкторы
	#@callback: (f, args...) -> stream = new CStream; f (do(stream, args)->-> stream.emit ); stream
	@fromCallback: (fn, args...) -> stream = new CStream; fn stream.emitter(args...); stream
	
	emitEmpty = ->
	@nothing: -> stream = new CStream; stream.emitValue = emitEmpty; stream
	@unit: (args...) -> (new CStream).map args...
	@error: (args...) -> (new CStream).mapError args...
	@later: (ms, args...) -> (new CStream).sleep(ms).emit args...
	@fromPromise: (promise, args...) -> stream = new CStream; promise args..., stream.emitter(), stream.errorer()
	@from: -> (stream = new CStream).from.apply stream, arguments
	@repeat: -> (stream = new CStream).repeat.apply stream, arguments
	@serial: -> (stream = new CStream).serial.apply stream, arguments
	@sleep: -> (stream = new CStream).sleep.apply stream, arguments
	
	constructor: -> @fork = []
	emitter: -> stream = this ; fn = (do(stream)-> (args...)-> stream.emitValue src: this, args: args); fn._belong = this ; fn
	errorer: -> stream = this ; fn = (do(stream)-> (args...)-> stream.emitError src: this, args: args); fn._belong = this ; fn
	
	# emitInterval = (channel, args...) ->
		# setInterval do(channel, args)=>
			# @_callback.apply channel, args
			# @send arguments
		# , @_ms
		# this
		
	# пути
	saveSend = (channel) ->
		for f in @fork then f.emitValue.call f, channel
		this
	saveSendError = (channel) ->
		for f in @fork then f.emitError.call f, channel
		this
	logSend = (channel) -> say "[", console.trace(), "]", channel; saveSend.call this, channel
	logSendError = (channel) -> say "[", arguments.callee.caller, "]", channel; saveSendError.call this, channel
	log: (flag = true) -> p = @constructor.prototype; (if flag then p.send = logSend; p.sendError = logSendError else p.send = saveSend; p.sendError = saveSendError); this
	
	send: saveSend
	sendError: saveSendError
		
	emitValue: saveSend
	emitError: saveSendError
	
	emit: (args...) -> @emitValue src: null, args: args
	error: (args...) -> @emitError src: null, args: args
	
	emits: (src, args...) -> @emitValue src: src, args: args
	errors: (src, args...) -> @emitError src: src, args: args
	
	# мета
	meta: (emit, param) -> @fork.push stream = new (@constructor)(); stream.emitValue = emit; (if param then for i of param then stream[i] = param[i]); stream
	
	metaError: (emit, param) -> @fork.push stream = new (@constructor)(); stream.emitError = emit; (if param then for i of param then stream[i] = param[i]); stream
	
	# ошибки
	emitFail = (channel) -> @_callback.apply channel.src, channel.args; @sendError channel
	fail: (onError) -> @metaError emitFail, onError
	
	mapError: -> @metaError @send
	
	# модифицирующие
	emitMapPath = (channel) ->
		from = channel.args
		from.unshift channel.src
		args = for path, i in @_paths
			if path == undefined then from[i]
			else
				v = from[path[0] || 0]
				for k in [1...] then v=v[path[k]]
				v
		channel.src = args.shift()
		channel.args = args
		@send channel

	path: -> @meta emitMapPath, _paths: (for arg in arguments then if arg then arg.split /\./)
		
	emitMap = (channel) -> channel.args = [@_callback.apply channel.src, channel.args]; @send channel
	emitMapTo = (channel) -> channel.args = @_args; @send channel
	map: (args...) ->
		if typeof (map = args[0]) == 'function' then @meta emitMap, _callback: map
		else @meta emitMapTo, _args: args

	emitMaps = (channel) ->	channel.args = @_callback.apply channel.src, channel.args; @send channel
	maps: (args...) -> if typeof (map = args[0]) == 'function' then @meta emitMaps, _callback: map else @meta emitMapTo, _args: args
	
	emitMapAll = (channel) -> @send @_callback channel
	emitMapAllTo = (channel) -> @send extend channel, @_map
	mapAll: (args...) -> if typeof (map = args[0]) == 'function' then @meta emitMapAll, _callback: map else @meta emitMapAllTo, _map: args[0], _args: args.slice 1
	
	emitMapChannel = (channel) -> channel.args = [extend {}, channel]; @send channel
	mapChannel: (map) -> @meta emitMapChannel
	
	emitFilter = (channel) -> (if @_callback.apply channel.src, channel.args then @send channel); this
	filter: (filter) -> @meta emitFilter, _callback: filter
	
	emitFilterNot = (channel) -> (unless @_callback.apply channel.src, channel.args then @send channel); this
	filterNot: (filter) -> @meta emitFilterNot, _callback: filter
	
	emitReduce = (channel) -> @_acc = @_callback.apply channel.src, [@_acc].concat channel.args; channel.args = [@_acc]; @send channel
	reduce: (arg, fn) -> (if arguments.length == 1 then fn = arg; arg = 0); @meta emitReduce, _callback: fn, _acc: arg
	
	emitSkipDuplicates = (channel) -> (if '_prev' of this and @_prev != channel.args[0] or not '_prev' of this then @_prev = channel.args[0]; @send channel); this
	emitSkipDuplicatesCmp = (channel) -> (if '_prev' of this and @_callback @_prev, channel.args[0] or not '_prev' of this then @_prev = channel.args[0]; @send channel); this
	skipDuplicates: (cmp) -> @meta (if cmp then emitSkipDuplicatesCmp else emitSkipDuplicates), _callback: cmp
	
	emitSleep = (channel) -> setTimeout (do(channel) => => @send channel), @_ms; this
	sleep: (ms) -> @meta emitSleep, _ms: ms
	
	emitSkip = (channel) -> (if @_skip < t = new Date().getTime() then @_skip = t+@_ms; @send channel); this
	skip: (ms) -> @meta emitSkip, _ms: ms, _skip: 0
	
	emitSkipCount = (channel) -> (unless @_count-- then @_count = @_n; @send channel); this
	skipN: (n) -> @meta emitSkipCount, _n: n, _count: n
	
	emitRepeat = (channel) -> (for i in [@_from...@_to] by @_by then @send extend {}, channel); this
	emitRepeatInterval = (channel) -> 
		clear = setInterval (fn = do(channel, clear)=>=> if @_from > (i = arguments.callee.i+=@_by) >= @_to then clearInterval clear else channel = extend {}, channel; channel.args = [i] if @_map; @send channel), @_ms
		fn.i = @_from
		channel = extend {}, channel
		channel.args = [@_from] if @_map
		@send channel
	repeat: (n, ms, map) -> (if typeof n == 'number' then n = to: n); @meta (if ms then emitRepeatInterval else emitRepeat), _ms: ms, _from: n.from || 0, _to: n.to, _by: n.by || 1, _map: map
	
	emitSerial = (channel) -> (for i in @_serial then @send extend {}, channel, args: [i]); this
	emitSerialInterval = (channel) -> 
		clear = setInterval (fn = do(channel, clear)=>=> if (i = ++arguments.callee.i) >= (serial = arguments.callee.serial).length then clearInterval clear; delete arguments.callee.serial else @send extend {}, channel, args: [serial[i]]), @_ms
		fn.i = 0
		fn.serial = @_serial
		@send extend {}, channel, args: [@_serial[0]]
	serial: (serial, ms) ->
		if typeof serial == 'number' then serial = to: n
		if serial instanceof Array then @meta (if ms then emitSerialInterval else emitSerial), _ms: ms, _serial: serial
		else @repeat serial, ms, on
	
	from: (serial, ms) -> @serial (if serial instanceof Array then serial else ([i, serial[i]] for i of serial)), ms
	
	getEnds: (ends) -> (if @fork.length == 0 then ends.push this else for s in @fork then s.getEnds ends); this
	getEndLast: (end) -> (if @fork.length == 0 then end.push this else @fork[@fork.length-1].getEndLast end); this
	getEndFirst: (end) -> (if @fork.length == 0 then end.push this else @fork[0].getEndFirst end); this
	
	emitFlatMap = (channel) ->
		stream = @_callback.apply channel.src, channel.args
		stream.getEnds ends = []
		for end in ends then end.fork = @fork
		stream.emitValue channel
		this
	flatMap: (map) -> @meta emitFlatMap, _callback: map
	
	emitFlatMapLast = (channel) ->
		stream = @_callback.apply channel.src, channel.args
		stream.getEndLast end = []
		end[0].fork = @fork
		stream.emitValue channel
		this
	emitFlatMapFirst = "emitFlatMapFirst="+String(emitFlatMapLast).replace /\bgetEndLast\b/, 'getEndFirst'
	eval emitFlatMapFirst
	flatMapLast: (map) -> @meta emitFlatMapLast, _callback: map
	flatMapFirst: (map) -> @meta emitFlatMapFirst, _callback: map
	
	# связывающие
	emitThen = (channel) -> @_callback.apply channel.src, channel.args; @send channel
	then: (onValue) -> @meta emitThen, _callback: onValue
	
	emitFindAssign = (channel) -> CRoot.find(@_object).invoke @_callback, @_args..., channel.args...; @send channel
	emitAssign = (channel) -> @_object[@_callback] @_args..., channel.args...; @send channel
	emitAssignVar = (channel) -> @_object[@_callback] = channel.args[0]; @send channel
	assign: (object, method, args...) -> @meta (if typeof object == 'string' then emitFindAssign else if typeof object[method] == 'function' then emitAssign else emitAssignVar), _callback: method, _object: object, _args: args

	# объединяющие
	merge: (streams...) -> @fork.push stream = new (@constructor)(); (for s in streams then s.fork.push stream); stream
	
	# ожидает пока все потоки не пришлют значение и объединяет их в массив
	preCombine =  (args, channel) -> src: channel.src, args: for i in args then i.args[0]
	mapCombine = (channel) -> channel.idx = @_idx; @send channel
	emitCombine = (channel) ->
		(q = @_queue[channel.idx]).push channel
		if q.length == 1
			@_len++
			if @_len == @_queue.length
				args = []
				for q in @_queue
					args.push q.shift()
					if q.length == 0 then @_len--
				@send @_callback args, channel
		this
		
	combine: (streams...) ->
		fn = if typeof streams[streams.length-1] == 'function' then streams.pop() else preCombine
		streams.unshift this
		len = streams.length
		streams = (for s, i in streams then s.meta mapCombine, _idx: i)
		stream = streams.shift()
		stream = stream.merge streams...
		stream.emitValue = emitCombine
		stream._queue = q = new Array len
		stream._len = 0
		stream._callback = fn
		for i in [0...len] then q[i] = []
		stream
	
	emitZipN = (channel) -> (q=@_queue).push channel; (if q.length == @_n then @_queue = []; @send @_zip q, channel); this
	emitZip = (channel) -> (q=@_queue).push channel; (if @_n q, channel then @_queue = []; @send @_zip q, channel); this
	emitZipSleep = (channel) -> (q=@_queue).push channel; (if q.length == 1 then setTimeout((=> q = @_queue; @_queue = []; @send @_zip q, q[q.length-1]), @_n)); this
	zip: (n, zip) -> @meta (if typeof n == 'number' then emitZipN else if typeof n == 'string' then n = (if /^\d+s$/.test n then 1000*parseInt n else parseInt n); emitZipSleep else emitZip), _queue: [], _n: n, _zip: zip || preCombine

	#switch: ->
	#	for i in [0...arguments] by 2
			
	
	# отключающие
	off: (streams...) -> fork = @fork; (for s in streams when -1 != i=fork.indexOf s then fork.splice i, 1); this

	
	
if window.CWidget
	CWidget.extend
		#stream: -> stream = new CStream; stream
		stream: (events) -> stream = new CStream; @on events, stream.emitter(); stream
		observeStream: (events) -> stream = new CStream; @observe events, stream.emitter(); stream
		ajaxStream: -> stream = new CStream; @on 'Load', stream.emitter(); @on 'Error', stream.errorer(); stream

if window.CModel		
	CModel.extend
		stream: (key) -> stream = new Stream; @on key, stream.emitter(); stream
		retriveStream: (key) -> stream = new Stream; @at key, stream.emitter(); stream

		
class CBox extends CStream
	constructor: (@_box) ->
	meta: -> box = super ; box.emitValue box._box = @_box; box