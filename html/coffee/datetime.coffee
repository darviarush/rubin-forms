CDate =
	i18n:
		month: 'Январ:я|ь,Феврал:я|ь,Март:а|,Апрел:я|ь,Ма:я|й,Июн:я|ь,Июл:я|ь,Август:а|,Сентябр:я|ь,Октябр:я|ь,Ноябр:я|ь,Декабр:я|ь'
		mon: 'Янв,Фев,Мар,Апр,Май,Июн,Июл,Авг,Сен,Окт,Ноя,Дек'
		days: 'Воскресенье,Понедельник,Вторник,Среда,Четверг,Пятница,Суббота'
		day: 'Вс,Пн,Вт,Ср,Чт,Пт,Сб'
		unit: 'миллисекунд:а|у|ы|,секунд:а|у|ы|,минут:а|у|ы|,час:||а|ов,день|день|дня|дней,недел:я|ю|и|ь|е,месяц:||а|ев|е,год|год|года|лет|году',
		number: 'од:ин|ну,дв:а|е,три,четыре,пять,шесть,семь,восемь,девять,десять'
		ampm: 'утра,вечера'
		ap: 'ут,веч'
		relative: (n) -> if 5 <= n <= 20 then 3 else if 1 == n % 10 then "" else if 2 <= n % 10 <= 4 then 2 else 3

	masks:
		format: 'yyyy-mm-dd'
		timeFormat: 'yyyy-mm-dd HH:MM:ss'
		
	format: (format, date = this, i18n = CDate.i18n) ->
		pad = CMath.pad
		r = i18n.relative
		
		utc = off
		format = format.replace /^UTC:/, -> utc = on ; ""
		_ = if utc then "getUTC" else "get"
		d = date[_ + "Date"]()
		D = date[_ + "Day"]()
		m = date[_ + "Month"]()
		y = date[_ + "FullYear"]()
		H = date[_ + "Hours"]()
		M = date[_ + "Minutes"]()
		s = date[_ + "Seconds"]()
		L = date[_ + "Milliseconds"]()
		o = if utc then 0 else date.getTimezoneOffset()
		
		token = ///day|mon|month|year|h12|h24|min|sec|msec|d{1,4}|m{1,4}|yy(?:yy)?|([HhMsTt])\1?|[LloSZ]|"[^"]*"|'[^']*'///g
		timezone = ///\b(?:[PMCEA][SDP]T|(?:Pacific|Mountain|Central|Eastern|Atlantic) (?:Standard|Daylight|Prevailing) Time|(?:GMT|UTC)(?:[-+]\d{4})?)\b///g
		timezoneClip = ///[^-+\dA-Z]///g
		
		
		flags =
			d:		d,
			dd:		pad d
			ddd:	i18n.day[D]
			dddd: 	i18n.days[D]
			day:	i18n["unit"+r d][4]
			#week:	i18n["unit"+r d][5]
			m:		m + 1
			mm:		pad m + 1
			mmm:	i18n.mon[m]
			mmmm: 	i18n.month1[m]
			mon:	i18n.month[m]
			month:	i18n["unit"+r m][6]
			yy:		pad y % 100
			yyyy: 	pad y, 4
			year:	i18n["unit"+r y][7]
			h:		H % 12 || 12
			hh:		pad H % 12 || 12
			h12:	i18n["unit"+r H % 12][3]
			H:		H
			HH:		pad H
			h24:	i18n["unit"+r H][3]
			M:		M
			MM:		pad M
			min:	i18n["unit"+r M][2]
			s:		s
			ss:		pad s
			sec:	i18n["unit"+r s][1]
			l:		pad L, 3
			L:		pad if L > 99 then Math.round L / 10 else L
			msec:	i18n["unit"+r L][0]
			t:		i18n.ap[Number H > 12]
			tt:		i18n.ampm[Number H > 12]
			T:		i18n.ap[Number H > 12].toUpperCase()
			TT:		i18n.ampm[Number H > 12].toUpperCase()
			Z:		if utc then "UTC" else (String(date).match(timezone) || [""]).pop().replace timezoneClip, ""
			o:		(if o > 0 then "-" else "+") + pad(Math.floor(Math.abs(o) / 60) * 100 + Math.abs(o) % 60, 4)
			S:		["th", "st", "nd", "rd"][if d % 10 > 3 then 0 else (d % 100 - d % 10 != 10) * d % 10]
		
		#for i, k in 'millisecond,second,minute,hour,day,month,year'.split "," then flags[i] = i18n.unit3[k]
		
		format.replace token, (a) -> if f=flags[a] then f else a.slice 1, a.length - 1
		
	parse_dict: (date, method, s) ->
		if typeof method == 'string' then date[method] parseInt(r=s.match(/^\d+/)[0]) - Number /Month$/.test method; return r.length
		x = s.match(/^(?:[a-z]|[\u80-\uFFFF])+/i)[0].toLowerCase()
		if method instanceof Array then for key in method when key.toLowerCase() == x then return key.length
		else {f, n, a} = method; n ||= a.length; for key, k in a when key.toLowerCase() == x then (if typeof f == 'function' then f date, k, n else date[f] k % n); return key.length
		throw "parse_dict: не распознано слово `#{x}` с места `#{s}`"
	
	parse: (format, s) ->
		date = new Date()
		i18n = CDate.i18n
		utc = off
		format = format.replace /^UTC:/, -> utc = on ; ""
		_ = if utc then "setUTC" else "set"
		_r =
			dddd:	i18n.days
			ddd:	i18n.day
			dd:		_+'Date'
			d:		_+'Date'
			day:	i18n.unitAll
			mmmm:	a: i18n.month1, f: _+'Month'
			mmm:	a: i18n.mon, f: _+'Month'
			mm:		_+'Month'
			m:		_+'Month'
			mon:	a: i18n.month, f: _+'Month'
			month:	i18n.unitAll
			yyyy:	_+'FullYear'
			yy:		_+'Year'
			year:	i18n.unitAll
			hh:		_+'Hours'
			h:		_+'Hours'
			h12:	i18n.unitAll
			HH:		_+'Hours'
			H:		_+'Hours'
			h24:	i18n.unitAll
			MM:		_+'Minutes'
			M:		_+'Minutes'
			min:	i18n.unitAll
			ss:		_+'Seconds'
			s:		_+'Seconds'
			sec:	i18n.unitAll
			l:		_+'Milliseconds'
			L:		_+'Milliseconds'
			msec:	i18n.unitAll
			tt: 	a: i18n.ampm, f: tt=(date, k) -> (if k then date.setHours date.getHours() + 12); on
			t:		a: i18n.ap, f: tt
		parse_dict = CDate.parse_dict
		try
			for r in format.split ///(day|mon|month|year|h12|h24|min|sec|msec|[dmyhHMstTlL]+)///
				s = s.slice if x = _r[r] then parse_dict date, x, s else if r == s.slice 0, r.length then r.length else throw "Распознаваемая дата не соответствует формату #{format} c `#{s}`"
			date
		catch e
			new Date NaN

	set_i18n: (i18n) ->
		for key, s of i18n when typeof s == 'string'
			t = [[]]
			for i, u in s.split ","
				x=i.split ":"
				if x.length==1 then x[1] = x[0]; x[0] = ""
				r = x[1].split "|"
				if 0 < m = r.length - t.length
					for j in [0...m] then t.push []
				for j, k in r then t[k][u] = x[0]+j
			
			all = []
			for r, i in t
				for j in [0...t[0].length] when !r[j]? then r[j] = t[i-1][j]
				CDate.i18n[key+if i then i else ""] = r; all = all.concat r
			CDate.i18n[key+'All'] = all
		on
		
CDate.set_i18n CDate.i18n


class CMonthWidget extends CWidget
	config:
		firstWeekDay: 1
		vertical: 0
	
	create: (date) ->
		year = date.getFullYear()
		month = date.getMonth()
		i18n = CDate.i18n
		
		cur = new Date year, month, 1
		k = 1-cur.getDay()-(conf=@config).firstWeekDay*6
		
		matrix = @tab row: 7, col: 7
		for td, i in matrix[0] then td.html(i18n.day[i]).addClass 'c-week'
		
		cday = date.getDate()
		@_days = days = {}
		
		for i in [1...7]
			for j in [0...7]
				cur = new Date year, month, k++
				day = matrix[i][j]
				day.text dcur = cur.getDate()
				day.element._$date = cur
				days[year+'-'+cur.getMonth()+'-'+dcur] = day
				if cur.getMonth() != month then day.addClass 'c-othermon'
				else if cday == dcur then day.addClass 'c-current'
		
		if conf.vertical then @tab cells: CMath.transpose matrix
		this
		
	byDate: (date) -> @_days[date.getFullYear()+'-'+date.getMonth()+'-'+date.getDate()]


class CCalendarWidget extends CFormWidget
	config:
		format: 'yyyy-mm-dd'
		timeFormat: 'yyyy-mm-dd HH:MM:ss'
		
	create: (date) ->
		@_date = date
		@mon.html CDate.i18n.month[date.getMonth()]
		@year.html date.getFullYear()
		@month.create date
		this

	inc_year: (inc, handlerName) -> @to_year @_date.getFullYear() + inc, handlerName
	inc_month: (inc, handlerName) -> @to_month @_date.getMonth() + inc, handlerName	
	to_year: (year, handlerName = 'onYear') -> date=@_date; date.setFullYear year; (if off != @send handlerName, date then @create date); off
	to_month: (mon) -> date=@_date; date.setMonth mon; (if off != @send "onMonth", date then @create date); off
	to_date: (date) -> (if off != @send "onDate", date then (if date.getYear() == @_date.getYear() and date.getMonth() == @_date.getMonth() then c='c-current'; @byDate().removeClass c; @byDate(@_date = date).addClass c else @create date)); this
	byDate: (date = @_date) -> @month.byDate date
	#date: (args...) -> @month.date args...

	getTargetDate: (e) -> t=e.target(); all = t.union(t.upAll())._all; d = all[all.indexOf(@month.element)-3]._$date; u=@_date;	new Date d.getFullYear(), d.getMonth(), d.getDate(), u.getHours(), u.getMinutes(), u.getSeconds(), u.getMilliseconds()

	larr_onclick: -> @inc_month -1
	rarr_onclick: -> @inc_month 1
	mon_onclick: -> @open 'year'
	year_onclick: (e) -> e.stop(); @open 'years'
	month_onclick: (e) -> @to_date @getTargetDate e

	open: (type) ->
		css = @css ['width', 'height']
		css.position = 'absolute'
		x = @wrap("<table id=#{@id()}_#{type} cview=calendar ctype="+type+"></table>").create(@_date).prependTo(@larr).css css
		x.mon.remove()
		x.month.css(width: '100%', height: '100%').up().attr 'colspan', 3
		x._calendar = this
		x.onMonth = x.onYear = (date) -> @_calendar.create date; @free(); off
		this
	
	input: (@_input, format) -> @conf format: format if format; @body().append this.create (if isNaN date = CDate.parse @config.format, @_input.val() then new Date() else date); @position @_input, 'bottom', 'right'
	timeInput: (@_timeInput, format) -> @conf timeFormat: format if format; @input @_timeInput; @_input = null ; this
	onDate: (date) ->
		if @_input then @_input.val(CDate.format @config.format, date).send 'onDate', date; @free()
		if @_timeInput then @free(); @_timeInput.val CDate.format @config.timeFormat, date; @wrap("<div cview=clock></div>").input(@_timeInput, @config.timeFormat)
		this
		

class CYearWidget extends CCalendarWidget
	create: (date) ->
		@_date = date
		mon = CDate.i18n.mon
		@year.html year = date.getFullYear()
		day = date.getDate()
		for w, i in tds = @wrap(@month.tab row: 3, col: 4).items() then w.element._$date = new Date year, i, day; w.html mon[i]
		tds[date.getMonth()].addClass 'c-current'	
		this

	larr_onclick: (e) -> e.stop(); @inc_year -1
	rarr_onclick: (e) -> e.stop(); @inc_year 1
	month_onclick: (e) -> e.stop(); @to_month @getTargetDate(e).getMonth()
	

class CYearsWidget extends CCalendarWidget
	create: (date) ->
		@_date = date
		cur = date.getFullYear()
		begin = year = parseInt(cur / 20) * 20
		month = date.getMonth()
		day = date.getDate()
		for w, i in tds = @wrap(@month.tab row: 4, col: 5).items() then w.html year; w.element._$date = new Date year++, month, day
		tds[cur-begin].addClass 'c-current'
		@year.html begin+' - '+(begin+19)
		this
		
	larr_onclick: (e) -> e.stop(); @inc_year -20, 'onYears'
	rarr_onclick: (e) -> e.stop(); @inc_year 20, 'onYears'
	year_onclick: (e) -> e.stop()
	month_onclick: (e) -> e.stop(); @to_year @getTargetDate(e).getFullYear()


class CClockWidget extends CFormWidget
	config:
		format: 'd mon yyyy'
		timeFormat: 'HH:MM:ss'
		inputFormat: 'yyyy-mm-dd HH:MM:ss'
	create: (date) ->
		hours = @$hours.tab row: 2, col: 12
		for cell, i in hours[0] then cell.html i; hours[1][i].html i+12
		minsec = @$minsec.tab row: 2, col: 16
		for cell, i in minsec[0] then j=(if i<6 then i else i-6); cell.html j; minsec[1][i].html j
		
		@date date
		@$minsec.tab(0, 6).union(@$minsec.tab(1, 6)).addClass 'c-zero'
		this
		
	clock: (date) -> @$clock.html CDate.format @config.timeFormat, date ; this
	date: (date) ->
		if arguments.length
			@_date = date
			@$date.html CDate.format @config.format, date
			@clock date
			@hours date.getHours()
			@min date.getMinutes()
			@sec date.getSeconds()
			this
		else
			@_date
	
	hours: (h) -> if arguments.length then @wrap(@$hours.tab {}).removeClass 'c-current'; @$hours.tab(Number(h>12), h % 12).addClass 'c-current'; this else @$hours.first('.c-current').prevAll().length
	getUnit: (w) -> x = w.find '.c-current'; x.item(0).prevAll().length*10 + x.item(1).prevAll().length - 6
	setUnit: (m, w) -> w.child().removeClass 'c-current'; w.child(parseInt m / 10).union(w.child 6 + m % 10).addClass 'c-current'; this
	min: (min) -> m = @$minsec.byTag 'tr'; if arguments.length then @setUnit min, m else @getUnit m
	sec: (sec) -> m = @$minsec.byTagAll('tr').item(1); if arguments.length then @setUnit sec, m else @getUnit m
		
	date_onclick: -> @wrap("<table cview=calendar></table>").input(@$date, @config.format).create @_date
	date_onDate: (date) -> @date date
	getTarget: (e, w) -> t=e.target(); all = t.union(t.upAll())._all; @wrap all[all.indexOf(w.element)-3]
	hours_onclick: (e) -> (date=@_date).setHours (t=@getTarget e, @$hours).prevAll().length + t.up().prevAll().length*12 ; @hours date.getHours(); @clock date
	minsec_onclick: (e) -> t=@getTarget e, @$minsec; unit=(if t.up().prev() then 'sec' else 'min'); m=this[unit](); this[unit] n = (if 6 > n = t.prevAll().length then n * 10 + m % 10 else n - 6 + parseInt(m / 10) * 10); @_date['set'+(if unit=='min' then 'Minutes' else 'Seconds')] n; @clock @_date
	
	input: (@_input, date, format) -> @$apply.show(); @conf inputFormat: format if format; @body().append @create (if isNaN date = CDate.parse @config.inputFormat, @_input.val() then new Date() else date); @position @_input, 'bottom', 'right'
	apply_onclick: -> @_input.val(CDate.format @config.inputFormat, @_date).send 'onDate'; @free(); off

extend CView,
	calendar: [CCalendarWidget, '''<thead><tr><td id=$-larr class=c-arr>&larr;<td id=$-mon class=c-mon><td id=$-year class=c-year><td id=$-rarr class=c-arr>&rarr;</thead><tbody><tr><td colspan=4><table id=$-month ctype=month class=c-month></table></tbody>''', class: 'c-calendar']
	clock: [CClockWidget, '''<div id=$-date class=c-date></div><div id=$-clock class=c-head></div><table id=$-hours class=c-hours></table><table id=$-minsec class=c-minsec></table><div><a href="#" id=$-apply class=c-apply style='display:none'>Ок</a></div>''', class: 'c-clock']
