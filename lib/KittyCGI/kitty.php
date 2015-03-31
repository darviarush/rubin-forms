<?php

#################################################################################
#																				#
# Автор:	Косьмина Ярослав													#
# Сайт:		http://darviarush.narod.ru											#
#																				#
# Среда:	http://php.net														#
#																				#
#################################################################################

ini_set('html_errors', True);
ini_set('implicit_flush', False);

function frisky_kitty($req, $param = null) { echo chr(6).$req.($param!==null? " ".(is_string($param)? $param: json_encode($param)): "")."\n"; flush(); }
function kitty($req, $param = null) {
	frisky_kitty(chr(6).$req, $param);
	$line = fgets(STDIN);
	if($line[0]=='{' or $line[0]=='[') $line = json_decode($line);
	return $line;
}

$_kitty_actions = array();

$_kitty_request = fgets(STDIN);

while($_kitty_request!==false) {
	$_kitty_request = rtrim($_kitty_request);
	
	if($_kitty_request[0] === '(') {
		try {
			eval("\$_kitty_ref = " . $_kitty_request . ";");
		} catch(Exception $e) {
			fwrite(STDERR, "Error: " . $e->getMessage() . "\n");
			
			foreach(debug_backtrace() as $f) {
				fwrite(STDERR, $f['file'] . ":" . $f['line'] . ' ' . $f['class'] . ($f['class']? $f['class'].$f['type']: '') . $f['function'] . "\n");
			}
		}
	} else {
	
		$_kitty_action = $_kitty_actions[$_kitty_request];
		if(!$_kitty_action) {
			$_kitty_action = 'kitty_' . str_replace(array('/', '.', '-'), '__', $_kitty_request);
			$_kitty_file = file_get_contents($_kitty_request);
			
			$_kitty_first = strrpos($_kitty_file, '<?php');
			$_kitty_last = strrpos($_kitty_file, '?>');
			if($_kitty_first === false) $_kitty_y = '<?php';
			else if($_kitty_last === false) $_kitty_y = '';
			else if($_kitty_last < $_kitty_first) $_kitty_y = '';
			else $_kitty_y = '<?php';
			
			$_kitty_file = implode("", array("function ", $_kitty_action, "() {?>", $_kitty_file, $_kitty_y, "; };"));
			eval($_kitty_file);
			$_kitty_actions[$_kitty_request] = $_kitty_action;
		}
		
		
		
		try {
			$_kitty_ref = $_kitty_action();
		} catch(Exception $e) {
			fwrite(STDERR, "Error: " . $e->getMessage() . "\n");
			
			foreach(debug_backtrace() as $f) {
				fwrite(STDERR, $f['file'] . ":" . $f['line'] . ' ' . $f['class'] . ($f['class']? $f['class'].$f['type']: '') . $f['function'] . "\n");
			}
		}
	}
	
	$_kitty_request = kitty("end", $_kitty_ref);
}
