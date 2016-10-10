package R::Model::Rowset;
# наборы моделей

use common::sense;
use R::App;

# todo: сделать добавление значений не в юникоде, для других кодировок и binary

our %OP = ("ne"=>"<>", "eq" => "=", "lt"=>"<", "le"=>"<=", "gt"=>">", "ge"=>">=", "like"=>" LIKE ", "ilike"=>" ILIKE ", "between"=>" BETWEEN ", "regexp"=>" REGEXP ", "iregexp" => " IREGEXP ", "startswith" => "+", "endswith" => "-");
our %FN = ("distinct" => "distinct",
"count" => "count", "sum" => "sum", "avg" => "avg", "min"=>"min", "max"=>"max",
"left" => "left", "right" => "right", "mid" => "mid",
"concat" => "concat",
"DAY"=>"day", "MONTH"=>"month", "YEAR"=>"year");


require POSIX;

# конструктор
sub new {
	my $cls = shift;
	my $rowset;
	if(ref $cls) {		# это уже rowset - значит требуется породить row
						# $app->model->user->new(x=>1, y=>2)
		my $row = $cls->ClassRow->new(@_);
		
		# ссылка
		if($cls->{find} && @{$cls->{find}}) {
			my $name = $cls->{find}[0];
			my $val = $cls->{find}[1];
			$row->$name($val);
		}
		
		$row
		
	} else {	# порождаем rowset
		my $self = bless {find=>[]}, $cls;
		#our %ROWSET;
		$app->{q}{_ROWSET}{int $self} = ref $self;
		$self
	}
}

# деструктор
sub DESTROY {
	my ($self) = @_;
	
	#msg1 ":on_green black", "FREE $self";#, ":reset", $self;
	
	#our %ROWSET;
	delete $app->{q}{_ROWSET}{int $self};
}

# возвращает id
sub id {
	my ($self) = @_;
	if(@_>1) {
		die "попытка проапдейтить столбец id";
	} else {
		my $ref = $self->view("id");
		wantarray? @{$ref->_col_ref}: @{$ref->limit(1)->_col_ref};
	}
}

# загружает запись. Если записи нет - устанавливает id в save
sub load {
	my ($self, $id) = shift;
	$self->exists($id) // do {
		my $row = $self->Model(undef);
		$row->{save}{id} = $id;
		$row
	}
}

# добавляет записи в m2m
sub add {
	my $self = shift;	# rowset таблицы в которую добавляют
	
	my $fld = $self->{find}[0];
	die "Для добавления в таблицу используйте insert" if !defined $fld;
	
	my $m2m = $self->Field->{$fld};		# поле из табл. в которую добавляют
	my $ref_val = $self->{find}[1];		# запись таблицы из к-й добавляют
	
	if($m2m->isa("R::Model::Field::Ref")) {	# back и assign ссылки
		my $name = $m2m->name;
		my $cls = $m2m->fieldset->cls_row;
		
		my @add;
		for my $row (@_) {
			$row = (Isa($row, $cls)? $row: $m2m->bean($row))->$name($ref_val);
			
			if(defined $row->{id}) {
				$row->save;
			}
			else {
				push @add, $row;
			}
		}
		
		$m2m->bean->insert(\@add) if @add;
		
		return $self;
	}

	my $ref = $m2m->toRef;
	my $toRef = $ref->name;
	my $toSelf = $m2m->toSelf->name;
	my @add;
	for my $row (@_) { # bean - это запись таблицы m2m
		push @add, $ref->bean(undef)->$toSelf($row)->$toRef($ref_val);
	}
	
	$ref->bean->insert(\@add);
	
	$self
}

# добавляет и возвращает
sub addRet {
	my $self = shift;
	my $m2m = $self->Field->{$self->{find}[0]};
	my $ret = $m2m->{toSelf}{ref}->bean({@_});
	$self->add($ret);
	$ret
}

# удаляет записи из m2m
sub del {
	my $self = shift;	# rowset таблицы в которую добавляют
	
	my $fld = $self->{find}[0];
	die "Для удаления из таблицы используйте erase" if !defined $fld;
	
	my $m2m = $self->Field->{$fld};
	my $ref_val = $self->{find}[1];
	
	if($m2m->isa("R::Model::Field::Ref")) {	# back и assign ссылки
		my $name = $m2m->name;
		$self->find(id=>\@_)->update($name => undef);	# проставляем null
		return $self;
	}

	# удаляем из таблицы m2m
	$m2m->toRef->bean->find( $m2m->toRef->name => $ref_val, $m2m->toSelf->name => \@_ )->erase;
	
	$self
}

# очищает связь m2m
sub clean {
	my ($self) = @_;
	
	my $fld = $self->{find}[0];
	die "Для удаления из таблицы используйте erase" if !defined $fld;
	
	my $m2m = $self->Field->{$fld};
	my $ref_val = $self->{find}[1];
	
	if($m2m->isa("R::Model::Field::Ref")) {	# back и assign ссылки
		my $name = $m2m->name;
		$self->update($name => undef);	# проставляем null
		return $self;
	}
	
	$m2m->toRef->bean->find( $m2m->toRef->name => $ref_val )->erase;
	
	$self
}

# создаёт копию себя заменяя ключи
sub _clone {
	my ($self, @args) = @_;
	my $bean = ref($self)->new;
	%$bean = (%$self, @args);
	wantarray? $bean->_rows: $bean;
}

# добавляет в select distinct
sub distinct {
	my ($self) = @_;
	$self->_clone(distinct => 1)
}

# объединяет несколько запросов через UNION ALL
sub union {
	my $self = shift;
	
	for(@_) {
		die "нельзя объединять запросы разных классов: " . ref($self) . " не " . ref $_ if ref $self ne ref $_;
	}
	
	$self->_clone(union => [ @{$self->{union}}, @_ ]);
}

# выбирает записи. Возвращает массив моделей или копию себя
sub find {
	my ($self, @filters) = @_;
	$self->_clone(find => [@{$self->{find}}, @filters]);
}

# оборачивает существующий find в скобки и добавляет указанный find
sub and {
	my $self = shift;
	my $find = $self->{find};
	$self->_clone(find => [($find && @$find? [@$find]: ()), (@_? [@_]: ())]);
}

# оборачивает существующий find в скобки и добавляет указанный find через OR
sub or {
	my $self = shift;
	my $find = $self->{find};
	$self->_clone(find => [($find && @$find? [@$find]: ()), OR => (@_? [@_]: ())]);
}

# заменяет find
sub replace_find {
	my $self = shift;
	$self->_clone(find => [@_]);
}

# выбирает много столбцов
sub view {
	my ($self, @view) = @_;
	$self->_clone(view => [($self->{view}? @{$self->{view}}: ()), @view]);
}

# заменяет мшуp
sub replace_view {
	my ($self, @view) = @_;
	$self->_clone(view => [@view]);
}

# можно указать выборку как текст
sub select {
	my ($self, $select) = @_;
	$self->_clone(select => $select);
}

# сортировка записей
sub order {
	my ($self, @order) = @_;
	$self->_clone(order => [@order]);
}

# добавление сортировки записей
sub append_order {
	my ($self, @order) = @_;
	$self->_clone(order => [($self->{order}? @{$self->{order}}: ()), @order]);
}

# добавление сортировки записей в начало сортировки
sub prepend_order {
	my ($self, @order) = @_;
	$self->_clone(order => [@order, ($self->{order}? @{$self->{order}}: ())]);
}


# offset
sub offset {
	my ($self, $offset) = @_;
	$self->_clone(offset => $offset);
}

# limit
sub limit {
	my ($self, $limit) = @_;
	$self->_clone(@_==3? (offset => $limit, limit => $_[2]): (limit => $limit));
}

# оборачивает find в скобки
sub wrap_find {
	my ($self) = @_;
	$self->_clone(find => [[@{$self->{find}}]])
}

# оборачивает having в скобки
sub wrap_having {
	my ($self) = @_;
	$self->_clone(having => [[@{$self->{having}}]])
}

# оборачивает aggregate в скобки
sub wrap_aggregate {
	my ($self) = @_;
	$self->_clone(aggregate => [[@{$self->{aggregate}}]])
}


# выборка страницы начиная с 1
sub page_query {
	my ($self, $page, $size) = @_;
	$size //= $self->Fieldset->{paging};
	$self->_clone(offset => ($page-1) * $size, limit => $size);
}

# количество страниц
sub pages_count {
	my ($self, $size) = @_;
	$size //= $self->Fieldset->{paging};
	POSIX::ceil($self->count / $size);
}

# # выборка страницы по limit
# sub page_from_limit {
	# my ($self, $q, $param, $size) = @_;
	
	# $size //= $self->Fieldset->{paging} // 6;
	# $param //= $self->Fieldset->{page_param} // "m";
	
	# my $page = int($q->param($param));
	
	# my @param = (
		# page_param => $param,
		# uri => $q->uri,
		# prev_page => $page-1,
		# next_page => $self->limit(($page) * $size, 1)->select($page+1)->asis,
	# );
	
	# $self->page_query($page, $size)->_clone(@param);
# }

# выборка страницы начиная с id
sub _form_page {
	my ($self, $page, $size) = @_;
	
	$page //= $self->{page};
	
	my @page;
	if(defined $page and @$page) {
		my $order = $self->{order};
		@page = @$page;
		die "размер параметра `".join(", ", @page)."` и сортировки `".join(", ", @$order)."` не совпадают" if @page && @$order != @page;
	}
	
	$size //= $self->{size} // $self->Fieldset->{paging} // $self->Fieldset->meta->{paging} // 20;
	
	$self = $self->{origin} if $self->{origin};
	
	$self->_clone(
		page => [@page],
		size => $size,
		origin => $self,
		offset => 0,		
	);
}

# выбирает по параметру и устанавливает параметр
sub qpage {
	my ($self, $param, $size) = @_;
	#return $self if exists $self->{page_param};
	#return $self->_clone(page_param=>$param) if exists $self->{page};
	$param //= "page";
	$self->_clone(page_param=>$param)->page([$app->perl->array($app->{q}->uriparam($param))], $size);
}

# выборка страницы начиная с id
sub page {
	my $self = shift;
	
	my $order = $self->{order};

	my @order = $order? @$order: do {
		my $order = $self->Fieldset->{ordering} // $self->Fieldset->meta->{ordering};
		$order? @$order: ()
	};
	push @order, "-id" if !@order || $order[$#order] !~ /^-?id$/;
	
	$self->order(@order)->_form_page(@_)->next_page
}

# возвращает запрос для выборки предыдущей части страницы
sub prev_page {
	my ($self) = @_;
	
	my $page = $self->{page};
	
	die "используйте next_page после page" if !$page;
	
	die "prev_page не работает в начале страницы" if !@$page;
	
	my $order = $self->{order};
	
	die "размер параметра `".join(", ", @$page)."` и сортировки `".join(", ", @$order)."` не совпадают" if @$order != @$page;

	my $i = 0;
	my @find = map {
		my $x = $order->[$i++];
		my $op = ($x=~s/^-//? "__gt": "__lt");
		($x . $op => $_)
	} @$page;
	
	my @order = map { my $x=$_; $x=~s/^-//? $x: "-$x" } @$order;

	my $size = $self->{size};
	
	$self->_form_page->and(@find)->order(@order)->limit(0, $size)
}

# возвращает запрос для выборки следующей части страницы
sub next_page {
	my ($self) = @_;
	
	my $page = $self->{page};
	
	die "используйте next_page после page" if !$page;
	
	$self = $self->_form_page;
	
	my $order = $self->{order};
	
	my @find;
	if(@$page) {
	
		die "размер параметра `".join(", ", @$page)."` и сортировки `".join(", ", @$order)."` не совпадают" if @$order != @$page;
	
		my $i = 0;
		@find = map {
			my $x=$order->[$i++];
			my $op = ($x=~s/^-//? "__le": "__ge");
			($x . $op => $_)
		} @$page;

		$self = $self->and(@find);
	}
	
	$self->limit(0, $self->{size})
}

# возвращает [, id предыдущей страницы]
sub is_prev_page {
	my ($self) = @_;

	my $page = $self->{page};
	
	die "используйте is_prev_page после page" if !$page;
	
	return undef if !@$page;

	#return $self->{prev_page_id} if exists $self->{prev_page_id};
	
	my $order = $self->{order};
	my @view = map { my $x=$_; $x=~s/^-//; $x } @$order;

	my $size = $self->{size};
	
	# выбираем страницу назад+1
	my @row = $self->prev_page->limit(0, $size+1)->annotates(@view);
	@row == 0? undef: @row == $size+1? $row[ $order->[$#$order] =~ /^-/? 1: $#row-1 ]: []
}


# сообщает, что есть следующая страница
sub is_next_page {
	my ($self) = @_;
	#return $self->{next_page_id} if exists $self->{next_page_id};
	
	my $page = $self->{page};

	die "используйте is_next_page после page" if !$page;
	
	my $order = $self->{order};

	my @view = map { my $x=$_; $x=~s/^-//; $x } @$order;
	
	my $size = $self->{size};
	
	my ($row) = $self->next_page->limit($size, 1)->annotates(@view);
	$row;
	#$self->{next_page_id} = $row? $row->{id}: undef;
}


# url предыдущей страницы
sub url_prev_page {
	my ($self) = @_;
	$self->_url_page( $self->is_prev_page );
}

# url следующей страницы
sub url_next_page {
	my ($self) = @_;
	$self->_url_page( $self->is_next_page );
}


# формирует url для страниц
sub _url_page {
	my ($self, $id) = @_;

	my $param = $self->{page_param} // "page";
	
	my $uri = $app->{q}{uri}->clone;
	my %x = $uri->query_form;
	
	if($id && @$id) {
		$x{$param} = join ",", @$id;
	} else {
		delete $x{$param};
	}
	$uri->query_form(%x? %x: undef);
	$uri->as_string;
}




# производит полнотектовый поиск, а именно: добавляет в find поисковые условия и параметр relevance, который потом можно добавить в order("Relevance") или в annotate("Relevance") или aggregate("Relevance") или извлечь из rowset и вставить в select: 
sub match {
	my ($self, $phrase) = @_;

	return $self->_clone if $phrase eq "";
	
	my $fieldset = $self->Fieldset;
	my $model = $fieldset->meta->model;
	my $match = $fieldset->{match};
	my ($weight, $tabfields, $lang, $assign) = @$match{qw/weight tabfields lang assign/};
	my $key = "modelWords$lang";
	my $wordset = $app->$key;
	
	#$wordset->phrase();		# в отличие от bind phrase распознаёт язык запросов
	my $word_entry = $wordset->build($phrase);
	
	return $self->_clone if 0 == keys %$word_entry;
	
	# формируем find:
	# 1. получем id слов для поиска
	my $model_words = "_Words_$lang";
	my %words_name = $model->$model_words->find(word => [keys %$word_entry])->annotateby("word"=>"id");
	
	# формируем relevance
	my @relevance;
	# 1. по словам	
	# для этого получим имя колумна word_id
	my $fieldset_assign = $fieldset->meta->fieldset($assign);
	my $bk = $fieldset_assign->field($fieldset->name)->back->name;
	
	push @relevance, map { "${bk}__word=$words_name{$_}, $word_entry->{$_}" } keys %words_name;
	
	# 1. получим id филдов
	my %fields_name = $model->_Fields->find( field => [values %$tabfields] )->annotateby("field", "id");
	# 2. удалим таблицы
	%fields_name = map { /\.([^\.]+)$/; $1 => $fields_name{$_} } keys %fields_name;
	# 3. добавим в релевантность
	push @relevance, map { "${bk}__field=$fields_name{$_}, $weight->{$_}*${bk}__entry" } keys %fields_name;
	
	$self->find("${bk}__word" => [ values %words_name ])->relevance(@relevance)->view("_relevance")->groupby("id")->prepend_order("-_relevance");
}

# добавляет релевантность: столбец, чему равно, вес
sub relevance {
	my $self = shift;
	$self->_clone(relevance => [ @{$self->{relevance}}, @_ ])
}

# основная функция для count, max и др. функций агрегации
sub __FN__ {
	my ($name, $self, $view) = @_;
	
	$self = $self->replace_view("${view}__$name") if $view;
	
	$self->_cache(sub {
		$self->Fieldset->fire("find", $self);
		my ($from, $view, $where) = $self->order->_query($view? (): "$name(*) as $name");
		$self->Fieldset->connect->query($from, $view, $where);
	});
}


# количество записей
sub count {	unshift @_, "count"; goto &__FN__; }
# и так понятно:
sub sum { unshift @_, "sum"; goto &__FN__; }
sub avg { unshift @_, "avg"; goto &__FN__; }
sub max { unshift @_, "max"; goto &__FN__; }
sub min { unshift @_, "min"; goto &__FN__; }


# добавляет group by
sub groupby {
	my ($self, @groupby) = @_;
	$self->_clone(groupby => [@groupby]);
}

# добавляет having
sub having {
	my ($self, @having) = @_;
	$self->_clone(having => [($self->{having}? @{$self->{having}}: ()), @having]);
}

# добавляет группировку одновременно с having
sub aggregate {
	my ($self, @aggregate) = @_;
	$self->_clone(aggregate => [($self->{aggregate}? @{$self->{aggregate}}: ()), @aggregate]);
}


# выдаёт аннотацию - хэш с данными и произвольными полями
sub annotate {
	my $self = shift;
	$self->replace_view(@_)->_all;
}

# возвращает в виде массива, а не хэша
sub annotates {
	my $self = shift;
	$self->replace_view(@_)->_array;
}

# вставить выбранные записи в указанную таблицу
sub into {
	my ($self, $fieldset, @view) = @_;
	if(!ref $fieldset) { $fieldset = $self->Fieldset->meta->exists($fieldset) }
	elsif(Isa $fieldset, "R::Model::Fieldset") {}
	elsif(Isa $fieldset, "R::Model::Rowset") { $fieldset = $fieldset->Fieldset }
	else {die "передан не филдсет: `$fieldset`"}
	
	local $_;
	
	my $view = $self->{view};
	
	@view = @$view if !@view;
	
	die "into: количество полей для записи не равно количеству считываемых: " . join(", ", @view) . " <> " . join(", ", @$view) if @view != @$view;
	
	my @rows;
	for my $row ($self->annotate(@$view)) {
		my $all = {};
		my $i = 0;
		for my $col (@view) {
			$all->{$col} = $row->{ $view->[$i++] };
		}
		push @rows, $all;
	}
	
	$fieldset->model->insert(\@rows);
	
	$self
}

# предназначен для быстрого копирования. Он сбрасывает кэш.
sub deep_into {
	my $self = shift;
	my ($fieldset) = @_;
	
	return $self->into(@_) if $fieldset->on_exists(["insert", "inserted", "save", "saved", "add", "added"]);
	
	my ($fieldset, @view) = @_;
	
	if(!ref $fieldset) { $fieldset = $self->Fieldset->meta->exists($fieldset) }
	elsif(Isa $fieldset, "R::Model::Fieldset") {}
	elsif(Isa $fieldset, "R::Model::Rowset") { $fieldset = $fieldset->Fieldset }
	else {die "передан не филдсет: `$fieldset`"}
	
	my $c = $fieldset->connect;
	my $field = $fieldset->{field};

	my $view = @view? " (" . join(", ", map { $c->word( $field->{$_}{col} ) } @view) . ") ": "";

	my $sql = join "", "INSERT INTO ", $c->word($fieldset->{tab}), $view, $self->query;
	
	$c->do($sql);
	
	$fieldset->{cache}->clear;

	$self
}

# вставить в таблицу группу записей
# записи могут быть: хешами, массивами или объектами этого филдсета. В последнем случае у объектов должна быть установлена save
sub insert {
	my $self = shift;
	
	my $fieldset = $self->Fieldset;
	my $cls = $self->ClassRow;
	
	local $_;
	
	my @add = map {
		ref $_ eq "" || ref $_ eq "HASH"? $self->new($_):
		ref $_ eq "ARRAY"? $self->new(@$_): do {
			die "невозможно сохранить " . ref($_) . " как $cls" if !Isa $_, $cls;
			$_->{save}{id} = $_->{id} if $_->{id};
			$_
		}
	} (@_==1 && ref $_[0] eq "ARRAY"? @{$_[0]}: @_);
	
	#msg1 \@add;
	
	$fieldset->fire("insert", $self, \@add);

	if($fieldset->on_exists(["add", "save"])) {
		for my $add (@add) {
			$fieldset->fire("add", $add);
			$fieldset->fire("save", $add);
		}
	}
	
	# преобразуем поля в rows
	my @fields;
	my %fields;	
	my @rows;
	for my $add (@add) {
		push @rows, my $row = [];
		my $save = $add->{save};
		# если в save оказалось id, то нужно проверить, что оно во всех записях проставилось
		$save->{id} = $add->{id} if defined $add->{id};
		
		while(my ($key, $val) = each %$save) {
			if(!exists $fields{$key}) {
				$row->[ @fields ] = $val;
				$fields{$key} = @fields;
				push @fields, $key;
			} else {
				$row->[ $fields{$key} ] = $val;
			}
		}
	}
	
	my $field = $fieldset->{field};
	@fields = map { $field->{$_}{col} } @fields;
	
	my $c = $fieldset->connect;
	$c->insert($fieldset->tab, \@fields, \@rows);

	if($fieldset->pk->{autoincrement}) {
		my $id = $c->last_id;

		for my $row (@add) {
			$row->{id} = $row->{save}{id} // $id++ if !defined $row->{id};
		}
	}
	
	if($fieldset->on_exists(["added", "saved"])) {
		for my $add (@add) {
			$fieldset->fire("added", $add);
			$fieldset->fire("saved", $add);
		}
	}
	
	for my $add (@add) {
		delete $add->{save};		# часто в insert приходят {}, а не row. Так что их перебирать не стоит
		# delete $add->{val}
		$add->CacheClear;
		$add->AfterSave;
	}
	
	$fieldset->fire("inserted", $self, \@add);
	
	$self
}

# проапдейтить записи
sub update {
	my $self = shift;
	
	my $fieldset = $self->Fieldset;
	
	$fieldset->fire("updates", $self, \@_);
	return $self if $self->{noAction};
	
	my @add = $self->for_update;
	
	if($fieldset->on_exists(["update", "save"])) {
		for my $add (@add) {
			$fieldset->fire("update", $add);
			$fieldset->fire("save", $add);
		}
	}
	
	# формируем set
	
	# my $set = {};
	# my $field = $fieldset->{field};
	# for(my $i=0; $i<@_; $i+=2) {
		# $set->{ $field->{$_[$i]}->col } = $_[$i+1];
	# }
	
	# апдейтим
	my ($from, $view, $where, $set) = $self->order->_query("", [@_]);
	$fieldset->connect->update($from, $set, $where);

	if($fieldset->on_exists(["updated", "saved"])) {
		for my $add (@add) {
			$fieldset->fire("updated", $add);
			$fieldset->fire("saved", $add);
		}
	}
	
	for my $add (@add) {
		delete $add->{save};
		# delete $add->{val}
		$add->CacheClear;
		$add->AfterSave;
	}
	
	$fieldset->fire("updateds", $self, \@_);
	
	$self
}

# быстрый update. Срабатывает, если нет записей
sub deep_update {
	my ($self) = @_;
	
	my $fieldset = $self->Fieldset;
	
	return $self->erase if $fieldset->on_exists(["save", "update", "saved", "updated", "updates", "updateds"]);
	
	my ($from, $view, $where) = $self->order->_query("");
	$fieldset->connect->erase($from, $where);
	
	$fieldset->{cache}->clear;
	
	$self
}

# удалить выбранные записи
sub erase {
	my ($self) = @_;
	my $fieldset = $self->Fieldset;
	
	$fieldset->fire("erases", $self);
	return $self if $self->{noAction};

	my @id = $self->for_update;
	
	if($fieldset->on_exists("erase")) {
		for my $row (@id) {
			$fieldset->fire("erase", $row);
		}
	}
	
	my ($from, $view, $where) = $self->order->_query("");
	$fieldset->connect->erase($from, $where);
	#$c->erase($fieldset->{tab}, {id => \@id}) if @id;
	
	if($fieldset->on_exists("erased")) {
		for my $row (@id) {
			$fieldset->fire("erased", $row);
		}
	}
	
	for my $row (@id) {
		delete $row->{save};
		# delete $row->{val}
		$row->CacheClear;
		$row->AfterSave;
	}
	
	$fieldset->fire("eraseds", $self, \@id);
	
	$self
}

# быстрое удаление
sub deep_erase {
	my ($self) = @_;
	
	my $fieldset = $self->Fieldset;
	
	return $self->erase if $fieldset->on_exists(["erase", "erased", "erases", "eraseds"]);
	
	my ($from, $view, $where) = $self->order->_query("");
	$fieldset->connect->erase($from, $where);
	
	$fieldset->{cache}->clear;
	
	$self
}

# возвращает количество записей изменённых предшествующим insert, into, update, erase, add или del
sub effected_rows {
	my ($self) = @_;
	$self->Fieldset->connect->effected_rows
}

# модифицирует запрос так, чтобы переданный массив совпадал (store ?)
sub merge {
	my ($self) = @_;
	
	todo;
	
	$self
}

# выдать в виде массива
sub rows {
	my ($self) = @_;
	[ $self->_rows ]
}

# если существует - выдаёт первую запись, иначе - undef
sub exists {
	my ($self, $id) = @_;
	$self = $self->find(id => $id) if defined $id;
	my ($exists) = $self->limit(1);
	$exists
}

# возвращает хэш field => row
sub by {
	my $self = shift;
	%{$self->refby(@_)};
}

# как и by, но ссылку на хэш
sub refby {
	my ($self, $field) = @_;
	
	$self = $self->view($field) if !grep { $_ eq $field } @{$self->{view}};
	
	my $ref = {};
	for my $row ( $self->order->_rows) {
		$ref->{ $row->$field } = $row;
	}
	$ref
}

# возвращает хэш field => {annotate}
sub annotateby {
	my $self = shift;
	%{$self->annotaterefby(@_)};
}

# как и annotateby, но ссылку на хэш
sub annotaterefby {
	my $self = shift;
	
	my $ref = {};
	
	if(@_ == 2) {
		my ($field, $key) = @_;
		for my $row ( $self->order->annotate(@_) ) {
			$ref->{ $row->{$field} } = $row->{$key};
		}
	} else {
		my ($field) = @_;
		for my $row ( $self->order->annotate(@_) ) {
			$ref->{ $row->{$field} } = $row;
		}
	}
	$ref
}

# возвращает select-запрос
sub query {
	my ($self) = @_;
	my $c = $self->Fieldset->fire("find", $self)->connect;
	$c->sel($self->_query);
}

# возвращает explain
sub explain {
	my ($self) = @_;
	my $c = $self->Fieldset->connect;
	my $sql = $self->query;
	$c->query_array( "EXPLAIN " . $sql );
}


# возвращает анализ данных
sub analyse {
	my ($self) = @_;
	my $c = $self->Fieldset->connect;
	my $sql = $self->order->query;
	$c->query_array( $sql . " PROCEDURE ANALYSE()" );
}


# устанавливает дефолтный left join (1), а не inner join (undef)
sub lj {
	my ($self) = @_;
	$self->_clone("join" => 1);
}

# устанавливает дефолтный inner join (undef), а не left join (1)
sub ij {
	my ($self) = @_;
	$self->_clone("join" => undef);
}

# возвращает себя как скаляр в любом контексте
sub asis {
	my ($self) = @_;
	$self
}

# создаёт блокировку чтения
sub share {
	my ($self) = @_;
	$self->_clone(append => "LOCK IN SHARE MODE");
}

# создаёт блокировку чтения
sub for_update {
	my ($self) = @_;
	$self->_clone(append => "FOR UPDATE");
}

# кэширует результат
sub cache {
	my ($self, $key, $lifetime) = @_;
	$self->_clone(cache_key => $key, cache_lifetime=>$lifetime)
}

# помечает запрос, как подзапрос в sql-запросе.
# например: ... FROM (SELECT a, b FROM ...) AS A
# или SELECT (SELECT a, b FROM ...) as A
# !!!
# недоделано - надо все поля в view добавить в fieldset, а так же алиас за скобкой заменять на А№, когда таблиц много
# и при срабатывании деструктора - разрушить метаинформацию о таблице!
# пока можно использовать для $query->as("tab")->count
sub as {
	my ($self, $name) = @_;
	
	my $meta = $self->Fieldset->meta;
	my $was = my $fieldset = $meta->exists($name);
	
	die "имя подзапроса `$name` совпадает с именем филдсета" if $fieldset && !$fieldset->{as};
	
	$fieldset //= $meta->fieldset($name);	# создаём филдсет
	
	$fieldset->{tab} = join "", "(", $self->query, ") ", $name;
	
	if(!$was) {		# не будем пересоздавать fieldset если он уже был
	
		$fieldset->{compute} = 1;	# это вычислимый филдсет
		$fieldset->{as} = 1;		# это подзапрос
		
		my $fs = $self->Fieldset;
		
		my $view = $self->{view};
		my @view = $view? @$view: "id";
		
		# копируем поля в новоиспечённый филд
		# проблема с полями через __, там же ещё count, avg могут быть...
		my $fields = $fs->{field};
		for my $fld (@view) {
			my @fld = split /__/, $fld;
			my $field = $fields->{$fld[0]};
			
			# двигаемся по ссылкам, чтобы добыть конечный field и 
			
			if(ref $field eq "R::Model::Field::Ref") {
				$fieldset->ref($field->name => $field->ref->fieldset->name);
			}
			elsif(ref $field eq "R::Model::Field::Col") {
				$fieldset->col($field->name => $field->type);
			}
			elsif(ref $field eq "R::Model::Field::M2m") {
				if(ref $field->back eq "R::Model::Field::M2m") {
					$fieldset->m2m($field->name => $field->toRef->fieldset->name);
				}
				else {
					$fieldset->m2n($field->name => $field->toRef->fieldset->name);
				}
			}
			elsif(ref $field eq "R::Model::Field::M2n") {
				if(ref $field->back eq "R::Model::Field::M2m") {
					$fieldset->n2m($field->name => $field->toRef->fieldset->name);
				}
				else {
					$fieldset->n2n($field->name => $field->toRef->fieldset->name);
				}
			}
			elsif(Isa $field, qw/R::Model::Back/) {		# пропускаем
			}
			else {
				die "не могу определить тип филда $fld[0]=" . ref $field;
			}
			
			
			# if(@fld>1) {
				# # если заканчивается на функцию агрегации, то создать филд с возвращаемым типом функции
				# $fld = pop @fld;
				# if(exists $FN{$fld}) {	
					# # todo - предусмотреть массив функций, с их типом возврата
					# $fieldset->col($fld => "bigint unsigned");
				# } else {
					# my $ref = shift @fld;
					# $ref = $ref->refTo for @fld;
					# $ref->fieldset->{field}{$fld}->cloneto($fieldset);
				# }			
			# } else {
				# $fields->{$fld}->cloneto($fieldset);
			# }
		}
	}
	
	$fieldset->model;
}

######################################################### Выборки #########################################################

# кэширует, если надо
sub _cache {
	my ($self, $sub) = @_;
	scalar(exists $self->{cache_key}? $self->Fieldset->meta->cache->ret($self->{cache_key}, $self->{cache_lifetime}, $sub): $sub->())
}

# возвращает массив массивов
sub _array {
	my ($self, $_view) = @_;
	
	my $ref = $self->_cache(sub {
		$self->Fieldset->fire("find", $self);
		my ($from, $view, $where) = $self->_query($_view);
		$self->Fieldset->connect->query_array($from, $view, $where);
	});
	
	wantarray? @$ref: $ref;
}

# возвращает массив хешей
sub _all {
	my ($self, $_view) = @_;
	
	my $ref = $self->_cache(sub {
		$self->Fieldset->fire("find", $self);
		my ($from, $view, $where) = $self->_query($_view);
		$self->Fieldset->connect->query_all($from, $view, $where);
	});
	
	wantarray? @$ref: $ref;
}

# возвращает массив значений
sub _col_ref {
	my ($self, $_view) = @_;
	my $ref = $self->_cache(sub {
		$self->Fieldset->fire("find", $self);
		my ($from, $view, $where) = $self->_query($_view);
		$self->Fieldset->connect->query_col($from, $view, $where);
	});
	wantarray? @$ref: $ref;
}

# возвращает beans
sub _rows {
	my ($self) = @_;
	my $cls = $self->ClassRow;
	if(exists $self->{view}) {
		# добавляем id, если нет id в view
		$self = $self->view("id") unless grep { $_ eq "id" } @{$self->{view}};
		# все столбцы добавляем в row.val
		
		my @rows;
		
		# только id
		if( 1==@{$self->{view}} ) {
			for my $id ($self->_col_ref) {
				push @rows, $cls->new($id);
			}		
		}
		else {
			for my $all ($self->_all) {
				my $row = $cls->new($all->{id});
				$row->CacheUpdate($all);
				$row->{val} = $all;
				push @rows, $row;
			}
		}

		@rows
	} else {
		map {$cls->new($_)} $self->_col_ref;
	}
	
}



# обходит структуру
my %_bypass;
sub _bypass {
	my ($node, $list, $context) = @_;
	
	my $default_join = $context->{default_join};	# left или inner
	my $leaf_key = $context->{leaf_key};			# .select, .where и т.д.
	
	if(exists $node->{join}) {				# меняем join
		$default_join = $node->{join};
	}
	
	# формируем ключи
	KeysFor:
	for(my $i=0; $i<@$list; $i+=2) {
		my ($keys, $val) = @$list[$i, $i+1];	# получаем пару, например, из find(id=>2)
		
		#msg1 $keys, "$val", $leaf_key;
		
		if(ref $keys eq "ARRAY") {				# скобки: find(id=>2, [id=>3, OR__id=>4])
			push @{$_bypass{$leaf_key}}, "(";
			$context = {%$context, default_join=>$default_join} if $context->{default_join} != $default_join;
			_bypass($node, $keys, $context);	# рекурсивно обрабатываем всё что есть в скобках
			push @{$_bypass{$leaf_key}}, ")";
			$i--;
			next;
		}

		# преобразуем ключ
		my $field = undef;
		my $key_field = undef;
		my $lj = $default_join;		# left join
		my $next_lj = $default_join;	# для m2m
		my $op = undef;
		my $fn_fld = undef;	# функции оборачивающие филд
		my $fn_val = undef;	# функции оборачивающие значение
		my $col_val = undef; # значение столбца - столбец
		my @keys = split /__/, $keys;
		for(my $j=0; $j<@keys; $j++) {	# бежим по частям ключа, разделённым __
			my $key = $keys[$j];
			
			if($op) {
				die "значение колумна должно быть всегда 1 `$keys`" if ref $val || $val ne 1;
				$col_val = join "__", @keys[$j..$#keys];
				last;
			}
			elsif(exists $OP{$key}) {
				$op = $OP{$key};
			}
			elsif(exists $FN{$key}) {
				my $fn = $FN{$key};
				if(defined $op) { push @$fn_val, [$fn]; } else { push @$fn_fld, [$fn]; }
			}
			elsif($key =~ /^\d+$/) {
				if($fn_val) { push @{$fn_val->[$#$fn_val]}, $key }
				elsif($fn_fld) { push @{$fn_fld->[$#$fn_fld]}, $key }
				else { $key_field .= "/$key" }
			}
			elsif(defined $field) {	# есть филд - формируем продолжение и выходим
				$val = $field->bean->find(join("__", ($next_lj && !$default_join? "lj": !$next_lj && $default_join? "ij": ()), @keys[$j..$#keys]) => $val);
				$next_lj = $default_join;
				last;
			}
			elsif($key eq "lj") {
				$lj = 1;
			}
			elsif($key eq "ij") {
				$lj = undef;
			}
			elsif($key eq "OR") {
				die "OR можно применять только в find, having или aggregate" if $leaf_key !~ /^\.(?:where|having|aggregate)$/;
				push @{$_bypass{$leaf_key}}, " OR ";
			}
			elsif($key eq "_relevance") {
				$key_field = "_relevance";
				# получить конструктором - нельзя, т.к. он зарегистрирует поле в таблице. А оно нам надо?
				$field = bless { name => "_relevance" }, "R::Model::Field::Col";
			}
			else {	# это филд
				$field = $node->Field->{$key};
				die "Поля ". $node->Fieldset->{name} .".$key нет для $leaf_key" unless $field;
				
				if($field->isa("R::Model::Field::M2m")) {
					splice @keys, $j+1, 0, $field->toRef->name;
					$field = $field->toSelf->back;
					$next_lj = $lj;
				}
				elsif($field->isa("R::Model::Field::Compute")) {
					if($leaf_key =~ /\.(?:(select)|order|groupby|(set|where|having))/) {
						# превращаем view(x__compute__y => "x__compute__y") в x__col1__y => 1, x__col2__y => 1 ...
						# а val order и groypby оставляем без изменений
						# для where, having и set устанавливаем val в значения, полученные из 
						my $this_is_select = defined $1;
						my $this_is_set = defined $2;
						if($this_is_set) {
							todo;
							#$field->bean()->
						}
						
						my @newlist = ();
						for my $rel (@{$field->{rel}}) {
							@keys[$j] = $rel;
							my $key = join("__", @keys);
							push @newlist, $key, $this_is_select? $key: $val;
						}
						
						splice @$list, $i, 2, @newlist;
						
						redo KeysFor;
					} else {
						die "столбец compute($field->{name}) в $leaf_key";
					}
				}
				
				$key_field = $field->{name};
			}
		}
		
		my $leaf;
		
		# поле уже есть
		if(exists $node->{$key_field}) {
			$leaf = $node->{$key_field};
			die "left join vs inner join" if $leaf->{"#lj"} && !$lj;
			die "inner join vs left join" if !$leaf->{"#lj"} && $lj;
		}
		else {
			
			if($field->can("refTo")) {	# это ссылка - получаем по ней новый rowset
				$leaf = $field->refTo->bean;
				%$leaf = ();
			} else {	# а это просто col или compute
				$leaf = {};
			}
			
			$leaf->{"#fld"} = $field->{name};
			$leaf->{"#lj"} = 1 if $lj;
			$node->{$key_field} = $leaf;
		}
		
		if(Isa $val, "R::Model::Rowset") {
			die "определять опрератор для связи - нельзя" if $op;
			die "определять функцию для связи - нельзя" if $fn_fld || $fn_val;
			$context = {%$context, default_join=>$default_join} if $context->{default_join} != $default_join;
			_bypass($leaf, $val->{find}, $context);
		} else {
		
			# ->toCol вызывается в connect->quote
			if($field->{check} && $leaf_key !~ /\.(?:select|order|groupby|relevance)/) {

				if(ref $val eq "ARRAY") {
					$val = [@$val];			# копируем чтобы:
					for my $v (@$val) {		# внешний массив не модифицируется
						my $e = $field->checking($v);
						die $e if defined $e;
					}
				} else {
					my $e = $field->checking($val);
					die "$field->{model}.$field->{name}: $e" if defined $e;
				}
			}
		
			my $bypass = {
				(defined($op)? (op => $op): ()),
				(defined($val)? (val => $val): ()),
				($fn_fld? (fn_fld => $fn_fld): ()),
				($fn_val? (fn_val => $fn_val): ()),
				($col_val? ("attach" => 1): ())
			};
			
			push @{$leaf->{$leaf_key}}, $bypass;
			push @{$_bypass{$leaf_key}}, $bypass;
			
			if(defined $col_val) {
				$context = {%$context, default_join=>$default_join} if $context->{default_join} != $default_join;
				_bypass($context->{"root"}, [$col_val=>1], $context);
			}
			
		}
	}
	
}

# возвращает "сырой" sql-запрос
sub _query {
	my ($self, $view, $set) = @_;
	
	my $fieldset = $self->Fieldset;
	
	# можно изменить запрос через обработчик события
	$fieldset->fire("query", $self, $view, $set);
	
	
	# очищаем bypass
	%_bypass = ();
	local ($a, $b, $_);
	
	$view //= $self->{"select"};
	#msg ":red", $self, $view;
	
	if(my $aggregate = $self->{aggregate}) {
		todo;	# проблема: having и groupby должен быть ниже, чтобы выполнилась функция bypass
	
		use List::Util qw/pairmap/;
		push @{$_bypass{".groupby"}}, pairmap { ($a => undef) } @$aggregate;
		push @{$_bypass{".having"}}, @$aggregate;
	}
	
	# создаём корень дерева
	my $root = ref($self)->new;
	%$root = ();
	
	#use Scalar::Util qw/weaken/;
	#weaken $root;
	
	
	my $context = { default_join => (exists $self->{join}? $self->{join}: 1), root => $root };
	
	#$context->{leaf_key} = ".aggregate", _bypass($root, $self->{aggregate}, $context) if $self->{aggregate};
	
	# _bypass построит дерево. Листам дерева будут присвоены ключи
	$context->{leaf_key} = ".set", _bypass($root, $set, $context) if $set;
	$context->{leaf_key} = ".select", _bypass($root, [map {($_ => $_)} @{$self->{view}}], $context) if !$view && $self->{view};
	$context->{leaf_key} = ".where", _bypass($root, $self->{find}, $context) if $self->{find};
	$context->{leaf_key} = ".groupby", _bypass($root, [map {$_ => undef} @{$self->{groupby}}], $context) if $self->{groupby};
	$context->{leaf_key} = ".having", _bypass($root, $self->{having}, $context) if $self->{having};
	my $order = $self->{order} // $self->Fieldset->{ordering};
	my $list = [map { my $x=$_; my $desc = $x=~s/^-//; ($x => $desc)} @$order];
	$context->{leaf_key} = ".order";
	_bypass($root, $list, $context);
	
	my $relevance;
	my $relevance_leaf;
	if( $self->{relevance} ) {
		$relevance = join "+", map { "if($_, 0)" } @{$self->{relevance}};
		my $field = {};
		while($relevance =~ /([a-z_]+\w*)(\(?)/ig) {
			$field->{$1}++ if !$2;
		}

		$context->{leaf_key} = ".relevance";
		_bypass($root, [map {($_ => $_)} keys %$field], $context);
	}
	
	# контекст удерживает root - очищаем
	%$context = ();
	
	my $c = $fieldset->connect;
	
	# обходим дерево и строим sql-запрос, оптимизируя его
	my @from;
	my $root_id = $root->Field->{"id"};
	my $root_col = $c->word($root_id->col);
	my $Asc = 1;
	$root->{"#from"} = $c->word($root_id->tab) . " A$Asc";
	$root->{"#As"} = "A$Asc";
	$root->{"#Id"} = ["A$Asc", $root_col];
	
	# оптимизация на root не имеет филдов, тогда и таблицу можно не подключать
	do {
		my $psevdo_root = $root;
		my @node = $root;
		my(@col, @ref);
		while(my ($key, $leaf) = each %$root) { # определяем связи
			if(Isa $leaf, "R::Model::Rowset") {	push @ref, $leaf; }
			elsif(ref $leaf eq "HASH") { push @col, $leaf }
		}
		
		if(@col == 0 && @ref==1) {
			my $leaf = $ref[0];
			my $fld = $root->Field->{ $leaf->{"#fld"} };
			if($fld->isa("R::Model::Field::Back") ) {
				@node = $leaf;
				$psevdo_root = $leaf;
				$leaf->{"#from"} = $c->word($fld->ref->tab) . " A$Asc";
				$leaf->{"#As"} = "A$Asc";
				$leaf->{"#Id"} = ["A$Asc", $c->word($fld->ref->fieldset->{field}{id}->col)];
				$root->{"#Id"} = ["A$Asc", $fld->ref->col];
			}
		}
			
		# шаримся в leaf в поисках .select, .where, etc и строим связи запроса
		my $_build_col = sub {
			my ($leaf, $col) = @_;
			
			while(my ($key, $val) = each %$leaf) {
				if($key =~ /^\./) {
					$_->{col} = $col for @$val;
				}
			}
		};
		
		while(@node) {
			my $node = pop @node;
			my $As = $node->{"#As"};
			my (@ref, @back, @col);
			while(my ($key, $leaf) = each %$node) { # определяем связи
				if(ref $leaf eq "HASH") { push @col, $leaf }
				elsif(Isa $leaf, "R::Model::Rowset") {
					push @node, $leaf;
					my $fld = $node->Field->{ $leaf->{"#fld"} };
					if( $fld->isa( "R::Model::Field::Ref" ) ) { push @ref, $leaf }
					else { push @back, $leaf }
				}
			}

			# оптимизация - если в подчинённой таблице только id
			if(@ref == 0 && @back == 0 && @col == 1 && $node != $psevdo_root && $col[0]->{"#fld"} eq "id") {
				$_build_col->($col[0], $node->{"#Id"});
				next;
			}
			
			# >1 || @col==1 && $node != $psevdo_root && $col[0]->{"#fld"} ne "id"
			#  && !(@col == 1 && $node != $psevdo_root && $col[0]->{"#fld"} eq "id")
			if(@ref || $node == $psevdo_root || @col) {
				push @from, $node->{"#from"} if $node->{"#from"};
			}
					
			if(@ref || @back) {
			
				my $Id = join ".", @{$node->{"#Id"}};
				
				for my $leaf (@ref, @back) {		# строим join
					my ($col);
					my $fld = $node->Field->{ $leaf->{"#fld"} };
					my $type = $leaf->{"#lj"}? "LEFT": "INNER";
					$Asc++;
					my $leafAs = $leaf->{"#As"} = "A$Asc";

					if( $fld->isa( "R::Model::Field::Back" ) ) {
						#$leaf->{"#from"} (?)
						push @from, "$type JOIN " . $c->word($fld->ref->tab) . " $leafAs ON $leafAs." . $c->word($fld->ref->col) . "=$Id";
						$leaf->{"#Id"} = $col = [$leafAs, $c->word($fld->ref->fieldset->{field}{id}->col)];
					}
					elsif( $fld->isa( "R::Model::Field::Ref" ) ) {
						$leaf->{"#from"} = "$type JOIN " . $c->word($fld->ref->tab) . " $leafAs ON $As." . $c->word($fld->col) . "=$leafAs." . $fld->ref->col;
						$leaf->{"#Id"} = $col = [$As, $c->word($fld->col)];
					}
					else {
						die "Неизвестный столбец без ссылки";
					}
					
					$_build_col->($leaf, $col);
				}
			}
			
			# проставляем столбцы (col) листьям дерева
			for my $leaf (@col) {
			
				# оппа - релевантность!
				if($leaf->{"#fld"} eq "_relevance") {
					die "для использования _relevance её нужно добавить в запрос методом relevance" if !defined $relevance;
					$relevance_leaf = $leaf;
					next;
				}
			
				my $fld = $node->Field->{ $leaf->{"#fld"} };
				my $col = [$As, $c->word($fld->col)];
				$_build_col->($leaf, $col);
			}
			
			# типовая ситуация - у ноды нет колумнов, кроме, разве что id, тогда вместо id берём ссылку на неё из верхнего колумна. И from на неё не делаем
			# if(!@col || @col == 1 && $node->{id}) {
			# }
			
		}
	};
	
	# если нет @from
	@from = $root->{"#from"} if !@from;

	# пошли
	my ($sep, $column);
	if(@from==1) {
		$from[0] =~ s/ A\d+$//;
		$sep = " ";
		$column = sub {$_->{col}->[1]};
	} else {
		$sep = "\n";
		$column = sub {join ".", @{$_->{col}}};
	}

	
	# релевантность
	if(defined $relevance) {
		my $flds = $_bypass{".relevance"};
		my %flds = map {( $_->{val} => $column->() )} @$flds;
		$relevance =~ s/([a-z_]\w*)(\(?)/ $2? $1.$2: $flds{$1} /ige;
	}
	
	# и релевантность - используется!
	if($relevance_leaf) {
		my $relevance_sum = [$_bypass{".groupby"}? "sum($relevance)": $relevance];
		
		if( my $val = $relevance_leaf->{".select"} ) {
			$_->{col} = $relevance_sum for @$val;
			$relevance_sum = ["_relevance"];
		}
		
		if( my $val = $relevance_leaf->{".where"} ) {
			$_->{col} = [$relevance] for @$val;
		}
		
		if( my $val = $relevance_leaf->{".groupby"} ) {
			$_->{col} = [$relevance] for @$val;
		}
		
		if( my $val = $relevance_leaf->{".having"} ) {
			$_->{col} = $relevance_sum for @$val;
		}
		
		if( my $val = $relevance_leaf->{".order"} ) {
			$_->{col} = $relevance_sum for @$val;
		}
	}
	
	if(defined $view) {
	}
	elsif(my $select = $_bypass{".select"}) {
		$view = join ", ", map {
			my $col=$_->{col}[1];
			my $val = $c->word($_->{val});
			my $ret = $column->();
			if(my $fn_fld = $_->{fn_fld}) {
				for my $fn (@$fn_fld) {
					my $name = shift @$fn;
					$ret = "$name(". join(", ", $ret, @$fn) .")"
				}
			}
			
			$ret .= " AS $val" if $val ne $col;
			$ret
		} @$select;
	} else {
		$view = (@from==1? $root->{"#Id"}[1]: join(".", @{$root->{"#Id"}})) . ($root->{"#Id"}[1] ne "id"? " AS id": "");
	}
	
	if($set) {
		$set = $_bypass{".set"};
		$set = $set? $self->__filter($set, $column, ", "): "";
	}
	
	my $where = $_bypass{".where"};
	$where = $where? $self->__filter($where, $column): "";
	
	if(my $groupby = $_bypass{".groupby"}) {
		$where .= "${sep}GROUP BY " . join ", ", map { $column->() } @$groupby;
	}
	if(my $having = $_bypass{".having"}) {
		$where .= "${sep}HAVING " . $self->__filter($having, $column);
	}
	if(my $order = $_bypass{".order"}) {
	
		$where .= "${sep}ORDER BY " . join ", ", map {
			my $desc = $_->{val};
			$column->() . ($desc? " DESC": "");
		} @$order;
		#$where .= ", _relevance DESC" if $relevance;
	}
	#elsif($relevance) {
	#	$where .= "${sep}ORDER BY _relevance DESC";
	#}
	
	$where = join $sep, $where, join "", "LIMIT ", ($self->{offset}? (0+$self->{offset}, ", "): ""), (0+$self->{limit}) if $self->{limit};
	
	
	$where = undef if $where eq "";
	
	if($self->{distinct}) {
		$view = "DISTINCT $view";
	}
	
	my $union = $self->{union};
	if($union && @$union) {
		my $main = $c->sel(\@from, $view, $where);
		my @main = (
			view => $self->{view},
			select => $self->{select},
			distinct => $self->{distinct},
		);
		return join "", "(", join( ") UNION ALL (", $main, map { $_->_clone(@main)->query } @$union), ")";
	}
	
	# очищаем bypass
	%_bypass = ();
	
	return \@from, $view, $where, $set;
}

# создаёт фильтр для where и having
sub __filter {
	my ($self, $where, $column, $SEP) = @_;
	local ($a, $b);
	my @out;
	for(my $i=0; $i<@$where; $i++) {
		($a, $b) = @$where[$i, $i+1];
		
		if(ref $a and ref $b and $a->{"attach"}) {
			my $x = $self->_filter($a, $column);
			my $y = $self->_filter($b, $column);
			$x =~ s/1$//;
			$y =~ s/=1$//;
			push @out, $x, $y;
			$i++;
			last unless $b = $where->[$i+1];
		} else {
			push @out, ref $a? $self->_filter($a, $column): $a;
		}
		
		
		if(
			ref $a and ref $b
			or !ref $a and $a eq ")" and ref $b
			or !ref $a and $a eq ")" and !ref $b and $b eq "("
			or ref $a and !ref $b and $b eq "("
		) {
			push @out, $SEP // " AND ";
		}

		if($i == @$where-1) {
			push @out, ref $b? _filter($a, $column): $b;
		}
		
	}

	join "", @out;
}

# фильтр для одного ключа-значения
sub _filter {
	my $self = shift;
	$_ = shift;
	my $column = shift;

	my $fieldset = $self->Fieldset;
	my $c = $fieldset->connect;
	
	my $fild = $column->();
	my $op = $_->{op} // "=";
	my $val = $_->{val};
	
	$val = $val->id if Isa $val, "R::Model::Row";
	
	if(!defined $val) {
		$op = $op eq "="? " IS ": " IS NOT ";
		$val = "NULL";
	}
	elsif(ref $val eq "ARRAY" and $op eq " BETWEEN ") {
		$val = $c->quote($val->[0]) . " AND " . $c->quote($val->[1]);
	}
	elsif(ref $val eq "ARRAY") {
		$op = " IN ";
		$val = $c->quote($val);
	}
	elsif($op =~ /^[+-]$/) {
		$val =~ s/[_%]/\\$&/g;
		if($op eq "-") { $val = "%$val" } else { $val .= "%" }
		$val = $c->quote($val);
		$op = " LIKE ";
	}
	else {
		$val = $c->quote($val);
	}
	
	my $fn1 = $_->{fn_fld};
	if($fn1) {
		for my $fn (@$fn1) {
			my $name = shift @$fn;
			$fild = "$name(" . join(",", $fild, @$fn) . ")";
		}
	}

	my $fn2 = $_->{fn_val};
	if($fn2) {
		for my $fn (@$fn2) {
			my $name = shift @$fn;
			$val = "$name(" . join(",", $val, @$fn) . ")";
		}
	}
	
	join "", $fild, $op, $val;
}





1;