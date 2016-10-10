package R::Form::Input;
# представляет ввод с формы, может сам сформировать форму

use common::sense;
use R::App;

our %InputAttrs = $app->perl->set(qw/title class placeholder cols rows size pattern autocomplete maxlength max min step accept/);
our %InputAttrsOnce = $app->perl->set(qw/disabled readonly formnovalidate multiple required autofocus/);



has_const qw/meta form/;


# конструктор инпута
sub new {
	my ($cls, $meta, $form) = @_;

	#assert Isa($form, "RubinForm"), "форма всегда - рубин!";
	#assert Isa($meta, "R::Form::Metainput"), "метаинпут всегда метаинпут";
	
	my $self = bless {
		meta => $meta,
		form => $form,
	}, ref $cls || $cls;
	
	#msg1 "input", "$self", "created";
	#our %INPUTS;
	$app->{q}{_INPUTS}{int $self} = ref $self;
	
	use Scalar::Util qw/weaken/;
	weaken $self->{form};	# инпуты не должны держать форму
	
	$self
}

sub DESTROY {
	our %INPUTS;
	delete $app->{q}{_INPUTS}{int $_[0]};
	#msg1 "input", "$_[0]", "destroyed";
}


# создание метакласса, если его ещё нет сразу после полной загрузки views
sub create_meta {
	my ($cls) = @_;
	if( !@{"${cls}::Meta::ISA"} ) {
		my @isa = @{"${cls}::ISA"};
		@{"${cls}::Meta::ISA"} = $isa[0] eq "R::Form::Input"? "R::Form::Metainput": $isa[0] . "::Meta";
		
		#msg1 ':space', "${cls}::Meta", 'extends', @{"${cls}::Meta::ISA"};
	}
}

# идентификатор инпута
# int($self->form) для уникальных id, например, в label for, когда форма повторяется в списке
sub id {
	my ($self) = @_;
	$self->{id} //= "$self->{form}{Name}-$self->{meta}{name}";
}

# имя инпута
sub name {
	my ($self) = @_;
	$self->{meta}{name}
}

# имя параметра, реализуемого инпутом
sub param {
	my ($self) = @_;
	$self->{meta}{param}
}

# возвращает филд
sub field {
	my ($self) = @_;
	$self->{meta}{field}
}

# возвращает модель
sub model {
	my ($self) = @_;
	$self->{meta}{model}
}

# возвращает параметр инпута, в отличие от value, которое преобразует его
sub val {
	my ($self) = @_;
	
	exists $self->{val}? $self->{val}: do {
	
		my $param = $self->{form}{param};
		my $name = $self->name;
		
		$self->{val} = exists $param->{$name}? $param->{$name}: do {
			my $meta = $self->meta;
	
			#msg1 $name, $meta->{major}, $param;
			
			$meta->{major}? $param->{$meta->{major}}->$name:
			$self->{meta}{value}
		}
		
	}
}

# значение
sub value {
	if(@_ == 1) {
		my ($self) = @_;
		
		my $val = $self->val;
		
		#if(my $field = $self->field) {	
		#}
		
		if(ref $val) {
			if( Isa $val, "R::Model::Row" ) { $val->id }
			elsif( Can $val, "toCol" ) {
				$val->toCol;
			}
			else { die "value из val: не понятно что из себя представляет ".$app->perl->inline_dump($val) }
		}
		else {
			$val // $self->{meta}{value};
		}
	}
	else {
		my ($self, $value) = @_;
		$self->{value} = $value;
		$self
	}
}


# только показывать
sub showonly {
	my ($self) = @_;
	$self->{meta}{showonly}
}

# html-код вокруг инпута
sub _WRAP {
	my ($prefix) = @_;
	my $wrapprefix = "wrap$prefix";
	return sub {
		my ($self) = @_;
		my $ref = $self->{$prefix} // $self->{meta}{$prefix};
		$ref = $self->form->meta->{$wrapprefix} if !$ref && !Isa $self, "HiddenInput";
		return if !defined $ref;
		$app->html->new( map { ref $_? @{ $_->render($self) }: $_ } @$ref );
	}
}

*pre	= _WRAP("pre");
*post	= _WRAP("post");
*prein	= _WRAP("prein");
*postin	= _WRAP("postin");
*presh	= _WRAP("presh");
*postsh	= _WRAP("postsh");


# возвращает класс
sub class {
	my ($self) = @_;
	$self->{class} //= $self->{meta}{class}
}

# возвращает значение атрибута
sub _attr {
	my ($attr, $val) = @_;
	return "" if !defined $val;
	if($val ne "") {
		$val = '="' . $app->html->escape($val) . '"';
	} else {
		$val = "";
	}
	$app->html->new(" $attr$val");
}


my %JOIN_ATTR = (
	style => ";",
	class => ' ',
);

# возвращает все атрибуты, сворачивая или объединяя их
sub attrs {
	my $self = shift;
	my $meta = $self->{meta};
	my %attrs;
	my @order;
	
	for my $attrs ($meta->{"attr"}, $meta->{$self->{form}->hasAllow? "attrin": "attrsh"}, {@_}) {
		
		while(my ($attr, $val) = each %$attrs) {
			next if !defined $val;
			
			if(defined(my $old = $attrs{$attr})) {
				if(my $join = $JOIN_ATTR{$attr}) {
					$attrs{$attr} = join $join, $old, $val;
				} else {
					$attrs{$attr} = $val;
				}
			}
			else {
				$attrs{$attr} = $val;
				push @order, $attr;
			}
		}
	}
	
	my $v = $app->html->new;
	
	for my $attr (@order) {
		my $val = $attrs{$attr};
		if($val ne "") {
			$val = join "", '="', $app->html->escape($val), '"';
		} else {
			$val = "";
		}
		push @$v, " $attr$val";
	}
	
	$v
}

# возвращает набор объектов для select или подобных виджетов
sub refset {
	my ($self) = @_;
	
	if($self->{refset}) {$self->{refset}}
	elsif(my $fld = $self->field) {
		if($fld->{refset}) {$fld->{refset}}
		elsif($fld->can("refTo")) {
			#my $model = $fld->refTo->model;
			#$app->model->$model
			$fld->refTo->bean
		}
		# elsif($fld->isa("R::Model::Field::Ref")) {
			# my $model = $fld->ref->model;
			# $app->model->$model
		# }
		# elsif($fld->isa("R::Model::Field::Back")) {
			# my $model = $fld->ref->model;
			# $app->model->$model
		# }
		# elsif($fld->isa("R::Model::Field::M2m")) {
			# my $model = $fld->ref->model;
			# $app->model->$model
		# }
	}
	elsif(my $model = $self->model) {
		$app->meta->exists($model)->model
	}

}

# опции для селекта и т.д.
sub options {
	my ($self) = @_;
	
	#msg1 $self->{id}, !!$self->{field}->{refset}, $self->{field}->{ref}{model} .".". $self->{field}->{name};
	
	my $field;
	my $options = $self->{options} // $self->{meta}{options};
	
	if($options) {
		$options
	}
	elsif(my $refset = $self->refset) {
		
		my $major = $self->meta->{major};
		$major = $self->form->{param}{$major};
		
		$refset = $refset->($major, $self) if ref $refset eq "CODE";
		
		$self->{options} = [
			$self->_emptyoption,
			map {{ value => $_->{id}, text => $_->annonce }} Isa($refset, "R::Model::Rowset")? $refset->_rows: @$refset
		]
	}
	elsif(($field = $self->field) && $field->{class} && $field->{class}->isa("R::Model::Type::Enum")) {
		my $enum = $field->{dop_param};
		$self->{options} = [
			$self->_emptyoption,
			map { my $v=$enum->{$_}; +{ value => $_, text => ref($v)? ($v->{text} // $v->{label} // $v->{name}): $v } } sort { $a <=> $b } keys %$enum
		];
	}
	else {
		die "нет опций у инпута " . $self->id;
	}
	
}

# возвращает пустую опцию, если она нужна
sub _emptyoption {
	my ($self) = @_;
	
	my $meta = $self->{meta};
	
	return $meta->{_emptyoption} if exists $meta->{_emptyoption};
	
	my $field;
	
	return if (($field=$self->field) && $field->{null} == 0) || defined $meta->{check}->get("need");
	
	+{value => "", text => "- не выбрано -"};
}

# оборачивает в теги
# *R::Form::Input::wrap = \&R::Form::Metainput::wrap;
# *R::Form::Input::wrapin = \&R::Form::Metainput::wrapin;
# *R::Form::Input::wrapsh = \&R::Form::Metainput::wrapsh;
# *R::Form::Input::pre = \&R::Form::Metainput::pre;
# *R::Form::Input::prein = \&R::Form::Metainput::pre;
# *R::Form::Input::presh = \&R::Form::Metainput::pre;
# *R::Form::Input::post = \&R::Form::Metainput::post;
# *R::Form::Input::postin = \&R::Form::Metainput::postin;
# *R::Form::Input::postsh = \&R::Form::Metainput::postsh;


1;