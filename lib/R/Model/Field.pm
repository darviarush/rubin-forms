package R::Model::Field;
# ��������� ������ � ����

# �����������
sub new {
	my ($cls, $app, $name, $type) = @_;
	bless {cls=>$cls, app=>$app, name=>$name, type=>$type, tab=>'' }, $cls;
}

# ���������� 


1;