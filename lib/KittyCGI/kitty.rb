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

	def frisky_kitty(req, param = nil)
		r = [6.chr, req]
		if param != nil
			r << ' '
			if param.class == String
				r << param
			else
				r << JSON.generate(param)
			end
		end
		puts r.join("")
		STDOUT.flush()
	end
		
	def kitty(req, param = nil)
		frisky_kitty(req, param)
		return STDIN.readline()
	end
end


def escapeHTML(s)
	return s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub(/\n/, '<br>')
end

def print_exc(e)
	puts '<pre>'
	puts escapeHTML(e.message)
	for i in e.backtrace
		puts escapeHTML(i)
	end
	puts '</pre>'
end


begin
	
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
			print_exc(e)
		end
		request = Kitty.kitty("end", ref)
		ref = nil
	end

rescue Exception => e
	print_exc(e)
end
