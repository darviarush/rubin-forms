# драйверы для протокола qq: http, fcgi и psgi
use strict;
use warnings;

package Rubin::HTTP;

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
	
	#my ($vec, $out) = "";
	#vec($vec, $_socket, 1) = 1;
	#vec($out, $_socket, 1) = 1;
	
	my($ns, $keep_alive);
	for(;;) {
		my $HTTP = undef;
		$HTTP = <$ns> if $keep_alive;
		unless(defined $HTTP) {
			close $ns if $ns;
			accept $ns, $self->{sd} or die "not ns: $!";
			$self->{ns} = $ns;
			die "get ns: $!" unless defined($HTTP = <$ns>);
		}
		
		#my $nfound = select $vec, $out, undef, undef;
		#msg CYAN."nfound ".RESET." soc=$_socket vec=$vec ".RED.$nfound.RESET;
		
		next unless $HTTP =~ m!^(\w+) ([^\s\?]*?(\.\w+)?)(?:\?(\S+))? HTTP\/(\d\.\d)\r?$!o;
		my($METHOD, $URL, $EXT, $SEARCH, $VERSION) = ($1, $2, $3, $4, $5);
		
		$self->{method} = $METHOD;
		$self->{location} = $URL;
		$self->{get} = Utils::param($SEARCH);
		
		 # считываем заголовки
		$self->{head} = my $HEAD = {};
		/: (.*?)\r?$/ and $HEAD->{$`} = $1 while defined($_ = <$ns>) and !/^\r?$/;
		
		# считываем данные
		my $CONTENT_LENGTH = $HEAD->{"Content-Length"};
		my $f;
		$self->{post} = $CONTENT_LENGTH? Utils::param_from_post($HEAD->{'REQUEST_BODY_FILE'}? do { open $f, $HEAD->{'REQUEST_BODY_FILE'} or die "NOT OPEN REQUEST_BODY_FILE=".$HEAD->{'REQUEST_BODY_FILE'}." $!"; $f }: $ns, $HEAD->{'Content-Type'}, $CONTENT_LENGTH): {};
		close $f if defined $f;
		$self->{cookie} = Utils::param($HEAD->{"Cookie"}, qr/;\s*/);
		
		# настраиваем сессионное подключение (несколько запросов на соединение, если клиент поддерживает)
		$self->{'keep-alive'} = $keep_alive = (lc $HEAD->{Connection} eq 'keep-alive');
		
		my $ret = $app->();
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
		
		$self->{cookie} = $self->{method} = $self->{location} = $self->{get} = $self->{post} = undef;
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
		
		$self->{location} = $self->{env}{DOCUMENT_URI}; # REQUEST_URI
		$self->{method} = $self->{env}{REQUEST_METHOD};
		$self->{head} = { map { my $val = $self->{env}{$_}; s/^HTTP_//; $_=lc $_; s/_(.)/"-".uc $1/ge; ($_ => $val) } grep { /^HTTP_/ } keys %$env };
		
		$self->{get} = Utils::param($env->{'QUERY_STRING'}, qr/&/);
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

sub accept {
	my ($self, $app) = @_;
	$main::app = (sub {
		return sub {
			my $ret = $app->();
			my ($status, $head, $out) = @$ret;
			
		}
	})->($app);
}



sub close { my ($self) = @_; }


1