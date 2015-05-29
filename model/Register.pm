package R::Row::Register;
# ������ ���� �� ����������� ������������

use base "R::Model::Row";

sub setup {
	my ($fields) = @_;
	
	$fields->
	
	pk("binary(20)")->
	col("email" => "varchar(255)")->
	col("now" => "datetime")->
	
	end
}

# ��������� ����� ��������
sub onAdd {
	my ($self) = @_;
	$self->now( Utils::now() );
}

# ������� ��� ������������ �����������
sub clean {
	my ($self) = @_;
	$self->Model->find(now__lt => Utils::now(time-3600))->erase;
	$self
}

1;