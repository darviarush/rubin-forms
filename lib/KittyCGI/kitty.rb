#!/usr/bin/env ruby
# encoding: UTF-8

#################################################################################
#																				#
# Автор:	Косьмина Ярослав													#
# Сайт:		http://darviarush.narod.ru											#
#																				#
# Среда:	https://www.ruby-lang.org											#
#																				#
#################################################################################

require 'json'

class KittyClass

	def frisky_kitty(req, *param)
		r = [6.chr, req]
		if param.size != 0
			r << " "
			r << JSON.generate(param)
		end
		puts r.join("")
		STDOUT.flush()
	end
		
	def kitty(req, *param)
		frisky_kitty(6.chr << req, *param)
		line = STDIN.readline()
		if line[0] == '[' or line[0] == '{'
			line = JSON.parse(line)
		end
		line
	end
end


Kitty = KittyClass.new

actions = {}

request = STDIN.readline()

while request != ''
	request = request.chomp()
	
	action = actions[request]
	if not action
		action = 'kitty_' << request.gsub(/[\/.-]/, '__')
	
		file = File.read(request)
		file = ["class KittyClass\ndef ", action, "()\n", file, "\nend\nend\n"].join('')
		
		eval( file )
		
		actions[request] = action
	end

	begin
		ref = Kitty.send action
	rescue Exception => e
		$stderr.puts e.message
		for i in e.backtrace
			$stderr.puts i
		end
		
	end
	request = Kitty.kitty("end", ref)
	ref = nil
end
