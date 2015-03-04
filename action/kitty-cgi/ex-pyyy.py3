
print( 'Hello Python 3!' )

frisky_kitty("response.head", 'Content-Type', 'text/plain; codepage=utf-8')


for i in kitty("response.head").items():
	print( "%s=%s" % i )

print( 'end page' )