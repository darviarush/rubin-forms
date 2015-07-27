package R::Async::Defer;
# ����� �������� ���������� promise

use common::sense;
use R::App;

use base "R::Async::Promise";

# �����������
sub new {
	my ($cls) = @_;
	bless {
	}, $cls;
}

# ���������� ������ �� �������
sub resolve (@) {
	my ($self, @args) = @_;
	$self->{Resolved} = [@args];
	for my $code (@{$self->{Then}}, @{$self->{Done}}) {
		$code->(@args);
	}
}

# ������� ��� resolve
\&fulfill = \&resolve;

# ������ ����������
sub reject (@) {
	my ($self, @args) = @_;
	$self->{Rejected} = [@args];
	for my $code (@{$self->{Fail}}, @{$self->{Done}}) {
		$code->(@args);
	}
}

# ���������� Promise
sub promise {
	my ($self) = @_;
	bless $self, "R::Async::Promise";
}




1;
