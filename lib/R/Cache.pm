package R::Cache;
# кеш в разделяемой памяти процессов

use threads::shared;

sub new {
	my($cls, $app) = @_;
	bless clone_shared({
		new => clone_shared({}),
		old => clone_shared({}),
		size => 0,
		size_old => 0,
		max_size => $::app->ini->{cache}{max_size} // 1024**3,	# 1G
	}), $cls;
}

sub get {
	my($self, $key)=@_;
	my ($new, $old) = @$self{new, old};
	my $val = $new->{$key};
	if(defined $val) {
		$val
	} elsif(defined( $val = $old->{$key} )) {
		$new->{$key} = $val;
		$self->{size_old} -= length($key) + length($val);
	}
}

sub set {
	my($self, $key, $val)=@_;
	my ($new, $old, $size, $max_size) = @$self{new, old, size, max_size};
	my $len = length($key) + length($val);
	
	$size += $len;
	
	if($size > $max_size) {
		$self->{old} = $new;
		$self->{size} = $self->{size_old} = $size - $self->{size_old};
		%$old = ();
		$self->{new} = $old;
	}
	
	$new->{$key} = $val;
	$self->{size} += $len;
}

1;