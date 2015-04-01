watch = kitty "request.get"

CoffeeScript = require 'coffee-script'
fs = require 'fs'

file = fs.readFileSync watch.from, {encoding: 'utf8'}

file = CoffeeScript.compile file, bare: true, sourceMap: true, file: watch.file, sourceRoot: watch.root, sourceFiles: [watch.source]

fs.writeFileSync watch.to, [file.js, "\n\n//# sourceMappingURL=", watch.map.match(///[^/]+$///)[0] ].join ""
fs.writeFileSync watch.map, file.v3SourceMap

console.log (new Date() + "").replace(/^.*(\d\d:\d\d:\d\d).*$/, "$1") + ' - compiled ' + watch.from_abs