package R::Raise;
# реализует исключение

# конструктор
sub new {
	my ($cls, $app) = @_;
	bless {app => $app}, $cls;
}

# создаёт исключение без трассировки
sub set {
	R::Raise::Trace->new(@_);
}

# создаёт исключение с трассировкой
sub trace {
	my ($self, $error) = @_;

	my $trace = R::Raise::Trace->new($error);
	
	for(my $i=1; my @param = caller($i); $i++) {
		my ($package, $file, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @param;
		$subroutine =~ s!^main::(\w+)$!$1!;
		$subroutine =~ s!(^|::)__ANON__$!$1~!;
		push @{$trace->{trace}}, {file=>$file, line=>$line, sub=>$subroutine} if $subroutine ne "(eval)";
	}

	$trace
}


package R::Raise::Trace;
# преобразует и печатает исключение

use Term::ANSIColor qw//;
use Cwd qw//;
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
	
	if(ref $error) { $error = Utils::Dump($error); }
	else {
		for my $e (split /\n/, $error) {
			$e =~ s!^syntax error at (\S+) line (\d+), (.*)$!! and push @$trace, { file=>$1, line=>$2, msg=>$3, action=>'syntax error'} or
			$e =~ s! at (\S+) line (\d+)(?:, <GEN\d+> line \d+)?(, .*)?\.?\s*$!! and push @$trace, { file=>$1, line=>$2, msg=>$3? $e.$3: $e}
			or push @$trace, { file=>"?", line=>"?", msg => $e };
		}
		
	}
	bless { orig => $error, trace => $trace }, $cls;
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

	return $self->asString if $ENV{TERM} eq 'dumb';
	
	join "", map {
		if($_->{sub}) { "$_->{file}:$_->{line}: $_->{sub}\n" }
		else { "$_->{file}:$_->{line}: " . Term::ANSIColor::colored(($_->{action} // $action).": ", $color_error) . Term::ANSIColor::colored($_->{msg}, $color_words) . "\n" }
	} @{$self->{trace}};
}

# строка
sub asString {
	my ($self, $action) = @_;
	join "", map {
		my $file = Cwd::abs_path($_->{file});
		$file =~ s!^/cygdrive/(\w)!$1:!;
		$file =~ s!^/(usr/)?!c:/cygwin/!;
		$file =~ s!/!\\!g;
		if($_->{sub}) { "$file:$_->{line}:1: $_->{sub}\n" }
		else { "$file:$_->{line}:1: " . ($_->{action} // $action) .": " . $_->{msg} . "\n" }
	} @{$self->{trace}};
}

# вывод в html
sub html {
	my ($self) = @_;
	my $i = 0;
	("<style><!--
.e-even {background: lavender}
.e-odd {background: AliceBlue}
.e-even, .e-odd { padding: 4pt 4pt 4pt 20pt }
--></style>
",
	map {
		"<div class='".($i++ % 2 == 0? 'e-odd': 'e-even')."'>".
		"<font color=LightSlateGray>".Utils::escapeHTML($_->{file}).":$_->{line}</font> ".
		Utils::escapeHTML($_->{sub} || $_->{msg}).
		"</div>"
	} @{$self->{trace}});
}

1;