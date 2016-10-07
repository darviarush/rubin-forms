package R::Raise;
# исключение фоматирует исключение


use common::sense;

use Carp qw/shortmess longmess/;
use Scalar::Util qw/blessed/;

use Term::ANSIColor qw/colorstrip color/;


use overload
	'""' => \&stringify,
	'.' => \&concat,
	'bool' => sub { 1 },
	"0+" => sub { $_[0]->{msg}? 1: 0 },
	"qr" => \&stringify,
	fallback => 1
;


# устанавливает обработчики
my $__DIE__;
my $__WARN__;
sub setdie {
	$__DIE__ = $main::SIG{ __DIE__ } if $main::SIG{ __DIE__ } != \&__ondie__;
	$__WARN__ = $main::SIG{ __WARN__ } if $main::SIG{ __WARN__ } != \&__onwarn__;
	$main::SIG{ __DIE__ } = \&__ondie__;
	$main::SIG{ __WARN__ } = \&__onwarn__;
}

# возвращает как было
sub retdie {
	$main::SIG{ __DIE__ } = $__DIE__ // "DEFAULT";
	$main::SIG{ __WARN__ } = $__WARN__  // "DEFAULT";
}

# возвращает дефолтные
sub defdie {
	$main::SIG{ __DIE__ } = "DEFAULT";
	$main::SIG{ __WARN__ } = "DEFAULT";
}

if(defined $^S) {
	setdie();
}

# конструктор
sub bingo {
	my ($cls, $abbr, $msg) = @_;
	my $self = $cls->new(longmess($msg), "bingo", $msg);
	$self->{abbr} = $abbr;
	$self
}

# конструктор
sub new {
	my ($cls, $msg, $who, $orig) = @_;
	
	# longmess почему-то бывает выдаёт скаляр $orig
	$msg = $$msg if ref $msg eq "SCALAR";
	
	if(@_ == 2) {
		$who = "throw";
		$orig = $msg;
		$msg = longmess($msg);
	}
	
	bless {
		msg => $msg,
		who => $who,
		orig => $orig,
		color => 1,
	}, ref $cls || $cls;
}

# обработчик события die
sub __ondie__ {
	my ($msg) = @_;
	
	unless(blessed($msg) and $msg->isa('R::Raise')) {
		#print STDERR "=== $msg\n";
		#use R::App qw/msg1/;
		#msg1 ":size10000", $msg;
		$msg = __PACKAGE__->new( longmess($msg), "error", $msg );
	}
	
	#print STDERR "@$ S==$^S ".@_."\@_==@_ GLOBAL_PHASE=${^GLOBAL_PHASE}\n";
	
	#die $msg;

	#return $msg if !defined $^S;
	die $msg if $^S <= 1;
	_log($msg);
	exit;
}

# обработчик события warn
sub __onwarn__ {
	my ($msg) = @_;
	
	unless(blessed($msg) and $msg->isa('R::Raise')) {
		$msg = __PACKAGE__->new( shortmess($msg), "warning", $msg );
	}
	
	warn $msg;
	_log($msg) if $^S > 1 || $^S < 0; # не в eval и не как обычно
	#exit;
	exit if $_[0]=~/^Deep recursion on subroutine/;
}

# логирует
sub _log {
	my ($msg) = @_;
	
	if($^S == 5) {
		$msg = "$msg\n\nRAISE IN DESTRUCT\n";
	}
	elsif($^S != 0) {
		$msg = "$msg\n\n\$^S == $^S";
	}
	
	#print STDERR $msg;
	
	#&retdie;
	eval {
		require R::App;
		$R::App::app->log->alert("$msg");
		#print STDERR $msg if !$R::App::app->log->{logs}{std};
	};
	print STDERR $msg if $@;
	#&setdie;
}

# превращает в строку
sub stringify {
	my $self = shift;
	
	local($_, $`, $', $1);
	$_ = $self->{msg};
	$_ = ref($_) eq "SCALAR"? $$_: $_;
	#$_ = (utf8::is_utf8($_)?"utf8":"no")."$_\n";
	#s/\\x\{(\w+)\}/ chr hex $1 /ge;
	
	#print STDERR "XXXXX: ".$self->{who}." $_\n\n";
	
	my @lines = split /\n/, $_;
	
	my $color = $self->{who} eq "bingo"? "cyan": $self->{who} eq "warning"? "yellow": "red";
	
	my $who = color($color) . $self->{who} . ": " . color("reset");
	
	for(@lines) {
		s{^\t?(.*?)(?: called)? at (.*?) line (\d+)}{
			my ($x, $f, $l)=($1, $2, $3);
			
			$x=~s{^\w+::(?:\w+::)+}{
				my $y = my $tmp = $&;
				$y =~ s!::!/!g; $y =~ s!/$!!;
				$f =~ m!\b$y\.pm$! ? "": $tmp
			}e;
			$x=~s![:\(\)]+!color("cyan") . $& . color("reset")!ge;
			"$f:".color("green")."$l".color("reset").": $who$x"
		}e;
		
		$who = "";
	}
	
	unshift @lines, $R::App::app->{connect}{CURR_SQL} if $R::App::app && $R::App::app->{connect} && $R::App::app->{connect}{CURR_SQL};
	
	join("\n", reverse @lines) . "\n";
}

# объединяет со строкой
sub concat {
	my ($self, $str, $wrap) = @_;
	if($wrap) { $str . $self->stringify }
	else { $self->stringify . $str }
}

# Возвращает оригинальную ошибку
sub orig {
	my ($self) = @_;
	$self->{orig}
}

# возвращает сообщение без at line
sub message {
	my ($self) = @_;
	ref $self->{orig}? $self->{orig}{message}: do { $self->{orig}=~ / at .* line \d+.*$/? $`: $self->{orig}  }
}

# добавляет в начало сообщения
sub messageAdd {
	my ($self, $add) = @_;
	$self->{orig} = join "", $add, "\n", $self->{orig};
	$self
}

# сообщает, что аббревиатура совпадает
sub is {
	my ($self, $abbr) = @_;
	$self->{abbr} && $self->{abbr} eq $abbr
}

# возвращает трейсбак
# count - количество строк с конца
sub trace {
	my ($self, $count) = @_;
	
	my $msg = longmess("app.raise.trace");

	if(defined $count) {
		local ($&, $`, $');
		my $r = "\n.*" x $count;
		$msg = $& if $msg =~ /$r$/;
	}
	
	__PACKAGE__->new( $msg, "trace", undef );
}

# возвращает строку
sub tracex {
	my ($self, $count) = @_;
	$self->trace($count)->stringify
}

1;