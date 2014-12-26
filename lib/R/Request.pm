# объект содержит запрос
package R::Request;

use base R::Utils::Object;

use IO::String;

# для разбора url. Используется вместе с reset
our $RE_LOCATION = qr!((/([^\s\?]*?)(?:(-?\d+)((?:_-?\d+)*)|(\.\w+))?)(?:\?(\S+))?)!;

# устанавливает новые значения
sub reset {
	my ($self) = @_;
	my ($ids, $id);
	($self, $self->{method}, $self->{url}, $self->{location}, $self->{action}, $id, $ids, $self->{ext}, $self->{search}, $self->{version}, $self->{head}, $self->{body}) = @_;

	$self->{action} = 'index' unless $self->{action};
	
	$self->{ids} = my $IDS = {};
	$IDS->{id} = $id if defined $id;
	if(defined $ids and $ids ne "") {
		my $i = 2;
		$IDS->{"id" . ($i++)} = $_ for split /_/, substr $ids, 1;
	}
	$self
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
		if(defined $self->{body}) {
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
		} else {
			$self->{post} = $post = {};
		}
	}
	defined($name)? $post->{$name}: $post;
}

sub param {
	my ($self, $name) = @_;
	my $param = $self->{param};
	unless(defined $param) {
		if(defined $name) {
			my $val = $self->{ids}{$name} // $self->{get}{$name} // $self->get($name);
			return $val if defined $val;
		}
		$self->{param} = $param = {%{$self->post}, %{$self->get}, %{$self->{ids}}};
	}
	defined($name)? $param->{$name}: $param;
}

# путь к html-файлам
sub html {
	my ($self) = @_;
	"html" . $self->{location};
}

sub action {
	$_action = 'index' if $_action eq "";
}

1;