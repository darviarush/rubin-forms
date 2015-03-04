/********************************************************************************
*																				*
* Автор:	Косьмина Ярослав													*
* Сайт:		http://darviarush.narod.ru											*
*																				*
* Среда:	http://nodejs.org/													*
*																				*
********************************************************************************/

(function() {

module.exports = $_kitty_server;

var fs = require('fs'),
	$_kitty_stdin;

var $_kitty_chr6 = String.fromCharCode(6);

//process.stdin.setEncoding('utf8');
process.stdout.setEncoding('utf8');
process.stderr.setEncoding('utf8');

function $_kitty_readline() {
	var ch, buf = '';
	while(ch = fs.readSync($_kitty_stdin.fd, 1, 0, "utf8") && ch!='\n') buf += ch;
	return buf;
}

function frisky_kitty() {
	var param = [].slice.call(arguments);
	var req = param.shift();
	var buf = [$_kitty_chr6, req];
	if(param.length) buf.push(" ", JSON.stringify(param));
	buf.push("\n");
	stdout.write(buf.join("")); 
	flush();
}
function kitty(req) {
	var args = [].slice.call(arguments);
	args[0] = $_kitty_chr6 + req
	frisky_kitty.apply(this, args);
	var line = $_kitty_readline();
	if(line[0] == '[' || line[0] == '{') line = JSON.parse(line);
	return line;
}

function $_kitty_wrap($_kitty_re_file) {
	
	var
		$_kitty_match,
		$_kitty_re = /([\w\$]+)\s*=[^=]/g,
		$_kitty_actions = {},
		$_kitty_request = $_kitty_readline(),
		$_kitty_ref;

	while($_kitty_request) {
		
		var $_kitty_action = $_kitty_actions[$_kitty_request];
		if(!$_kitty_action) {
			$_kitty_action = $_kitty_request.replace(/[\/\.\-]/g, '__');
			var $_kitty_stream = fs.openSync($_kitty_request, 'rb');
			$_kitty_stream.setEncoding('utf8');
			var $_kitty_file = $_kitty_stream.read();
			$_kitty_stream.close();
			
			$_kitty_vars = [];
			while($_kitty_match = $_kitty_re.exec($_kitty_file)) {
				$_kitty_vars.push($_kitty_match[1]);
				$_kitty_re.lastIndex--;
			}
			$_kitty_re.lastIndex = 0;
			
			$_kitty_vars = $_kitty_vars.length? ["var ", $_kitty_vars.join(", "), "; "].join(''): '';
			
			$_kitty_file = $_kitty_re_file($_kitty_file);
			
			$_kitty_file = ["$_kitty_action = function ", $_kitty_action, "(){", $_kitty_vars, $_kitty_file, "}"].join("");
			
			eval($_kitty_file);
			$_kitty_actions[$_kitty_request] = $_kitty_action;			
		}
		
		try {
			$_kitty_ref = $_kitty_action();
		} catch(e) {
			console.log(e.stack);
		}
		
		$_kitty_request = kitty("end", $_kitty_ref);
	}
}


function $_kitty_server(fn) {
	try {
		$_kitty_stdin = process.stdin;
		$_kitty_wrap(fn);
	} catch(e) {
		var net = require('net');
		var server = net.createServer(function(c) { //'connection' listener
		  console.log('client connected');
		  $_kitty_stdin = c;
		  $_kitty_wrap(fn);
		  //c.pipe(c);
		});
		server.listen(8889, function() { //'listening' listener
		  console.log('server wrap.js bound on 8889');
		});		
	}
	
	
	
}

})();