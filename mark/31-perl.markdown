# Вспомогательные функции

## Инициализация

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1 in out body invariant RETURN/;

$app->man->conf;


```

## like

Хелпер для превращения глоба в регулярку:

* % - несколько символов исключая /
* * - несколько символов включая /
* ? - один символ
* {...} - 0+
* (...) - 1+
* [...] - 0|1
* |...| - один из указанных символов, - - символьный интервал
* ||...|| - кроме указанных символов
* , или ; - или
* \ - экранировать следующий символ
* <name:...> - именованная группа
* <...> или <:...>- скобки

```perl

'' =~ $app->perl->like('%');						# 1
'.png' =~ $app->perl->like('%.png');				# 1
'a/1.png' =~ $app->perl->like('*a/%.png');		  	# 1
'a/x/1.png' =~ $app->perl->like('*a/%.png');		# 

'a1.png' =~ $app->perl->like('a?.png');			 	# 1
'a12.png' =~ $app->perl->like('a?.png');			# 

'a12.png' =~ $app->perl->like('a{\d}.png');		 	# 1
'a.png' =~ $app->perl->like('a{\d}.png');		 	# 1

'a.png' =~ $app->perl->like('a[\d\d].png');		 	# 1
'a1.png' =~ $app->perl->like('a[\d\d].png');		# 
'a12.png' =~ $app->perl->like('a[\d\d].png');		# 1 

'a12.png' =~ $app->perl->like('a(\d\d).png');		# 1 
'a.png' =~ $app->perl->like('a(\d\d).png');			#  
'a123.png' =~ $app->perl->like('a(\d\d).png');		#  
'a1234.png' =~ $app->perl->like('a(\d\d).png');		# 1

'ab.png' =~ $app->perl->like('a|a-z_|.png');		# 1
'a9.png' =~ $app->perl->like('a|a-z_|.png');		# 

'ab.png' =~ $app->perl->like('a||a-z_||.png');		# 
'a9.png' =~ $app->perl->like('a||a-z_||.png');		# 1

'abccda.png' =~ $app->perl->like('{abc;cda}.png');	# 1

'abc.png' =~ $app->perl->like('<:abc,cda>.png');	# 1
'cda.png' =~ $app->perl->like('<abc,cda>.png');		# 1
'abc.png' =~ $app->perl->like('<name:abc,cda>.png') && $+{name};	# abc

'{}.png' =~ $app->perl->like('\{\}.png');			# 1

```

Рекурсия позволяет распознавать вложенные скобки:

```perl

'((123)(2))' =~ $app->perl->like('<bra:\(((||()||),&bra)\)>');			# 1
'((123)(2))' =~ $app->perl->like('<bra:\(((||()||),&{bra})\)>');			# 1

```

Регулярка `like` работает от начала и до конца строки:

```perl

'1' =~ $app->perl->like('1');			# 1
'12' =~ $app->perl->like('1');			# 


