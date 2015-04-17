package R::Model::Query;
# вспомогательный класс для sql-запроса

#Utils::has_const(qw//);
Utils::has_array(qw/from where/);

our %operators = qw(eq = ne <> lt < le <= gt > ge >= in in like like ilike ilike between between regexp regexp);

sub new {
	my ($cls, $key, $val, $like) = @_;
	
	my @keys = split /__/, $key;
	my $op = $operators{$keys[$#keys]};
	if($op) { pop @keys } else { $op = "=" }
	
	
	bless {
		keys => [@keys],
		val => $val,
		like => $like,
		from => [],
		where => [],
		op => $op
	}, $cls;
}


# возвращает 1-й ключ
sub front {
	$_[0]->{keys}[0]
}

# возвращает val, приобразованный к sql
sub val {
	my ($self, $val) = @_;
	local $_;
	
	my $c = $::app->connect;
	my $op = $self->{op};
	my $val = @_>1? $val: $self->{val};
	
	if(Utils::isa($val, "R::Model::Row")) {
		$val->store if !$val->{id};
		$c->quote($val->{id})
	#} elsif(Utils::isa($val, "R::Model::Rowset")) {
	
	# } elsif(Utils::isa($val, "R::Model::Field")) {
		# my $query = R::Model::Query->new(, {});
		# $val->form();
	} elsif(ref $val eq "ARRAY" && $op eq "in") {
		"(" . join(",", map { $self->val($_) } @$val) . ")";
	} elsif(ref $val eq "ARRAY" && $op eq "between") {
		$c->quote($val->[0]) . " AND " . $c->quote($val->[1]);
	} elsif(!defined $val and $self->{op} eq "=") {
		$self->{op} = "is not";
		$c->quote($val);
	} else { $c->quote($val) }
}

# формирует выражение
sub exp {
	my ($self) = @_;
	my $val = $self->val; 
	" $self->{op} $val"
}


1;