<?php

echo chr(6)."i am kitty!\n";

function read() { flush(); return fgets(STDIN); }

$_kitty_actions = array();

while(($_kitty_request = read())!==false) {
	#$_kitty_request = json_decode($_kitty_request, true);
	
	$_kitty_action = $_kitty_actions[$_kitty_request];
	if(!$_kitty_action) $_kitty_actions[$_kitty_request] = $_kitty_action = new Function("", file_get_contents($_kitty_request));
	
	$_kitty_ref = $_kitty_action();
	
	echo chr(6)."end".(isset($_kitty_ref)? " ".json_encode($_kitty_ref): "")."\n";
}
