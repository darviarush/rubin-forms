
print 'Hello Python!'

frisky_kitty("response.head", 'Content-Type', 'text/plain; codepage=utf-8')

for i in kitty("request.head").iteritems():
	print( "%s=%s" % i )


print 'end page'