
# изменяет модель. Изменяет $ini
sub model_edit {

	my $erase = $param->{method} eq 'erase';
	my $action = $param->{action};
	my $tab = $param->{tab};
	my $col = $param->{col};
	my $role = $param->{role};
	my $perm = $param->{perm};
	
	my $inject = sub {
		my ($arg, $key, $col) = @_;
		my $val;
		$ini->{do}{$key} = $val = join ",", ($erase? (): $col), grep {$_ ne $col} (split /,\s*/, $ini->{do}{$key});
		if($val ne "") { Utils::inject_ini($_[0], "do", $key, $val) } else { Utils::delete_ini($_[0], "do", $key); delete $ini->{do}{$key} }
	};
	
	if($action eq "valid") {
		$inject->($_[0], "$tab.$_", $col) for split /,\s*/, $perm;
	}
	elsif($action eq "tab_perm") {
		$inject->($_[0], "$tab.$role", $perm);
	}
	elsif($action eq "perm") {
		$inject->($_[0], "$tab.$role.$perm", $col);
	}
	else {
		die "Неизвестный action=$action";
	}
}


sub get_install_info {
	my ($order, $install, $tab, $col) = 1;
	local *f;
	
	for my $file (@_) {
		
		open f, $file or die $!;
		
		my $package = undef;
		
		while(<f>) {
			if(/create\s+table\s+(?:`([^`]*)`|(\w+))/i) {
				$install->{$tab = $1 // $2} = {
					name => $tab,
					package => $package,
					file => $file,
					order => $order++
				};
			} elsif(/^\s*(?:`([^`]*)`|(\w+))\s*/ and SQL_WORD($col = $1 || $2) eq $col) {
				my $ins = $';
				$ins =~ s/,?\s*$//;
				$install->{$tab}{cols}{$col} = {package => $package, install => $ins, order => $order++};
			} elsif(/^--\s*\[(.*?)\]/) {
				$package = $1;
			} else {
				
			}
		}
		close f;
	}
	$install
}

1;