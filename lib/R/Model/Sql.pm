package R::Model::Sql;
# ��������� ������� sql

use strict;
use warnings;

Utils::has(qw/bean/);

our $FIND_SEPARATOR = "__";

# �����������
sub new {
	my ($cls, $bean) = @_;
	bless {bean => $bean}, $cls;
}

sub fieldset {
	my ($self) = @_;
	$::app->modelMetafieldset->{cls}{ref $self->{bean}};
}

# ���������� ������ select
sub sql {
	my ($self, $ref) = @_;
	my @any = $self->select($ref);
	$any[0] = "*" if $any[0] eq "";
	my $sql = join " ", "SELECT", grep {$_ ne ""} @any;
	my $union = " UNION ALL ";
	$sql = join "", $sql, map { $_ eq "0"? do { $union = " union "; () }: do { my $s = $union.$_->sql($ref); $union = " union all "; $s } } @{$self->{union}};
	return $sql;
}

# ��������� ������ ��� ������
sub select {
	my ($self, $ref) = @_;
	
	my $table = $self->fieldset->{tab};
	push @{$ref->{"<>"}}, ["", $table];
	#push @{$ref->{"<->"}}, $self;
	my $set = join ", ", map {escape($_->[0])." = ".quote($_->[1], $ref)} build_alias($self->{set});
	my $values = $self->values($ref);
	my $from = "from $table";
	my $where = $self->where($ref);
	my $group = join ", ", map { quote($_, $ref) } @{$self->{group}}; $group = "group by $group" if $group;
	my $having = $self->where($ref, 1);
	my $order = join ", ", map { quote($_, $ref) } @{$self->{order}}; $order = "order by $order" if $order;
	my $offset = $self->{offset}? "offset $self->{offset}": "";
	my $limit = $self->{limit}? "limit $self->{limit}": "";
	my $join = pop @{$ref->{"<>"}};
	#pop @{$ref->{"<->"}};
	return ($values, $set, $from, $join->[0], $where, $group, $having, $order, $offset, $limit);
}

# ������ join-�
sub from_join {
	my ($join, $ref) = @_;
	
	my $r = $ref->{"<>"}; # <> - from
	$r = $r->[$#$r];
	my $main_tab = $r->[1];
	
	return "$main_tab.$join->[0]" if @$join <= 1;	# ������ ���� ���������, ����� ������������ join-�
	
	# �������������� �������, ���� �� ����
	$ref->{"#"} = "A" unless defined $ref->{"#"};
	
	# ������� � $ref ��������� ����� ����
	my ($cash, $i);
	for($i = $#$join; $i>0; $i--) {
		$i++, last if $cash = $ref->{join "::", $main_tab, @{$join}[0..$i]};
	}

	# ��������� ��� � ��������� ���������, ���� ������ �� �������
	$cash = [$main_tab, $main_tab] unless $cash;
	
	# ������ join-�� ��� ����������� �����
	my $U = $cash->[1];
	for(; $i < $#$join; $i++) {
		my $key = $join->[$i];
		my $model;
		my $j;
		$U = $ref->{"#"}++;								# # - ������� U
		if($key =~ /_ref$/) {	# �������� ������
			local ($`, $', $1);
			$key =~ /(?:__(\w+))?_ref$/;
			my ($tab, $fld) = ($`, $1 // ($i==0? $main_tab: $join->[$i-1]));
			get_ref($tab, $fld);	# ��������, ��� ����� ���� ����
			$model = $tab;
			$key = $fld;
			$j = "inner join ".escape($model)." $U on $cash->[1].id=$U.${key}_id\n";
		} else {				# ������ ������
			$model = get_ref($cash->[0], $key);
			$j = "inner join ".escape($model)." $U on $cash->[1].${key}_id=$U.id\n";
		}
		$r->[0] .= $j;
		$ref->{join "::", $main_tab, @{$join}[0..$i]} = $cash = [$model, $U];
	}
	
	return "$U.$join->[$#$join]";	# ���������� ������� �� ������� ������ ������� (��� select, where, having)
}

# ��������, � ������ ������ join-��
sub escape_dom {
	my ($val, $ref) = @_;
	$val = [split $FIND_SEPARATOR, $val];
	from_join($val, $ref);
}

# ��������� where
%OP = qw(eq = ne <> lt < le <= gt > ge >= in in like like ilike ilike between between);
sub where {
	my ($self, $ref, $having) = @_;
	local $_;
	my $sql = "";
	my @filter;
	my $op;
	my ($filter, $i) = ($self->{$having? "having": "filter"}, 0);

	for(;;) {		# ��� ������ [] -> ()

		for(; $i<@$filter; $i+=2) {
			my $a = $filter->[$i];
			my $b = $filter->[$i+1];
			if($a eq "OR") {
				$sql .= " OR ";
				$i--;
				next;
			}

			if(ref $a eq "ARRAY") {	# ������
				push @filter, [$filter, $i];
				$filter = $a;
				$i = 0;
				$sql .= "(";
				next;
			}

			if(ref $a eq "R::Model::Sql::functor") {
				$a = functor2sql($a, $ref);
				$op = "=";
			}
			else {
				my @join = split /::/, $a;	# join-�
				$op = $OP{$join[$#join]};	# ���������
				if($op) { pop(@join); } else { $op = '=' }

				# ��������� join-��
				$a = from_join(\@join, $ref);
			}
			
			# ��������� ������� ��� in
			if(ref $b eq "ARRAY") {
				$b = join ", ", map { quote($_, $ref) } @$b;
			} else {
				$b = quote($b, $ref);
			}

			$op = $op eq "="? "is": "is not" if not defined $b;

			$sql .= "$a $op $b";
			last unless $i+2<@$filter;
			$sql .= " AND ";
		}

		($filter, $i) = @{pop @filter};
		last unless defined $filter;
		$sql .= ")";
	}
	return $sql? ($having? "having": "where")." $sql": "";
}


# ��������� values
sub values {
	my ($self, $ref) = @_;
	local $_;
	my $dom = $self->{dom};
	my $as = $self->{as};
	return "" unless @$dom | @$as;
	my $x = join ", ", map({ escape_dom($_, $ref) } @$dom), map {quote($_->[0], $ref)." as ".escape($_->[1])} build_alias($as);
	return $x;
}

# ��������� as � set
sub build_alias {
	my ($as) = @_;
	my ($i, $val);
	map { if($i++ % 2 == 0) { $val = $_; () } else { [$val, $_] } } @$as;
}

# ���������� ����� ��������
sub names {
	my ($self, $ref) = @_;
	local $_;
	my $i = 0;
	join ", ", (map { my @A = split "::", $_; escape($A[$#A]) } @{$self->{dom}},
		map { $i++ % 2==0? escape_dom($_, $ref): () } @{$self->{as}});
}

# ����������� � '' ��������, ��� �������� select
sub quote {
	my ($val, $ref) = @_;
	ref $val eq "SCALAR"? escape_dom($$val, $ref):
	ref $val eq "ARRAY"? "(".join(", ", map { quote($_, $ref) } @$val).")":
	ref $val && $val->isa("model::orm")? (%$val == 2 && @{$val->{dom}}==1? escape_dom($val->{dom}->[0], $ref): "(".$val->sql.")"):
	ref $val && $val->isa("model::functor")? functor2sql($val, $ref):
	$val=~/^-?\d+(?:\.\d+)?\z/? $val:
	$dbh->quote($val);
}

# ����������� � "" �������� ������� ��� �������, ���� �����
%ESCAPE = utils::set(qw/select update insert set from where and or not user/);
sub escape {
	my ($val) = @_;
	return $val if $val =~ /^[a-z_]\w*\z/i and not exists $ESCAPE{lc $val};
	local ($`, $', $&);
	$val =~ s/[\\"]/\\$&/g;
	return "\"$val\"";
}


1;