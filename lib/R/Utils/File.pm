package R::Utils::File;
# ������������ ���� � $app->request->param("file_key")

use strict;
use warnings;

use Utils;

Utils::has(qw/body head tmpfile/);

# �����������
sub new {
	my ($cls, $param) = @_;
	bless $param, $cls;
}

sub in_memory {
	exists $_[0]->{body}
}

1;