package R::Raise;
# реализует исключение

use strict;
use warnings;

# синглетон
our $raise;

# обработчик события die
sub __ondie__ {
	my ($msg) = @_;
	if(ref $msg ne 'R::Raise::Trace') {
		eval { $msg = $raise->trace($msg) };
		die "ошибка в die: $@" if $@;
	}
	die $msg if $^S;
	print STDERR $msg;
	exit
}

# обработчик события warn
sub __onwarn__ {
	my $msg = $raise->trace($_[0])->color("warning", 'yellow', 'green');
	die $msg if $^S;
	print STDERR $msg;
	exit;
	exit if $_[0]=~/^Deep recursion on subroutine/;
}

# конструктор - синглетон
sub new {
	my ($cls, $app) = @_;
	return $raise if $raise;
	
	$raise = bless {app => $app}, $cls;
	
	$SIG{ __DIE__ } = \&__ondie__;
	$SIG{ __WARN__ } = \&__onwarn__;
	
	$raise
}

# создаёт исключение без трассировки
sub set {
	R::Raise::Trace->new($_[1]);
}

# создаёт исключение с трассировкой
sub trace {
	my ($self, $error) = @_;

	my $trace = R::Raise::Trace->new($error);
	my $TRACE = $trace->{trace};
	
	for(my $i=3; my @param = caller($i); $i++) {
		#::msg("$i:", @param);
		my ($package, $file, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @param;
		
		if(defined $evaltext) {
			$subroutine = "REQUIRE" if $is_require;
			$subroutine = $evaltext unless $is_require
		}
		
		$subroutine =~ s!(^|::)__ANON__$!$1~!;
		#$subroutine =~ s!^main(::[^:]+)$!$1!;

		push @$TRACE, {
			file=>$file,
			line=>$line,
			subroutine=> $subroutine
		};# if $subroutine ne "(eval)";
	}
	
	@$TRACE = $self->reverse_trace($TRACE);
	$trace->{trace} = [reverse @$TRACE];
	
	$trace
}

# преобразует trace
sub reverse_trace {
	my ($self, $trace) = @_;
	my $i = 0;
	map {
		$_->{file} = file($_->{file});
		$i++;
		my $sub = my $x = $trace->[$i]{subroutine} // "~";
		$x =~ s!::!/!g;
		$x =~ s!/[^/]+$!!;
		$x = quotemeta $x;
		$sub =~ s!.*::([^:]+)$!$1! if $_->{file} =~ /$x\.pm$/;
		
		if($_->{subroutine}) {
			$_->{sub} = $sub;
			$_
		} elsif(@$trace!=$i and $trace->[$i]{subroutine} and $sub ne "~") {
			($_, {file => $_->{file}, line => $_->{line}, sub => $sub })
		}
		else {$_}
	} @$trace;
}

# возвращает ?, если не указан файл
sub file {
	my ($file) = @_;
	return "?" unless defined $file;
	# watch/action_c/index.act.pl -> action/index.act
	$file =~ s!/watch/(\w+)_c/(.*\.\w+)\.pl$!/$1/$2!;
	$file
}


package R::Raise::Trace;
# преобразует и печатает исключение

use Term::ANSIColor qw//;
#use Cwd qw/abs_path getcwd/;
use Data::Dumper;
use overload
	'""' => \&stringify,
	'.' => \&concat,
	'bool' => sub { @{$_[0]->{trace}}? 1: undef },
	"0+" => sub { @{$_[0]->{trace}} },
	"qr" => \&stringify,
	fallback => 1
;

# конструктор
sub new {
	my ($cls, $error) = @_;
	local ($_, $`, $', $1, $2);
	my $trace = [];
	my @lines;
	
	if(ref $error) { $error = $Utils::{Dump}{CODE}? $Utils::{Dump}{CODE}->($error): Dumper($error); }
	else {
		#$error = "< ошибка-строка >" . $error . "< конец >";
		for my $e (split /\n/, $error) {
			if($e =~ s!^syntax error at (\S+) line (\d+), (.*)$!!) {
				push @$trace, { file=>$1, line=>$2, msg=>$3, action=>'syntax error'}
			} elsif($e =~ s! at (.*?) line (\d+)(?:, <GEN\d+> line \d+)?(,? .*)?\.?\s*$!!) {
				push @$trace, { file=>$1, line=>$2, msg=>$3? $e.$3: $e}
			} elsif($e =~ m!:(\d+):\s+!) {
				push @$trace, { file=>$`, line=>$1, msg => $' };
			} else {
				push @lines, $e;
			}
		}
		
	}
	
	push @$trace, { file => "?1", line => "?1", msg => join "\n", @lines } if @lines;
	
	push(@$trace, { file => "?2", line => "?2", msg => $R::Connect::CURR_SQL }), $R::Connect::CURR_SQL = undef if $R::Connect::CURR_SQL;
	
	bless { orig => $error, trace => $trace }, $cls;
}

# возвращает trace
sub trace {
	my ($self) = @_;
	my $trace = $self->{trace};
	@$trace
}

# превращает в строку
sub stringify {
	my ($self) = @_;
	$self->color('error', 'red', 'cyan');
}

# объединяет со строкой
sub concat {
	my ($self, $str, $wrap) = @_;
	if($wrap) { $str . $self->stringify }
	else { $self->stringify . $str }
}

# выводит колоризированным
sub color {
	my ($self, $action, $color_error, $color_words) = @_;

	return $self->asString($action) unless $::_UNIX;
	
	my $col = Term::ANSIColor::colored("::", $color_words);
	#my $raz = Term::ANSIColor::colored(":", $color_error);
	
	join "", map {
		$_->{file} //= "??";
		$_->{line} //= "??";
		$_->{sub} //= $_->{subroutine};
		if($_->{sub}) { my $sub = $_->{sub}; $sub =~ s!::([^:]+)$!$col$1!; "$_->{file}:$_->{line}: $sub\n" }
		else {
			"$_->{file}:$_->{line}: " . Term::ANSIColor::colored(($_->{action} // $action).": ", $color_error) . Term::ANSIColor::colored($_->{msg} // "-", $color_words) . "\n"
		}
	} $self->trace;
}

# изменяет путь cygwin на виндовый
sub _winpath {
	my ($path) = @_;
	return "--undef path in winpath--" unless defined $path;
	
	return $path if $main::_UNIX;
	
	local ($`, $');
	
	my $file = $path;

	if(-e $path) {
		$path = eval { require Cwd; Cwd::fast_abs_path($path) };
		$file = $path unless $@ // $!;
	}
	
	$file =~ s!^/cygdrive/(\w)!$1:!;
	$file =~ s!^/(usr/)?!c:/cygwin/!;
	$file =~ s!/!\\!g;
	$file
}


# строка
sub asString {
	my ($self, $action) = @_;
	join "", map {
		my $file = _winpath($_->{file});
		if($_->{sub}) { "$file:$_->{line}:1: $_->{sub}\n" }
		else { "$file:$_->{line}:1: " . ($_->{action} // $action) .": " . $_->{msg} . "\n" }
	} $self->trace;
}

# вывод в html
sub html {
	my ($self) = @_;
	my $i = 0;
	join "", ("<style><!--
.e-container .e-even {background: lavender}
.e-container .e-odd {background: AliceBlue}
.e-container .e-even, .e-container .e-odd { padding: 4pt 4pt 4pt 20pt; overflow: visible; color: black }
--></style>
<div class=e-container>
", # style='overflow: auto; width: 100%; height: 153px'
	map({
		"<div class='".($i++ % 2 == 0? 'e-odd': 'e-even')."'>".
		"<font color=LightSlateGray>".Utils::escapeHTML(R::Raise::file($_->{file})).":".($_->{line} // "?")."</font> ".
		Utils::escapeHTML($_->{sub} // $_->{msg} // "?").
		"</div>"
	} $self->trace), "</div>");
}

1;