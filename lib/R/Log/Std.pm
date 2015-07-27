package R::Log::Std;
# логирует на терминал

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

# сообщение
sub send {
	my ($self, $level, $message) = @_;
	print STDERR $message;
}

1;
