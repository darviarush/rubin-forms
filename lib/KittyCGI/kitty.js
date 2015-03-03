/********************************************************************************
*																				*
* Автор:	Косьмина Ярослав													*
* Сайт:		http://darviarush.narod.ru											*
*																				*
* Среда:	http://nodejs.org/													*
*																				*
********************************************************************************/


require('./wrap.js')(function(file) {
	vars = [];
	while(match = re.exec(file)) {
		vars.push(match[1]);
		re.lastIndex--;
	}
	re.lastIndex = 0;
	
	vars = vars.length? ["var ", vars.join(", "), "; "].join(''): '';
	
	return vars + file;
});
