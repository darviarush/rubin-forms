# драйверы для протокола qq: http, fcgi и psgi
use strict;
use warnings;

package Rubin::HTTP;

use Term::ANSIColor qw(:constants);
use Carp qw/verbose/;
use Socket;

# создаёт подключение
sub new {
	my ($cls, $_port) = @_;
	
	my $sd;
	
	if($_port =~ /^\d+$/) {
		socket $sd, AF_INET, SOCK_STREAM, getprotobyname("tcp") or die "socket: $!\n";
		setsockopt $sd, SOL_SOCKET, SO_REUSEADDR, pack("l", 1) or die "setsockopt: $!\n"; # захватываем сокет, если он занят другим процессом
		bind $sd, sockaddr_in($_port, INADDR_ANY) or die "bind: $!\n";
		listen $sd, SOMAXCONN or die "listen: $!\n";
	} else {
		socket $sd, PF_UNIX, SOCK_STREAM, 0 or die "socket: $!\n";
		unlink $_port;
		bind $sd, sockaddr_un($_port) or die "bind: $!\n";
		listen $sd, SOMAXCONN  or die "listen: $!\n";
	}

	
	bless { sd => $sd }, $cls;
}

sub bind {
	my ($self) = @_;
	close $self->{ns} if $self->{ns};
}

sub accept {
	my ($self, $app) = @_;
	
	#my $sel = IO::Socket->new($_socket);
	#$sel->add();
	
	# добавляем в векторы сокет
	# my ($vec, $out, $err) = ("", "", "");
	# my $sd = fileno($self->{sd});
	# vec($vec, $sd, 1) = 1;
	# vec($out, $sd, 1) = 1;
	# vec($err, $sd, 1) = 1;
	
	my($ns, $keep_alive);
	for(;;) {
		
		#my $nfound = select $vec, undef, undef, undef;
		#msg CYAN."nfound ".RESET." soc=$self->{sd} vec=$vec ".RED.$nfound.RESET;
		#$nfound = select undef, $out, undef, undef;
		#if $nfound == $sd
		#$nfound = select undef, undef, $err, undef;
		#next unless defined $nfound;
		
		#if $nfound == $sd;
		
		my ($HTTP, $ret) = ();
		$HTTP = <$ns> if $keep_alive;
		unless(defined $HTTP) {
			close $ns if $ns;
			accept $ns, $self->{sd} or die "not ns: $!";
			$self->{ns} = $ns;
			next unless defined($HTTP = <$ns>);
		}
		
		main::stat_start() if $::_test;
		
		if($HTTP =~ m!^(\w+) $::_RE_LOCATION (HTTP\/\d\.\d)\r?$!o) {
			my($METHOD, $URL, $LOCATION, $ACTION, $ID, $EXT, $SEARCH, $VERSION) = ($1, $2, $3, $4, $5, $6, $7, $8);
					
			$main::_METHOD = $METHOD;
			$main::_URL = $URL;
			$main::_LOCATION = $LOCATION;
			$main::_action = $ACTION;
			$main::_id = $ID;
			$main::_EXT = $EXT;
			$main::_VERSION = $VERSION;
			
			# считываем заголовки
			/: (.*?)\r?$/ and $main::_HEAD->{$`} = $1 while defined($_ = <$ns>) and !/^\r?$/;
			
			# считываем данные
			$main::_GET = Utils::param($SEARCH);
			if(my $CONTENT_LENGTH = $main::_HEAD->{"Content-Length"}) {
				my $f;
				$main::_POST = Utils::param_from_post($main::_HEAD->{'REQUEST_BODY_FILE'}? do {
				open $f, $main::_HEAD->{'REQUEST_BODY_FILE'} or die "NOT OPEN REQUEST_BODY_FILE=".$main::_HEAD->{'REQUEST_BODY_FILE'}." $!"; $f
				}: $ns, $main::_HEAD->{'Content-Type'}, $CONTENT_LENGTH);
				close $f if defined $f;
				$main::param = { %$main::_POST, %$main::_GET };
			}
			else {
				$main::param = $main::_GET;
			}
			$main::_COOKIE = Utils::param($main::_HEAD->{"Cookie"}, qr/;\s*/);
			
			main::stat_begin() if $::_test;
			
			# настраиваем сессионное подключение (несколько запросов на соединение, если клиент поддерживает)
			$self->{'keep-alive'} = $keep_alive = (lc $main::_HEAD->{Connection} eq 'keep-alive');
			
			$ret = $app->();
		} else {
			$ret = [400, ["Content-Type: text/plain; charset=utf-8"], ["400 Bad Request"]]
		}
		my ($status, $head, $out) = @$ret;
		
		my $RESPONSE = "HTTP/1.1 $status $main::_STATUS{$status}\n";

		my $len = 0;
		$len += length $_ for @$out;
		push @$head, "Content-Length: $len";
		push @$head, "Connection: keep-alive" if $keep_alive;
		
		send $ns, $RESPONSE, 0;
		send $ns, "$_\n", 0 for @$head;
		send $ns, "\n", 0;
		send $ns, $_, 0 for @$out;
		
		$main::_action = $main::_id = $main::_VERSION = $main::_METHOD = $main::_LOCATION = $main::_URL = $main::_HEAD = $main::_COOKIE = $main::_GET = $main::_POST = $main::param = $main::_user_id = undef;
		
		main::stat_end($RESPONSE, $head, $out) if $::_test;
		
		@main::_HEAD = %main::_HEAD = @main::_COOKIE = ();
		@$out = ();
	}
}


sub close { my ($self) = @_; close $self->{ns} if $self->{ns}; close $self->{sd}; }



package Rubin::FCGI;

use FCGI;

# создаёт подключение
sub new {
	my ($cls, $_port) = @_;
	bless { socket => FCGI::OpenSocket(":$_port", 5) }, $cls;
}

sub bind {
	my ($self) = @_;
	my ($env, $in, $out, $x, $y) = {};
	open $in, "<", \$x;
	open $out, ">", \$y;
	$self->{request} = FCGI::Request($in, $out, $out, $env, $self->{socket});
	$self->{stdin} = $in;
	$self->{stdout} = $out;
	$self->{env} = $env;
}

sub accept {
	my ($self, $app) = @_;
	for(;;) {
		last if $self->{request}->Accept() < 0;
	
		my $env = $self->{env};
		
		$main::_METHOD = $self->{env}{REQUEST_METHOD};
		$main::_LOCATION = $self->{env}{DOCUMENT_URI};
		$main::_URL = $self->{env}{REQUEST_URI};
		
		$main::_LOCATION =~ m!^/(.*(?:(-?\d+)|\.(\w+)))$!;
		
		$main::_action = $1;
		$main::_id = $2;
		$main::_EXT = $3;
		$main::_VERSION = $self->{env}{SERVER_PROTOCOL};
		
		$main::_HEAD = { map { my $val = $self->{env}{$_}; s/^HTTP_//; $_=lc $_; s/_(.)/"-".uc $1/ge; ($_ => $val) } grep { /^HTTP_/ } keys %$env };
		
		$main::_GET = Utils::param($env->{'QUERY_STRING'}, qr/&/);
		my $f;
		$self->{post} = $env->{CONTENT_LENGTH}? Utils::param_from_post($env->{'REQUEST_BODY_FILE'}? do { open $f, $env->{'REQUEST_BODY_FILE'} or die "NOT OPEN REQUEST_BODY_FILE=".$env->{'REQUEST_BODY_FILE'}." $!"; $f }: $self->{stdin}, $env->{'CONTENT_TYPE'}, $env->{'CONTENT_LENGTH'}): {};
		close $f if defined $f;
		$self->{cookie} = Utils::param($env->{'HTTP_COOKIE'}, qr/;\s*/);

		my $ret = $app->();
		my ($status, $head, $out) = @$ret;
		my $stdout = $self->{stdout};
		push @$head, "Status: $status $main::_STATUS{$status}\r\n";
		print($stdout $_), print $stdout "\r\n" for @$head;
		print $stdout "\r\n";
		print $stdout $_ for @$out;
		
		@$out = ();
	}
}

sub close { my ($self) = @_; FCGI::CloseSocket($self->{socket}); }


# PSGI
package Rubin::PSGI;


sub new {
	my ($cls, $_port) = @_;
	bless {port => $_port}, $cls;
}

sub bind {
	my ($self) = @_;
}

# http://perl5doc.ru/cpan/PSGI
sub accept {
	my ($self, $app) = @_;
	$main::app = (sub {
		return sub {
			my $env = shift;
			
			my ($URL, $LOCATION, $ACTION, $ID, $EXT, $SEARCH) = $env->{REQUEST_URI} =~ /^$::_RE_LOCATION$/;
			
			$main::_METHOD = $env->{REQUEST_METHOD};
			$main::_URL = $URL;
			$main::_LOCATION = $LOCATION;
			$main::_action = $ACTION;
			$main::_id = $ID;
			$main::_EXT = $EXT;
			$main::_VERSION = $env->{SERVER_PROTOCOL};
			
			$SEARCH //= $env->{QUERY_STRING};
			
			
			
			# считываем заголовки
			while(my($key, $val) = each %$env) {
				if($key =~ s/^HTTP_//) {
					$key = lc $key;
					$key =~ s/_(\w)/"-".ucFirst $1/ge;
					$main::_HEAD->{ucFirst $key} = $val;
				}
			}
			
			$main::_HEAD->{"Content-Length"} = my $CONTENT_LENGTH = $env->{CONTENT_LENGTH};
			$main::_HEAD->{"Content-Type"} = $env->{CONTENT_TYPE};
			
			# считываем данные
			$main::_GET = Utils::param($SEARCH);
			if($CONTENT_LENGTH) {
				my $f;
				my $body = $main::_HEAD->{'Request-Body-File'};
				$main::_POST = Utils::param_from_post($body? do {
					open $f, $body or die "NOT OPEN REQUEST_BODY_FILE=$body $!"; $f
				}: $env->{"psgi.input"}, $main::_HEAD->{'Content-Type'}, $CONTENT_LENGTH);
				close $f if defined $f;
				$main::param = { %$main::_POST, %$main::_GET };
			}
			else {
				$main::param = $main::_GET;
			}
			$main::_COOKIE = Utils::param($main::_HEAD->{"Cookie"}, qr/;\s*/);
			
			my $ret = $app->();
			my ($status, $head, $out) = @$ret;
			$head = [map { /:\s*/; ($`, $') } @$head];
			[$status, $head, $out]
		}
	})->($app);
}



sub close { my ($self) = @_; }


1