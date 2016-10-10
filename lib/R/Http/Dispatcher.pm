package R::Http::Dispatcher;
# диспетчер - несёт всю информацию о диспетчере:
# кто (форма, экшн-отображение или функция контроллера), откуда (файл, строка)

use common::sense;
use R::App;

has qw/uri prefix controller action sub class file lineno olduri/;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		type => undef,			# тип диспетчера
		uri => undef,			# путь диспетчера
		olduri => undef,		# путь диспетчера, который был до переименования
		prefix => undef,		# путь контроллера
		controller => undef,	# пакет контроллера
		action => undef,		# имя экшена
		sub => undef,			# функция экшена
		class => undef,			# класс диспетчера (форма или страницы)
		file => undef,			# файл с диспетчером
		lineno => undef,		# номер строки в файле
	}, ref $cls || $cls;
}

our %TYPES  = (
	0 => [":red", "<dispatcher>", "dispatcher"],		# диспетчер
	1 => [":red dark", "<% ACTION %>", "action"],
	2 => [":green dark", "<on>", "on"],
	3 => [":cyan dark", "<class>", "class"],
	4 => [":magenta dark", "<controller/action>", "controller"],
);

our %TYPES_BY_NAME = map { $TYPES{$_}[2] => $_ } keys %TYPES;

# устанавливает тип как по имени, так и по номеру. Возвращает номер
sub type {
	my $self = shift;
	if(@_) {
		my $type = shift;
		$type = $TYPES_BY_NAME{$type} if $type !~ /^\d+$/;
		die "тип $type не определён" if !exists $TYPES{$type};
		$self->{type} = $type;
		$self
	}
	else {
		$self->{type}
	}
}


# переименовывает диспетчера
sub rename {
	my ($self, $new) = @_;
	$self->olduri($self->uri);
	$self->uri($new);
}

# выводит цветовую составляющую
sub color {
	my ($self) = @_;
	$TYPES{ $self->type }[0];
}

# выводит именную составляющую
sub name {
	my ($self) = @_;
	$TYPES{ $self->type }[1];
}

# выводит мелкое имя
sub nik {
	my ($self) = @_;
	$TYPES{ $self->type }[2];
}

# выводит класс или nik
sub cls {
	my ($self) = @_;
	$self->type==3? $self->class: $self->name;
}

# выводит controller/action или action
sub action_name {
	my ($self) = @_;
	$self->controller && $self->action? $self->controller . "/" . $self->action:
	$self->action? $self->action:
	""
}

1;