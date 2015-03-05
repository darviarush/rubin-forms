/** ex.js - example kitty-cgi **/


console.log( 'Hello Node Js!' )

frisky_kitty("response.head", 'Content-Type', 'text/plain; codepage=utf-8')

head = kitty("request.head")
for(i in head) console.log(i+': '+head[i])


console.log( 'end page' )