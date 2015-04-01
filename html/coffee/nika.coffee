CNika = (module || {}).exports = 
	code: (code, file = "(string)") ->
		#vendor = CNavigator.vendor
		vendor = ""
		start = "\n$ret.push('"
		stop = "');\n"
		for_c = c = 0
		lineno = 1
		u = -1
		S = []
		camel = (s)-> s.replace /// -(\w) ///g, (a, b)-> b.toUpperCase()
		decamel = (s)-> s.replace /// [A-Z] ///g, (a) -> "-" + a.toLowerCase()
		
		re_vars = ///([\w\$]+)\s*=///g
		vars = (x)->
			vario = []
			i = 0
			while m = re_vars.exec x
				vario.push m[1]
				re_vars.lastIndex--
			re_vars.lastIndex = 0
			if vario.length then ["var ", vario.join(","), "; "].join("")
			else ""	

		# 1 2 3     4     5    6   7     8     9   10          11        12              13           14    15  16  17  18
		# { } for_v for_i in   of  range if    %{} присвоение  функция   вызов-функции   выражение_js  \'   \n   \r	\t+	;
		re = /// (\{) | (\}) |
		%for\s+ ([\w\$]+) (?:\s*,\s*([\w\$]+))? \s+ (?:(in)|(of)) \s+ ([^\{\}]+) \{ |
		%if\s+ ([^\{\}]+) \{ |
		%\{ ([^\{\}]+) \} | 
		%([\w\$-]+)\s*\{ |
		%([\w\$-]+ \s* \( [^\(\)]* \)) \s* \{ |
		%([\w\$-]+) \s* : |
		%([\w\$].*)(?:\r\n|\r|\n) |
		(['\\]) | (\n) | (\r) | (\t+) ///g
		#code = code.replace /// %([\w-]+ \s* : [^;\}]+) ///g, if vendor then -> [vendor, m[1], "; ", m[1]].join "" else '$1'
		#code = code.replace /// ([^:]+) \s* : -%- ([^;\}]+) ///g, if vendor then -> [vendor, m[1], "; ", m[1]].join "" else '$1: $2'
		#.replace /// %((?:[\w-]|#{re_in})+ \s* : (?:#{re_in}|[^;\{\}])+) ///g, if vendor then (z, a) -> [vendor, a, "; ", a].join "" else '$1'
		#.replace /// ((?:[\w-]|#{re_in})+) \s* : \s* -%- ((?:#{re_in}|[^;\{\}])+) ///g, if vendor then (z, a, b)-> [a, ": ", vendor, b, "; ", a, ": ", b].join "" else '$1: $2'
		
		re_in = '%\\{[^\\{\\}]*\\}'
		
		code = code
		#.replace /// %((?:[\w-]|#{re_in})+ \s* : (?:#{re_in}|"(?:\\"|[^"])*"|'(?:\\'|[^'])*'|[^;\{\}])+) ///g, 
		.replace re, (m...) ->
			#say (lineno+":"+c+':'+u+':'+k+': '+i for i, k in m when i? and 0<k and k<17)[0]
			s = if m[1]? then c++; "{"
			else if m[2]?
				#say "}", lineno, c-1, u == c
				(if flag_call_fn == c then flag_call_fn = null; "'), '" else "") + if u == c--
					#if S.length == 0 then throw "ошибка выполнения "+u+' '+c
					x = S.pop()
					u = (S[S.length-1] || [0, -1])[1]
					[stop, (if x[0] == 10 then "var "+x[2]+"=$ret.join(''); $ret=$rets.pop();"
					else if x[0] == 11 then "return $ret.join('');\n}"
					else "}"), start].join('')
				else "}"
			else if m[3]?
				S.push [3, u=++c]
				for_c++
				r = [stop, vars(m[7])]
				if m[6]?
					r.push "var ", (arr="_ARR"+for_c), "=", m[7], "; for(var ", m[3], " in ", arr, ") {\n"
					if m[4]? then r.push "var ", m[4], "=", arr, "[", m[3], "];\n"
				else if (x = m[7].split /(\.{2,3})/).length == 3 then r.push "for(var ", (i=m[3] || "_I"+for_c), "=", x[0], ", ", (to="_TO"+for_c), "=", x[2], "; ", i, (if x[1]=='..' then "<=" else "<"), to, "; ", i, "++) {"
				else r.push "var ", (arr="_ARR"+for_c), "=", m[7], "; for(var ", (i=m[4] || "_I"+for_c), "=0, ", (n="_N"+for_c), "=", arr, ".length;", i, "<", n, "; ", i, "++) {\nvar ", m[3], "=", arr, "[", i, "];\n"
				r.push start
				r.join("")
				
			else if m[8]? then S.push [8, u=++c]; [stop, "if(", m[8], ") {", start].join("")
			else if m[9]? then ["', (", m[9], "), '"].join("")
			else if m[10]? then S.push [10, u=++c, camel m[10]]; [stop, "$rets.push($ret); $ret=[];", start].join("")
			else if m[11]? then S.push [11, u=++c]; [stop, "function ", camel(m[11]), "{var $ret=[];", start].join("")
			else if m[12]? then flag_call_fn = c; ["', ", camel(m[12]), "('"].join("")
			else if m[13]? then lineno++; [stop, vars(m[13]), m[13], start].join("")
			else if m[14]? then "\\"+m[14]
			else if m[15]? then lineno++; "\\n"
			else if m[16]? then "\\r"
			else if m[17]? then ""
			else if m[18]? then (if flag_call_fn == c then flag_call_fn = null; "'), ';" else ";")
			else throw new Error file+":"+lineno+": fatal error: regexp не обработан"
			return s
	
		if S.length then throw new Error file+":"+lineno+"Не закрыта скобка для "+S[S.length-1][0]
		if c!=0 then throw new Error file+":"+lineno+"Не закрыта скобка "+c
	
		["_Nika_$=function(){ var $ret=[], $rets=[]; ", start, code, stop, "return $ret.join(''); }"].join('')

	load: (css) ->
		CRoot.new("div").appendTo(CRoot.body()).ping(_method: 'GET', _act: css+'.css').onLoad = (code) ->
			@free()
			_Nika_$ = null
			eval CNika.code(code)
			@head().append @new("style").html _Nika_$()