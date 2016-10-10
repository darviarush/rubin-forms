package R::Model::Row;
# наследный класс для моделей. Представляет запись

use common::sense;
use R::App;

# операторы возвращающие строку
#use overload '""' => sub { overload::StrVal($_[0])  };

# операторы возвращающие число
#use overload '0+' => sub { $_[0]->id // 0 };

#use overload '=' => sub { msg ":on_yellow black", "XXX", "$_[0]", ":reset", "REFCNT", $app->perl->refcnt($_[0]); $_[0] };

# конструктор
# app->model->модель или model->m2m->new или model->back->new
sub new {

	my $cls = shift;
	$cls = ref $cls || $cls;
	my $self = bless {id => undef}, $cls;
	
	if(@_==1) {
		my $id = shift;
		if(ref $id) {
			if(Isa $id, $cls) {			# row
				$self->{id} = $id->id;
			} else {					# hash
				$self->update($id);
			}
		} else {						# scalar
			$self->{id} = $id;
		}
	}
	else {
		$self->update(@_);
	}
	
	#our %ROW;
	$app->{q}{_ROW}{int $self} = ref $self;
	
	#msg1 ":on_cyan black", "$self", ":reset", $self, $app->raise->tracex;
	#msg1 ":on_cyan black", "$self";
	$self
}

# деструктор
sub DESTROY {
	my ($self) = @_;
	
	delete $app->{q}{_ROW}{int $self};
	
	$self->save if $self->{save};
	#msg1 ":on_green black", "FREE $self";#, ":reset", $self;
	
	#our %ROW;
	
}

# # помощник
# sub FromHash {
	# my ($self, $hash) = @_;
	# $self->{save} //= {};
	# while(my($k, $v) = each %$hash) {
		# $self->$k($v);
	# }
	# $self
# }

# добавляет элементы
sub update {
	my $self = shift;
	
	$self->{save} //= {};
	
	if(@_==1) {
		my $update = shift;
		
		if(ref $update ne "HASH") {
			my $cls = ref $self;
			die "Нельзя ". ref($update) ." обратить в модель $cls" if !Isa $update, ref $self;
			return $self if !$self->{save};
			$update = $self->{save};
		}
		
		while(my ($k, $v) = each %$update) { $self->$k($v) }
		
		return $self;
	}
	
	for(my $i=0; $i<@_; $i+=2) {
		my ($k, $v) = @_[$i, $i+1];
		$self->$k($v);
	}
	$self
}

# обновляет запись, если есть id
sub touch {
	my ($self) = @_;
	if(defined $self->{id}) {
		$self->{save} = {};
		$self->save;
	}
	$self
}

# возвращает/устанавливает идентификатор
sub id {
	my ($self, $val) = @_;
	if(@_>1) {
		if(defined $self->{id} and $val ne $self->{id}) {
			die "попытка изменить id"; # нужно при изменении id изменить id во всех ссылающихся на него
			$self->{save}{id} = $val;
			#$self->save;
		} else {
			$self->{id} = $val;
		}
		$self
	}
	else { $self->save if !$self->{id} && $self->{save}; $self->{id} }
}

# добавляет поля, которые должны запроситься при первом запросе
# compute-поля отбрасываются
# если compute-поле зависит от другого поля - устанавливается и другое поле
sub view {
	my ($self, @view) = @_;
	my $field = $self->Field;
	$self->{view} = [@{$self->{view}}, grep { !$field->{$_}->compute } map { my $fld=$field->{$_}; $fld->{rel}? @{$fld->{rel}}: $_ } @view];
	$self
}

# возвращает хэш с указанными полями. Поля могут быть любыми - так же и вычисляемыми
sub annotate {
	my ($self, @fields) = @_;
	my ($res) = $self->Model->find(id=>$self)->order->annotate(@fields);
	$res
}

# сохраняет в указанный идентификатор
sub saveAs {
	my ($self, $id) = @_;
	$self->{id} = undef;
	$self->{save}{id} = $id;
	$self->save;
}

# сохраняет, если есть что
sub save {
	my ($self) = @_;
	
	my $save = $self->{save};
	return $self if !$save;
	
	my $id = $self->{id};


	if(defined $id) {
		
		my $fieldset = $self->Fieldset;
		my $c = $fieldset->connect;
		$fieldset->fire("update", $self);
		$fieldset->fire("save", $self);
		$self->{noAction} = undef, return $self if $self->{noAction};
	
		my ($tab, $s) = $self->ToCol;
		$c->update($tab, $s, { "id" => $id });
		$self->{id} = $id if $id = $s->{id};
		$fieldset->fire("updated", $self);
		$fieldset->fire("saved", $self);
		
	} else {
		my $fieldset = $self->Fieldset;
		$fieldset->fire("add", $self, 1);
		$fieldset->fire("save", $self, 1);
		$self->{noAction} = undef, return $self if $self->{noAction};
		if(my $if_add = $self->{if_add}) {
			while(my ($key, $val) = each %$if_add) {
				$self->{save}{$key} = $val;
			}
		}
		my ($tab, $s) = $self->ToCol(1);
		my $c = $fieldset->connect;
		#msg1 "".$app->raise->trace;
		$c->add($tab, $s);
		$self->{id} = $save->{id} // $c->last_id;
		$fieldset->fire("added", $self, 1);
		$fieldset->fire("saved", $self, 1);
	}
	
	$self->AfterSave
}

# очищает save после сохранения
sub AfterSave {
	my ($self) = @_;
	
	my $save = delete $self->{save};	# удаляем - раз мы сохраняемся, а то ещё повторно придётся
	
	# данные сохранились, перебрасываем в val из save
	while(my ($k, $v) = each %$save) {
		# проверяем, что v - не массив, т.е. не оператор
		if(ref $v) {
			delete $self->{val}{$k};
			$self->CacheDel( $k );
		}
		else {
			$self->{val}{$k} = $v;
			$self->CacheSet( $k, $v );
		}
	}
	
	if(defined( my $id = $self->{id} ) && defined( my $rel = $self->{rel} )) {
		$rel->{save}{$self->{ref}} = $id if $rel->{id} ne $id;
	}
	
	$self
}

# сохраняет - смотрит, есть ли с таким id запись и обязательно сохраняет, даже если нет $self->{save}
sub store {
	my ($self) = @_;
	
	if(my $id = $self->{id} // $self->{save}{id}) {
		unless($self->Fieldset->connect->query($self->Fieldset->{tab}, "1", {id=>$id})) {
			# нет записи с таким id
			$self->{save}{id} = $id;
			$self->{id} = undef;
		} else {
			# есть запись с таким id
			$self->{id} //= $self->{save}{id};
			delete $self->{save}{id};
			delete($self->{save}), return $self if !int %{$self->{save}};
		}
	}
	
	$self->save;
}

# формирует ключ кеша
sub CacheKey {
	my ($self, $fld) = @_;
	$fld = $self->Field->{$fld};
	#pack "", $self->{id}, int $fld;
	#join "", $self->{id}, "\f", int $fld
	my $fieldset = $fld->fieldset;
	join "-", $fieldset->meta->name, $fieldset->name, $fld->name;
}

# устанавливает
sub CacheSet {
	my ($self, $k, $v) = @_;
	return $self if !defined $self->{id};
	$self->Fieldset->{meta}{cache}->set($self->CacheKey($k), $v);
	$self
}

# возвращает
sub CacheGet {
	my ($self, $k) = @_;
	return if !defined $self->{id};
	$self->Fieldset->{meta}{cache}->get($self->CacheKey($k));
}

# проверяет
sub CacheExists {
	my ($self, $k) = @_;
	return if !defined $self->{id};
	$self->Fieldset->{meta}{cache}->exists($self->CacheKey($k));
}

# удаляет
sub CacheDel {
	my ($self, $k) = @_;
	return if !defined $self->{id};
	$self->Fieldset->{meta}{cache}->del($self->CacheKey($k));
}

# удаляет запись
sub CacheClear {
	my ($self) = @_;
	return if !defined $self->{id};
	my $cache = $self->Fieldset->{meta}{cache};
	for my $k (keys %{$self->Field}) {
		$cache->del($self->CacheKey($k));
	}
	$self
}

# апдейтит записи
sub CacheUpdate {
	my ($self, $all) = @_;
	while(my ($k, $v) = each %$all) {
		$self->CacheSet($k, $v);
	}
	$self
}

#die "кэш имеет" if $app->ini->{model}{cache} !~ /^cache|val|$/;

#*CacheSet=sub { $_[0]->{val}{$_[1]} = $_[2] },
#*CacheGet=sub { $_[0]->{val}{$_[1]} },
#*CacheExists=sub { exists $_[0]->{val}{$_[1]} },
#*CacheDel=sub { delete $_[0]->{val}{$_[1]} },
#*CacheClear=sub { delete $_[0]->{val} },
#*CacheUpdate=sub { $_[0]->{val} = $_[1] }
#if $app->ini->{model}{cache} eq "val";

*CacheSet=sub {},
*CacheGet=sub {},
*CacheExists=sub {},
*CacheDel=sub {},
*CacheClear=sub {},
*CacheUpdate=sub {}
if $app->ini->{model}{cache} !~ /^yes$/i;



# применяется в событии update, но в событии updated - нет
# возвращает копию объекта, которая будет возвращать немодифицированные, а реальные поля
sub New {
	my ($self) = @_;
	my $new = $self->new(undef);				# копируем
	%$new = %$self;
	my $save = delete $new->{save};				# удаляем save
	while(my ($key, $val) = each %$save) {
		if(ref $val) {
			die "нельзя преобразовать $key=$val в New";
		}
		$new->{val}{$key} = $val;
	}

	$new
}

# применяется в событии update, но в событии updated - нет
# возвращает копию объекта, которая будет возвращать немодифицированные, а реальные поля
sub Old {
	my ($self) = @_;
	my $new = $self->new(undef);			# копируем
	%$new = %$self;
	delete $new->{save};				# удаляем save
	$new
}

# удаляет кэш val и save
sub Real {
	my ($self) = @_;
	my $new = $self->new(undef);			# копируем
	%$new = %$self;
	delete @$new{qw/save val/};				# удаляем save и val
	$new
}


# сохраняет первую попавшуюся
# sub replace {
	# my ($self) = @_;
	# $self->Fieldset->connect->replace($self->ToCol);
	# $self
# }

# помощник
sub ToCol {
	my ($self, $for_add) = @_;
	my $fieldset = $self->Fieldset;
	my $tab = $fieldset->{tab};
	my $field = $fieldset->{field};

	my $s = {};
	my $save = $self->{save};
	while(my ($k, $v) = each %$save) {
		#$v = $v->id if ref $v;
		my $fld = $field->{$k};
		my $col = $fld->{col};
		if(ref $v eq "ARRAY") {
			my ($op, $val) = @$v;
			my $c = $fieldset->connect;
			if($c->{no_update_operations}) {
				my $def = $for_add? $fld->{default}: $self->$k;
				$s->{$col} = eval("$def $op $val");
			} else {
				$s->{$col} = $for_add? \\ ($fld->{default} . " $op " .  $c->quote($val)): \\ ($c->word($col) . " $op " .  $c->quote($val));
			}
		} else {
			$s->{$col} = $v;
		}
	}
	#$self->{save} = undef;
	return ($tab, $s);
}

# удаляет строку
sub erase {
	my ($self) = @_;
	die "нельзя удалить не созданную запись без id" unless $self->{id};
	my $fieldset = $self->Fieldset;
	$fieldset->fire("erase", $self);
	$self->{noAction} = undef, return $self if $self->{noAction};
	my $id = $self->{id};
	$fieldset->connect->erase($fieldset->{tab}, {id => $id});
	$self->{id} = undef;
	$fieldset->fire("erased", $self, $id);
	$self
}

# проверяет sql-запросом, существует ли запись
sub exists {
	my ($self) = @_;
	return if !defined $self->{id};
	$self->save if $self->{save};
	my $fieldset = $self->Fieldset;
	$fieldset->connect->query($fieldset->tab, "1", {id => $self->{id}})? $self: undef;
}


# возвращает подстроку поля
sub left {
	my ($self, $name, $length) = @_;
	my ($key, $val) = %{$self->annotate("${name}__left__$length")};
	$val
}

# возвращает подстроку поля
sub right {
	my ($self, $name, $length) = @_;
	my ($key, $val) = %{$self->annotate("${name}__right__$length")};
	$val
}

# возвращает подстроку поля
sub mid {
	my ($self, $name, $from, $length) = @_;
	my ($key, $val) = %{$self->annotate("${name}__mid__${from}__$length")};
	$val
}

# ===== унификация интерфейса =====

# строчное представление объекта
sub annonce {
	my ($self) = @_;
	my $fieldset = $self->Fieldset;
	my $fld = $fieldset->{annonce};
	return $fieldset->{remark} . " № " . ($self->id // 0) unless $fld;
	my $max = 100;
	my $desc = $self->left($fld, $max);
	$desc =~ s/.$/ …/s if length($desc)==$max;
	$desc
}


# uri на страницу объекта
sub annonce_href {
	my ($self) = @_;
	my $fieldset = $self->Fieldset;
	join "", "/", $fieldset->{href} // $fieldset->{name}, $self->id;
}

# объект img, представляющий объект - ава, логотип и т.д.
sub annonce_img {
	my ($self) = @_;
	my $fieldset = $self->Fieldset;
	my $annonce = $fieldset->{annonce_img};	# получаем филд на картинку
	return $fieldset->model(undef) unless $annonce;	# возвращаем заглушку
	$self->$annonce
}


# синхронизирует запись с 
# sub sync {
	# my ($self) = @_;
	
	# my $c = $self->Fieldset->connect;
	# $self
# }

# ===== события =====
# все события выполняются перед sql-запросом
# отменить можно установив $self->{noAction} в 1
# создание таблицы
#sub onCreate {}
# удаление таблицы
#sub onDrop {}
# создание записи
#sub onAdd {}
# измение записи
#sub onUpdate {}
# сохранение записи - 2-й параметр: 1-add или 0-update
#sub onSave {}
# удаление записи
#sub onErase {}

1;