# объект содержит запрос
package R::Request;

use base R::Utils::Object;

use IO::String;

sub new {
	my ($cls, $app) = @_;
	bless {}, $cls;
}

# для разбора url. Используется вместе с reset
our $RE_LOCATION = qr!((/([^\s\?]*?)(?:(-?\d+)((?:_-?\d+)*)|(\.\w+))?)(?:\?(\S+))?)!;

# устанавливает новые значения
sub reset {
	my ($self, @any) = @_;
	my ($ids);
	($self->{method}, $self->{url}, $self->{location}, $self->{action}, $self->{ids}{id}, $ids, $self->{ext}, $self->{search}, $self->{version}, $self->{head}) = @any;
	
	if(defined $ids and $ids ne "") {
		my $i = 2;
		$self->{ids}{"id" . ($i++)} = $_ for split /_/, substr $ids, 1;
	}
}

sub head {
	my ($self, $name) = @_;
	my $head = $self->{head};
	defined($name)? $head->{$name}: $head;
}

sub cookie {
	my ($self, $name) = @_;
	my $cookie = $self->{cookie};
	unless(defined $cookie) {
		$self->{cookie} = $cookie = Utils::param($self->{head}{Cookie}, qr/;\s*/);
	}
	defined($name)? $cookie->{$name}: $cookie;
}

sub get {
	my ($self, $name) = @_;
	my $get = $self->{get};
	unless(defined $get) {
		$self->{get} = $get = Utils::param($self->{search});
	}
	defined($name)? $get->{$name}: $get;
}

sub post {
	my ($self, $name) = @_;
	my $post = $self->{post};
	unless(defined $post) {
		my $head = $self->{head};
		my ($type, $len, $rbfile) = ($head->{'Content-Type'}, $head->{'Content-Length'}, $head->{'REQUEST_BODY_FILE'});
		if(defined $rbfile) {
			my $f;
			open $f, $rbfile or die "NOT OPEN REQUEST_BODY_FILE=$rbfile $!";
			$self->{post} = $post = Utils::param_from_post($f, $type, $len);
			close $f;
		} else {
			$self->{post} = $post = Utils::param_from_post(IO::String->new($self->{body}), $type, $len);
		}
	}
	defined($name)? $post->{$name}: $post;
}

sub param {
	my ($self, $name) = @_;
	my $param = $self->{param};
	unless(defined $param) {
		if(defined $name) {
			return $self->{ids}{$name} // $self->get($name) // $self->post($name);
		}
		$self->{param} = $param = {%{$self->post}, %{$self->get}, %{$self->{ids}}};
	}
	defined($name)? $get->{$name}: $get;
}

1;