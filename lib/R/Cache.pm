package R::Cache;
# кеш в разделяемой памяти процессов

use threads::shared;

my %CACHE:shared;

sub new {
	my($cls, $app) = @_;
	bless {}, $cls;
}

sub get { my($self, $key)=@_; $CACHE{$key} }
sub set { my($self, $key, $val)=@_; $CACHE{$key} = $val }

1;