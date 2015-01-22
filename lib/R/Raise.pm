package R::Raise;
# реализует исключение

use strict;
use warnings;


# конструктор
sub new {
	my ($cls, $app) = @_;
	bless {app => $app}, $cls;
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
	
	for(my $i=1; my @param = caller($i); $i++) {
		my ($package, $file, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @param;
		#$subroutine =~ s!^main::(\w+)$!$1!;
		$subroutine =~ s!(^|::)__ANON__$!$1~!;
		$subroutine =~ s!^main(::[^:]+)$!$1!;
		
		push @$TRACE, {file=>$file, line=>$line, subroutine=> ($is_require? "require ": "").$subroutine} if $subroutine ne "(eval)";
	}

	$trace
}


package R::Raise::Trace;
# преобразует и печатает исключение

use Term::ANSIColor qw//;
use Cwd qw//;
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
	
	my ($file, $line);
	
	if(ref $error) { $error = $Utils::{Dump}{CODE}? $Utils::{Dump}{CODE}->($error): Dumper($error); }
	else {
		for my $e (split /\n/, $error) {
			$e =~ s!^syntax error at (\S+) line (\d+), (.*)$!! and push @$trace, { file=>$file=$1, line=>$line=$2, msg=>$3, action=>'syntax error'} or
			$e =~ s! at (\S+) line (\d+)(?:, <GEN\d+> line \d+)?(, .*)?\.?\s*$!! and push @$trace, { file=>$file=$1, line=>$line=$2, msg=>$3? $e.$3: $e}
			or push @$trace, { file=> $file // "?", line=> $line // "?", msg => $e };
		}
		
	}
	
	push(@$trace, { file=> $file // "?", line=> $line // "?", msg => $R::Connect::CURR_SQL }), $R::Connect::CURR_SQL = undef if $R::Connect::CURR_SQL;
	
	bless { orig => $error, trace => $trace }, $cls;
}


# преобразует trace перед выводом и возвращает его
sub trace {
	my ($self) = @_;
	my $trace = $self->{trace};
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
		} elsif(@$trace!=$i and $trace->[$i]{subroutine}) {
			($_, {file => $_->{file}, line => $_->{line}, sub => $sub })
		}
		else {$_}
	} @$trace;
}

sub file {
	my ($file) = @_;
	return "?" unless defined $file;
	$file =~ s!/watch/action_c/(.*)\.(\w+)\.pl$!/action/$1.$2!;
	$file
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

	return $self->asString($action) unless exists $ENV{SHLVL};
	
	my $col = Term::ANSIColor::colored("::", $color_words);
	#my $raz = Term::ANSIColor::colored(":", $color_error);
	
	join "", map {
		if($_->{sub}) { my $sub = $_->{sub}; $sub =~ s!::([^:]+)$!$col$1!; "$_->{file}:$_->{line}: $sub\n" }
		else {
			$_->{file} //= "??";
			$_->{line} //= "??";
			"$_->{file}:$_->{line}: " . Term::ANSIColor::colored(($_->{action} // $action).": ", $color_error) . Term::ANSIColor::colored($_->{msg}, $color_words) . "\n"
		}
	} $self->trace;
}

# изменяет путь cygwin на виндовый
sub _winpath {
	return "--undef path in winpath--" if !defined $_[0];
	local ($`, $');
	my $file = eval { Cwd::abs_path($_[0]) };
	$file //= $_[0];
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
	("<style><!--
.e-even {background: lavender}
.e-odd {background: AliceBlue}
.e-even, .e-odd { padding: 4pt 4pt 4pt 20pt; overflow: visible; color: black }
--></style>
<div class=e-container>
", # style='overflow: auto; width: 100%; height: 153px'
	map({
		"<div class='".($i++ % 2 == 0? 'e-odd': 'e-even')."'>".
		"<font color=LightSlateGray>".Utils::escapeHTML(file($_->{file})).":".($_->{line} // "?")."</font> ".
		Utils::escapeHTML($_->{sub} // $_->{msg} // "?").
		"</div>"
	} $self->trace), "</div>");
}

1;