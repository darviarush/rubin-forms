package R::Cache;
# клиент кэша app->cacheServer

use parent qw/R::Process::Client/;

use common::sense;
use R::App;

# # конструктор
# sub new {
	# my $cls = shift;
	# my $self = $cls->SUPER::new(@_);
	# $self->{remote} //= $app->ini->{cache}{remote};
	# $self->{port} //= $app->ini->{cache}{port};
	# $self
# }

# отправляет приглашение
sub hi {
	my ($self) = @_;
	$self->send("hi!c");
}

# закрываем соединение
sub bay {
	my ($self) = @_;
	$self->freeze(["bay"]);
}

# отправляет команду
sub put {
	my $self = shift;
	$self->connect if !$self->{ns};
	$self->freeze(\@_);
}

# set
sub set {
	my $self = shift;
	$self->put("set", @_);
}

# get
sub get {
	my $self = shift;
	$self->put("get", @_);
	${ $self->thaw };
}

# ret
sub ret {
	my ($self, $key, $lifetime, $sub) = @_;
	
	if(@_ == 3) {
		$sub = $lifetime;
		$self->put("ret", $key);
	}
	else {
		$self->put("ret", $key, $lifetime);
	}
	
	my ($exists, $get) = @{ $self->thaw };
	
	$sub->($self, $key) if !$exists;
}

# ttl
sub ttl {
	my $self = shift;
	$self->put("ttl", @_);
}

# exists
sub exists {
	my $self = shift;
	$self->put("exists", @_);
}

# add
sub add {
	my $self = shift;
	$self->put("add", @_);
}

# sub
sub sub {
	my $self = shift;
	$self->put("sub", @_);
}

# inc
sub inc {
	my $self = shift;
	$self->put("inc", @_);
}

# dec
sub dec {
	my $self = shift;
	$self->put("dec", @_);
}


# должен устанавливаться перед расщеплением процессов
sub destroyer {
	my $self = shift;
	
	# контракт
	die "destroyer должен устанавливаться перед расщеплением процессов" if %{$app->processManager->{kid}};
	
	$app->cacheServer->cache->destroyer(@_);
	
	$self
}

1;