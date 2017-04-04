# Поля ввода в формах

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1/;

```

Зададим конфигурацию:

```perl

$app->man->configure->form;

my $ret;



```

## Атрибуты

У большинства инпутов есть `placeholder`.

```perl

$ret = $app->view->create(q{<% GET
	class PlaceholderExample inherits RubinForm
		sub fields
			self.add("question" => "line").placeholder("Ну как?")
		end
		sub allow* then 1
		sub success*,* then 
	end
	
	new PlaceholderExample
%>});


$ret;		#~ Ну как?



```

## Checkbox

```perl

$app->q->action("/");

$ret = $app->view->create(q{
<% GET
	class CheckboxExample inherits RubinForm
		sub fields
			self.add("is1" => "checkbox").checked
			self.add("is2" => "checkbox")
		end
		sub allow* then 1
		sub success*, param then self.addErrors("что бы не было дефолтных параметров в view")
	end
	
	new CheckboxExample
%>});


$ret;		#~ <input type=checkbox id="CheckboxExample-is1" name="is1" value="1" checked>

$ret;		#~ <input type=checkbox id="CheckboxExample-is2" name="is2" value="1">


$app->q->action("/", {'@action' => "/checkbox/example", is2 => "on"});

$ret = $app->view->create(q{<% GET	
	new CheckboxExample
%>});

$ret;		#~ <input type=checkbox id="CheckboxExample-is1" name="is1" value="1">

$ret;		#~ <input type=checkbox id="CheckboxExample-is2" name="is2" value="1" checked>


```

## select

У метаинпута `select` есть метод `options`:

```perl

$ret = $app->view->create(q{<% GET
	class SelectExample inherits RubinForm
		sub fields
			self.add("question" => "select").options([1=>"hi!", 2=>"no!"], [2])
		end
		sub allow* then 1
		sub success*,* then 
	end
	
	new SelectExample
%>});


$ret;		#~ <option value="1">hi!<option value="2" selected>no!


```

### Опции SelectInput и наследуемых от него

Опции могут быть не только указыны при описании инпута, но и в филде модели.

#### Тип enum

Если филд модели типа `enum`:

```perl

$app->meta->fieldset("enumexam")->
	col(gender => 'enum(man,woman,neuter)')->default("neuter")->
	col(sex => 'enum(man,woman,neuter)')->null->
sync;


$ret = $app->view->create(q{<% GET
	object EnumExam inherits RubinForm
		sub fields
			self.add(":enumexam").allow
			self.add(":enumexam.gender")
			self.add(":enumexam.sex")
		end
		sub allow* then 1
		sub success*,* then 
	end
%>});

```

`default` модели устанавливается в `default` филда:

```perl

$ret;		#~ <option value="2" selected>neuter

```

Прибавляется "нулевая" опция, если поле имеет `null`:

```perl

$ret;		#~ <option value="" selected>


```

#### Ссылка

Если филд модели ссылка (`ref`, `m2m` или `n2m`), то будут выбираться все значения из связанной таблицы:

```perl

$app->meta->fieldset("gender")->
	col("name" => "string")->
sync;

$app->model->gender->insert({name => "man"}, {name => "woman"}, {name => "neuter"});

$app->meta->fieldset("refexam")->
	ref('gender')->default(3)->
	ref(sex => 'gender')->
	n2m(sexual => 'gender' => 'genders')->
	m2m(sexuals => 'gender' => 'unigen')->
end;

# нужно синхронизировать n2m и m2m - sync на таблице не сработает.
$app->meta->sync;

$ret = $app->view->create(q{<% GET
	class SelectRefExample inherits RubinForm
		sub fields
			self.add(":refexam").allow
			self.add(":refexam.gender")
			self.add(":refexam.sex")
			#self.add(":refexam.sexual")
			#self.add(":refexam.sexuals")
		end
		sub allow* then 1
		sub success*,* then 
	end
	
	new SelectRefExample
%>});


$ret;		#~ <option value="3" selected>neuter
$ret;		#~ <option value="" selected>


```

#### refset

Если филд модели ссылка и надо ограничить набор значений, то используйте `refset`:

