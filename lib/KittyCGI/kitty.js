/********************************************************************************
*																				*
* Автор:	Косьмина Ярослав													*
* Сайт:		http://darviarush.narod.ru											*
*																				*
* Среда:	http://nodejs.org/													*
*																				*
********************************************************************************/

var $_kitty_html = function(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }

try {

var fs = require('fs')

var
	stdin = process.stdin,
	stdout = process.stdout,
	$_kitty_chr6 = String.fromCharCode(6);

stdin.setEncoding('utf8');
stdout.setEncoding('utf8');
process.stderr.setEncoding('utf8');

function readline() {
	var ch, buf = '';
	while(ch = fs.readSync(stdin.fd, 1, 0, "utf8") && ch!='\n') buf += ch;
	return buf;
}

function frisky_kitty(req, param) {
	var buf = [$_kitty_chr6, req];
	if(param!==undefined) buf.push(" ", typeof param === "string"? param: JSON.stringify(param));
	buf.push("\n");
	stdout.write(buf.join("")); 
	flush();
}
function kitty(req, param) { frisky_kitty(req, param); return readline(); }

+function() {
	var
		$_kitty_match,
		$_kitty_re = /([\w\$]+)\s*=[^=]/g,
		$_kitty_actions = {},
		$_kitty_request = readline(),
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
			
			$_kitty_file = ["$_kitty_action = function ", $_kitty_action, "(){", $_kitty_vars, $_kitty_file, "}"].join("");
			
			
			eval($_kitty_file);
			$_kitty_actions[$_kitty_request] = $_kitty_action;			
		}
		
		try {
			$_kitty_ref = $_kitty_action();
		} catch(e) {
			console.log(["<pre>", $_kitty_html(e.stack), '</pre>'].join(''));
		}
		
		$_kitty_request = kitty("end", $_kitty_ref);
	}
}();

} catch(e) {
	console.log(["<pre>GLOBAL ERROR:\n\n", $_kitty_html(e.stack), '</pre>'].join(''));
}