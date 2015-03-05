#################################################################################
#																				#
# Автор:	Косьмина Ярослав													#
# Сайт:		http://darviarush.narod.ru											#
#																				#
# Среда:	http://coffeescript.org												#
#																				#
#################################################################################


require('./wrap.js') (file) ->
	CoffeeScript = require 'coffee-script'
	CoffeeScript.compile file, bare: true
