package R::Log::File;
# логирует на терминал

use common::sense;
use R::App;

use POSIX qw/strftime/;
use Fcntl qw(:flock SEEK_END);   # импортируем константы LOCK_*

# конструктор
sub new {
	my ($cls) = @_;
	
	my $path = $app->ini->{'log'}{path};
	
	if(-e $path) {
		my $f = $app->file($path);		
		$f->bzip2( $f->dir($f->dir . "/log-bk")->adddate("bz2")->mkpath->path );
	}
	
	open my $log, ">", $path or die "Не могу открыть $path: $!";
	
	bless {
		"file" => $log,
	}, $cls;
}

# сообщение
sub send {
	my ($self, $level, $message) = @_;
	
	my $log = $self->{file};
	#$message =~ s!^!\t!gm;
	#$message =~ s/$/\n/;
	my $c = 0;
	$c++ while $message =~ /\n/g;
	
	my ($info1, $info2);
	
	my $log_info_prefix = $app->ini->{'log_info_prefix'};
	if($log_info_prefix) {
		my $info = strftime("%Y-%m-%d %H:%M:%S", localtime) . " [$$] {$level}";
		$info1 = "$info ";
		$info2 = "\n\t$info\n";
	}
	
	$self->lock;
	
	if($c<2) {
		print $log $info1, $message;
	} else {
		print $log $info2, $message, "\n";
	}

	$self->unlock;
	
	$self
}

sub lock {
	my $self = shift;
	my $log = $self->{"file"};
	flock($log, LOCK_EX) or do { print STDERR "Cannot lock log - $!\n"; exit };
	seek($log, 0, SEEK_END)  or do { print STDERR "Cannot seek - $!\n"; exit };	# и если что-то добавилось, пока мы ожидали...
	$self
}

sub unlock {
	my $self = shift;
	flock($self->{"file"}, LOCK_UN) or do { print STDERR "Cannot unlock log - $!\n"; exit };
	$self
}

1;
