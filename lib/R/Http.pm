package R::Http;
# ��, ��� ��������� � ��������� http - ������ � ������

use common::sense;
use R::App;

# �����������
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

# ������ http-������ �� ��������� �����
sub makeServer {
	my ($self, $port) = @_;
	my $server = $app->new->serverHttp;
	$server
}

# ����������� � ����-�� �� ��������� http
sub connect {
	$app->new->connectHttp;
}





1;