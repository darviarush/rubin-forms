package R::Form::Form;
# форма - представляет объект модели в html

use common::sense;
use R::App;

use R::Form::Metaform;
use URI;

has qw/Name/;

# конструктор - синглетон
sub new {
	my $cls = shift;
	
	$cls = ref $cls || $cls;
	
	#my $models = { map { ($_->Fieldset->{name} => $_) } @_ };
	
	# если в запросе форма уже создана
	
	my $self = bless {
		#info => [],
		#errors => undef,	# ошибки формы
		#error => undef,	# ошибки полей ввода
		#isError => undef,	# хэш ошибок
		#param => {},		# параметры форм
		#answer => undef, 	# результат, возвращённый success или fail - проверяется exists в методе _answer
		#allow => undef,	# не должно быть ключа для первого запуска
		#method => "POST",	# метод формы
		#enctype => undef,	# формат отправляемых данных
		#id => 'form1',		# номер формы на странице, если форма 1-я, то "", иначе 2, 3...
	}, $cls;
	
	# получаем q
	my $q = $app->{q};
	
	# увеличиваем номер формы на странице
	my $number = $q->{NumberForms}{$cls}++;
	
	# формируем имя
	$self->{Name} = $number? $cls . $number: $cls;
	$self->{Number} = $number;
	
	# инициализация полей
	my $param = {};
	if(@_) {
		for(my $i=0; $i<@_; $i+=2) {
			my ($name, $val) = @_[$i, $i+1];
			$param->{$name} = ref $val? $val->{id}: $val;
		}
	}

	# инициализируем поля. Используется, когда allow=0 и нужно их инициализировать в show
	$self->{param_init} = $param;
	
	#msg1 "form", ref $self, "created";
	#our %FORMS;
	$q->{_FORMS}{int $self} = ref $self;
	
	# если форма уже есть (сохранялась в начале запроса)
	my $form = $q->{form};
	if($form and ref $form eq $cls) {
		
		my $equal = 1;
		
		$self->hasAllow;
		
		# у формы должны совпадать все параметры init, если они есть
		if(%$param) {

			while(my ($k, $v) = each %$param) {
				undef $equal if !exists $form->{param}{$k} or $form->{param}{$k} ne $v;
			}
			
		}
		# форма не имеет параметра: возращаем сразу
		if($equal) {
			$form->{param_init} = $param;
			$form->{Number} = $self->{Number};
			$form->{Name} = $self->{Name};
			$form->{Concat} = 1;
			return $form;
		}
	}
	
	
	
	$self
}


sub DESTROY {
	my ($self) = @_;
	#msg1 "form", ref $self, "destroyed";
	#our %FORMS;
	delete $app->{q}{_FORMS}{int $self};
}

# создание метаформы сразу после полной загрузки views
sub create_meta {
	my ($cls) = @_;
	R::Form::Metaform->new($cls);
}

# возвращает гиперссылку на форму
sub uri {
	my ($self) = @_;
	return $self->{uri} if exists $self->{uri};
	local ($&, $`, $');
	my $uri = ref $self || $self;
	$uri =~ s![A-Z]! "/" . lc $& !ge;
	$self->{uri} = $uri;
}

# возвращает url формы с параметрами
sub url {
	my ($self) = @_;
	
	return $self->{url} if exists $self->{url};
	
	my @param;
	my @id;
	my $meta = $self->meta;
	my $q = $app->q;
	
	$self->hasAllow;
	$self->check;
	
	for my $metainput (@{$meta->{inputset}}) {
		my $param = $metainput->{param};
		next if !defined $param;
		
		my $name = $metainput->{name};
		my $val = $self->at($name)->value;
		
		my $id = $param =~ /^id(\d+)?$/? ($1 // 1)-1: undef;

		if(defined $id and $val =~ /^\d+$/) { $id[$id] = $val }
		else { push @param, $param, $val }
	}

	my $uri = URI->new( $self->uri . join("_", @id) );
	$uri->query_form(@param);
	$self->{url} //= $uri->as_string;
}

# класс для ссылки на форму (метод href в RubinForm)
sub href_class {
	my ($self) = @_;
	$self->{href_class} //= $self->meta->{href_class}
}

#  для ссылки на форму (метод href в RubinForm)
sub href_label {
	my ($self) = @_;
	$self->{href_label} //= $self->meta->{href_label}
}

# имеет разрешение
sub hasAllow {
	my ($self) = @_;
	exists $self->{allow}? $self->{allow}: do {
		$self->runInit;
		$self->check(1);
		$self->{allow} = $self->isErrors? undef: $self->allow($self->{param});
	};
}

# валидация параметров
# проводится в 2 этапа:
# 1. для allow-параметров
# 2. для save - из q.param
# а для view производится своя "валидация"
sub check {
	my ($self, $to_allow) = @_;
	
	my $to_name = $to_allow? "param_allow": "param_view";
	
	return $self if $self->{ $to_name };
	
	my $q = $app->{q};
	
	my $method = $self->{save} == 1? $q->can(lc $self->meta->method):	# для сохранения формы через @action
		$self->{save} == 2? $q->can("param"):		# для link и ajax
		$self->{save} == 3? $q->can("uriparam"):	# для пейджеров
		$q->can("ids");								# для обычного отображения формы
	
	# считываем параметры и проводим валидацию
	my $meta = $self->meta;
	my $cur_param = $self->{ $to_name } = {};
	my $param = $self->{"param"} //= {};
	my $init = $to_allow? $self->{param_init}: {};	# когда использовать init? todo: сделать тест с типовыми формами
	my $inputs = $to_allow? $meta->{inputset_before}: $meta->{inputset_after};
	
	for my $metainput (@$inputs) {
		# валидацию нельзя проводить, если поле только для чтения	
		next if $metainput->{showonly};
		next if $metainput->{novalidate};

		my $key = $metainput->{'param'};
		
		my $name = $metainput->{name};
		# если поле инициализировано - берём инициализированное
		my $val = exists $init->{$name}? $init->{$name}:
		#my $val =
			# если у поля нет параметра - берём дефолтный
			defined($key)?
				($metainput->{param_array}?
					[$method->($q, $key)]:
					scalar($method->($q, $key) // $metainput->{value})
				):
				$metainput->{value}
			;
		
		#msg1 $name, $metainput->name;
		
		my $check = $metainput->{check};
		if($check) {
			my $e = $check->stash(form=>$self)->test($val);
			$self->addError($name => $e) if defined $e;
			$check->stash(form=>undef);
		}
		
		$cur_param->{$name} = $param->{$name} = $val;
	}
	
	$self
}

# запускает init единожды
sub runInit {
	my ($self) = @_;
	
	return $self if $self->{runInit};
	$self->{runInit} = 1;

	$self->init($self->{param_init});
	
	$self
}


# устанавливает дефолтные значения параметрам для представления
# и запускает view
sub runView {
	my ($self) = @_;

	return $self if $self->{runView};
	$self->{runView} = 1;
	
	if($self->{save} == 1) {				# опа - тут у нас сохранение
		$self->{save} = 0;					# отключаем брать из POST-параметров
		delete $self->{param_allow};		# заново распознаём allow-параметры
	}
	
	$self->check(1);
	
	my $meta = $self->meta;
	my $inputs = $meta->{inputset_after};	# перезаписываем только не allow-параметры
	my $param = $self->{'param'} //= {};
	my $param_view = $self->{'param_view'} //= {};
	my $init = $self->{'param_init'};
	
	#msg1 "runView", $param;
	
	for my $metainput (@$inputs) {
		
		next if $metainput->{novalidate};
		
		my $name = $metainput->{name};

		my $val = exists $init->{$name}? $init->{$name}: $metainput->{value};
		
		# запускаем чекеры метаинпута
		my $view = $metainput->{view};
		if($view) {
			my $e = $view->stash(form=>$self)->test($val);
			$self->addError($name => $e) if defined $e;
			$view->stash(form => undef);
		}
		
		$param_view->{$name} = $param->{$name} = $val;		# перезаписываем параметры
	}

	$self->view($self->{param_allow}, $param_view);
}

# через form.new, hasAllow или init устанвливаются начальные значения, помеченные "allow"
# если в form:param для "allow" уже есть ключ - check не будет его переустанавливать
# после complete, перед view param заменяется на param_init

# СХЕМА form.start
#
#			start
#			  |
# 			init
#			 |
# 	нет -- allow --- да
#	 |				 |
#	 |				save
#	 |				 |
#	 |				check
#	 |				 |
#	 |			  validate
#	 |				 |
#	 |		 нет - isErrors - да
#	 |		  |			      |
#	 |		error		   success
#	 |		 |			     |
#	 |		 --- complete ---
#	 |				|
#    ------ view ----
#			|
#		 content
#			|
#		  finish
#			|
#		  end

# init запускается через runInit в hasAllow

# параметры инициализируются через конструктор формы: new MyForm(param1=>val1...)
# или через переопределённый метод init
# инициализированные параметры уже не считываются из параметров скрипта
# 'allow'-параметры считываются и при save и при view, но если у них нет param - инициализируются из meta.value
# остальные параметры при save считываются, а при view устанавливаются из meta.value (переписываются)
# view срабатывает, если не было ошибок формы и при считывании параметров и при success


# инициализатор - запускается при старте формы до hasAllow
sub init {}

# обработчик валидации - позволяет добавить ошибки. Запускается после валидации
sub validate {}

# обработчик успешного завершения
sub success {}

# обработчик ошибки
sub error {}

# обработчик сохранения формы. Выполняется в любом случае
sub complete {}

# устанавливает данные для формы
sub view {}

# вызывается после отображения формы из end
sub finish {}

# вызывается для сохраниения результатов
# возвращает результат обработчика success или error
sub save {
	my ($self) = @_;
	
	#return $self if exists $self->{answer};
	
	# проверяем, что можно редактировать, заодно в hasAllow будет вызван check(1) и подготовлены allow_param
	$self->addErrors($app->locale->PERMISSION_DENIED) if !$self->hasAllow;
	
	# можно редактировать
	
	$self->check;	# получаем, преобразуем и проверяем параметры
	
	my $param_allow = $self->{param_allow};
	my $param_view = $self->{param_view};
	
	$self->validate($param_allow, $param_view);	# обработчик валидации
	
	my $answer;
	if($self->isErrors) {	# есть ошибки на форме
		$answer = $self->error($param_allow, $param_view);
	} else {				# всё ок
		$answer = $self->success($param_allow, $param_view);
	}
	
	# ну и в любом случае
	$self->complete($param_allow, $param_view, $answer);
	
	$app->{q}->head("X-Errors" => scalar keys %{$self->{isError}}) if $self->isErrors;
	
	#msg1 $self->isErrors, $self->{error}, $self->{errors}, $self->{isError};
	
	# сохраняем параметры формы
	my $param = $self->{param};
	while(my ($key, $val) = each %$param) {
		$val->save if Isa($val, "R::Model::Row") and $val->{save};
	}
	
	$answer
}

# есть ли ошибки на форме
sub isErrors {
	my ($self) = @_;
	!!$self->{isError}
}

# проверяет - установлена ли такая ошибка
sub hasError {
	my ($self, $error) = @_;
	!!$self->{isError}{$error}
}

# добавляет ошибки в форму
sub addErrors {
	my $self = shift;
	local $_;
	push @{$self->{errors}}, @_;
	$self->{isError}{$_} = 1 for @_;
	$self
}

# добавляет информацию в форму
sub addInfo {
	my $self = shift;
	push @{$self->{info}}, @_;
	$self
}

# добавляет ошибку к полю
sub addError {
	my ($self, $name, $error) = @_;
	$self->{error}{$name} = $error;
	$self->{isError}{$error} = 1;
	$self
}

# возвращает указанный инпут. Служит, когда название инпута перекрывается какой-то функцией
require Scalar::Util;
sub at {
	my ($self, $name) = @_;
	# форма держит инпут, а инпут форму - нет
	$self->{inputs}{$name} //= $self->sex($name);
}

# порождает инпут по имени
sub sex {
	if(@_==2) {
		my ($self, $name) = @_;
		my $metainput = $self->meta->{inputs}{$name};
		die "нет инпута `$name` на форме " . ref $self if !$metainput;
		$metainput->{cls}->new($metainput, $self)
	} elsif(@_>2) {
		my ($self, $name, $type) = splice @_, 0, 3;
		my $metainput = $self->meta->add($name => $type);
		
		for(my $i=0; $i<@_; $i+=2) {
			my ($key, $val) = @_[$i, $i+1];
			$metainput->$key($val);
		}
		
		$metainput->{cls}->new($metainput, $self);
	} else {
		my ($self) = @_;
		die "не указано имя инпута на форме " . ref $self;
	}
}

# если форма вставлена в шаблон - распечатывает всю форму
sub render {
	my ($self) = @_;
	
	# ничего не выводим если указано ничего не выводить
	return if $self->meta->{pass} && !$self->hasAllow;
	
	my $output = $self->start;
	push @$output, @{$self->content};
	push @$output, @{$self->end};
	$output
}

# возвращает содержимое формы
sub content {
	my ($self) = @_;
	
	my $output = $app->html->new;
	my $meta = $self->meta;
	my $hidden = $meta->{hiddens};
	
	for my $metainput ( @{$meta->{inputset}} ) {
		my $name = $metainput->{name};
		next if exists $hidden->{$name};
		my $input = $self->at($name);
		push @$output, @{ $input->all };
	}
	
	$output
}

# запускается в end
sub runInEnd {
	my ($self) = @_;
	
	my $param = $self->{param};
	$self->finish($param);
	
	$self
}

1;