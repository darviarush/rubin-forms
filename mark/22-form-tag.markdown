# Теги в формах

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

$app->man->conf->form;

```

Объявляем переменные:

```perl

my $ret;


```

## Тег label

Вот пример формы с меткой:

```perl

$ret = $app->view->create(q{<% GET
	class SimpleForm inherits RubinForm
		sub fields
			self.add("search" => "line").post(new LabelTag("метка"))
		end
		sub allow* then 1
		sub success*,* then 
	end
	
	new SimpleForm
%>});
	
$ret;		#~ <input id="SimpleForm-search" name="search" value="">\s*<label for="SimpleForm-search">метка:</label>


