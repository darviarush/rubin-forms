#################################################################################
#																				#
# �����:	�������� �������													#
# ����:		http://darviarush.narod.ru											#
#																				#
# �����:	http://coffeescript.org												#
#																				#
#################################################################################


require('./wrap.js') (file) ->
	CoffeeScript = require 'coffee-script'
	CoffeeScript.compile file, bare: true
