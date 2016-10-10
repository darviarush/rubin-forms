package R::Cache::Bagatur;
# кэш LFU + TTL

# наследуем Lfu и Ttl
use parent qw/R::Cache::Lfu R::Cache::Ttl/;
use mro 'c3';

use common::sense;
use R::App;

# переопределяем конструктор
sub new {
	my ($cls) = @_;
	
	$cls = ref $cls || $cls;
	
	my $self = $cls->SUPER::new;
	$self->new_ttl;					# добавляем необходимое для ttl
	
	$self->maxkeysize( $app->perl->size( $app->ini->{cache}{maxkeysize} ) ) if exists $app->ini->{cache}{maxkeysize};
	$self->maxsize( $app->perl->size( $app->ini->{cache}{maxsize} ) ) if exists $app->ini->{cache}{maxsize};
	
	$self
}

# начало логирования
sub start_log {
	my $self = shift;
	$app->log->info(":space inline nonewline bold black", @_);
	$app->bench->time;
	$self
}

# конец логирования
sub end_log {
	my $self = shift;
	$app->log->info(":space", "\t\t", @_, $app->bench->log);
	$self
}

if( $app->ini->{log}{cache} =~ /^\s*yes\s*$/i ) {

	*set = sub {
		my $self = shift;
		$self->start_log("set", @_);
		my $ret = $self->SUPER::set(@_);
		$self->end_log;
		$ret
	};
	
	*get = sub {
		my $self = shift;
		$self->start_log("get", @_);
		my $ret = $self->SUPER::get(@_);
		$self->end_log($ret);
		$ret
	};
	
	*del = sub {
		my $self = shift;
		$self->start_log("del", @_);
		my $ret = $self->SUPER::del(@_);
		$self->end_log;
		$ret
	};
}

1;