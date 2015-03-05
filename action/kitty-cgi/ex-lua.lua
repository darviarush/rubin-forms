print "hello lua!"

frisky_kitty("response.head", 'Content-Type', 'text/plain; codepage=utf-8')

for key, val in pairs( kitty("request.head") ) do
  print(key .. ": " .. val)
end

print "end page"