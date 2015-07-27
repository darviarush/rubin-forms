package R::Async::Fileset;
# ����� ������, � �� ����� ��� R::File - �������

use common::sense;
use R::App;
use R::Async::File;

use base "R::Async::Set";

# �����������
sub new {
	my $cls = shift;
	bless [map { R::Async::File->new($_) } @_], ref $cls || $cls;
}

# ���� ������� �� �������
use vars '$AUTOLOAD';

sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	eval "sub $AUTOLOAD {
		my \$self = shift;
		wantarray? map({  \$_->$prop(\@_) } \@\$self): bless [map({  \$_->$prop(\@_) } \@\$self)], ref \$self;
	}";
	die "not make $AUTOLOAD: " . ($@ // $!) if $@ // $!;
	&$AUTOLOAD(@_);
}

sub DESTROY {}



1;
