
sub Valid::image {
	my ($val, $tab, $col, $op) = @_;
	
	if($op =~ /^(?:add|edit)$/ and $val !~ /^\d+$/) {	
		my $id = add('img');
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


sub Valid::ref {
	my ($val, $tab, $col, $op) = @_;
	return valid_param('replace', TAB_ref($col), $val) if ref $val;
	die "Значение $tab.$col не может быть ссылкой, т.к. оно не число и не HASH" if $val =~ /^-?\d+$/;
	$val;
}


sub Valid::int { die "не int ".join(", ", @_) if $_[0]!~/^-?\d+$/; $_[0] }
sub Valid::float { my ($val) = @_; die "не float" if $val !~ /^-?\d+(?:\.\d+)?(?:[Ee][+-]?\d+)?$/; $val }

1;