package R::Log;
# обёртка для логов

use common::sense;
use R::App;

use POSIX qw/strftime/;
use Term::ANSIColor qw/color colorstrip /;

# конструктор
sub new {
	my ($cls, %x) = @_;
	
	my $as_is = exists $x{log_as_is}? $x{log_as_is}:
		exists $app->ini->{'log'}? 
		(exists $app->ini->{'log'}{log_as_is}? $app->ini->{'log'}{log_as_is}: "std"):
		"std";
	my $log = exists $x{'log'}? $x{'log'}: $app->ini->{'log'}{'log'};
	
	my @as_is = map { "log" . ucfirst($_) } split /\s+/, $as_is;
	my @log = map { "log" . ucfirst($_) } split /\s+/, $log;
	
	bless {
		_log_as_is => [map {$app->$_} @as_is],
		_log => [map {$app->$_} @log],
		log_as_is => [@as_is],
		log => [@log],
		logs => {map { {$_=>1} } @as_is, @log},
	}, ref $cls || $cls;
}

#$app->ini->{"original-log"} = $app->ini->{log};


# переключает на дефолтный
sub default {
	my ($self) = @_;
	
	$app->ini->{log}{"original-log"} = { %{$app->ini->{log}} } if !exists $app->ini->{log}{"original-log"};
	
	$app->ini->{log} = { %{$app->ini->{log}}, %{$app->ini->{log}{"original-log"}} };
	%$self = %{$app->log->new};
	$self
}

# переключает на серверный
sub server {
	my ($self) = @_;
	
	$app->ini->{log}{"original-log"} = { %{$app->ini->{log}} } if !exists $app->ini->{log}{"original-log"};
	
	$app->ini->{log} = { %{$app->ini->{log}}, %{$app->ini->{log}{server}} };
	%$self = %{$app->log->new};
	$self
}



my %control = (%Term::ANSIColor::ATTRIBUTES, $app->perl->set(qw/
space empty sep time
inline inline_end nonewline
SIZE
/));


# возвращает колоризированную строку
sub colorized {
	my $self = shift;
	
	local ($_, $`, $', $&);
	
	my ($sep, $next, $reset, $inline) = ", ";
	my $newline = 1;
	my $color = "reset";
	my $bg = "on_black";
	my $dump_size = 1000;
	
	my $last_sep_pos;
	my @msg;
	
	for(my $index = 0; $index<@_; $index++) {
		my $p = $_[$index];
		
		if(!defined($p)) {
			push @msg, color("red"), color("on_black"), "undef";
		}
		elsif(ref $p) {
			if($inline) {
				push @msg, $app->perl->inline_dump($p, $dump_size);
			} else {
				push @msg, $app->perl->dump($p, $dump_size);
			}
		}
		elsif($p =~ /^:/) {
			my @param = split / +/, $';
			
			if(grep { s/^size(\d+)$/ $dump_size = $1; "SIZE" /e; !exists $control{$_} } @param) {
				push @msg, $p;
			}
			else {
				for my $r (@param) {
					if($r eq "SIZE") {}
					elsif($r eq "nonewline") { $newline = undef; }
					elsif($r eq "inline") { $inline = 1; }
					elsif($r eq "inline_end") { $inline = 0; }
					elsif($r eq "space") { $sep = " "; }
					elsif($r eq "empty") { $sep = ""; }
					elsif($r eq "sep") { $sep = ", "; }
					elsif($r eq "time") { push @msg, strftime("%T", localtime) }
					else {
						$reset = 1;
						$color = $r if $r !~ /on_|clear|reset|bold|dark|faint|underline|underscore|blink|reverse|concealed/;
						$bg = $r if $r =~ /on_/;
						$color = "reset", $bg = "reset" if $r =~ /reset/;
						push @msg, color($r);
					}
				}
				next;
			}
		} else {
			push @msg, $p;
		}
		
		$last_sep_pos = undef;
		
		if($sep ne "") {
			$reset = 1;
			$last_sep_pos = @msg;
			push @msg, color("red") . color("on_black") . $sep . color($color) . ($color ne "reset" && $bg ne "reset"? color($bg): "");
		}
	}
	
	splice @msg, $last_sep_pos, 1 if $last_sep_pos;	# удаляем последний разделитель
	
	push @msg, color("reset") if $reset;
	push @msg, "\n" if $newline;
	
	join "", @msg;
}

# сообщение
sub send {
	my $self = shift;
	
	my $log_as_is = $self->{_log_as_is};
	my $logs = $self->{_log};
	
	return $self if @$log_as_is == 0 && @$logs == 0;
	
	my $level = shift;
	#return $self unless exists $levels{$level};
	
	my $msg = $self->colorized(@_);
	
	for my $log (@$log_as_is) {
		$log->send($level, $msg);
	}
	
	if(@$logs) {
		$msg = colorstrip($msg);
		
		for my $log (@$logs) {
			$log->send($level, $msg);
		}
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
