package R::Cache::Server;
# сервер кэша
# реализует протокол:
# 

use parent qw/R::Process::Server/;

use common::sense;
use R::App;

has qw/cache/;

my %allow = $app->perl->set(qw/set get ret exists inc dec add sub/);

# конструктор
sub new {
	my $cls = shift;
	my $self = $cls->SUPER::new(@_? @_: (
		port => $app->ini->{cache}{port} // $app->ini->{cache}{remote},
	));
	
	$self->{cache} = $app->cacheBagatur;
	
	$self
}

# переопределяем обработчик
sub impulse {
	my $self = shift;

	my $q = $app->q;
	
	my $hi = $q->recv(4);
	msg("неверный протокол: клиент указал приветствие `$hi`"), return $q->close if "hi!c" ne $hi;
	
	for(;;) {
	
		my $args = eval { $q->thaw };
		msg("сообщение не по протоколу: $@"), last if $@;
		
		my $method = shift @$args;
		
		last if $method eq "bay";	# уходим по английски - не прощаясь
		
		msg("не зарегистрирована команда кэша `$method`"), last if !exists $allow{$method};
		
		if($method eq "ret") {
			my ($key, $lifetime) = @$args;
			$self->ttl($lifetime) if @$args == 2;
			$q->freeze([ $self->cache->exists($key), $self->cache->get($key) ]);
		}
		else {
			my $res = $self->cache->$method(@$args);
			$q->freeze(\$res) if $method =~ /^(?:get|exists)$/;
		}
		
	}
	
}


1;