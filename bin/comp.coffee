#console.log process.cwd(), __filename #, global

fs = require 'fs'
Path = require 'path'
child_process = require 'child_process'

lib = process.env.APPDATA+'/npm/node_modules/coffee-script'
bin = lib+'/bin/coffee'
lib = lib+'/lib/coffee-script/'
command = require lib+'command.js'

r = []
dir = Path.dirname __filename
root = Path.normalize dir + "/../.."

getFiles = (path) -> for f in fs.readdirSync path when /\.coffee$/.test f then Path.normalize path+"/"+f

for file in fs.readdirSync root when fs.statSync(path = root+"/"+file).isDirectory()
	continue unless fs.existsSync path+"/html"
	files = getFiles path+"/html"
	coffee = path+"/html/coffee"
	if fs.existsSync coffee then files.push coffee
	continue unless files.length
	y = path+'/html/js'
	fs.mkdirSync y unless fs.existsSync y
	
	r.push [y].concat files

console.log process.argv
	
for x, i in r

	if r.length-1 != i
		p = child_process.spawn process.execPath, [bin, '-bmcw', '-o'].concat(x),
			cwd: process.cwd(),
			env: process.env,
			customFds: [0, 1, 2]
		
	else process.argv = [bin, '-bmcw', '-o'].concat(x); command.run()
