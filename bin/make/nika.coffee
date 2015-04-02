watch = kitty "request.get"

fs = require 'fs'

file = fs.readFileSync watch.from, {encoding: 'utf8'}

Nika = require '../../html/js/nika.js'

code = Nika.code file, watch.from_abs

fs.writeFileSync watch.to, ["""/*** compiled nika-css ***/
document.writeln("<style>",
(""", code.replace(/^_Nika_\$=/, ''), """)(),
"</style>")
"""].join ""

console.log (new Date() + "").replace(/^.*(\d\d:\d\d:\d\d).*$/, "$1") + ' - compiled ' + watch.from_abs
