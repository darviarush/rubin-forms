package R::Log::Echo;
# печатает в html

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, $cls;
}

# сообщение
sub send {
	my ($self, $level, $message) = @_;
	
	push @{$app->{q}{logEcho}}, $app->html->escape_ansi($message), "<br>" if $app->{q};
	
	$self
}

# добавляет к ответу сообщение
sub response {
	my ($self) = @_;
	
	my $q = $app->{q};
	
	if($q and $q->{logEcho} and $q->type eq "text/html") {
		$q->echo("<div style='background:#3F3F3F;color:#DCDCDC;padding:0.5em'>", @{$q->{logEcho}}, "</div>");
	}
	
	delete $q->{logEcho};
	
	$self
}

1;
