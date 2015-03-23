watch = kitty "request.get"

CoffeeScript = require 'coffee-script'
fs = require 'fs'

file = fs.readFileSync watch.from, {encoding: 'utf8'}

file = CoffeeScript.compile file, bare: true, sourceMap: true, file: watch.to, sourceRoot: watch.root, sourceFiles: [watch.from]

fs.writeFileSync watch.to, file.js
fs.writeFileSync watch.map, file.v3SourceMap

pat = (s) -> s = ""+s; if s.length == 1 then "0"+s else s
d = new Date()
d = pat(d.getHours())+':'+pat(d.getMinutes())+':'+pat(d.getSeconds())

console.log d + ' - compiled ' + watch.from_abs