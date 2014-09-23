use strict;
use warnings;

our ($param, $ini, $_info);

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
		my $val = $ini->{do}{$key}? join ",", sort { $a cmp $b } ($erase || !$col? (): $col), grep {$_ ne $col} (split /,\s*/, $ini->{do}{$key}): $col;
		$ini->{do}{$key} = $val;
		if($val ne "") { Utils::inject_ini($_[0], "", $key, $val) } else { msg "in $key delete"; Utils::delete_ini($_[0], "", $key); delete $ini->{do}{$key} }
	};
	
	if($action eq "selfcol") {
		my $key = "$tab.selfcol";
		if($perm ne "") {
			for my $col (split /,\s*/, $perm) {
				return status 406, "`$col` не разделён \".\"" unless $col =~ /\./;
				return status 406, "Нет таблицы $col в базе" unless exists $_info->{$`};
				return status 406, "Нет столбца $col в базе" unless exists $_info->{$`}{$'};
			}
			$ini->{do}{$key} = $perm;
			Utils::inject_ini($_[0], "", $key, $perm);
		}
		else { Utils::delete_ini($_[0], "", $key); delete $ini->{do}{$key} }
	}
	elsif($action eq "valid") {
		my @roles = split /,\s*/, $perm;
		get_validator($_, "$tab.$_", $col) for @roles; # тестируем, чтобы были такие валидаторы
		$inject->($_[0], "$tab.$_", $col) for @roles;
		$inject->($_[0], "$tab.$_") unless @roles;
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
	my ($order, $prev, $install, $tab, $col) = (1, "\@", {});
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
				push @{ $install->{$prev}{"after"} }, $_;
			} elsif(/^\s*(?:`([^`]*)`|(\w+))\s+(\w+)/) {
				my $ins = $3.$';
				$col = $1 // $2;
				$ins =~ s/,?\s*$//;
				$install->{$tab}{cols}{$col} = {name => $col, package => $package, install => $ins, order => $order++};
			} elsif(/^\s*(INDEX|UNIQUE)/i) {
				my $ins = $1.$';
				$ins =~ s/,?\s*$/\n/;
				$install->{$tab}{indexes} .= $ins;
			} elsif(/^\s*\)/) {
				my $ins = $';
				$ins =~ s/;?\s*$//;
				$install->{$tab}{options} = $ins;
				$prev = $tab;
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

my %column_type = ("int(11)" => "int", "tinyint(4)" => "tinyint");

sub sql_from_info {
	my ($sql) = @_;
	($sql? (($column_type{$sql->{column_type}} || $sql->{column_type} || "").
	($sql->{is_nullable} eq "YES" || $sql->{column_key} =~ /PRI/? "": " not null").
	(defined($sql->{column_default})? " default $sql->{column_default}": "").
	($sql->{column_key} =~ /PRI/? " primary key": "").
	($sql->{extra} ne ""? " $sql->{extra}": "")): "")
}

1;