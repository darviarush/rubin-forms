# объект содержит запрос
package R::Request;

use strict;
use warnings;

use IO::String;

# назначаем свойства
Utils::has("app", "method", "url", "location", "action", "ext", "search", "version");


sub new {
	my ($cls, $app) = @_;
	bless {app => $app}, $cls;
}

# для разбора url. Используется вместе с reset
our $RE_LOCATION = qr!((/([^\s\?]*?(?:/\d+)?)_?(?:(-?\d+)((?:_-?\d+)*)|\.(\w+))?)(?:\?(\S+))?)!;

# устанавливает новые значения
sub reset {
	my ($self, @args) = @_;
	
	%$self = (app=>$self->{app});
	
	my ($ids, $id);
	($self->{method}, $self->{url}, $self->{location}, $self->{action}, $id, $ids, $self->{ext}, $self->{search}, $self->{version}, $self->{head}, $self->{body}) = @args;

	#main::msg 'req->reset', $self->{method}, $self->{url}, $self->{location}, $self->{action}, $id, $ids, $self->{ext}, $self->{search}, $self->{version}, $self->{head}, $self->{body};
	
	$self->{action} = 'index' unless $self->{action};
	
	$self->{ids} = my $IDS = {};
	$IDS->{id} = $id if defined $id;
	if(defined $ids and $ids ne "") {
		my $i = 2;
		$IDS->{"id" . ($i++)} = $_ for split /_/, substr $ids, 1;
	}
	$self
}

# заголовки
sub head {
	my ($self, $name) = @_;
	my $head = $self->{head};
	defined($name)? $head->{$name}: $head;
}

# возвращает url c которого пришло
sub referer {
	my ($self, $default) = @_;
	my $head = $self->head;
	my $referer = exists $head->{Referer}? $head->{Referer}: $default;
	my $host = $self->{app}->ini->{site}{host};
	$referer =~ s!^https?://$host!!;
	$referer
}

# возвращает куки
sub cookie {
	my ($self, $name) = @_;
	my $cookie = $self->{cookie};
	unless(defined $cookie) {
		$self->{cookie} = $cookie = Utils::param($self->{head}{Cookie}, qr/;\s*/);
	}
	defined($name)? $cookie->{$name}: $cookie;
}

# возвращает параметры URL: /path5_6_-7, тогда ids = { id: 5, id2: 6, id3: -7 }
sub ids {
	my ($self, $name) = @_;
	@_>1? $self->{ids}{$name}: $self->{ids}
}

# параметры после ?
sub get {
	my ($self, $name) = @_;
	my $get = $self->{get};
	unless(defined $get) {
		$self->{get} = $get = Utils::param($self->{search});
	}
	defined($name)? $get->{$name}: $get;
}

# POST-параметры
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
		} elsif($len && defined $self->{body}) {
			$self->{post} = $post = Utils::param_from_post(IO::String->new($self->{body}), $type, $len);
		} else {
			$self->{post} = $post = {};
		}
	}
	defined($name)? $post->{$name}: $post;
}

# параметры POST, GET и из URL
sub param {
	my ($self, $name) = @_;
	my $param = $self->{param};
	unless(defined $param) {
		if(defined $name) {
			my $val = $self->{ids}{$name} // $self->{get}{$name} // $self->get($name);
			return $val if defined $val;
		}
		#main::msg "xtx", $self->{ids};
		$self->{param} = $param = {%{$self->post}, %{$self->get}, %{$self->{ids}}};
	}
	defined($name)? $param->{$name}: $param;
}

# путь к html-файлам
sub html {
	my ($self) = @_;
	"html" . $self->{location};
}

#sub action {
	#$_action = 'index' if $_action eq "";
#}

# возвращает текущую сессию
sub session {
	my ($self) = @_;
	$self->{session} //= $::app->model->session($self->cookie("sess"));
}

# возвращает текущего пользователя
sub user {
	my ($self) = @_;
	$self->session->user;
}




1;