/********************************************************************************
*																				*
* Автор:	Косьмина Ярослав													*
* Сайт:		http://darviarush.narod.ru											*
*																				*
* Среда:	http://nodejs.org/													*
*																				*
********************************************************************************/

(function() {

module.exports = $_kitty_wrap;

var fs = require('fs');

var $_kitty_chr6 = String.fromCharCode(6);


//process.stdin.setEncoding('utf8');
process.stdout.setEncoding('utf8');
process.stderr.setEncoding('utf8');

function $_kitty_readline() {
	var size = 1024;
	var buf = new Buffer(size);
	var ch = '\n'.charCodeAt();
	var len;
	for(var i=0; (len = fs.readSync(0, buf, i, 1)) && buf.readUInt8(i)!=ch; i+=len) {
		if(i+1==buf.length) {
			var x = new Buffer(buf.length+size);
			buf.copy(x);
			buf = x;
		}
	}
	return buf.toString('utf8', 0, (buf.readUInt8(i-1)==ch? i-1: i));
}

function frisky_kitty() {
	var param = [].slice.call(arguments);
	var req = param.shift();
	var buf = [$_kitty_chr6, req];
	if(param.length) buf.push(" ", JSON.stringify(param));
	buf.push("\n");
	fs.writeSync(1, buf.join(""), 0, 'utf8');
	fs.fsyncSync(1);
	//process.stdout.write(buf.join("")); 
	//process.stdout.flush();
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
			
			var $_kitty_file = fs.readFileSync($_kitty_request, {encoding: 'utf8'});
			
			$_kitty_file = $_kitty_re_file($_kitty_file);
			
			$_kitty_file = ["$_kitty_action = function ", $_kitty_action, "() {\n", $_kitty_file, "\n}"].join("");
			
			//console.log($_kitty_file)
			
			eval($_kitty_file);
			$_kitty_actions[$_kitty_request] = $_kitty_action;			
		}
		
		try {
			$_kitty_ref = $_kitty_action();
		} catch(e) {
			console.log(e.stack);
		}
		
		$_kitty_request = kitty("end", $_kitty_ref);
		$_kitty_ref = void(0);
	}
}


})();