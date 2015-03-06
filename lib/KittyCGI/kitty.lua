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

local json = require("json")

function frisky_kitty(...)
	local req = table.remove(arg, 1)
	local r = {string.char(6), req}
	if #arg ~= 0 then
		table.insert(r, " ")
		table.insert(r, json.encode(arg))
	end
	print(table.concat(r))
	io.flush()
end
		
function kitty(...)
	local req = table.remove(arg, 1)
	frisky_kitty(string.char(6) .. req, unpack(arg))
	local line = io.read()
	local first = string.sub(line, 1, 1)
	
	if first == "[" or first == "{" then
		line = json.decode(line)
	end
	return line
end



local actions = {}

local request = io.read()

while request ~= "" do
	request = string.gsub(request, "%n$", "")
	
	local action = actions[request]
	if not action then
		local action_name = 'kitty_' .. string.gsub(request, '[\/.-]', '__')
	
		local file = io.open(request):read("*a")
		local less = {}
		
		local k, v -- "(%w+)%s*=[^=]|(%w+(?:%s*,%s*%w+)*)%s+in%s"
		for k in string.gmatch(file, "(%w+(%s*,%s*%w+)*%s+in%s)") do
			print( "k=" .. k )
			if v then
				k = v
			end
			table.insert(less, k)
		end
		
		if #less > 0 then
			file = table.concat( { 'local ', table.concat(less, ", "), "; ", file } )
		end
		print(file)
		action = assert(loadstring( file, action_name ))
		
		if action == nil then
			print("Функция `" .. action_name .. "` не скомпиллировалась")
			action = function() end
		else
			actions[request] = action
		end
	end

	local ref
	local status, err = pcall(function()
		ref = action()
	end)
	
	if not status then
		io.stderr:write(err .. "\n")
		io.stderr:write(debug.traceback())
	end
	request = kitty("end", ref)
	ref = nil
end