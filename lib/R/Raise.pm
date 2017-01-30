package R::Raise;
# исключение фоматирует исключение


use common::sense;

#use Carp qw/shortmess longmess/;
use Scalar::Util qw/blessed looks_like_number/;

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
	my $self = $cls->new($msg, "bingo");
	$self->{abbr} = $abbr;
	$self
}

# конструктор
sub new {
	my ($cls, $msg, $who, $arity) = @_;
	
	# longmess почему-то бывает выдаёт скаляр $orig
	#$msg = $$msg if ref $msg eq "SCALAR";
	
	# if(@_ == 2) {
		# $who = "throw";
		# $orig = $msg;
		# $msg = longmess($msg);
	# }
	
	bless {
		who => $who // "throw",		# error, warning, trace, throw, etc...
		msg => $msg,		# сообщение об ошибке
		trace => &DB::__RAISE__TRACE__($arity),		# traceback - массив [[file, lineno, object]]...
		color => 1,			# колоризировать
	}, ref $cls || $cls;
}

# обработчик события die
sub __ondie__ {
	my ($msg) = @_;
	
	unless(blessed($msg) and $msg->isa('R::Raise')) {
		#print STDERR "=== $msg\n";
		#use R::App qw/msg1/;
		#msg1 ":size10000", $msg;
		$msg = __PACKAGE__->new( $msg, "error", 3 );
	}
	
	#print STDERR "@$ S==$^S ".@_."\@_==@_ GLOBAL_PHASE=${^GLOBAL_PHASE}\n";
	
	#die $msg;

	#return $msg if !defined $^S;
	
	die $msg if $^S <= 1;
	
	print "raise to log\n";
	
	_log($msg);
	exit;
}

# обработчик события warn
sub __onwarn__ {
	my ($msg) = @_;
	
	unless(blessed($msg) and $msg->isa('R::Raise')) {
		$msg = __PACKAGE__->new( $msg, "warning", 3 );
	}
	
	warn $msg;
	_log($msg) if $^S > 1 || $^S < 0; # не в eval и не как обычно
	#exit;
	exit if $_[0]=~/^Deep recursion on subroutine/;
}

# логирует
sub _log {
	my ($msg) = @_;
	
	print "raise _log\n";
	
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


# возвращает аргументы предпредпоследнего вызова
package DB {
	# нужно использовать с функцией 2-й вложенности или задать вложенность
	sub __RAISE__TRACE__ {
		my ($arity) = @_;
		my $trace = [];
		for(my $i=$arity // 0;; $i++) {
			my $args = [];
			@$args = caller($i);
			last if !@$args;
			push @$args, [ @DB::args ];
			push @$trace, $args;
		}
		return $trace;
	}
}


# возвращает пустую строку
sub empty { "" }

# 
sub _tostring {
	my ($x) = @_;
	$x =~ s/\t/\\t/g;
	$x =~ s/\n/\\n/g;
	"\"$x\""
}

# обращает в строку _toargs
sub _toargs {
	my ($args) = @_;
	my $chars = 100;
	join(", ", map { 
		my $x = looks_like_number($_)? $_: !ref($_)? _tostring($_): sprintf("%s=%X", ref($_), int($_));
		$x = substr($x, 0, $chars) . "…" if length($x) > $chars;
		$x
	} @$args)
}

# превращает в строку
sub stringify {
	my $self = shift;

	local($_, $`, $', $1);
	
	my $res = "";
	
	for my $trace (@{$self->{trace}}) {
		my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash, $args) = @$trace;
		
		my $arguments = $hasargs? "("._toargs($args).")": "";
		
		$subroutine = "~" if $subroutine eq "__ANON__";
		
		my $pack = quotemeta $package;
		$package = $subroutine =~ /^$pack/? "": "$package ";
		
		$subroutine =~ s/::(\w+)$/.$1/;
		
		$res .= "$filename:$line $package$subroutine$arguments\n";
	}
	
	$res .= "$self->{who}: $self->{msg}";
	
	$res
	
	
	# $_ = $self->{msg};
	# $_ = ref($_) eq "SCALAR"? $$_: $_;
	# #$_ = (utf8::is_utf8($_)?"utf8":"no")."$_\n";
	# #s/\\x\{(\w+)\}/ chr hex $1 /ge;
	
	# # eval {
		# # require R::App;
		# # $R::App::app->file("var/last.raise.trace")->write($R::App::app->perl->dumper($self));
	# # };
	# # return "$self->{who}: $self->{orig}\n" if !$@;
	
	# #print STDERR "XXXXX: ".$self->{who}." $_\n\n";
	
	# my @lines = split /\n/, $_;
	
	# my $color = $self->{who} eq "bingo"? "cyan": $self->{who} eq "warning"? "yellow": "red";
	
    # #R::App::msg1(-t STDERR);
    # # -t STDERR;
    # my $cc = 1? \&color: \&empty;
    
	# my $who = $cc->($color) . $self->{who} . ": " . $cc->("reset");
	
	# for(@lines) {
		# s{^\t?(.*?)(?: called)? at (.*?) line (\d+)}{
			# my ($x, $f, $l)=($1, $2, $3);
			
			# $x=~s{^\w+::(?:\w+::)+}{
				# my $y = my $tmp = $&;
				# $y =~ s!::!/!g; $y =~ s!/$!!;
				# $f =~ m!\b$y\.pm$! ? "": $tmp
			# }e;
			# $x=~s![:\(\)]+!$cc->("cyan") . $& . $cc->("reset")!ge;
            
            # $f =~ s!/cygdrive/(\w)!$1:!, $f =~ s!/!\\!g if $cc == \&empty;
            
			# "$f:".$cc->("green")."$l".$cc->("reset").": $who$x"
		# }e;
		
		# $who = "";
	# }
	
	# unshift @lines, $R::App::app->{connect}{CURR_SQL} if $R::App::app && $R::App::app->{connect} && $R::App::app->{connect}{CURR_SQL};
	
	# join("\n", reverse @lines) . "\n";
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
	$self->{msg}
}

# возвращает сообщение без at line
sub message {
	my ($self) = @_;
	ref $self->{msg}? $self->{msg}{message}: do { $self->{msg}=~ / at .* line \d+.*$/? $`: $self->{msg}  }
}

# # добавляет в начало сообщения
# sub messageAdd {
	# my ($self, $add) = @_;
	# $self->{orig} = join "", $add, "\n", $self->{orig};
	# $self
# }

# сообщает, что аббревиатура совпадает
sub is {
	my ($self, $abbr) = @_;
	$self->{abbr} && $self->{abbr} eq $abbr
}

# возвращает трейсбак
# count - количество строк с конца
sub trace {
	my ($self, $count) = @_;
	
	#my $msg = longmess("app.raise.trace");

	# if(defined $count) {
		# local ($&, $`, $');
		# my $r = "\n.*" x $count;
		# $msg = $& if $msg =~ /$r$/;
	# }
	
	__PACKAGE__->new( "app.raise.trace", "trace" );
}

# возвращает строку
sub tracex {
	my ($self, $count) = @_;
	$self->trace($count)->stringify
}

1;