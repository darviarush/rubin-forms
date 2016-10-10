package R::Log::Syslog;
# логирует на терминал

use common::sense;
use R::App;

use Sys::Syslog qw/:standard/;

# конструктор
sub new {
	my ($cls) = @_;
	openlog($app->{site}{name}, "ndelay,pid");
	bless {}, $cls;
}

# сообщение
sub send {
	my ($self, $level, $message) = @_;
	syslog("err" //$level, $message);
}

# деструктор
sub DESTROY {
    closelog();
}

1;
