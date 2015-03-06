# ex.coffee - example kitty-cgi


console.log 'Hello CoffeeScript!\n'


frisky_kitty "response.head", 'Content-Type', 'text/plain; codepage=utf-8'

for i, j of kitty "request.head"
	console.log i+': '+j


console.log '\nend page'