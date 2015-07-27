package R::Log::Echo;
# печатает в html

use common::sense;
use R::App;

use Term::ANSIColor qw//;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}

# сообщение
sub send {
	my ($self, $level, $message) = @_;
	
	local ($_, $`, $', $1, $2, $3, $4, $5, $6);
	my $stack = 0;
	$message =~ s!(&)|(<)|(>)|(")|(')|\e\[(\d+)m! $1? '&amp;': $2? '&lt;': $3? '&gt;': $4? '&quot;': $5? '&#39;': do {
		$_ = $Term::ANSIColor::ATTRIBUTES_R{$6};
		if(/clear|reset/) { my $x='</span>' x $stack; $stack = 0; $x }
		else { $stack++; "<span class='ansi-$_'>" }
	}
	!ge;
	
	
	$app->response->echo($level, ": ", $message, "<br>");
}

1;
