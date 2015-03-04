puts "hello ruby!"

frisky_kitty("response.head", 'Content-Type', 'text/plain; codepage=utf-8')

puts kitty("request.head").inspect

puts "end page"