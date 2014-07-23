#console.log process.cwd(), __filename #, global

fs = require 'fs'
Path = require 'path'
child_process = require 'child_process'

lib = process.env.APPDATA+'/npm/node_modules/coffee-script'
bin = lib+'/bin/coffee'
lib = lib+'/lib/coffee-script/'
command = require lib+'command.js'

r = []
for file in fs.readdirSync Path.dirname(__filename) + "/../.." when fs.statSync(path = "../"+file).isDirectory()
	files = for f in fs.readdirSync path when /\.coffee$/.test f then Path.normalize path+"/"+f
	coffee = path+"/coffee"
	if fs.existsSync coffee then files.push coffee
	continue unless files.length
	y = path+'/js'
	fs.mkdirSync y unless fs.existsSync y
	
	r.push [y].concat files
	
for x, i in r

	if r.length-1 != i then child_process.spawn process.execPath, [bin, '-bmcw', '-o'].concat(x), {
		cwd: process.cwd(),
		env: process.env,
		customFds: [0, 1, 2]
    }
	else process.argv = process.argv.slice(0, 2).concat '-bmcw', '-o', x; command.run()
