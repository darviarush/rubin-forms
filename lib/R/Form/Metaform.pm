package R::Form::Metaform;
# метаинформация о форме - аналог фиелдсета

use common::sense;
use R::App;

use R::Form::Metainput;		# для wrap

has qw/form name inputset inputs hiddens class action method/;

our %FORM;

# проверяет - есть ли форма
sub exists {
	my ($cls, $form) = @_;
	$FORM{ref $form || $form}
}

# конструктор - синглетон
sub new {
	my ($cls, $form) = @_;
	
	$form = ref $form || $form;
	
	return $FORM{$form} if exists $FORM{$form};
	
	# $form - класс формы
	my $name = $form;
	$name =~ s/::/-/g;
	
	my $self = bless {
		name => $name,			# имя формы
		form => $form,			# класс формы
		inputset => [],			# инпуты по порядку
		inputset_before => [],	# инпуты с allow
		inputset_after => [],	# инпуты без allow
		inputs => {},			# инпуты по имени
		hiddens => {},			# скрытые инпуты
		visibleset => [],		# не скрытые инпуты по порядку
		#model => undef,		# имя модели, которую представляет
		method => "POST",		# метод формы - POST или GET
		action => undef,		# экшн формы
		class => undef,			# класс тега формы
		wrappre => undef,		# html перед каждым инпутом. Так же: wrappresh, wrapprein
		wrappost => undef,		# html после каждого инпута
		pre => undef,			# html переl формой
		post => undef,			# html после формы
		before => undef,		# html после открывающего тега формы
		after => undef,			# html перед закрывающим тегом формы
		pass => undef,			# не выводить форму, если не allow
	}, ref $cls || $cls;
	
	
	*{"${form}::meta"} = closure( $self, sub { shift() } );
	
	#msg1 "form->", $name;
	
	$_->($self) for $app->perl->canall($form, "fields");
	$self->submit if !$self->{inputs}{"submit"};
	
	#msg1 "form->fields", $name;
	
	$FORM{$form} = $self;
}

# создаёт поле
sub add {
	my $self = shift;
	
	my ($name, $type, @model) = $self->name_type_model(@_);
	
	die "инпут $name на форме $self->{name} уже существует" if exists $self->{inputs}{$name};
	
	$type ||= "line";
	
	my $cls_input = ucfirst($type) . "Input";
	my $cls_meta = $cls_input . "::Meta";
	
	my $input = $cls_meta->new($cls_input, $name, $self);
	
	die "метаинпут $self->{form}.$name класса $cls_meta не вызвал конструктор" if !$input->{name};
	
	push @{$self->{inputset}}, $input;
	push @{$self->{inputset_after}}, $input;
	
	
	push @{$self->{visibleset}}, $self->{inputs}{$name} = $input;
	$self->{hiddens}{$name} = $input if $type eq "hidden";
	
	$input->model($model[0]) if @model == 1;
	$input->field(@model) if @model>1;
	
	my $cls = $self->form;
	
	# создаём метод
	if(!$cls->can($name)) {
		eval "sub ${cls}::$name {
			if(\@_>1) {
				my \$self=shift;
				if(\@_==1) {
					\$self->{param}{'$name'} = shift;
				} else {
					my \$i = \$self->at('$name');
					%\$i = ( %\$i, \@_ );
				}
				\$self 
			}
			else { shift->at('$name') }
		}";
		die $@ if $@;
	}
	else {
		#msg "имя метода для инпута $name на форме $cls - занято";
	}
	
	$input
}


# удаляет метаинпут из метаформы
sub del {
	my ($self, $name) = @_;
	my $del = delete $self->{inputs}{$name};
	delete $self->{hiddens}{$name};
	$self->{inputset} = [ grep { $_ != $del } @{$self->{inputset}} ];
	$self->{inputset_after} = [ grep { $_ != $del } @{$self->{inputset_after}} ];
	$self->{inputset_before} = [ grep { $_ != $del } @{$self->{inputset_before}} ];
	$self
}

# заменяет инпут
sub ovl {
	my $self = shift;
	my ($name) = $self->name_type_model(@_);
	$self->del($name)->add(@_)
}

# по переданным параметрам определяет тип и модель
sub name_type_model {
	my ($self, $name, $type) = @_;
	
	$type = $name, $name = undef if @_==2;
	
	($type, my $model) = split /:/, $type;
	
	my @model = split /\./, $model;
	
	my $field;
	if(@model>1) {
		$name = $model[$#model] if !defined $name;
		
		my $metainput = $self->{inputs}{$model[0]};
		my $fieldset_name = $metainput->{model};
		die "нет модели в поле $model[0], для поля $self->{name}.$name" if !defined $fieldset_name;
		my $fieldset = $app->meta->exists($fieldset_name);
		#msg1 \@model;
		die "нет модели $fieldset_name, указанной в поле $self->{name}.$name" if !$fieldset;
		$field = $fieldset->field($model[1]);
		
		my $inp = $field->input;
		
		$type ||= ref $inp? $inp->{type}: $inp;
	} else {
		$name = $model if !defined $name;
		$type ||= $app->meta->exists($model[0])->{input};
	}
	
	return $name, $type, @model;
}

# возвращает инпут по имени
sub at {
	my ($self, $at) = @_;
	$self->{inputs}{$at}
}

# добавляет поля из указанной модели
sub for {
	my ($self, $input, @fld) = @_;
	my $meta = $app->modelMetafieldset;
	my $model = $self->at($input)->model;
	my $fieldset = $meta->exists($model);
	
	die "нет модели `$model`" if !defined $fieldset;
	
	my $fld = $fieldset->{field};
	my $cls = ref $self;
	
	local $_;
	
	for my $field (@fld? map({ $fld->{$_} } @fld): grep { $_->{name} ne "id" } @{$fieldset->{fieldset}}) {
		my $name = $field->{name};
	
		$self->add($name => ":$input.$name");
	}
	
	$cls
}


# создаёт submit
sub submit {
	my ($self, $value) = @_;
	my $submit = $self->at("submit");
	return $submit->value($value) if $submit;
	$self->add("submit" => "submit")->value($value // $app->sign->faCheck . " Отправить")
}

# метод GET
sub GET {
	my ($self) = @_;
	$self->method("GET")
}

# метод POST
sub POST {
	my ($self) = @_;
	$self->method("POST")
}

# тип формы "для добавления", по умолчанию
# при сохранении формы, если не было ошибок, будут показаны параметры "для отображения"
sub ADD {
	my ($self) = @_;
	delete $self->{MOD};
	$self
}

# тип формы "для редактирования". 
# при редактировании не вызывает initView
# не используется в pages. Pages всегда EXMOD
sub MOD {
	my ($self) = @_;
	$self->{MOD} = 1;
	$self
}

# тип формы "для редактирования". 
# при редактировании не вызывает initView, но вызывает view
# не используется в pages. Pages всегда EXMOD
# sub EXMOD {
	# my ($self) = @_;
	# $self->{MOD} = 2;
	# $self
# }

# указывает не выводить форму, если нет разрешения (hasAllow)
sub pass {
	my ($self) = @_;
	$self->{pass} = 1;
	$self
}

# уникальное имя
sub uniq_name {
	my ($self, $dop) = @_;
	$dop . ++$self->{uniq}{$dop};
}

# оборачивает в emmet несколько инпутов
# параметры: для всех, для allow, для !allow
sub wrap {

	goto &R::Form::Metainput::wrap if ref $_[$#_] ne "CODE";

	my $self = shift;
	my $sub = pop;
	#my ($wrap, $wrapin, $wrapsh) = @_;
	
	local $_;
	
	my $visibleset = $self->{visibleset};
	
	my @PRE = ("pre", "prein", "presh");
	my @POST = ("post", "postin", "postsh");
	my @pre;
	my @post;
	my $POS = @$visibleset;
	
	my $i = -1;
	
	for my $wrap (@_) {
		$i++;
		
		next if !defined $wrap;
		
		my @html = @{ $app->html->emmet($wrap) };
	
		$app->css->reg_html(@html);
		
		$pre[$i] = $html[0];
		$post[$i] = $html[1];
	}
	
	# выполняем блок
	$sub->();
	
	# а иначе - создаём фиктивный инпут
	$self->add($self->uniq_name("fake") => "fake") if @$visibleset == $POS;
	
	$i = -1;
	
	for my $wrap (@_) {
		$i++;
	
		next if !defined $wrap;

		my $pre = $PRE[$i];
		my $post = $POST[$i];
	
		push @{ $visibleset->[$POS]->{$pre} }, $pre[$i];
		push @{ $visibleset->[$#$visibleset]->{$post} }, $post[$i];
	}
	
	$self
}

# оборачивает форму
#*wrap = \&R::Form::Metainput::wrap;
*wrapin = \&R::Form::Metainput::wrapin;
*wrapsh = \&R::Form::Metainput::wrapsh;
*pre = \&R::Form::Metainput::pre;
*prein = \&R::Form::Metainput::prein;
*presh = \&R::Form::Metainput::presh;
*post = \&R::Form::Metainput::post;
*postin = \&R::Form::Metainput::postin;
*postsh = \&R::Form::Metainput::postsh;

# оборачивает в теги каждый инпут, кроме скрытых
*each = R::Form::Metainput::_WRAP("wrappre", "wrappost");

# добавляет перед контентом, после тега формы и перед закрывающим тегом формы
*inner = R::Form::Metainput::_WRAP("before", "after");
*before = R::Form::Metainput::_PRE("before");
*after = R::Form::Metainput::_POST("after");

# то же для режима show
*eachsh = R::Form::Metainput::_WRAP("wrappresh", "wrappostsh");
*innersh = R::Form::Metainput::_WRAP("beforesh", "aftersh");
*beforesh = R::Form::Metainput::_PRE("beforesh");
*aftersh = R::Form::Metainput::_POST("aftersh");

# то же для режима input (allow)
*eachin = R::Form::Metainput::_WRAP("wrapprein", "wrappostin");
*innerin = R::Form::Metainput::_WRAP("beforein", "afterin");
*beforein = R::Form::Metainput::_PRE("beforein");
*afterin = R::Form::Metainput::_POST("afterin");




1;