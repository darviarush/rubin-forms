use strict;
use warnings;

our ($param, $ini);

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
		my $val = $ini->{do}{$key}? join ",", ($erase? (): $col), grep {$_ ne $col} (split /,\s*/, $ini->{do}{$key}): "";
		$ini->{do}{$key} = $val;
		if($val ne "") { Utils::inject_ini($_[0], "do", $key, $val) } else { Utils::delete_ini($_[0], "do", $key); delete $ini->{do}{$key} }
	};
	
	if($action eq "valid") {
		my @roles = split /,\s*/, $perm;
		get_validator($_, "$tab.$_", $col) for @roles; # тестируем, чтобы были такие валидаторы
		$inject->($_[0], "$tab.$_", $col) for @roles;
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

# выбирает информацию из sql
sub get_install_info {
	my ($order, $install, $tab, $col) = 1;
	my $f;
	
	for my $file (@_) {
		
		open $f, $file or die $!;
		
		my $package = undef;
		
		while(<$f>) {
			if(/create\s+table\s+(?:`([^`]*)`|(\w+))/i) {
				$install->{$tab = $1 // $2} = {
					name => $tab,
					package => $package,
					file => $file,
					order => $order++
				};
			} elsif(!$tab) {
			} elsif(/^\s*(?:`([^`]*)`|(\w+))\s+(\w+)/) {
				my $ins = $3.$';
				$col = $1 // $2;
				$ins =~ s/,?\s*$//;
				$install->{$tab}{cols}{$col} = {package => $package, install => $ins, order => $order++};
			} elsif(/^\s*(INDEX|UNIQUE)/i) {
				my $ins = $1.$';
				$ins =~ s/,?\s*$/\n/;
				$install->{$tab}{indexes} .= $ins;
			} elsif(/^\s*\)/) {
				my $ins = $';
				$ins =~ s/;?\s*$//;
				$install->{$tab}{options} = $ins;
				$tab = undef;
			} elsif(/^--\s*\[(.*?)\]/) {
				$package = $1;
			} elsif(/^\s*--/ || /^\s*$/) {
			} else {
				die "что-то нераспознанное `$_` в таблице `$tab`";
			}
		}
		close $f;
	}
	$install
}

1;