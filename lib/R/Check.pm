package R::Check;
# очередь валидаторов и преобразователей

use common::sense;
use R::App;

our %Check;
our %Sinonim = (
	required => "need",
	require => "need",
	positive_integer => "uint",
	integer => "int",
	double => "float",
);

# конструктор - создаёт новую очередь валидаторов
sub new {
	my ($cls) = @_;
	bless {
		stash => {},	# дополнительные параметры
		tests => [],	# очередь тестов
	}, ref $cls || $cls;
}

# регистрирует класс в чекерах
sub register {
	my ($self, $name, $class) = @_;
	
	if(ref $class eq "CODE") {
		my $n = $name;
		$n =~ s/\W/_/g;
		$class = $self->class("$n" => $class);
	}
	
	die "Регистрируемый чекер `$class` должен наследовать `R::Check::Rubin`" if !$class->isa("R::Check::Rubin");
	
	die "чекер с именем `$name` уже зарегистрирован" if exists $Check{$name} or exists $Sinonim{$name};
	
	$Check{$name} = $class;
	
	$self
}

# добавляет в очередь чекеры с другого чекера
sub union {
	my ($self, $any_check) = @_;
	
	for my $test (@{$any_check->{tests}}) {
		$self->add($test->{name}, @{$test->{args}});
	}
	
	$self->stash(%{$any_check->{stash}});
	
	$self
}

# добавляет чекер в очередь
sub add {
	my $self = shift;
	my ($name) = @_;
	
	$name = $Sinonim{$name} // $name;
	
	die "чекера `$name` не существует" if !exists $Check{$name};

	my $check = $Check{$name}->new(@_);
	$check->{stash} = $self->{stash};
	push @{$self->{tests}}, $check;
	
	$self
}

# добавляет дополнительные параметры для всех чекеров
sub stash {
	my $self = shift;
	
	my $stash = $self->{stash};
	for(my $i=0; $i<@_; $i+=2) {
		my ($k, $v) = @_[$i, $i+1];
		$stash->{$k} = $v;
	}
	
	$self
}

# возвращает номер по имени
sub pos {
	my ($self, $name, $not_error) = @_;
	
	my $pos = $self->get($name);
	
	die "нет чекера `$name` в очереди" if !defined $pos and !$not_error;
	$pos
}

# возвращает позицию чекера с именем name в очереди или undef
sub get {
	my ($self, $name) = @_;
	my $tests = $self->{tests};
	for(my $i=@$tests-1; $i>=0; $i--) {
		return $i if $tests->[$i]{name} eq $name;
	}
	undef
}

# удаляет последний чекер из очереди с указанным именем
sub del {
	my ($self, $name, $not_error) = @_;
	
	splice @{$self->{tests}}, $self->pos($name, $not_error), 1;
	
	$self
}

# добавляет наименование ошибки к последнему или ко всем по имени
sub error {
	my ($self, $name, $error) = @_;
	my $tests = $self->{tests};
	my $pos;
	
	if(@_ == 2) {
		$error = $name;
		$pos = $#$tests;
	} else {
		$pos = $self->pos($name);
	}
	
	$tests->[$pos]->{error} = $error;
	$self
}

# количество чекеров
sub length {
	my ($self) = @_;
	0+@{$self->{tests}}
}

# тестирует и изменяет val
sub test {
	my ($self, $val) = @_;
	
	my $setval;
	
	for my $check (@{$self->{tests}}) {
		$check->test($val);
		$setval=1, $val = delete $check->{val_} if exists $check->{val_};
		return delete $check->{error_} if exists $check->{error_};
	}
	
	$_[1] = $val if $setval;
	
	return;
}



# хелпер - создаёт класс чекера для регистрации
sub class {
	my ($self, $name, $test) = @_;
	
	my $class = "R::Check::" . ucfirst $name;
	
	die "$class уже существует. Его ISA=" . join(", ", @{"${class}::ISA"}) if @{"${class}::ISA"} > 0;
	
	@{"${class}::ISA"} = qw/R::Check::Rubin/;
	*{"${class}::test"} = $test;
	
	$class
}

# есть ли чекер?
sub exists {
	my ($self, $name) = @_;
	$Check{$Sinonim{$name} // $name}
}

# возвращает хэш чекеров
sub checkers {
	\%Check
}

# добавляет атрибуты
sub add_attributes {
	my ($self, $code) = @_;
	
	my $package = caller;
	

	for my $check (keys(%Check), keys %Sinonim) {
	
		next if $check !~ /^\w+$/;
	
		#die "не могу установить чекер: уже есть метод $check" 
		next if $package->can($check);
		
		*{"${package}::$check"} = closure $check, $code // sub {
			my($name, $self) = splice @_, 0, 2;
			$self->check($name, @_);
		};
	}
	
	$self
}

# базовый класс чекеров
package R::Check::Rubin {
	
	# конструктор
	sub new {
		my $cls = shift;
		my $name = shift;
		my $self = bless { name=>$name, args=>[@_] }, ref $cls || $cls;
		#$self->init;	# инициализация
		$self
	}
	
	# устанавливает новое значение
	sub val {
		my ($self, $val) = @_;
		$self->{val_} = $val;
		$self
	}
	
	# устанавливает ошибку
	sub error {
		my ($self, $error) = @_;
		$self->{error_} = $self->{error} // $error;
		$self
	}

	# возвращает все аргументы
	sub args {
		my ($self) = @_;
		@{$self->{args}}
	}
	
	# возвращает аргумент по индексу
	sub arg {
		my ($self, $idx) = @_;
		$self->{args}[$idx]
	}
	
	# возвращает элемент из сташа
	sub stash {
		my ($self, $key) = @_;
		$self->{stash}{$key}
	}
	
}


### имя - класс чекера ###
our %Check = (

	undef => do {
		# идентификатор базы данных, если приходит "", то превращается в undef
		package R::Check::Undef; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			$self->val(undef) if $val eq "";
		}
		__PACKAGE__
	},

	leave_only => do { 
		# пропускает только указанные символы
		# можно указывать символы через "-". "-" нужно экранировать: "\-"
		package R::Check::LeaveOnly; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $leave = $self->arg;
			$val =~ s/[^$leave]+//g;
			$self->val($val);
		}
		__PACKAGE__
	},

	split => do {
		# разбивает по маске и превращает в ссылку на массив
		package R::Check::Split; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $sep = $self->arg;
			$self->val(split $sep, $val);
		}
		__PACKAGE__
	},
	
	to_uc => do {
		# переводит в верхний регистр
		package R::Check::ToUc; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			$self->val(uc $val);
		}
		__PACKAGE__
	},

	to_lc => do { 
		# переводит в нижний регистр
		package R::Check::ToLc; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			$self->val(lc $val);
		}
		__PACKAGE__
	},
	
	model => do {
		# модель
		package R::Check::Model; use parent qw/-norequire R::Check::Rubin/;		
		use R::App;
		sub test {
			my ($self, $val) = @_;
			my $model = $self->arg;
			$self->val( $app->model->$model($val) );
		}
		__PACKAGE__
	},

	trim => do {
		# обрезает пробелы с обеих стророн строки
		package R::Check::Trim; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			$val =~ s/^\s*(.*)\s*$/$1/s;
			$self->val($val);
		}
		__PACKAGE__
	},
	
	need => do {
		# обязательное поле. Синонимы: required, require
		package R::Check::Need; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			$self->error($self->arg // "обязательное поле") if !defined $val;
		}
		__PACKAGE__
	},

	max_length => do {
		# максимальная длина
		package R::Check::MaxLength; use parent qw/-norequire R::Check::Rubin/;
		use R::App;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $len = $self->arg;
			$self->error($self->arg(1) // "максимум $len " . $app->locale->abbr($len, "символ", "символа", "символов")) if length $val > $len;
		}
		__PACKAGE__
	},

	min_length => do {
		# минимальная длина
		package R::Check::MinLength; use parent qw/-norequire R::Check::Rubin/;
		use R::App;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $len = $self->arg;
			$self->error($self->arg(1) // "минимум $len " . $app->locale->abbr($len, "символ", "символа", "символов")) if length $val < $len;
		}
		__PACKAGE__
	},
	
	length_between => do {
		# длина между
		package R::Check::lengthBetween; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $from = $self->arg;
			my $to = $self->arg(1);
			$self->error($self->arg(2) // "длина от $from до $to символов") if !($from <= length $val && length $val <= $to);
		}
		__PACKAGE__
	},
	
	natural => do {
		# проверяет, что значение - натуральное
		package R::Check::Natural; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			$self->error($self->arg // "должно быть целое больше нуля") if $val !~ /^\d+$/;
		}
		__PACKAGE__
	},
	
	uint => do {
		# положительное целое
		package R::Check::UInt; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			$self->error($self->arg // "должно быть положительное целое") if $val !~ /^\d+$/;
		}
		__PACKAGE__
	},
	
	int => do {
		# целое
		package R::Check::Int; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			$self->error($self->arg // "должно быть целое") if $val !~ /^-?\d+$/;
		}
		__PACKAGE__
	},

	float => do {
		# плавающее
		package R::Check::Float; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			$self->error($self->arg // "должно быть дробное") if !Num $val;
		}
		__PACKAGE__
	},
	
	user_pass => do {
		# добавляет валидатор, к-й сверяет переданный пароль с паролем текущего пользователя
		# требует наличия параметра form и работает только в запросе http
		package R::Check::UserPass; use parent qw/-norequire R::Check::Rubin/;
		use R::App;
		sub test {
			my ($self, $val) = @_;
			my $user = $app->q->user;
			my $form = $self->stash("form");
			$form->addErrors($self->arg(1) // "пользователь не залогинен"), return if !$user->{id};
			$self->error($self->arg // "пароль не совпадает") if $user->passwd ne $app->perl->cipher($val);
		}
		__PACKAGE__
	},
	
	equal_to_field => do {
		# равно полю (поле должно быть описано выше этого)
		package R::Check::EqualToField; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			my $form = $self->stash("form");
			my $field = $self->arg;
			$self->error($self->arg(1) // "не равно") if $val ne $form->{param}{$field};
		}
		__PACKAGE__
	},

	max => do {
		# максимальное число
		package R::Check::Max; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $len = $self->arg;
			$self->error($self->arg(1) // "максимум - $len") if $val > $len;
		}
		__PACKAGE__
	},
	
	min => do {
		# минимальное число
		package R::Check::Min; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $len = $self->arg;
			$self->error($self->arg(1) // "минимум - $len") if $val < $len;
		}
		__PACKAGE__
	},
	
	between => do {
		# число между
		package R::Check::Between; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $from = $self->arg;
			my $to = $self->arg(1);
			$self->error($self->arg(2) // "должно быть от $from до $to") if $from <= $val && $val <= $to;
		}
		__PACKAGE__
	},
	
	one_of => do {
		# одно из значений
		package R::Check::OneOf; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $enum = $self->arg;
			$self->error($self->arg(1) // "значение должно быть одно из: " . join ", ", @$enum) if !grep { $val eq $_ } @$enum;
		}
		__PACKAGE__
	},
	
	pattern => do {
		# устанавливает паттерн, для ввода
		package R::Check::Pattern; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			my $pattern = $self->arg;
			$self->error($self->arg(1) // "не соответствует шаблону $pattern") if $val !~ $pattern;
		}
		__PACKAGE__
	},
	
	email => do {
		# email
		package R::Check::Email; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			return if !defined $val;	# для null
			$self->error($self->arg // "должен быть e-mail адрес") if $val !~ /\@/;
		}
		__PACKAGE__
	},

	load => do {
		# загружает модель
		package R::Check::Load; use parent qw/-norequire R::Check::Rubin/;
		sub test {
			my ($self, $val) = @_;
			
			if( !ref $val ) {
				use R::App;
				my $model = $self->arg;
				$val = $app->model->$model($val || undef);
				$self->val($val);
			}
			
			$self->error($self->arg(1) // "не существует модель") if !$val->exists;
		}
		__PACKAGE__
	},

	not_found => do {
		# ошибка 404, если есть ошибка на этом поле
		package R::Check::NotFound; use parent qw/-norequire R::Check::Rubin/;
		use R::App;
		sub test {
			my ($self, $val) = @_;
			die $app->raise->bingo("error/404" => "not found") if $self->{error};
		}
		__PACKAGE__
	},
	
);


1;