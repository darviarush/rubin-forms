<?php

#################################################################################
#																				#
# Автор:	Косьмина Ярослав													#
# Сайт:		http://darviarush.narod.ru											#
#																				#
# Среда:	http://php.net														#
#																				#
#################################################################################

function frisky_kitty($req, $param = null) { echo chr(6).$req.($param!==null? " ".(is_string($param)? $param: json_encode($param)): "")."\n"; flush(); }
function kitty($req, $param = null) { frisky_kitty($req, $param); return fgets(STDIN); }

$_kitty_actions = array();

$_kitty_request = fgets(STDIN);

while($_kitty_request!==false) {
	$_kitty_request = rtrim($_kitty_request);
	
	$_kitty_action = $_kitty_actions[$_kitty_request];
	if(!$_kitty_action) {
		$_kitty_action = str_replace(array('/', '.', '-'), '__', $_kitty_request);
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
	
	$_kitty_ref = $_kitty_action();
	$_kitty_request = kitty("end", $_kitty_ref);
}
