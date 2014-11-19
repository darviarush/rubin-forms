package R::Valid;
# методы для валидации параметров

use base R::Utils::Main;

sub image {
	my ($self, $val, $tab, $col, $op) = @_;
	
	my $app = $self->{app};
	
	if($op =~ /^(?:add|edit)$/ and $val !~ /^\d+$/) {	
		my $id = $app->connect->push('img');
		my $path = 'image/'.Utils::to_radix($id, "/");
		mkdir $path;
		Utils::write('original', $val);
		return $id;
	}
}

#sub Valid::update_image {
#	my ($tab, $col, $val, $id) = @_;
#}

#sub Valid::error_image {
#	my ($val, $tab, $col, $op) = @_;
#	
#}


sub ref {
	my ($self, $val, $tab, $col, $op) = @_;
	return $self->app->auth->replace($app->connect->TAB_ref($col), $val) if ref $val;
	die "Значение $tab.$col не может быть ссылкой, т.к. оно не число и не HASH" if $val =~ /^-?\d+$/;
}


sub int { die "не int ".join(", ", @_[1..$#_]) if $_[1]!~/^-?\d+$/; $_[1] }
sub float { my ($self, $val) = @_; die "не float" if $val !~ /^-?\d+(?:\.\d+)?(?:[Ee][+-]?\d+)?$/; }

1;