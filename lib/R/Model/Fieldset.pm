package R::Model::Fieldset;
# таблица - менеджер полей, дополнительных опций таблицы базы и ключей

use common::sense;
use R::App;

require R::Model::Metafieldset;
require R::Model::Row;
require R::Model::Rowset;
require R::Model::Index;
require R::Model::Indexref;
require R::Model::Field::Col;
require R::Model::Field::Ref;
require R::Model::Field::Back;
require R::Model::Field::M2m;
require R::Model::Field::M2n;
require R::Model::Field::Compute;
require R::Model::Field::Assign;

# use bignum;

# добавляем чекеры
$app->check->add_attributes;

# обработчики событий
our %inspect = $app->perl->set(qw/create created alter altered sync sincing synced drop dropped add added insert inserted update updated updates updateds save saved truncate truncated erase erased erases eraseds setup setuped find query/);
our %inspected = map {("on".ucfirst($_)=>$_)} keys %inspect;

# проверяет, что есть такой обработчик
sub _inspect {
	my ($self, $name) = @_;
	die "нет зарегистрированного события $name" if !exists $inspect{$name};
}

*on = \&R::Model::Metafieldset::on;
*fire = \&R::Model::Metafieldset::fire;
*on_exists = \&R::Model::Metafieldset::on_exists;


has_const qw/name tab cls_row cls_rowset/;

# конструктор
sub new {
	my ($cls, $name, $meta, $cls_row_name) = @_;
	
	$meta //= $app->modelMetafieldset;
	
	die "$meta должна быть типа R::Model::Metafieldset" if !Isa $meta, "R::Model::Metafieldset";
	
	# ВНИМАНИЕ!!! В конструкторе не вызывать app->model - будет рекурсия!!!
	
	#msg $meta->name, $name;
	
	my $tab = $meta->connect->lc($name);
	
	$cls_row_name //= ucfirst $name;
	my $metaname = $meta->name;
	my $cls_row = "${metaname}::Row::$cls_row_name";
	my $cls_rowset = "${metaname}::Rowset::$cls_row_name";
	
	$meta->{fieldset}{$name} = my $self = bless {
		meta => $meta,	# метаинформация
		name => $name,	# имя филдсета
		tab => $tab,	# имя таблицы в базе
		cls_row => $cls_row,		# имя класса row
		cls_rowset => $cls_rowset,	# имя класса rowset
		field=>{},		# филды имя=>филд
		fieldset=>[],	# порядок филдов
		pk=>undef,		# primary key
		indexes=>{},	# индексы
		indexref=>{},	# индексы-ссылки
		remark => undef,			# комментарий таблицы
		engine => $meta->{engine},	# движёк таблицы
		compute => undef,			# 1-вычислимая таблица - в синхронизации не участвует
		options => undef,			# дополнительные опции таблицы
		charset => $meta->{charset},	# collate таблицы
		paging => $meta->{paging},		# размер страницы
		ordering => $meta->{ordering},	# сортирвка по умолчанию
		input => $meta->{input},		# инпут по умолчанию для всех полей этой модели
		inputset => $meta->{inputset},	# для множественных полей back и m2m
		href => undef,		# гиперссылка на страницу объекта модели
		annonce => undef,	# поле для текстового анонса
		annonce_img => undef, # поле для анонса-картинки
		data => [],			# данные для синхронизации
		testdata => [],		# данные для синхронизации в тестовом режиме
		sync => undef,		# синхронизация таблицы начата
		synced => undef,	# синхронизация таблицы закончена
		lang => $meta->{lang},	# имя дефолтной таблицы слов (Rus)
		touch => $meta->{touch},	# now и upd-столбцы
		softerase => $meta->{softerase},	# мягкое удаление
	}, $cls;
	
	# создаём роусет
	@{"${cls_row}::ISA"} = "R::Model::Row" unless @{"${cls_row}::ISA"};
	@{"${cls_rowset}::ISA"} = "R::Model::Rowset" unless @{"${cls_rowset}::ISA"};
	my $getter = sub {$_[0]};
	my $fs = closure($self, $getter);
	my $ff = closure($self->{field}, $getter);
	my $mm = sub { my $self = shift; $self->Fieldset->model(@_) };
	*{"${cls_row}::Fieldset"} = $fs;
	*{"${cls_rowset}::Fieldset"} = $fs;
	*{"${cls_row}::Field"} = $ff;
	*{"${cls_rowset}::Field"} = $ff;
	*{"${cls_row}::Model"} = $mm;
	*{"${cls_rowset}::Model"} = $mm;
	
	my $ClassRow = closure("${cls_row}", $getter);
	my $ClassRowset = closure("${cls_rowset}", $getter);
	*{"${cls_rowset}::ClassRow"} = $ClassRow;
	*{"${cls_row}::ClassRowset"} = $ClassRowset;

	$self->pk($meta->{pk_type})->autoincrement;
	
	# порядок создания таблиц - в начале те, у которых нет ссылок на следующие
	unshift @{$meta->{fields}}, $self;
	
	$self
}

our %Meta = $app->perl->set(qw/tab charset paging ordering engine options remark href input inputset lang compute annonce annonce_img touch/);

# устанавливает метаинформацию для филдсета
sub meta {
	return shift->{meta} if @_ == 1;

	my ($self, %args) = @_;

	while(my($k, $v) = each %args) {
		die "неизвестная опция `$k` в meta" unless exists $Meta{$k};
		$self->{$k} = $v;
	}
	
	my $ordering = $self->{ordering};
	if(defined $ordering) {
		$self->{ordering} = [split /\s*,\s*|\s+/, $ordering] if !ref $ordering;
	}
	
	my $tab = $self->{tab};
	if(defined $tab and $tab ne lc $tab) {
		$self->{tab} = lc $tab;
	}
	
	my $touch = $self->{touch};
	if(defined $touch) {
		$self->now->upd;
	}
	
	# withTrashed и restore - todo
	# withDeleted
	my $softerase = $self->{softerase};
	if(defined $softerase) {
		$self->del;
	}
	
	$self
}

# запускаем сетап
sub setup {
	my ($self, $setup) = @_;
	
	# запускаем setup, если он есть
	$setup //= $self->{cls_row}->can("setup");
	
	$self->fire("setup", $self, $setup);
	
	my $cls_rowset = $self->cls_rowset;
	my $cls_row = $self->cls_row;
	for my $sub ($app->perl->unique( $app->perl->canallnames($cls_row) )) {
		if($sub =~ s/::query([A-Z][\w]*)$/lcfirst $1/e) {
			my $name = lcfirst $1;
			die "query"  . ucfirst($name). "уже устанвлен в $cls_rowset" if $cls_rowset->can($name);
			*{"${cls_rowset}::$name"} = \&$sub;
		}
	}
	
	$setup->($self) if $setup;
	$self->fire("setuped", $self, $setup);
	
	$self
}


# устанавливаем обработчики событий
sub setup_on {
	my ($self, $cls) = @_;

	$cls //= $self->{cls_row};
	
	while(my ($method, $on) = each %inspected) {
		my $code = $cls->can($method);
		$self->on($on, $code) if $code;
	}
	
	$self
}

# устанавливаем обработчики событий c указанного класса и с доп-аргументами
sub setup_on_args {
	my ($self, $cls) = splice @_, 0, 2;

	$cls //= $self->{cls_row};
	
	while(my ($method, $on) = each %inspected) {
		my $code = $cls->can($method);
		$self->on($on, closure @_, $code) if $code;
	}
	
	$self
}

# модель
sub model {
	my $self = shift;
	my $name = $self->{name};
	$self->meta->model->$name(@_);
}

# возвращает все филды или один по имени
sub field {
	my ($self, $name) = @_;
	@_==2? $self->{field}{$name}: $self->{field} 
}



# импортирует поля из указанного филдсета
sub import {
	my ($self, $name) = @_;
	my $fieldset = ref $name? $name: $self->meta->fieldset($name);
	for(@{$fieldset->{fieldset}}) {
		my $fld = $self->{field}{$_->name};
		$fld->delete if $fld;
		push @{$self->{fieldset}}, $self->{field}{$_->name} = $_;
	}
	$self
}

# расширяет модель другой
sub extends {
	my ($self, $name) = @_;
	
	my $fieldset = ref $name? $name: $self->meta->fieldset($name);
	$self->import($fieldset);
	
	push @{ref($self) . "::ISA"}, ref $fieldset if !grep { $_ eq ref $fieldset } @{ref($self) . "::ISA"};
	
	$self
}

# указывает, что столбец был переименован c from, где from - наименование столбца в базе 
sub rename {
	my ($self, $from) = @_;
	$self->last->rename( $from );
	$self
}

# возвращает последний филд
sub last {
	my ($self) = @_;
	my $x = $self->{fieldset};
	$x->[$#$x];
}

# добавляет в последний столбец charset:collate, если ":" не будет, то collate будет взято из _: utf8_unicode_ci => utf8:utf8_unicode_ci
sub charset {
	my ($self, $charset) = @_;
	$self->last->charset($charset);
	$self
}

# указывает имя поля в базе
sub col_name {
	my ($self, $col) = @_;
	$self->last->col($col);
	$self
}

# добавляет вычислимый столбец
sub compute {
	my ($self, $name, @relation_fields) = @_;
	R::Model::Field::Compute->new($self, $name, \@relation_fields);
	$self
}

# добавляет поле
sub col {
	my ($self, $name, $type, $col) = @_;
	
	my $field = R::Model::Field::Col->new(@_);
	#$self->required;
	
	$self->{annonce} = $name if not defined $self->{annonce} and exists $self->meta->{string_types}{lc(($field->{type} =~ /^(\w+)/)[0])};
	$self
}

# добавляет поле-ссылку
sub ref {
	my ($self, $name, $to_model, $bk_name, $fk_name) = @_;
	my $ref = R::Model::Field::Ref->new($self, $name, $to_model);
	my $fk = $ref->ref;
	my $to_fieldset = $fk->fieldset;
	my $back = R::Model::Field::Back->new($to_fieldset, $ref, $bk_name);
	$ref->{back} = $back;
	$ref->fk_to($fk, $fk_name);
	$self
}

# обавляет поле-ссылку один-к-одному
#	user.id -> everUser.id (assign) everUser.ever -> ever.id (one)
#	everUser.ever <- ever.everUser
sub one {
	my ($self, $name, $to_model, $bk_name, $fk_name) = @_;
	
	my $ref = R::Model::Field::Ref->new($self, $name, $to_model);
	my $fk = $ref->ref;
	my $to_fieldset = $fk->fieldset;
	my $back = R::Model::Field::Assign->new($to_fieldset, $ref, $bk_name);
	
	$ref->{back} = $back;
	
	$ref->fk_to($fk, $fk_name);
	$self->unique($name);
	
	$self
}


# добавляет столбец один-к-одному. Должен быть после столбца, который будет его представлять
# обычно используется для связи id-to-id
sub assign {
	my ($self, $to_model, $bk_name, $fk_name) = @_;
	
	# параметры:
	#	self -> admin
	#	name -> user
	#	to_model -> user
	#	bk_name -> admin
	# например:
	#	admin.id -> user.id
	# тогда:
	#	->assign("user")
	#
	#	admin.user =>
	#		col => id
	#		ref => user.id
	#		back => user.admin
	#	user.admin =>
	#		col => id
	#		ref => admin.id
	#		back => admin.user

	$bk_name //= $self->{name};
	my $col = $self->pk->{col} // "id";
	$self->pk(undef);
	
	my $ref = R::Model::Field::Ref->new($self, "id", $to_model);
	$ref->{col} = $col;
	$ref->{pk} = 1;
	$ref->{null} = 0;
	$ref->{autoincrement} = 0;
	$self->{pk} = $ref;
	my $fk = $ref->ref;
	my $to_fieldset = $fk->fieldset;
	my $back = R::Model::Field::Assign->new($to_fieldset, $ref, $bk_name);

	$ref->{back} = $back;
	$ref->fk_to($fk, $fk_name);
	
	$self
}



# ссылка многие-ко-многим
#	$name - имя филда m2m
#	$to_model - имя модели
#	$name_from_model - имя обратной связи в $to_model
#	$m2m_model - имя модели-связи
#	$alias1 - название ref на себя
#	$alias2 - название ref на модель
sub m2m {
	my ($self, $name, $to_model, $name_from_model, $m2m_model, $alias1, $alias2) = @_;
	
	unless(defined $to_model) {
		if($name =~ /s$/i) {
			$to_model = $name;
			$to_model =~ s/s$//i;
		} else {
			$to_model = $name;
			$name .= "s";
		}
	}
	
	my $to_fieldset = $self->meta->fieldset($to_model);
	
	$name_from_model //= $self->{name} . "s";
	unless($m2m_model) {
		my $x = $name =~ /s$/? $`: $name;
		my $y = $name_from_model =~ /s$/? $`: $name_from_model;
		$m2m_model = $x . ucfirst $y;
	}
	
	$alias1 //= $self->{name};
	$alias2 //= ($alias1 eq $to_model? 'any' . $to_model: $to_model);
	
	my $m2m_fieldset = $self->meta->fieldset($m2m_model)->
	#pk(undef)->
	ref($alias1 => $self->{name})->
	ref($alias2 => $to_model)->
	unique("$alias1, $alias2");
	
	$m2m_fieldset->{for_m2m} = "m2m";
	
	my $ref_from = $m2m_fieldset->{field}{$alias1};
	my $ref_to = $m2m_fieldset->{field}{$alias2};
	
	# местами не менять! последним должен быть филд ref1
	my $ref2 = R::Model::Field::M2m->new($name_from_model, $ref_to, $ref_from);
	my $ref1 = R::Model::Field::M2m->new($name, $ref_from, $ref_to);
	$ref1->{back} = $ref2;
	$ref2->{back} = $ref1;
	
	$self
}

# ссылка многие-ко-многим
#	$name - имя филда m2m
#	$to_model - имя модели
#	$name_from_model - имя обратной связи в $to_model
#	$m2m_model - имя модели-связи
#	$alias1 - название ref на себя
#	$alias2 - название ref на модель
sub m2n {
	my ($self, $name, $to_model, $name_from_model, $m2m_model, $alias1, $alias2) = @_;
	
	$to_model = $name unless defined $to_model;
	
	my $to_fieldset = $self->meta->fieldset($to_model);
	
	$name_from_model //= $self->{name} . "s";
	unless($m2m_model) {
		my $x = $name =~ /s$/? $`: $name;
		my $y = $name_from_model =~ /s$/? $`: $name_from_model;
		$m2m_model = $x . ucfirst $y;
	}
	
	$alias1 //= $self->{name};
	$alias2 //= ($alias1 eq $to_model? 'any' . $to_model: $to_model);
	
	my $m2m_fieldset = $self->meta->fieldset($m2m_model)->
	ref($alias1 => $self->{name})->
	one($alias2 => $to_model)->
	index("$alias1, $alias2");
	
	$m2m_fieldset->{for_m2m} = "m2n";
	
	my $ref_from = $m2m_fieldset->{field}{$alias1};
	my $ref_to = $m2m_fieldset->{field}{$alias2};
	
	# местами не менять! последним должен быть филд ref1
	my $ref2 = R::Model::Field::M2n->new($name_from_model, $ref_to, $ref_from);
	my $ref1 = R::Model::Field::M2m->new($name, $ref_from, $ref_to);
	$ref1->{back} = $ref2;
	$ref2->{back} = $ref1;
	
	$self
}

# ссылка один-ко-многим
#	$name - имя филда m2m
#	$to_model - имя модели
#	$name_from_model - имя обратной связи в $to_model
#	$m2m_model - имя модели-связи
#	$alias1 - название ref на себя
#	$alias2 - название ref на модель
sub n2m {
	my ($self, $name, $to_model, $name_from_model, $m2m_model, $alias1, $alias2) = @_;
	
	unless(defined $to_model) {
		if($name =~ /s$/i) {
			$to_model = $name;
			$to_model =~ s/s$//i;
		} else {
			$to_model = $name;
			$name .= "s";
		}
	}
	
	my $to_fieldset = $self->meta->fieldset($to_model);
	
	$name_from_model //= $self->{name}; # . "s";
	unless($m2m_model) {
		my $x = $name =~ /s$/? $`: $name;
		my $y = $name_from_model =~ /s$/? $`: $name_from_model;
		$m2m_model = $x . ucfirst $y;
	}
	
	$alias1 //= $self->{name};
	$alias2 //= ($alias1 eq $to_model? 'any' . $to_model: $to_model);
	
	my $m2m_fieldset = $self->meta->fieldset($m2m_model)->
	one($alias1 => $self->{name})->
	ref($alias2 => $to_model)->
	index("$alias2, $alias1");
	
	$m2m_fieldset->{for_m2m} = "n2m";
	
	my $ref_from = $m2m_fieldset->{field}{$alias1};
	my $ref_to = $m2m_fieldset->{field}{$alias2};
	
	# местами не менять! последним должен быть филд ref1
	my $ref2 = R::Model::Field::M2m->new($name_from_model, $ref_to, $ref_from);
	my $ref1 = R::Model::Field::M2n->new($name, $ref_from, $ref_to);
	$ref1->{back} = $ref2;
	$ref2->{back} = $ref1;
	
	$self
}

# ссылка многие-ко-многим
#	$name - имя филда m2m
#	$to_model - имя модели
#	$name_from_model - имя обратной связи в $to_model
#	$m2m_model - имя модели-связи
#	$alias1 - название ref на себя
#	$alias2 - название ref на модель
sub n2n {
	my ($self, $name, $to_model, $name_from_model, $m2m_model, $alias1, $alias2) = @_;
	
	$to_model = $name unless defined $to_model;
	
	my $to_fieldset = $self->meta->fieldset($to_model);
	
	$name_from_model //= $self->{name};
	unless($m2m_model) {
		my $x = $name =~ /s$/? $`: $name;
		my $y = $name_from_model =~ /s$/? $`: $name_from_model;
		$m2m_model = $x . ucfirst $y;
	}
	
	$alias1 //= $self->{name};
	$alias2 //= ($alias1 eq $to_model? 'any' . $to_model: $to_model);
	my $m2m_fieldset = $self->meta->fieldset($m2m_model)->
	#assign($alias1 => $self->{name})->
	one($alias1 => $self->{name})->
	one($alias2 => $to_model);
	
	$m2m_fieldset->{for_m2m} = "n2n";
	
	my $ref_from = $m2m_fieldset->{field}{$alias1};
	my $ref_to = $m2m_fieldset->{field}{$alias2};
	
	# местами не менять! последним должен быть филд ref1
	my $ref2 = R::Model::Field::M2n->new($name_from_model, $ref_to, $ref_from);
	my $ref1 = R::Model::Field::M2n->new($name, $ref_from, $ref_to);
	$ref1->{back} = $ref2;
	$ref2->{back} = $ref1;
	
	$self
}

# частоиспользуемое поле - время добавления
sub now {
	my ($self) = @_;
	$self->col(now => "now")
}

# частоиспользуемое поле - время изменения
sub upd {
	my ($self) = @_;
	$self->col(upd => "upd")
}

# сокращение для col(name => enum => ...)
sub enum {
	my $self = shift;
	my $name = shift;
	
	$self->col($name => "enum", @_);
}

# добавляет функцию возвращающую запрос на множество объектов, к-е могут быть вставлены в это поле
sub refset {
	my ($self, $refset) = @_;
	if(!ref $refset) {
		$refset =~ s/\./->/g;
		$refset = eval "sub {shift->$refset}";
		die $@ if $@;
	}
	$self->last->refset($refset);
	#$self->check();
	$self
}

# добавляет валидатор или преобразователь
sub check {
	my $self = shift;
	$self->last->check(@_);
	$self
}

# добавляет тип виджета
sub input {
	my $self = shift;
	$self->last->input(@_);
	$self
}

# возвращает, добавляет или удаляет pk
sub pk {
	return shift->{pk} if @_==1;

	my ($self, $type, $col) = @_;
	
	$col //= "id";
	
	my $pk = $self->{pk};
	
	if(!$pk) {	# создаём pk единожды - pk всегда остаётся в self->pk и  может быть восстановлено
		$pk = $self->{pk} = R::Model::Field::Col->new($self, "id", $type);
		$pk->{pk} = 1;
		$self->{pk} = $pk;
	}
	
	# удаляем pk из столбцов таблицы
	$pk->{col} = $col if defined $col;
	$pk->{autoincrement} = 0;		# сбрасываем автоинкремент
	$pk->delete;					# удаляем из таблицы
	$pk->register if defined $type;	# прописываем в столбцах таблицы
	$pk->{type} = $type;			# меняем тип
	$pk->{real_type} = $type;
	$pk->register_class;
	
	$self
}

# добавляет автоинкремент
sub autoincrement {
	my ($self) = @_;
	$self->last->{autoincrement} = 1;
	$self
}

# делает филд нулевым
sub null {
	my $self = shift;
	my $field = $self->last;
	#$field->{check}->del("need", 1) if $field->{check};
	$field->{null} = 1;
	$self
}

# делает филд обязательным
sub require {
	my $self = shift;
	my $field = $self->last;
	$field->check("need") if !$field->{check} or !defined $field->{check}->get("need");
	$field->{null} = 0;
	$self
}
sub required { goto &require }
sub need { goto &require }

# добавляет значение по умолчанию к последнему филду
# raw используется для указания функций: today, timestamp и т.д.
sub default {
	my ($self, $default, $raw) = @_;
	
	my $field = $self->last;

	if(!$raw) {
		my $e = $field->checking($default);
		die $e if defined $e;
	}

	$field->{raw_default} = $default;
	$field->{default} = $raw? $default: $self->connect->quote($default);
	$self
}

sub default_raw {
	my ($self, $default) = @_;
	$self->default($default, 1);
}

# добавляет текст в описание столбца. Только для col
sub extra {
	my ($self, $extra) = @_;
	$self->last->extra($extra);
	$self
}

# добавляет комментарий к последнему филду
sub remark {
	my $self = shift;
	my $fld = $self->last->remark(@_);
	$self
}

# добавляет индекс
our %IDX = qw(INDEX idx UNIQUE unq SPATIAL sp FULLTEXT full);
sub _add_index {
	my ($keyword, $self, $idx, $name) = @_;
	my @idx = split /\s*,\s*/, $idx // $self->last->{name};
	$name ||= $IDX{$keyword} . "_" . join "__", @idx;
	$self->{indexes}{$name} = R::Model::Index->new($keyword, [@idx], $name, $self);
	$self
}

sub primary_key { unshift @_, 'PRIMARY KEY'; push @_, 'PRIMARY'; goto &_add_index; }
sub index { unshift @_, 'INDEX'; goto &_add_index; }
sub unique { unshift @_, 'UNIQUE'; goto &_add_index; }
sub fulltext { unshift @_, 'FULLTEXT'; goto &_add_index; }
sub spatial { unshift @_, 'SPATIAL'; goto &_add_index; }


# мультииндекс - создаёт таблицу, которая будет служить индексом.
# принимает 1-й параметр: строка-запрос или запрос в функции
# и имена столбцов с весами
# полнотекстовый поиск осуществляется с помощью присоединённой таблицы words
sub mult {
	my ($self, $query) = @_;
	
	#$query
	
	todo;
	
	$self
}

# # добавляет вес для предыдущего столбца или перечисленных, для поиска по релевантности
# sub weight {
	# my ($self) = @_;
	# $self
# }

# присоединяет столбец другой таблицы
# можно объединять только col и ref
sub attach {
	my ($self) = @_;
	
	todo;
	
	$self->one("setuped", sub {
		
	});
}

# объединяет столбец со столбцом из другой таблицы
# при изменении значения в любом из столбцов изменяется и в ассоциированом
# можно объединять только col и ref
sub associate {
	my ($self) = @_;
	$self
}

# добавляет полнотекстовый индекс для таблицы
sub match {
	my $self = shift;
	my $lang = $self->{lang};
	my $name = $self->name;
	my $assign = "match$lang" . ucfirst($name);
	my $is_first = !$self->{match};
	
	#$self->meta->load("model/Words/$lang.pm");
	$self->meta->
	create("_Fields", sub { shift->
		col("field" => "varchar(255)")->unique->remark("имя филда: 'филдсет.филд'")->
		meta(
			remark => "филды в индексах полнотекстового поиска",
		)
	})->
	create("_Words_$lang", sub { shift->
		col("word" => "varchar(32)")->unique->remark("лексема - слово без окончания")->
		meta(
			remark => "слова для полнотекстового поиска",
		)
	})->
	create($assign, sub { shift->
		ref("word" => "_Words_$lang")->require->remark("ссылка на лексему")->
		ref("field" => "_Fields")->require->remark("ссылка на поле")->
		ref($name)->require->remark("id объекта $name")->
		col("entry" => "int unsigned")->remark("количество такой лексемы в поле")->
		index("word")->
		index("field")->
		meta(
			remark => "спектр слов",
		)
	});
	
	my $match = $self->{match} = { lang => $lang, assign => $assign };
	my $fields = $match->{fields} //= [];	# поля
	my $tabfields = $match->{tabfields} //= {};	# поля "филдсет.поле"
	my $weight = $match->{weight} //= {};	# веса: поле-вес
	
	my $last;
	
	push @_, $self->last->name if !@_;
	
	for(my $i=0; $i<@_; $i++) {	# извлекаем веса
		my $fld = $_[$i];
		if($fld =~ /^\d+$/) {
			$weight->{$last} = $fld;
		} else {
			push @$fields, ($last = $fld);
			$tabfields->{$fld} = "$name.$fld";
			$weight->{$fld} = 1;
		}
	}
	
	if($is_first) {
	
		# перезаписываем
		$self->on("saved", sub {
			my ($self, $add) = @_;
			my $fieldset = $self->Fieldset;
			my $match = $fieldset->{match};
			my $fields = $match->{weight};
			
			my $save = $self->{save};	# выбираем поля, к-е есть в индексе
			$save = { map {($_ => $save->{$_})} grep {exists $fields->{$_}} keys %$save };
			
			if(%$save) {	# одно или несколько полей изменились
				my $tabfields = $match->{tabfields};
				my $assign = $match->{assign};
				my $name = $fieldset->name;
				
				# разбираемся с филдами сохранёнными в таблице _Fields
				my $model = $fieldset->meta->model;
				my %fields_name = $model->_Fields->find( field => [ map { $tabfields->{$_} } keys %$save ] )->annotateby("field", "id");
				
				my @fields;
				if(keys %fields_name != keys %$save) {	# а ежели таких не найдено, то добавить!
					for my $field (map { $tabfields->{$_} } keys %$save) {
						push @fields, $model->_Fields(field => $field) if !exists $fields_name{$field};
						#$fields_name{$field} = $model->_Fields(field => $field)->store->id;
					}
					$model->_Fields->insert(\@fields);
					$fields_name{ $_->field } = $_->id for @fields;
				}
				
				# my %words_name = $app->perl->reverse(\%words_id);
				# my @word;
				# for my $word (keys %words) {
					# push @word, $model->$word_model({word=>$word}) if !$words_name{$word};
				# }
				# $model->$word_model->insert(\@word);
				# $words_id{ $_->id } = $_->word for @word;
				
				%fields_name = map { /\.([^\.]+)$/; $1 => $fields_name{$_} } keys %fields_name;
				
				my %fields_id = $app->perl->reverse(\%fields_name);
				
				my $lang = $match->{lang};
				my $key = "modelWords$lang";
				my $wordset = $app->$key;
				my $word_model = "_Words_$lang";
				
				# 1. получаем слова, к-е нужно добавить: A
				# 2. получаем какие есть: B
				# 3. удаляем разницу: B - A
				# 4. у кого не совпадает entry - апдейтим: A*B
				# 5. добавляем недостающие
				
				# 1. получаем слова, к-е нужно добавить: A
				my %A;	# field => { word => entry }
				my %words;
				while(my ($field, $phrase) = each %$save) {
					my $words = $wordset->build($phrase);
					$A{$field} = $words;
					while(my ($word, $entry) = each %$words) {
						$words{$word} = 1;
					}
				}
				
				my %words_id = $model->$word_model->find( word => [keys %words] )->annotateby("id", "word");
				if(keys %words_id != keys %words) {	# добавляем слова, если их нет
					my %words_name = $app->perl->reverse(\%words_id);
					my @word;
					for my $word (keys %words) {
						push @word, $model->$word_model(word=>$word) if !$words_name{$word};
					}
					$model->$word_model->insert(\@word);
					$words_id{ $_->id } = $_->word for @word;
					
					#$words_id{ $model->$word_model(word=>$word)->save->id } = $word
				}
				
				# 2. получаем какие есть: B
				my @B = $model->$assign->view("word", "field", "entry")->find($name => $self, field=>[keys %fields_id]);
				
				# находим разницу: B - A
				my @del;	# слова, к-х нет
				#my @upd;	# у кого не совпадает entry
				my @add;	# добавить
				for my $row (@B) {
					my $field_id = $row->field->id;
					my $word_id = $row->word->id;
					my $entry = $row->entry;
					
					my $field = $fields_id{$field_id};
					my $word = $words_id{$word_id};
					
					# нет слова $word при удалении
					#msg1 $field, $word, $word_id;
					
					if(my $new_entry = $A{$field}{$word}) {
						$row->entry($new_entry) if $new_entry != $entry;
						$A{$field}{$word} = 0;
					} else {
						push @del, $row;
					}
				}
				
				my %words_name = $app->perl->reverse(\%words_id);
				my $id = $self->{id};
				while(my ($field, $words) = each %A) {
					while(my ($word, $entry) = each %$words) {
						if( $entry ) {
							push @add, { field=> $fields_name{ $field }, entry=>$entry, word => $words_name{ $word }, $name => $id };
						}
					}
				}
				
				# удаляем перед добавлением, иначе fk к табличам _WordsRus и _Fields сработают
				$model->$assign->find( id=>\@del )->erase if @del;
				$model->$assign->insert( \@add ) if @add;
			}
		});
		
		# удаляем
		$self->on("erase", sub {
			my ($self) = @_;
			my $fieldset = $self->Fieldset;
			my $assign = $fieldset->{match}{assign};
			$fieldset->meta->model->$assign->find($fieldset->name => $self)->erase;		# удаляем все указатели на слова
		});
	
	}
	
	$self
}

# создаёт поле-счётчик для подсчитывания ссылок
sub counter {
	my ($self, $name, $bk, $type, $filter) = @_;
	
	$bk //= $self->last->name;	# если у вас m2m перед counter стоит
	
	$filter = $type, $type = undef if ref $type eq "CODE";
	
	$self->col($name => $type // $self->meta->pk_type)->default(0);
	
	my $fieldset;
	my $ref_name;
	my $is_m2m;
	if($bk =~ /^(\w+)\.(\w+)$/) {
		$fieldset = $1;
		$ref_name = $2;
		$fieldset = $self->meta->fieldset($fieldset);
	}
	else {
		my $m2m = $self->{field}{$bk};
		
		die "указано неверное поле в counter($name => $bk)" if !$m2m;
		die "ссылка для счётчика должна быть m2m. А не `" . ref($m2m) ."`" if !Isa $m2m, qw/R::Model::Field::M2m/;
		
		my $ref = $m2m->toSelf->back->ref;
		
		$fieldset = $ref->fieldset;
		$ref_name = $ref->name;
		$is_m2m = $m2m->toRef->name;
	}
	
	$self->{field}{$name}->counter({
		fieldset => $fieldset,
		ref => $ref_name,
		ref_m2m => $is_m2m,
		filter => $filter,
	});
	
	if($filter) {
	
		if($is_m2m) {
		
			$fieldset->on("added", closure $is_m2m, $filter, $name, $ref_name, sub {
				my ($is_m2m, $filter, $name, $ref_name, $row) = @_;
				my $ref = $row->$ref_name;
				my $op = "+";
				$ref->$name($op=>1) if defined $ref->{id} and $filter->($row->$is_m2m, $ref, $op, $row);
			});
			$fieldset->on("update", closure $is_m2m, $filter, $name, $ref_name, sub {
				my ($is_m2m, $filter, $name, $ref_name, $row) = @_;
				
				# если ссылка изменяется
				if(exists $row->{save}{$ref_name}) {		
					my $old = $row->Old->$ref_name;		# какой была до сохранения
					my $new = $row->New->$ref_name;		# какой будет после сохранения

					if($old->{id} != $new->{id}) {
						my $op = "-";
						$old->$name($op=>1) if defined $old->{id} and $filter->($row->$is_m2m, $old, $op, $row);
						$op = "+";
						$new->$name($op=>1) if defined $new->{id} and $filter->($row->$is_m2m, $new, $op, $row);
					}
				}
			});	
			$fieldset->on("erase", closure $is_m2m, $filter, $name, $ref_name, sub {
				my ($is_m2m, $filter, $name, $ref_name, $row) = @_;
				my $ref = $row->$ref_name;
				my $op = "-";
				$ref->$name($op=>1) if defined $ref->{id} and $filter->($row->$is_m2m, $ref, $op, $row);
			});
		
		} else {
		
			$fieldset->on("added", closure $filter, $name, $ref_name, sub {
				my ($code, $name, $ref_name, $row) = @_;
				my $ref = $row->$ref_name;
				my $op = "+";
				$ref->$name($op=>1) if defined $ref->{id} and $filter->($row, $ref, $op);
			});
			$fieldset->on("update", closure $filter, $name, $ref_name, sub {
				my ($code, $name, $ref_name, $row) = @_;
				
				# если ссылка изменяется
				if(exists $row->{save}{$ref_name}) {		
					my $old = $row->Old->$ref_name;
					my $new = $row->New->$ref_name;

					if($old->{id} != $new->{id}) {
						my $op = "-";
						$old->$name($op=>1) if defined $old->{id} and $filter->($row, $old, $op);
						$op = "+";
						$new->$name($op=>1) if defined $new->{id} and $filter->($row, $new, $op);
					}
				}
			});	
			$fieldset->on("erase", closure $filter, $name, $ref_name, sub {
				my ($code, $name, $ref_name, $row) = @_;
				my $ref = $row->$ref_name;
				my $op = "-";
				$ref->$name($op=>1) if defined $ref->{id} and $filter->($row, $ref, $op);
			});
		}
	}
	else {

		$fieldset->on("added", closure $name, $ref_name, sub {
			my ($name, $ref_name, $row) = @_;
			my $ref = $row->$ref_name;
			$ref->$name("+"=>1) if defined $ref->{id};
		});
		$fieldset->on("update", closure $name, $ref_name, sub {
			my ($name, $ref_name, $row) = @_;
			
			# если ссылка изменяется
			if(exists $row->{save}{$ref_name}) {		
				my $old = $row->Old->$ref_name;
				my $new = $row->New->$ref_name;

				# проверяем, что id не совпадают
				if($old->{id} != $new->{id}) {
					# если есть старый id, а не null
					$old->$name("-"=>1) if defined $old->{id};
					# если есть новый id, то произошла замена одного объекта на другой
					$new->$name("+"=>1) if defined $new->{id};
				}
			}
		});	
		$fieldset->on("erase", closure $name, $ref_name, sub {
			my ($name, $ref_name, $row) = @_;
			my $ref = $row->$ref_name;
			$ref->$name("-"=>1) if defined $ref->{id};
		});
	}
	
	$self
}


# пересчитывает счётчики в таблице
sub recalc {
	my $self = shift;
	local $_;
	
	todo;
	
	for my $fld (@_ or map {$_->{name}} grep {$_->{counter}} @{$self->{fieldset}}) {
		$fld = $self->{fields}{$fld};
		die "поле $fld->{name} не является счётчиком" if !$fld->{counter};
		$fld->{counter}
	}
	
	$self
}


# просто для окончания, чтобы можно было столбец закомментировать
sub end {}

# в новую таблицу добавляются обязательные данные
sub data {
	my ($self, @args) = @_;
	push @{$self->{data}}, @args;
	$self
}

# в новую таблицу добавляются тестовые данные
sub testdata {
	my ($self, @args) = @_;
	push @{$self->{testdata}}, @args;
	$self
}

# добавляет данные
sub sync_data {
	my ($self) = @_;
	
	my $_test = $self->meta->{addtestdata};
	
	my $cls_row = $self->{cls_row};
	
	$self->run_data($self->{data}) if @{$self->{data}};
	$cls_row->can("realdata")->($self) if $cls_row->can("realdata");

	$self->run_data($self->{testdata}) if $_test && @{$self->{testdata}};
	$cls_row->can("testdata")->($self) if $_test && $cls_row->can("testdata");
	
	$self
}

# запускает данные
sub run_data {
	my ($self, $rows) = @_;
	
	my $beans = [];
	for my $row (@$rows) {

		if(CORE::ref $row eq "ARRAY") {
			my $bean = $self->model({});
			my $fieldset = $self->{fieldset};
			my $i = 0;
			for my $val (@$row) {
				my $fld = $fieldset->[$i++];
				while(CORE::ref($fld) =~ /^R::Model::Field::(?:Back|M2m)$/) { $fld = $fieldset->[$i++] }
				my $name = $fld->{name};
				$bean->$name($val);
			}
			#msg $bean, $row;
			#push @$beans, $bean;
			$bean->store;
		} else {
			die "Что-то неясное попало в инициализирующие данные: $row";
		}
		
	}
	$self
}

# возвращает имена столбцов таблицы
sub col_keys {
	my ($self) = @_;
	map { $_->{col} } grep { !$_->{compute} } @{$self->{fieldset}};
}

# возвращает коннект таблицы
sub connect {
	my ($self) = @_;
	$self->{meta}{connect}
}

# проверяет, что в базе есть таблица. По умолчанию - своя
sub existsTab {
	my ($self, $tab) = @_;
	$self->connect->info->{$tab // $self->{tab}}
}

# проверяет, что в базе есть колумн. По умолчанию - последний
sub existsCol {
	my ($self, $col) = @_;
	my ($tab, $col) = split /\./, $col;
	
	$self->connect->info->{$tab // $self->{tab}}
}


# после столбца - устанавливается перед change
sub after {
	my ($self, $after) = @_;
	$self->last->{after} = $after;
	$self
}

# синхронизирует последний столбец
sub change {
	my ($self) = @_;
	
	$self->last->change;

	$self
}

# синхронизация таблицы
sub sync {
	my ($self) = @_;
	
	my $c = $self->connect;
	
	# сброс кэшей
	$c->clean;
	
	for my $fieldset (@{$self->meta->{fields}}) {
		$fieldset->{sync} = $fieldset->{synced} = undef;
	}
	
	my $sql_before = $self->meta->{sql_before} = [];
	my $sql_main = $self->meta->{sql_main} = [];
	my $sql_after = $self->meta->{sql_after} = [];
	
	$self->presync;
	
	# запись в базу
	for my $sql (@$sql_before, @$sql_main, @$sql_after) {
		$c->do($sql);
	}
	
	$self->sync_data;
	
	# сброс кэшей
	$c->clean;
	
	$self
}

# создание sql для синхронизации таблицы и всех связанных таблиц
sub presync {
	my ($self) = @_;
	
	return $self if $self->{sync};
	$self->{sync} = 1;
	return $self if $self->{compute};
	
	local ($a, $b, $_);
	
	my $name = $self->{name};
	my $meta = $self->meta;
	my $sql_before = $meta->{sql_before};
	my $sql_main = $meta->{sql_main};
	my $sql_after = $meta->{sql_after};
	
	my $c = $self->connect;
	my $tab = $self->{tab};
	my $info = $c->info->{$tab};
	
	# синхронизируем вначале зависимые таблицы
	while(my ($name, $indexref) = each %{$self->{indexref}}) {
		$indexref->fk->fieldset->presync;
	}
	
	$self->fire("sync", $self);
	
	# создаём или редактируем
	if(!$info) {	# создаём
		$self->fire("create", $self);

		my $sql = $self->create_table;
		push @$sql_main, $sql;
		
		# fk - в metafieldset после полной синхронизации
		while(my ($name, $indexref) = each %{$self->{indexref}}) {
			$indexref->sync if !$indexref->fk->fieldset->{synced};
		}
		
		$self->fire("created", $self);
		
	} else {
	
		$self->fire("alter", $self);
	
		# опции таблицы
		my $tab_info = $c->tab_info->{$self->{tab}};
		$tab_info->{charset} = undef if !$self->{charset} and ($tab_info->{charset} // "") eq $meta->{charset};
		
		my @a = $self->sql;
		my @b = $self->sql($tab_info);
		
		my $i = 0;
		for $a (@a) {
			$b = $b[$i++];
			if($a ne $b) {
				my $comment = "/*\n1) $b\n2) $a */\n";
				my $sql = $comment . $self->alter($a);
				push @$sql_main, $sql;
			}
		}
		
		# столбцы
		my %is;
		my $num = 1;
		my $after = 1;
		for my $field (@{$self->{fieldset}}) {
			next if $field->compute;
			$field->sync($after, $num++);
			
			# после какого столбца
			$after = $field->{col};
			
			# такой столбец есть
			$is{delete($field->{sync_rename}) // $field->{col}} = 1;
		}
		
		# индексы
		while(my ($name, $index) = each %{$self->{indexes}}) {
			$index->sync;
		}
		
		# удаляем индексы
		my $idx_info = $c->index_info->{$tab} // {};
		while(my ($k, $v) = each %$idx_info) {
			if(not exists $self->{indexes}{$k} and $k ne "PRIMARY" or 
				$k eq "PRIMARY" and !$self->{pk}->{type} and not exists $self->{indexes}{$k}
			) {

				# удаляем зависящие fk
				$self->drop_relation(map {$_->{col}} @$v);
				
				push @$sql_before, R::Model::Index::drop($self, $tab, $k);
			}
		}
		
		# fk - в metafieldset после полной синхронизации
		while(my ($name, $indexref) = each %{$self->{indexref}}) {
			$indexref->sync;
		}
		
		my $fk_info = $c->fk_info->{$tab} // {};
		# удаляем fk - в metafieldset перед полной синхронизацией
		for my $k (keys %$fk_info) {
			if( !exists $self->{indexref}{$k} ) {
				my $v = delete $fk_info->{$k};
				push @$sql_before, R::Model::Indexref::drop($self, $tab, $k);
			}
		}
		
		
		# удаляем столбцы
		while(my ($k, $v) = each %$info) {
			$self->drop_relation($k),
			push @$sql_main, R::Model::Field::Col::drop($self, $tab, $k) if !$is{$k};
		}
		
		$self->fire("altered", $self);
	}
	
	# таблица полностью синхронизирована
	$self->{synced} = 1;
	
	$self->fire("synced", $self);
	
	$self;
}

# если есть fk зависящие от удаляемых ключей или изменяемых столбцов, то - удаляем их
# параметры - столбцы
sub drop_relation {
	my $self = shift;
	
	my $tab = $self->{tab};
	my $c = $self->connect;
	my $meta = $self->meta;
	my $sql_before = $meta->{sql_before};
	
	# fk-ключи таблицы зависимые от столбцов таблицы
	my $fk_info = $c->fk_info->{$tab} // {};
	my $fk_col = $self->{fk_col} //= { map { ($fk_info->{$_}{col} => $_)	} keys %$fk_info };
	
	# fk-ключи других таблиц зависимые от столбцов таблицы
	my $fk_info_backward = $c->fk_info_backward->{$tab} // {};
	my $fk_col_bk = $self->{fk_col_bk} //= { map { my $v=$fk_info_backward->{$_}; ($v->{ref_col} => $v)	} keys %$fk_info_backward };
	
	for my $col (@_) {
		if(my $fk = $fk_col->{$col}) {
			if($fk_info->{$fk}) {
				$meta->{drop_fk}{$fk} = 1, push @$sql_before, R::Model::Indexref::drop($self, $tab, $fk) if !$meta->{drop_fk}{$fk};
			}
		}
		
		if(my $fk = $fk_col_bk->{$col}) {
			my $tab = $fk->{tab};
			my $fk = $fk->{name};
			if($fk_info_backward->{$fk}) {
				$meta->{drop_fk}{$fk} = 1, push @$sql_before, R::Model::Indexref::drop($self, $tab, $fk) if !$meta->{drop_fk}{$fk};
			}
		}
	}
	
	$self
}

# возвращает значение автоинкремента таблицы
sub autoinctrement_get {
	my ($self) = @_;
	my $c = $self->connect;
	$c->query("INFORMATION_SCHEMA.TABLES", "AUTO_INCREMENT", ["WHERE", "TABLE_SCHEMA" => $c->basename, "TABLE_NAME" => $self->{tab}]);
}

# устанавливает значение автоинкремента таблицы
sub autoinctrement_set {
	my ($self, $id) = @_;
	my $c = $self->connect;
	$c->do("ALTER TABLE " . $c->word($self->{name}) . " AUTO_INCREMENT=" . (0+$id));
	$self
}

# инкрементирует автоинкремент на указанное количество и возвращает последний id
sub autoincrement_inc {
	my ($self, $inc) = @_;
	my $c = $self->connect;
	my $id = $self->autoinctrement_get;
	$id += $inc;
	$self->autoinctrement_set($id);
	$id-1;
}


# возвращает дополнительные опции таблицы, которые можно использовать в alter table
sub sql {
	my ($self, $opt, $create) = @_;
	$opt //= $self;
	my $c = $self->connect;
	
	my $collation = $opt->{charset} // $self->{charset};
	$collation =~ /_/; 
	my $charset = $`;
	
	return (
		($create? "DEFAULT CHARACTER SET '$charset' COLLATE '$collation',":
		"CONVERT TO CHARACTER SET '$charset' COLLATE '$collation'"),
		"ENGINE=" . uc($opt->{engine} || $self->{engine}),
		"COMMENT=" . $c->quote($opt->{remark} // ""),
		($opt->{options}? $opt->{options}: ()),
	)
}

# возвращает alter table для таблицы (не для столбцов)
sub alter {
	my ($self, $sql) = @_;
	my $c = $self->connect;
	"ALTER TABLE " . $c->word($self->{tab}) . " " . ($sql // join " ", $self->sql(undef, 1));
}

# возвращает create table
sub create_table {
	my ($self) = @_;
	
	my $c = $self->connect;
	
	my @sql = ("CREATE TABLE ", $c->word($self->{tab}), " (\n");
	my @col;
	for my $field (@{$self->{fieldset}}) {
		push @col, $field->sql unless $field->compute;
	}
	
	while(my ($key, $idx) = each %{$self->{indexes}}) {
		push @col, $idx->sql;
	}
	
	while(my ($key, $idx) = each %{$self->{indexref}}) {
		push @col, $idx->sql if $idx->fk->fieldset->{synced};
	}
	
	push @sql, join ",\n", @col;
	
	push @sql, "\n) ", join " ", $self->sql(undef, 1);
	join "", @sql;
}

# # переименовывает таблицу
# sub sql_rename {
	# my ($self, $tab) = @_;
	# my $c = $self->connect;
	# join "", "ALTER TABLE ", $c->word($self->{tab}), " RENAME ", $c->word($tab);
# }

# # переименовывает таблицу
# sub rename {
	# my ($self, $new_name) = @_;
	# my $c = $self->connect;
	# $c->do($self->sql_rename($new_name));
# }

# удаляет таблицу
sub drop {
	my ($self, $tab) = @_;
	
	$self->fire("drop", $self) if !defined $tab;
	return $self if $self->{noAction};
	
	my $c = $self->connect;
	my $tab = $tab // $self->{tab};
	
	# сносим fk указывающие на таблицу
	my $fk_info_bk = $c->fk_info_backward->{$tab};
	while(my($name, $fk) = each %$fk_info_bk) {
		$c->do(R::Model::Indexref::drop($self, $fk->{tab}, $name));
	}
	
	my $sql = "DROP TABLE " . $c->word($tab);
	$c->do($sql);

	# удаляем информацию о fk таблицы
	my $fk_info = $c->fk_info->{$tab};
	my $fk_info_bk = $c->fk_info_backward;
	while(my($name, $fk) = each %$fk_info) {
		delete $fk_info_bk->{$fk->{ref_tab}}{$name};
	}
	delete $c->fk_info->{$tab};
	
	$self->fire("dropped", $self) if !defined $tab;
	
	$self
}

# удаляет данные в таблице
sub truncate {
	my ($self) = @_;
	my $c = $self->connect;
	$c->do("truncate " . $c->word( $self->tab ));
	$self
}

1;