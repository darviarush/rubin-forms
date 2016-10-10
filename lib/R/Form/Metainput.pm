package R::Form::Metainput;
# метаинформация для инпута

use common::sense;
use R::App;

has qw/metaform name cls/;

$app->check->add_attributes;
die "no attributes!" if !*pattern{CODE};

# конструктор метаинпута
sub new {
	my ($cls, $type, $name, $metaform) = @_;
	
	die "метаформа всегда метаформа" if !Isa($metaform, "R::Form::Metaform");
	#msg1 "meta-new", $cls, $type, $name, $metaform->{name};
	my $self = bless {
		cls => $type,			# класс инпута
		name => $name,			# имя
		metaform => $metaform,	# метаформа
		param => $name,			# имя параметра запроса
		check => undef,			# валидаторы
		view => undef,			# валидаторы отображения
		mirror => undef,		# отображать если не отображается
		#model => undef,			# имя филдсета к которому привязан инпут
		#major => undef,			# ведущий инпут-модель
		#field => undef,			# филд к которому привязан инпут
		#model_view => undef,			# view модели у мойора
		attr => {},				# атрибуты общие
		attrin => {},			# атрибуты input
		attrsh => {},			# атрибуты show
		pre => undef,			# html-код до элемента
		post => undef,			# html-код после элемента
		presh => undef,			# html-код до элемента в режиме show
		postsh => undef,		# html-код после элемента show
		prein => undef,			# html-код до элемента в режиме input
		postin => undef,		# html-код после элемента input
	}, ref $cls || $cls;
	
	$self->init;	# для переопределения в наследниках
	$self
}

sub init {}

# добавляет валидатор по имени из зарегистрированных или возвращает очередь чекеров
sub _check {
	my $check_name = shift;
	sub {
		my $self = shift;
		my $check = $self->{$check_name} //= $app->check->new->stash(metainput => $self);
		$check->add(@_) if @_;
		$self
	}
}

*check = _check("check");
*view = _check("view");

# чекер для рефового поля
$app->check->register("input.refTo" => $app->check->class("inputRefTo" => \&_check_refTo));
sub _check_refTo {
	my ($self, $val) = @_;
	my $metainput = $self->stash("metainput");
	$val = $metainput->{field}->refTo->fieldset->model($val || undef);
	$self->val( $val );
}

# записываем в свойство major
$app->check->register("input.toMajor" => $app->check->class("inputToMajor" => \&_check_toMajor));
sub _check_toMajor {
	my ($self, $val) = @_;
	my $metainput = $self->stash("metainput");
	my $form = $self->stash("form");
	my $name = $metainput->{field}->name;
	$form->{param}{ $metainput->{major} }{val}{$name} = $val;
}

# считываем из майора значение по рефке
$app->check->register("view.majorRef" => $app->check->class("viewMajorRef" => \&_check_majorRef));
sub _check_majorRef {
	my ($self, $val) = @_;
	my $metainput = $self->stash("metainput");
	my $form = $self->stash("form");
	
	die "no metainput" if !$metainput;
	
	my $major = $metainput->{major};
	my $ref = $metainput->{field}{name};
	#msg1 "---->>>>";
	#msg1 "---->>>>", $major, $ref, $form->{param};
	$self->val( $form->{param}{$major}->$ref )
}

# чекер для модели
$app->check->register("input.model" => $app->check->class("inputModel" => \&_check_inputModel));
sub _check_inputModel {
	my ($self, $val) = @_;
	my $metainput = $self->stash("metainput");
	my $model = $metainput->{model};
	my $model_view = $metainput->{model_view};
	$val = $app->model->$model($val || undef);
	$val->view(@$model_view) if $model_view;		# app->model->x->view(...)
	$self->val( $val );
}

# устанавливает/возвращает модель
sub model {
	my $self = shift;
	if(@_) {
		my $model = $_[0];
		
		die "модель $self->{model} в инпут `$self->{name}` уже установлена. А устанавливается $model" if $self->{model};
		
		#$self->check( "undef" );
		#$self->view( "undef" );
		$self->check( "input.model");
		$self->view( "input.model");
		$self->{model} = $model;
		$self
	}
	else {
		$self->{model}
	}	
}

# связывает с филдом модели
# должен быть связан с другим филдом, представляющим модель
sub field {
	my ($self, $major, $name) = @_;
	
	die "метаформа всегда метаформа" if !Isa($self->metaform, "R::Form::Metaform");
	
	my $major_input = $self->metaform->at($major);
	my $mirrorOff = $major_input->{mirrorOff};
	my $fieldset = $app->modelMetafieldset->exists($major_input->{model});
	
	die "нет филдсета `$major_input->{model}` для $self->{metaform}{name}.$major" if !$fieldset;
	
	my $field = $fieldset->{field}{$name};
	die "нет филда $fieldset->{name}.$name для $self->{metaform}{name}.$major" if !$field;

	$self->{major} = $major;
	$self->{field} = $field;
	
	# добавляем отображение для модели 
	push @{$major_input->{model_view}}, $name;
	
	# устанавливаем всё что можно с филда
	$self->placeholder( $field->{remark} ) if !exists $self->{attrin}{placeholder} && exists $field->{remark};
	#$self->require if !$field->{null} && $field->isa("R::Model::Field::Col");
	# TODO: добавить чекеры из филда
	if( $field->{check} ) {
		$self->check->{check}->union($field->{check});
		#$self->view->{view}->union($field->{check});	# тоже надо, т.к. ещё и конвертеры там
	}
	
	$self->default($field->{raw_default}) if exists $field->{raw_default};
	
	# требуется перевести "" в undef, иначе не поймёт model
	#$self->check( "undef" );
	#$self->view( "undef" );
	
	# если с формы приходит рефка, то её нужно обернуть в модель	
	if($field->can("refTo")) {
		$self->check("input.refTo");
	}

	if( !$mirrorOff ) {	# если нужно отобразить - записываем в свойство major
	
		$self->check("input.toMajor");
	}
	
	# устанавливаем значение по умолчанию для отображения
	#$self->{mirror_view} = @{$self->{view}};
	
	$self->view("view.majorRef");	# считать из майора значение
	
	$self
}

# изменяет поведение взятых от этого параметра параметров-моделей формы
# 
# например:
# class MirrorForm inherits RubinForm
#	sub fields
#		self.add("task" => "hidden:task")
#		self.add("aim" => "hidden:aim").mirror.id.need
# 	end
#	sub allow then 1
# end
sub mirror {
	my ($self) = @_;
	$self->{mirrorOff} = 0;
	$self
}

# отключает отображение
sub mirrorOff {
	my ($self) = @_;
	$self->{mirrorOff} = 1;
	$self
}

# сообщает, что ожидается массив параметров
sub array {
	my $self = shift;
	$self->{param_array} = 1;
	$self
}

# устанавливает плейсхолдер
sub placeholder {
	my ($self, $placeholder) = @_;
	$self->{attrin}{placeholder} = $placeholder;
	$self
}


# указывает, что поле должно браться для определения разрешения (метода allow)
sub allow {
	my ($self) = @_;
	#$self->{allow} = 1;
	
	my $metaform = $self->{metaform};
	
	die "метаформа всегда метаформа" if !Isa($metaform, "R::Form::Metaform");
	
	push @{$metaform->{inputset_before}}, $self;
	$metaform->{inputset_after} = [grep { $_ != $self } @{$metaform->{inputset_after}}];
	
	$self
}

# указывает из какого параметра грузить
sub param {
	my ($self, $param) = @_;
	$self->{param} = $param;
	$self
}

# сокращение для param(id)
sub id {
	my ($self) = @_;
	$self->{param} = "id";
	$self
}


# сокращение для param(id2)
sub id2 {
	my ($self) = @_;
	$self->{param} = "id2";
	$self
}

# только для показа
sub showonly {
	my ($self) = @_;
	$self->{showonly} = 1;
	$self
}

# не имеет значения
sub novalidate {
	my ($self) = @_;
	$self->{novalidate} = 1;
	$self
}

# устанавливает атрибут класс
sub _class {
	my ($attr) = @_;
	sub {
		my ($self, $class) = @_;
		$self->{$attr}{class} = $class;
		$self
	}
}

*class = _class("attr");
*classin = _class("attrin");
*classsh = _class("attrsh");

# добавляет атрибуты
sub _attr {
	my ($attr) = @_;
	sub {
		my $self = shift;
		for(my $i=0; $i<@_; $i+=2) {
			my ($k, $v) = @_[$i, $i+1];
			$self->{$attr}{$k} = $v;
		}
		$self
	}
}

*attr = _attr("attr");
*attrin = _attr("attrin");
*attrsh = _attr("attrsh");

# устанавливает дефолтный параметр для отображения
sub default {
	my ($self, $default) = @_;
	$self->{value} = $default;
	$self
}

# не считывает параметр, а всегда устанавливает его
sub const {
	my ($self, $default) = @_;
	$self->param(undef)->default($default)
}

# устанавливает дефолтное значение (синоним default)
sub value {
	my ($self, $val) = @_;
	$self->{value} = $val;
	$self
}

# добавляет label к полю
sub label {
	my ($self, $label) = splice @_, 0, 2;
	
	$self->pre( LabelTag->new($label, @_) );
}

# добавляет label к полю
sub nlabel {
	my ($self, $label) = splice @_, 0, 2;
	
	$self->pre( NideLabelTag->new($label, @_) );
}

# добавляет label к полю
sub rlabel {
	my ($self, $label) = splice @_, 0, 2;
	
	$self->post( NideLabelTag->new($label, @_) );
}

# преобразует html
sub _escapeHTMLX {
	my $html = shift;
	my @html = ref $html? (
		Isa($html, "R::Html")? @$html: Can($html, "render")? $html:
		die "чего пихаешь сюда? просто скаляр или R::Html или объект с методом render только подойдёт. А ты `$html` запихнул"
	): @{$app->html->emmet($html)};
	
	$app->css->reg_html( @html );	# регистрируем классы css
	
	@html
}

# оборачивает в теги
sub _WRAP {
	my ($pre, $post) = @_;
	return sub {
		my ($self, $abbr) = @_;
		
		$self->{$pre} //= $app->html->new;
		$self->{$post} //= $app->html->new;
		
		my @html = @{ $app->html->emmet($abbr) };
		
		$app->css->reg_html( @html );	# регистрируем классы css
		
		unshift @{$self->{$pre}}, $html[0];
		push @{$self->{$post}}, $html[1];

		$self
	}
}

# добавляет html-текст до инпута
sub _PRE {
	my ($pre) = @_;
	return sub {
		return $_[0]->{$pre} if @_ == 1;
		my ($self, $html) = @_;
		$self->{$pre} //= $app->html->new;
		unshift @{$self->{$pre}}, _escapeHTMLX($html);
		$self
	}
}

# добавляет html-текст после инпута
sub _POST {
	my ($post) = @_;
	return sub {
		return $_[0]->{$post} if @_ == 1;
		my ($self, $html) = @_;
		$self->{$post} //= $app->html->new;
		push @{$self->{$post}}, _escapeHTMLX($html);
		$self
	}
}

*wrap = _WRAP("pre", "post");
*pre = _PRE("pre");
*post = _POST("post");

# то же для режима show
*wrapsh = _WRAP("presh", "postsh");
*presh = _PRE("presh");
*postsh = _POST("postsh");

# то же для режима input (allow)
*wrapin = _WRAP("prein", "postin");
*prein = _PRE("prein");
*postin = _POST("postin");


1;