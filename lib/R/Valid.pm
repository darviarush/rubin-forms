package Valid;
# методы для валидации параметров

sub image {
	my ($val, $app, $tab, $col, $op) = @_;
	
	if($op =~ /^(?:add|edit)$/ and $val !~ /^\d+$/) {	
		my $id = $app->connect->push('img');
		my $path = 'image/'.Utils::to_radix($id, "/");
		mkdir $path;
		Utils::write('original', $val);
		return $id;
	}
	$val;
}

#sub Valid::update_image {
#	my ($tab, $col, $val, $id) = @_;
#}

#sub Valid::error_image {
#	my ($val, $tab, $col, $op) = @_;
#	
#}


sub ref {
	my ($val, $app, $tab, $col, $op) = @_;
	return $app->auth->valid('replace', $app->connect->TAB_ref($col), $val) if ref $val;
	die "Значение $tab.$col не может быть ссылкой, т.к. оно не число и не HASH" if $val =~ /^-?\d+$/;
	$val;
}


sub int { die "не int ".join(", ", @_) if $_[0]!~/^-?\d+$/; $_[0] }
sub float { my ($val) = @_; die "не float" if $val !~ /^-?\d+(?:\.\d+)?(?:[Ee][+-]?\d+)?$/; $val }

1;