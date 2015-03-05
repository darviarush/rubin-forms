/********************************************************************************
*																				*
* Автор:	Косьмина Ярослав													*
* Сайт:		http://darviarush.narod.ru											*
*																				*
* Среда:	http://nodejs.org/													*
*																				*
********************************************************************************/


require('./wrap.js')(function(file) {
	var vars = [], re = /([\w\$]+)(?:\s*=[^=]|\s+in[^\w])/g;
	
	while(match = re.exec(file)) {
		vars.push(match[1]);
		re.lastIndex--;
	}
	re.lastIndex = 0;
	
	return vars.length? ["var ", vars.join(", "), ";\n", file].join(''): file;
});
