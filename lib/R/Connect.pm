package R::Connect;
# ����������� � ���� � ����������� ������� ��� ��������

use DBI;

sub new {
	my ($cls, $app) = @_;
	my $self = bless { app => $app }, $cls;
	$self->connect
}


# �������
sub connect {
	my ($self) = @_;
	$self->close if $self->{dbh};
	my $ini = $self->{app}->ini->{mysql};
	$self->{dbh} = my $dbh = DBI->connect($ini->{DNS}, $ini->{user}, $ini->{password},
		{RaiseError => 1, PrintError => 0, PrintWarn => 0});
	$dbh->do("SET NAMES utf8");
	$self
}

# ��������� ����������
sub close {
	my ($self) = @_;
	$self->{dbh}->disconnect;
	delete $self->{info};
	$self
}

# ������������������, ���� ����� ��������
sub reconnect {
	my ($self) = @_;
	if($self->{dbh}) {
		return $self if $self->{dbh}->ping;
		$self->close;
	}
	$self->connect
}

# ���������� ��� ���� ������
sub basename {
	my ($self) = @_;
	$self->{app}->ini->{mysql}{DNS} =~ /database=(\w+)/ and $1
}

# ���������� dbh
sub dbh {
	my ($self) = @_;
	$self->{dbh}
}


# �������� ���. � ��������
sub info {
	my ($self) = @_;
	$self->{info} //= $self->get_info;
}

# ���������� ���������� � ��������
sub get_info {
	my ($self) = @_;
	my $dbh = $self->{dbh};
	my $sql = "select table_name, column_name, data_type, column_type, column_default, is_nullable, character_maximum_length, extra, column_key, ordinal_position
		from information_schema.columns
		where table_schema=".$dbh->quote($self->basename);
	my $rows = $dbh->selectall_arrayref($sql, {Slice=>{}});
	my $info = {};
	
	for my $row (@$rows) {	# ������ info
		$info->{$row->{table_name}}{$row->{column_name}} = $row;
	}
	return $info;
}

1;