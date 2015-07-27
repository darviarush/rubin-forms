package R::Log;
# обёртка для логов

use common::sense;
use R::App;

use POSIX qw/strftime/;
use Term::ANSIColor qw/color colorstrip /;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		log_as_is => [$app->logStd],
		log => []
	}, $cls;
}

my %control = (%Term::ANSIColor::ATTRIBUTES, $app->data->set(qw/
space empty sep time
inline inline_end nonewline
/));

# сообщение
sub send {
	my $self = shift;
	my $level = shift;
	
	#return $self unless exists $levels{$level};
	
	my ($sep, $next, $reset, $inline) = ", ";
	my $newline = 1;
	my $color = "reset";
	my $bg = "reset";
	
	my $sepout = sub { (color("red"), $sep, color($color)) };
	
	my @msg = map {
		!defined($_)? (color("red"), "undef", color($color), &$sepout):
		ref $_? ($inline? $app->data->inline_dump($_): $app->data->dump($_),  &$sepout):
		/^:/? do {
			my @param = split / /, $';
			my $save = $_;
			if(grep { !exists $control{$_} } @param) { ($save, &$sepout) }
			else {
				map {
					$_ eq "nonewline"? do { $newline = undef; () }:
					$_ eq "inline"? do { $inline = 1; () }:
					$_ eq "inline_end"? do { $inline = 0; () }:
					$_ eq "space"? do { $sep = " "; () }:
					$_ eq "empty"? do { $sep = ""; () }:
					$_ eq "sep"? do { $sep = ", "; () }:
					$_ eq "time"? do { strftime("%T", localtime) }:
					do {
						$reset = 1;
						$color = $_ if !/on_|clear|reset|bold|dark|faint|underline|underscore|blink|reverse|concealed/;
						$bg = $_ if /on_/;
						color($_);
					}
				} @param;
			}
		}: ($_, &$sepout);
	} @_;
	
	splice @msg, @msg-3, 3 if @msg>=3;	# удаляем последний разделитель
	
	push @msg, color("reset") if $reset;
	push @msg, "\n" if $newline;
	
	my $msg = join "", @msg;
		
	for my $log (@{$self->{log_as_is}}) {
		$log->send($level, $msg);
	}
	
	$msg = colorstrip($msg);
	
	for my $log (@{$self->{log}}) {
		$log->send($level, $msg);
	}
	
	$self
}

# уровень информации
sub info {
	my $self = shift;
	$self->send("info", @_);
}

# уровень отладки
sub debug {
	my $self = shift;
	$self->send("debug", @_);
}

# уровень важных сообщений
sub notice {
	my $self = shift;
	$self->send("notice", @_);
}

# уровень предупреждений
sub warn {
	my $self = shift;
	$self->send("warning", @_);
}

# уровень ошибок
sub error {
	my $self = shift;
	$self->send("error", @_);
}

# критический уровень
sub critical {
	my $self = shift;
	$self->send("critical", @_);
}

# сообщение должно быть доставлено
sub alert {
	my $self = shift;
	$self->send("alert", @_);
}

# ничто не работает
sub emerg {
	my $self = shift;
	$self->send("emerg", @_);
}



1;
