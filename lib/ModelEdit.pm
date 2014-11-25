package ModelEdit;

use strict;
use warnings;

sub new {
	my ($cls, $app) = @_;
	bless {app => $app}, $cls;
}

sub app { $_[0]->{app} }

# изменяет модель. Изменяет $ini
sub edit {
	my ($self) = @_;

	my $app = $self->{app};
	my $request = $app->request;
	my $response = $app->response;
	my $ini = $app->ini;
	
	my $erase = $request->param("method") eq 'erase';
	my $action = $request->param("action");
	my $tab = $request->param("tab");
	my $col = $request->param("col");
	my $role = $request->param("role");
	my $perm = $request->param("perm");
	
	my $inject = sub {
		my ($arg, $key, $col) = @_;
		my $val = $ini->{do}{$key}? join ",", sort { $a cmp $b } ($erase || !$col? (): $col), grep {$_ ne $col} (split /,\s*/, $ini->{do}{$key}): $col;
		$ini->{do}{$key} = $val;
		if($val ne "") { Utils::inject_ini($_[0], "", $key, $val) } else { Utils::delete_ini($_[0], "", $key); delete $ini->{do}{$key} }
	};
	
	if($action eq "selfcol") {
		my $key = "$tab.selfcol";
		if($perm ne "") {
			my $i = 0;
			my $_info = $app->connect->info;
			for my $col (split /,\s*/, $perm) {
				if($i++ == 0 && $col !~ /\./) { $col = "$tab.$col"; }
				return $response->error(406, "`$col` не разделён \".\"") unless $col =~ /\./;
				return $response->error(406, "Нет таблицы $col в базе") unless exists $_info->{$`};
				return $response->error(406, "Нет столбца $col в базе") unless exists $_info->{$`}{$'};
			}
			$ini->{do}{$key} = $perm;
			Utils::inject_ini($_[1], "", $key, $perm);
		}
		else { Utils::delete_ini($_[1], "", $key); delete $ini->{do}{$key} }
	}
	elsif($action eq "valid") {
		my @roles = split /,\s*/, $perm;
		$self->app->auth->get_validator($_, "$tab.$_", $col) for @roles; # тестируем, чтобы были такие валидаторы
		$inject->($_[1], "$tab.$_", $col) for @roles;
		$inject->($_[1], "$tab.$_") unless @roles;
	}
	elsif($action eq "tab_perm") {
		$inject->($_[1], "$tab.$role", $perm);
	}
	elsif($action eq "perm") {
		$inject->($_[1], "$tab.$role.$perm", $col);
	}
	else {
		die "Неизвестный action=$action";
	}
}

# кеширует
sub install_info {
	my $self = shift;
	return $self->{install_info} if exists $self->{install_info};
	$self->{install_info} = $self->get_install_info(@_ or main::files("install.sql"));
}

# выбирает информацию из sql-файлов
sub get_install_info {
	my ($self, @file) = @_;
	my ($order, $prev, $install, $tab, $col) = (1, "\@", {});
	my $f;
	
	for my $file (@file) {
		
		open $f, $file or die $!;
		
		my $package = undef;
		
		while(<$f>) {
			if(/create\s+table\s+(?:`([^`]*)`|(\w+))/i) {
				$install->{$tab = $1 // $2} = {
					name => $tab,
					package => $package,
					file => $file,
					order => $order++,
					line => $.,
					install => $_
				};
			} elsif(!$tab) {
				$install->{$prev}{"after"} .= $_;
				$install->{$prev}{"end"} .= $.;
			} elsif(/^\s*(?:`([^`]*)`|(\w+))\s+(\w+)/) {
				my $ins = $3.$';
				$col = $1 // $2;
				$ins =~ s/,?\s*$//;
				$install->{$tab}{cols}{$col} = {name => $col, package => $package, install => $ins, order => $order++};
				$install->{$tab}{install} .= $_;
			} elsif(/^\s*(INDEX|UNIQUE)/i) {
				my $ins = $1.$';
				$ins =~ s/,?\s*$/\n/;
				$install->{$tab}{indexes} .= $ins;
				$install->{$tab}{install} .= $_;
			} elsif(/^\s*\)/) {
				my $ins = $';
				$ins =~ s/;?\s*$//;
				$install->{$tab}{options} = $ins;
				$install->{$tab}{install} .= $_;
				$prev = $tab;
				$tab = undef;
			} elsif(/^--\s*\[(.*?)\]/) {
				$package = $1;
			} elsif(/^\s*--/ || /^\s*$/) {
				$install->{$tab}{install} .= $_;
			} else {
				$install->{$tab}{install} .= $_;
				warn "что-то нераспознанное `$_` в таблице `$tab`";
			}
		}
		close $f;
	}
	$install
}

my %column_type = ("int(11)" => "int", "tinyint(4)" => "tinyint");

#sub sql_from_info {
sub alter_column {
	my ($self, $sql) = @_;
	($sql? (($column_type{$sql->{column_type}} || $sql->{column_type} || "").
	($sql->{is_nullable} eq "YES" || $sql->{column_key} =~ /PRI/? "": " not null").
	(defined($sql->{column_default})? " default $sql->{column_default}": "").
	($sql->{column_key} =~ /PRI/? " primary key": "").
	($sql->{extra} ne ""? " $sql->{extra}": "")): "")
}

1;