watch = kitty "request.get"

file = fs.readFileSync watch.from, {encoding: 'utf8'}

# = require 'html/js/nika.js'