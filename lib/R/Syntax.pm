package R::Syntax;
# �������������� ����������
# ������������� �� ���� �������� �����, ��������� ���� ����� ���������� ������� ���������

use common::sense;
use R::App;

# �����������
sub new {
	my ($cls) = @_;
	bless {
		
		PREFIX => {},			# �������-���������
		INFIX => {},			# ������-��������� 
		POSTFIX => {},			# ��������-���������
		
		BR => {},				# ������
		CR => {},				# ����������� ������ (��� ������������ �������)
		X => {},				# ���������
		
		PRIO => 0,				# ��������� ����������
		
		LEXX => undef,			# ����������� ����������
		
		trace => "EXAMPLE",		# ���� ����� �������� ��������
		file => "",				# ���� � �������� �����
		lineno => 1,			# ����� ������ � ������� �����
		
		stack => undef,			# ���� ����������
		terms => undef,			# ���� ���������
		space => undef,			# �������������� ���� ������
		
		op => "",				# ����������� ��������
		front => 1,				# ���������� ������� ���������� (������� �� �������)
		
		error => {				# ������
			sym => "����������� ������ `%s`",
		},
		
	}, ref $cls || $cls;
}

###############################  ������������ ������� ###############################

# �����
# ������
# ���������

our $nonassoc = 0b000001;				# �����������������
our $leftassoc = 0b000010;				# ������������� ���������������
our $rightassoc = 0b000100;				# �������������� ���������������

our $infix = 0b001000;					# ��������� ��������
our $prefix = 0b010000;					# ���������� ��������
our $postfix = 0b100000;				# ����������� ��������

our $xfy=$infix | $leftassoc;			# ����������������� ���������
our $yfx=$infix | $rightassoc;			# ������������������ ���������
our $xfx=$infix | $nonassoc;			# ��������������� ���������

our $yf=$postfix | $leftassoc;			# ������������������ ����������
our $xf=$postfix | $nonassoc;			# ��������������� ����������

our $fy=$prefix | $rightassoc;			# ����������������� �����������
our $fx=$prefix | $nonassoc;			# ��������������� �����������

our %FIX = (
	xfy => $xfy,
	yfx => $yfx,
	xfx => $xfx,
	xf => $xf,
	yf => $yf,
	fx => $fx,
	fy => $fy,
);


# ������ ������� ����������
sub td {
	my $self = shift;
	my $type = shift;
	
	my $fix = $FIX{$type};
	die "��� $type �����" if !defined $fix;

	my %p = (
		prio=>$_PRIO,
		fix=>$fix,
		type=>$type,
	);
	
	my $key = $fix & $infix? "INFIX": $fix & $prefix? "PREFIX": "POSTFIX";
	for my $x (@_) {
		die "�������� $type `$x` ��� ��������" if exists $self->{$key}{$x};
		$self->{$key}{$x} = {%p, name=>"$type $x"};
	}

	$self
}

# ������ ������� ����������
sub tr {
	my $self = shift;
	$self->{PRIO}++;
	$self->td(@_) if @_;
	$self
}

# ������
sub br {
	my $self = shift;
	
	my $br = $self->{BR};
	my $closest = $self->{CR};
	my $open;			# ����������� ������
	my $close = 1;		# ����������� ������
	
	for(my $i=0; $i<@_; $i++) {
		my $a = $_[$i];
		if(ref $a eq "Regexp") {
			my $r = $close? $close: $open;
			die "��������� ��� ���� � ������ $r->{name}" if exists $r->{re};
			$r->{re} = $a;
		}
		elsif(ref $a eq "CODE") {
			my $r = $close? $close: $open;
			die "��� ��� ���� � ������ $r->{name}" if exists $r->{sub};
			$r->{sub} = $a;
		}
		elsif($close) {	# ����������� ������
			die "������ `$a` ��� ����" if exists $br->{ $a };
			$br->{ $a } = $open = { name => "br $a" };
		}
		else {	# ����������� ������
			if(exists $closest->{ $a }) {
				$close = $closest->{ $a };
			} else {
				$closest->{ $a } = $close = { name => "cr $a" };
			}
			$open->{tag} = $a;
		}
	}
	
	$self
}

# �������� (���������)
sub x {
	my $self = shift;
	
	#die "������������ ������� �������� ��� ���������" if $self->{LEXX};
	
	my $x = $self->{X};
	my $prev;
	
	for(my $i=0; $i<@_; $i++) {
		my $a = $_[$i];
		if(ref $a eq "Regexp") {
			die "��������� ��� ���� � ��������� $prev->{name}" if exists $prev->{re};
			$prev->{re} = $a;
		}
		elsif(ref $a eq "CODE") {
			die "��� ��� ���� � ��������� $prev->{name}" if exists $prev->{sub};
			$prev->{sub} = $a;
		}
		else {
			die "�������� `$a` ��� ����" if exists $x->{ $a };
			$x->{ $a } = $prev = { name => "x $a" };
		}
	}
	
	$self
}

###############################  ����������� ���������� ###############################

# ��������� ������ ��� ����������
sub operators {
	my ($self) = @_;
	keys %{ +{ keys %{$self->{INFIX}}, keys %{$self->{PREFIX}}, keys %{$self->{POSTFIX}} } };
}

# ��������� �������
sub _lex {
	my $self = shift;
	join "|", map {
		$_->{re} // do { 
			my $x = quotemeta($_->{name} =~ /^\w+ /? $`: die("�������� name"))
			$x = "\\b$x" if $x =~ /^\w/;
			$x = "$x\\b" if $x =~ /\w$/;
		}
	} @_
}

# ��������� ����������� ���������� �� ������ ����������, ������ � ���������
sub lexx {
	my ($self) = @_;
	
	return $self->{LEXX} if defined $self->{LEXX};
	
	my $re_op = $self->_lex( values %{ +{ %{$self->{INFIX}}, %{$self->{PREFIX}}, %{$self->{POSTFIX}} } } );
	
	my $open_brakets = $self->_lex( values %{$self->{BR}} );
	my $close_brakets = $self->_lex( values %{$self->{CR}} );
	my $terms = $self->_lex( values %{$self->{X}} );	
	
	$self->{LEXX} = qr{
		(?<op> $re_op )				(?{ $self->op($+{op}) }) |
		(?<br> $open_brakets )		(?{ $self->push($+{br}) }) |
		(?<cr> $close_brakets )		(?{ $self->pop($+{cr}) }) |
		(?<x>  $terms )				(?{ $self->atom($+{x}) }) |
		\s+							|	# ���������� �������
		(?<sym> . )					(?{ $self->error(sprintf($self->{error}{sym}, $+{sym})) })
	}sxo
}

###############################  �������������� ������  ###############################

=pod ������� ����������



=cut



# ����������� ��������
sub popop {
	my ($self) = @_;
	
	my $front = $self->{front};
	my $op = $self->{OP};
	my $stmt = $push->{stmt};
	#my $OP = $self->top->{OP};		# 1-����� �������� ��� ������������ ���������
	
	# a++ b - gosub			����� a ���. 1
	# a b - gosub
	# a +b = a + b
	# a + -b
	
	
	
	# if(!$operator && $OP) {			# ��������� gosub
		# # ����������� ���������� ��� ��������������� ����� ������ � gosub
		# if(exists $OP->{tag} or exists $OP->{gosub}) {
			# push @$code, $prev = {stmt => 'gosub', var => 1, endline => 1, gosub => 1};
		# }
		# else {
			# $prev->{gosub} = 1;
			# $prev->{endline} = 1;
			# $prev->{stmt} .= "_go";
		# }
		# push @{$self->{stack}}, $prev;
		# $self->trace("^", $prev);


	#push @$T, $operator;
	#$self->trace("?", $operator);
	
	$self
}


# ������ ��������
sub op {
	my $self = shift;
	my $push = {%+, 'stmt', @_};
	
	$self->popop($push) if $self->{op};
	
	$self->{op} = $push;
	
	#my $stmt = $_[0];
	
	# ������� � ����� ���������� ��������� � ����������� ������ = 1
	# ����� �����, ����������� ������ � ������������ ��������� = 0
	# ^ ( +				=1
	# a ) a++ -a		=0
	
	# 0 + 1
	# 0 -a 1
	
	# my $front = $self->{front};
	
	# my $op = $front? $PREFIX{ $stmt }: $INFIX{ $stmt } // $POSTFIX{ $stmt };
	
	# $self->error("�� �������� ".($front? "����������": "��������� ��� �����������")." �������� $stmt") unless $op;
	
	# my $fix = $op->{fix};
	# $self->{front} = !($fix & $postfix);
	
	# my $S = $self->{stack};
	
	# # ����������� ��� ��������� � ������� �����������		
	# my $prio = $op->{prio};
	# my $x; my $s;
	# while(@$S && defined($x = ($s = $S->[-1])->{prio}) && (
			# $x < $prio || $x==$prio && $s->{fix} & $leftassoc
		# )) {
		# $self->popop;
	# }
	
	# $self->error("�������� $s->{stmt} ��������������") if $s && $s->{fix} & $nonassoc && $prio == $x;
	
	
	# my $name = $op->{stmt};
	# $push->{stmt} = $name if defined $name;
	# $push->{prio} = $prio;
	# $push->{fix} = $fix;
	# push @$S, $push;
	# $self->trace("?", $push);
	
	$self
}


# ��������� ����
sub atom {
	my $self = shift;
	my $push = {%+, 'stmt', @_};
	
	if(my $op = $self->{op}) {
		if($op->{FIX} & $postfix)
	}
	
	$self->{front} = 0;
	my $terms = $self->{terms};
	push @$terms, $push;
	$self->trace("�", $push);
	$self
}



# ��������� ����������� ������
sub push {
	my $self = shift; 
	my $push = {%+, 'stmt', @_, 'T+' => 1 + @{$self->{terms}} };
	
	$self->{front} = 1;
	
	push @{$self->{stack}}, $push;
	push @{$self->{space}}, $push;
	
	$self->trace("+", $push);
	
	$self
}

# ����������� ������
sub pop {
	my ($self, $stag) = @_;
	
	$self->{front} = 0;
	
	my $S = $self->{stack};
	my $T = $self->{terms};
	my $C = $self->{space};
	
	# ������
	$self->error("��� ����������� ������" . (defined($stag)? "� $stag": "")) if !@$S;
	
	# ����������� ��� ��������� �� ������
	while(@$S && defined $S->[-1]{prio}) {
		$self->popop;
	}
	
	$self->error("��� ����������� ������ ".(defined($stag)? "� $stag ": "")."- ���� S ����") if !@$S;
	$self->error("��� ����������� ������ ".(defined($stag)? "� $stag ": "")."- ���� � ����") if !@$C;
	
	my $sk = pop @$S;
	my $Sk = pop @$C;
	
	
	$self->error("������ $Sk->{stmt} �� ������ ���������. ��������� ������ ����� ������������� � ������������� ����� ��������") if $sk != $Sk;
	
	$self->error("��� �������� ������ $stag ��������� ".(@$T < $sk->{'T+'}? '������': '������')." ���������� ��� �����") if $sk->{'T+'} != @$T;
	
	my $tag;
	$self->error("����������� ������ $stag ����������� �� ������� $tag") if defined $stag and ($tag = $sk->{tag} // $sk->{stmt}) ne $stag;
	
	#$self->error("���� T ����: ���������� ������� ������� ��� ������") if !@$T;
	
	$sk->{right} = pop @$T;
	push @$T, $sk;
	
	$self->trace("-", $sk);

	$self
}

# ���������� ���������������� ������ ������ ��� trace � error
sub color_stacks {
	my ($self) = @_;
	local $_;
	return ":space",
		":dark white", "\tC:", ":reset", map({ $_->{stmt} } @{$self->{space}}),
		":dark white", "\tT:", ":reset", map({ $_->{stmt} } @{$self->{terms}}),
		":dark white", "\tS:", ":reset", map({ defined($_->{prio})? (":bold blue", $_->{stmt}, ":reset"): $_->{stmt} } @{$self->{stack}})
}

# ���������� �������� �� ������ � ���
sub trace {
	my ($self, $op, $top) = @_;
	
	my $trace = $self->{trace};
	if( defined($trace) && $self->{file} eq $trace ) {
	
		local($+, $`, $', $&, $_, $a, $b);
	
		my $stmt = $top->{stmt};
	
		my @after;
		if(0) {
			my $after = {%$top};
			delete @$after{qw/stmt e left right/};
			@after = pairmap { "$a=$b" } %$after;
		}
		
		if(1) {
			push @after, $self->color_stacks;
		}
		
		$app->log->info( ":space", "$self->{lineno}:", ($op eq "+" || $op eq "^"? ":red": $op eq "-"? ":bold blue": $op eq "?"? ":red": $op eq "?"? ":bold blue": ":dark white"), $op, $stmt, ":reset", @after );
	}
	
	$self
}

# ����������� ������
sub error {
	my ($self, $msg) = @_;
	local ($_, $`, $', $&);
	
	my $color_msg = $app->log->colorized( "$self->{file}:$self->{lineno}: $msg", $self->color_stacks );
	
	die "$self->{file}:$self->{lineno}: $color_msg";
}

# ��������� ������
sub masking {
	my ($self, $s) = @_;
	
	my $lex = $self->lexx;
	
	while($s =~ /$lex/g) {}			# ��������� ������
	
	$self
}

# ������������� ������� �����
sub templates {
	my $self = shift;
	
	my $c = $self->{lang}{templates} //= {};

	for(my $i=0; $i<@_; $i+=2) {
		my ($k, $v) = @_[$i, $i+1];
		
		$v =~ s/'/\\'/g;
		$v =~ s/\{\{\s*(\w+)\s*\}\}/', \$_->{$1} ,'/g;
		
		$c->{$k} = eval "sub { join '', '$v' }";
	}
	
	$self
}



# ������������ ��� ������� �� ������ ���� � ��������� ���
sub expirience {
	my ($self) = @_;
	
	my $S = $self->{stack};
	my $T = $self->{terms};
	
	$self->error("expirience: ���� S �� ����") if @$S != 0;
	$self->error("expirience: � ����� T ������ ���� 1-� �������") if @$T != 1;
	

	#msg1 ":size10000", $self->top;
	
	# ����� � ������� - ����������� ������
	if(defined(my $modifiers = $self->{lang}{modifiers})) {
		my @path = $T->[0];
		while(@path) {
			my $node = $path[-1];
			
			# �������� �����������, ���� �� �� �������� �������
			if(!exists $node->{"&"}) {
				my $fn = $modifiers->{$node->{stmt}};
				$fn->($self, $node, \@path) if $fn;
			}
			
			if(exists $node->{left} && $node->{"&"} < 1) {	# �� ����������
				$node->{"&"}=1;
				push @path, $node->{left};
			}
			elsif(exists $node->{right} && $node->{"&"} < 2) {	# �� ����������
				$node->{"&"}=2;
				push @path, $node->{right};
			}
			else {
				pop @path;		# ������� �������
			}
		}
	}
	
	# ������������ ���� �� ��������
	my $templates = $self->{lang}{templates};
	my $out;
	my @path = $T->[0];
	while(@path) {
		my $node = $path[-1];
		
		if(exists $node->{left} && $node->{"&"} < 3) {	# �� ����������
			$node->{"&"}=3;
			push @path, $node->{left};
		}
		elsif(exists $node->{right} && $node->{"&"} < 4) {	# �� ����������
			$node->{"&"}=4;
			push @path, $node->{right};
		}
		else {
			$_ = pop @path;		# ������� �������
			
			#$_->{code} = join "", @$code if $code;
			
			my $template = $templates->{ $_->{stmt} };
			die "��� ������� $_->{stmt} � ����� $self->{lang}" if !$template;
			
			if(@path) {
				my $parent = $path[-1];
				if($parent->{"&"} == 3) {
					$parent->{left} = $template->();
				} else {
					$parent->{right} = $template->();
				}
			}
			else {
				$out = $template->();
			}
		}
	}
	
	$out
}



# ��������� � ������ ����
sub morf {
	my ($self, $s) = @_;
	$self->masking($s)->expirience;
}

# ��������� ���������
sub eval {
	my ($self, $code) = @_;
	my $ret = eval $self->morf($code);
	die $@ if $@;
	$ret
}

1;