package R::Log::Std;
# логирует на терминал

#use base "R::Log::File";

use common::sense;
use R::App;

#binmode STDOUT, ":utf8";
#binmode STDERR, ":utf8";

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		echo => [],
	}, $cls;
}

# сообщение
sub send {
	my ($self, $level, $message) = @_;
	
	if($level =~ /^info|debug|notice$/) {
		print STDOUT $message;
	} else {
		print STDERR $message;
	}
}

1;
