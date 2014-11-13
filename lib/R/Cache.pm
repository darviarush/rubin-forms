package R::Cache;
# кеш в разделяемой памяти процессов

use threads::shared;

sub new {
	my($cls, $app) = @_;
	bless clone_shared({}), $cls;
}

sub get { my($self, $key)=@_; $self->{$key} }
sub set { my($self, $key, $val)=@_; $self->{$key} = $val }

1;