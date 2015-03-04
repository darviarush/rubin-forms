#!/usr/bin/env ruby


----------------------------------------------------------------------------------
--																				--
--	Автор:	Косьмина Ярослав													--
--	Сайт:	http://darviarush.narod.ru											--
--																				--
--	Среда:	http://www.lua.org													--
--	Ссылки:	http://tylerneylon.com/a/learn-lua/									--
--																				--
----------------------------------------------------------------------------------

require 'json'

function frisky_kitty(req, *param)
	r = [string.char(6), req]
	if param.size != 0
		table.insert(r, " ")
		table.insert(r, JSON.generate(param))
	end
	print(table.concat(r))
	STDOUT.flush()
end
		
function kitty(...)
	arg
	frisky_kitty(string.char(6) .. req, *param)
	line = STDIN.readline()
	if line[0] == '[' or line[0] == '{'
		line = JSON.parse(line)
	end
	line
end


function escapeHTML(s)
	return string.gsub(s, '([&<>\n])', {'&'='&amp;', '<'='&lt;', '>'='&gt;', '\n'='\n<br>'})
end


if pcall(function()
	
	Kitty = KittyClass.new
	
	actions = {}

	request = STDIN.readline()

	while request != ''
		request = request.chomp()
		
		action = actions[request]
		if not action then
			action = 'kitty_' .. request.gsub(/[\/.-]/, '__')
		
			file = File.read(request)
			file = ["class KittyClass\ndef ", action, "()\n", file, "\nend\nend\n"].join('')
			
			eval( file )
			
			actions[request] = action
		end

		if pcall(function()
			ref = Kitty.send action
		end) then
			print_exc(e)
		end
		request = kitty("end", ref)
		ref = nil
	end

end) then
else
	print('<pre>', , '</pre>')
end
