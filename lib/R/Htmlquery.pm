package R::Htmlquery;
# коллекция html-элементов

use common::sense;
use R::App qw/$app msg msg1 Num/;

use HTML::TreeBuilder;
use HTML::TreeBuilder::Select;
use HTML::Selector::XPath qw(selector_to_xpath);


# конструктор, создаёт новую коллекцию
# new(..., [{options}])
sub new {
	my $self = shift;
	
	my $cls = ref $self || $self;
	
	return bless [], $cls if @_ == 0;
	
	local $_;
	
	my $options;
	$options = pop if @_ && ref $_[$#_] eq "HASH";
	
	bless [map {
		ref $_? (
			ref $_ eq $cls? @$_:
			ref $_ eq "SCALAR"? do {
				@$self? $self->[0]->root->findnodes($$_): ();
			}:
			$_->isa("HTML::Element")? $_:
			die "попытка вставить в коллекцию `$_`"
		):
		!defined($_)? ():
		/^</? do {
			my $root = HTML::TreeBuilder->new(ignore_unknown=>0, implicit_tags=>0, no_space_compacting=>1, %$options);
			$root->parse($_);
			$root->eof;
			{
				local $_;
				map { ref $_? $_: _createTextNode($_) } @{$root->{_content}}
			}
		}:
		/^~/? _createTextNode(substr $_, 1):
		do {	# селектор
			my $selector = selector_to_xpath($_);
			@$self? $self->[0]->root->findnodes($selector): ();
		}
	} @_], $cls;
}

# создаёт текстовую ноду
sub _createTextNode {
	my ($text, $parent, $i) = @_;
	local $_;
	my $x = HTML::Element->new('~literal', 'text' => $text);
	HTML::Element::_weaken($x->{_parent}=$parent), $parent->{_content}[$i] = $x if $parent;
	$x
}

# возвращает коллекцию подэлементов
sub children {
	my ($self, $selector) = @_;
	if(@_>1 && Num $selector) {
		local $_;
		bless [map {
			my $content = $_->{_content};
			my $x=$content->[$selector];
			ref $x? $x: defined($x)? _createTextNode($x, $_, $selector): ();
		} @$self], ref $self
	}
	elsif(defined $selector) {
		$self->contents->filter($selector)
	} else {
		goto &contents;
	}
}

# устанавливает или возвращает контент нод
sub contents {
	my $self = shift;
	local $_;
	if(@_) {
		my $c = $self->new(@_);

		die "обнаружено зацикливание" if $c->contains($self);
		
		for my $x (@$self) {
			$x->splice_content(0, scalar(@{$x->{_content}}), @$c);
		}
		$self
	} else {
		my $new = bless [], ref $self;
		for my $x (@$self) {
			my $content = $x->{_content};
			my $i = 0;
			for my $e (@$content) {
				push @$new, ref $e? $e: _createTextNode($e, $x, $i);
				$i++;
			}
		}
		$new
	}
}

# возвращает по номеру элемент коллекции, обернув его в коллекцию
sub eq {
	my ($self, $i) = @_;
	bless [ $self->[$i] or () ], ref $self
}

# проверяет, что 1-й элемент коллекции - текст
sub is_text {
	my ($self, $i) = @_;
	return unless my $x = $self->[$i];
	$x->{_tag} eq "~literal"
}

# проверяет, что 1-й или указанный элемент коллекции текст, причём пустой или из пробельных символов
sub is_space {
	my ($self, $i) = @_;
	return unless my $x = $self->[$i];
	$x->{_tag} eq "~literal" && $x->{text} =~ /^\s*$/
}

# проверяет, что 1-й или указанный элемент коллекции - элемент html
sub is_element {
	my ($self, $i) = @_;
	return unless my $x = $self->[$i];
	scalar( $x->{_tag} !~ /^~/ )
}


# возвращает html элементов коллекции
sub as_html {
	my ($self) = @_;
	local $_;
	join "", map { $_->as_HTML } @$self
}

# объединяет коллекции
sub add {
	my ($self) = @_;
	local $_;
	bless [ map { @{$self->new($_)} } @_ ], ref $self;
}

# объединяет коллекции, причём добавляемые - впереди
sub addBack {
	my $self = shift;
	local $_;
	bless [ map { @{$self->new($_)} } @_, $self ], ref $self;
}

# переворачивает коллекцию
sub reverse {
	my ($self) = @_;
	bless [reverse @$self], ref $self
}

# перебирает элементы
sub each {
	my ($self, $sub) = @_;
	local $_;
	my $element = bless [0], ref $self;
	for my $x (@$self) {
		$_ = $element;
		$element->[0] = $x;
		$sub->();
	}
	$self
}

# создаёт новую коллекцию
sub map {
	my ($self, $sub) = @_;
	local $_;
	my $new = bless [], ref $self;
	my $element = bless [0], ref $self;
	for my $x (@$self) {
		$_ = $element;
		$element->[0] = $x;
		push @$new, @{ $self->new($sub->()) };
	}
	$new
}

# фильтрует элементы коллекции через функцию
sub grep {
	my ($self, $sub) = @_;
	local $_;
	my $new = bless [], ref $self;
	my $element = bless [0], ref $self;
	for my $x (@$self) {
		$_ = $element;
		$element->[0] = $x;
		push @$new, $x if $sub->();
	}
	$new
}

# перебирает элементы
sub eeach {
	my ($self, $sub) = @_;
	local $_;
	for my $x (@$self) {
		$_ = $x;
		$sub->();
	}
	$self
}

# создаёт новую коллекцию
sub emap {
	my ($self, $sub) = @_;
	local $_;
	my $new = bless [], ref $self;
	for my $x (@$self) {
		$_ = $x;
		push @$new, @{ $self->new($sub->()) };
	}
	$new
}

# фильтрует элементы коллекции через функцию
sub egrep {
	my ($self, $sub) = @_;
	local $_;
	my $new = bless [], ref $self;
	for my $x (@$self) {
		$_ = $x;
		push @$new, $x if $sub->();
	}
	$new
}

# ищет подэлементы в коллекции
sub find {
	my ($self, $query) = @_;
	local $_;
	if(ref $query ne "SCALAR") { $query = selector_to_xpath($query, root => './') }
	else { $query = $$query }
	bless [ map { $_->findnodes($query) } @$self ], ref $self
}


# фильтрует элементы коллекции по селектору, но ежели селектор не указан, то возвращает себя
sub filter {
	my ($self, $query) = @_;
	return $self unless defined $query;
	local $_;
	if(ref $query ne "SCALAR") { $query = selector_to_xpath($query) }
	else { $query = $$query }
	bless [ grep { $_->matches($query) } @$self ], ref $self;
}

# возвращает все элементы коллекции не соответсвующие селектору
sub not {
	my ($self, $query) = @_;
	return $self unless defined $query;
	local $_;
	if(ref $query ne "SCALAR") { $query = selector_to_xpath($query) }
	else { $query = $$query }
	bless [ grep { !$_->matches($query) } @$self ], ref $self;
}

# проверяет, что указанный или первый элемент коллекции соответствуют маске
sub is {
	my ($self, $query, $i) = @_;
	return unless my $x = $self->[$i];
	if(ref $query ne "SCALAR") { $query = selector_to_xpath($query) }
	else { $query = $$query }
	$x->matches($query);
}

# если существует путь в указанном или первом элементе коллекции
sub has {
	my ($self, $selector, $i) = @_;
	return unless my $x = $self->[$i];
	if(ref $selector ne "SCALAR") { $selector = selector_to_xpath($selector) }
	else { $selector = $$selector }
	$x->exists($selector)
}

# возвращает истину, если хоть один элемент $collect входит в первый элемент $self
sub contains {
	my ($self, $collect, $i) = @_;
	return unless my $x = $self->[$i];
	
	for my $y (@$collect) {
		my $z = $y;
		while( $z=$z->{_parent} ) {
			return 1 if $x == $z;
		}
	}
}

# устанвливает всем элементам коллекции указынный атибут, или возвращает значение атрибута первого элемента
sub attr {
	local $_;
	if(@_ == 3) {
		my ($self, $k, $v) = @_;
		$_->attr($k, $v) for @$self;
		$self
	} else {
		my ($self, $k) = @_;
		@$self? $self->[0]->attr($k): undef
	}
}

# возвращает/устанавливает атрибут name
sub name {
	my $self = shift;
	$self->attr("name", @_)
}

# возвращает/устанавливает атрибут id
sub id {
	my $self = shift;
	$self->attr("id", @_)
}

# устанавливает всем элементам коллекции тэг или возвращает тэг 1-го элемента
sub tag {
	local $_;
	if(@_ == 2) {
		my ($self, $k) = @_;
		$_->tag($k) for @$self;
		$self
	} else {
		my ($self) = @_;
		@$self? $self->[0]->tag: undef
	}
}

# размер коллекции
sub size {
	my ($self) = @_;
	scalar @$self
}

# возвращает html всех элементов или устанавливает html всем элементам
sub html {
	my ($self, $html, $options) = @_;
	local $_;
	if(@_ != 1) {
		my $root = HTML::TreeBuilder->new(ignore_unknown=>0, implicit_tags=>0, no_space_compacting=>1, %$options);
		$root->parse($html);
		$root->eof;
		my $content = $root->{_content};
		
		for my $x (@$self) {
			$x->splice_content(0, scalar(@{$x->{_content}}), HTML::Element->clone_list(@$content));
		}
		
		$self
	}
	else {
		my @out;
		for my $x (@$self) {
			push @out, map { ref $_? $_->as_HTML: $_ } @{$x->{_content}}
		}
		join "", @out
	}
}

# устанавливает или возвращает текст
sub text {
	my $self = shift;
	local $_;
	if(@_) {
		for my $x (@$self) {
			$x->splice_content(0, scalar(@{$x->{_content}}), map { "$_" } @_);
		}
		$self
	}
	else {
		my @out;
		for my $x (@$self) {
			my @p = $x;
			#my %check = ();
			while (@p) {
				my $node = shift @p;
				if(ref $node) {
					#msg1 _address($node), exists $check{int $node};
					#die "обнаружена петля для ноды " . $node->{_tag} if exists $check{int $node};
					#$check{int $node} = 1;
					
					if($node->{_tag} =~ /^(?:script|style)$/) {}
					elsif($node->{_tag} eq "~literal") { push @out, $node->{text} }
					else { unshift @p, @{$node->{_content}}; }
				} else {
					push @out, $node;
				}
			}
			
		}
		join "", @out;
	}
}

# 
sub _lineage {
    my $here = shift;
    my @lineage;
	
	my %check;
	
    while ( defined( $here = $here->{'_parent'} ) and ref($here) ) {
	
		return @lineage, "($here->{_tag})" if exists $check{int $here};
	
		$check{int $here} = 1;
        push @lineage, $here;
    }
    return @lineage;
}

# возвращает адрес 1-го или указанного элемента коллекции в его дереве
sub address {
	my ($self, $i) = @_;
	return unless my $node = $self->[$i];
	local $_;
	return join(
		'.',
		reverse(    # so it starts at the top
			map( { ref $_? $_->{_tag} . ($_->pindex() // 0): $_ }    # so that root's undef -> '0'
				$node,                   # self and...
				_lineage($node) )
		)
	);
}

# тестирует элементы коллекции на петли в дереве
sub samnam {
	my ($self) = @_;
	
	my @out;
	for my $x (@$self) {
		my %check = ();
		my @p = $x;
		while (@p) {
			my $node = shift @p;
			
			if(ref $node) {
				push(@out, address([$node])), next if exists $check{ int $node };
				$check{ int $node } = 1;
				unshift @p, @{$node->{_content}};
			}
		}
		
	}
	join ", ", @out;
}

# клонирует все элементы коллекции
sub clone {
	my ($self) = @_;
	local $_;
	my $new = bless [], ref $self;
	for my $e (@$self) {
		push @$new, $e->clone;
	}
	$new
}

# добавляет подэлементы в начало элементов коллекции
sub prepend {
	my $self = shift;
	local $_;
	my $x = $self->new(@_);
	die "обнаружено зацикливание" if $x->contains($self);
	for my $e (@$self) {
		$e->unshift_content(@$x);
	}
	$self
}

# добавляет подэлементы в конец элементов коллекции
sub append {
	my $self = shift;
	local $_;
	my $x = $self->new(@_);
	die "обнаружено зацикливание" if $x->contains($self);
	for my $e (@$self) {
		$e->push_content(@$x);
	}
	$self
}

# вставляет указанный контент перед каждым элементом в коллекции
sub before {
	my $self = shift;
	local $_;
	my $x = $self->new(@_);
	die "обнаружено зацикливание" if $x->contains($self);
	for my $e (@$self) {
		$e->preinsert(@$x);
	}
	$self
}

# вставляет указанный контент перед каждым элементом в коллекции
sub after {
	my $self = shift;
	local $_;
	my $x = $self->new(@_);
	die "обнаружено зацикливание" if $x->contains($self);
	for my $e (@$self) {
		$e->postinsert(@$x);
	}
	$self
}

# добавляет подэлементы в начало элементов
sub prependTo {
	my $self = shift;
	my $x = $self->new(@_);
	die "обнаружено зацикливание" if $self->contains($x);
	for my $e (@$x) {
		$e->unshift_content(@$self);
	}
	$self
}

# добавляет подэлементы в конец элементов
sub appendTo {
	my $self = shift;
	my $x = $self->new(@_);
	die "обнаружено зацикливание" if $self->contains($x);
	for my $e (@$x) {
		$e->push_content(@$self);
	}
	$self
}

# вставляет коллекцию перед каждым указанным контентом
sub insertBefore {
	my $self = shift;
	my $x = $self->new(@_);
	die "обнаружено зацикливание" if $self->contains($x);
	for my $e (@$x) {
		$e->preinsert(@$self);
	}
	$self
}

# вставляет коллекцию после каждого указанным контентом
sub insertAfter {
	my $self = shift;
	my $x = $self->new(@_);
	die "обнаружено зацикливание" if $self->contains($x);
	for my $e (@$x) {
		$e->postinsert(@$self);
	}
	$self
}

# заменяет каждый элемент коллекции на контент
*replaceWith = \&replace;
*replace_with = \&replace;
sub replace {
	my $self = shift;
	#local $_;
	my $replace = $self->new(@_);
	die "обнаружено зацикливание" if $replace->contains($self);
	for my $x (@$self) {
		$x->replace_with( @$replace );
	}
	$self
}

# удаляет элементы из дерева
sub remove {
	my ($self) = @_;
	for my $x (@$self) { $x->detach }
	$self
}

# возвращает коллекцию парент-элементов или устанавливает парент
sub parent {
	my $self = shift;
	if(@_) {
		my $parent = $self->new($_[0]);
		return $self if !$parent->is_element;	# парент не может быть текстом
		$parent = $parent->[0];
		for my $x (@$self) {
			$x->detach;
			HTML::Element::_weaken($x->{_parent} = $parent);
		}
		return $self;
	}
	local $_;
	bless [map { my $p=$_->parent; defined($p)? $p: () } @$self], ref $self
}

# все соседи
sub siblings {
	my ($self, $query) = @_;
	$self->map(sub { $_->prevAll->add($_->nextAll) })->filter($query)
}

# # позиция элемента в паренте
# sub _pos {
	# my ($e) = @_;
	# my $parent = $e->{_parent} // return;
	# my $i=0;
	# for my $x (@{$parent->{_content}}) {
		# return $i if ref($x) && $x == $e;
		# $i++;
	# }
# }

# возвращает элемент, если текст - то превращает в ~literal
sub _child {
	my ($e, $add) = @_;
	my $i = $e->pindex // return;
	my $parent = $e->{_parent};
	my $content = $parent->{_content};
	$i+=$add;
	return if  $i<0 || $i>=@$content;
	my $x = $content->[$i];
	ref $x? $x: _createTextNode($x, $parent, $i);
}

# предыдущий элемент
sub prev {
	my ($self, $query) = @_;
	$self->emap(sub { _child($_, -1) })->filter($query)
}

# следующий элемент
sub next {
	my ($self, $query) = @_;
	$self->emap(sub { _child($_, +1) })->filter($query)
}

# предыдущий элемент
sub prevAll {
	my ($self, $query) = @_;
	my $out = bless [], ref $self;
	for my $x (@$self) {
		my $parent = $x->{_parent};
		my $content = $parent->{_content};
		for(my $i=0; $i<@$content; $i++) {
			my $e = $content->[$i];
			last if ref($e) && $e == $x;
			push @$out, ref $e? $e: _createTextNode($e, $parent, $i);
		}
	}
	$out->filter($query)
}

# следующий элемент
sub nextAll {
	my ($self, $query) = @_;
	my $out = bless [], ref $self;
	for my $x (@$self) {
		my $parent = $x->{_parent};
		my $content = $parent->{_content};
		for(my $i=$x->pindex+1; $i<@$content; $i++) {
			my $e = $content->[$i];
			push @$out, ref $e? $e: _createTextNode($e, $parent, $i);
		}
	}
	$out->filter($query)
}

# предыдущий элемент
sub prevUntil {
	my ($self, $to, $query) = @_;
	
	if(ref $to ne "SCALAR") { $to = selector_to_xpath($to) }
	else { $to = $$to }
	
	my $out = bless [], ref $self;
	for my $x (@$self) {
		my $parent = $x->{_parent};
		my $content = $parent->{_content};
		my @out;
		for(my $i=$x->pindex-1; $i>=0; $i--) {
			my $e = $content->[$i];
			last if ref $e and $e->matches($to);
			unshift @out, ref $e? $e: _createTextNode($e, $parent, $i);
		}
		push @$out, @out;
	}
	
	$out->filter($query)
}

# следующий элемент
sub nextUntil {
	my ($self, $to, $query) = @_;
	
	if(ref $to ne "SCALAR") { $to = selector_to_xpath($to) }
	else { $to = $$to }
	
	my $out = bless [], ref $self;
	for my $x (@$self) {
		my $parent = $x->{_parent};
		my $content = $parent->{_content};
		for(my $i=$x->pindex+1; $i<@$content; $i++) {
			my $e = $content->[$i];
			last if ref $e and $e->matches($to);
			push @$out, ref $e? $e: _createTextNode($e, $parent, $i);
		}
	}
	
	$out->filter($query)
}


# # коллекция парент-элементов до рута включительно
# sub parents {
	# my ($self) = @_;
	# $self->map(sub { $_->parent })
# }

# # возвращает рутовые элементы
# sub root {
	# my ($self) = @_;
	# $self
# }

# # удаляет элементы
# sub DESTROY {
	# my ($self) = @_;
	# $_->delete for @$self;
# }

# # 
# sub prev {
	# my ($self) = @_;
	# $self
# }

# # элементы в элементе
# sub children {
	# my ($self, $selector) = @_;
	# defined($selector)? $self->contents->filter($selector): $self->contents;
# }

# # все элементы перед, отвечающие селектору
# sub prevAll {
	# my ($self, $selector) = @_;
	# my $out = $self->new;
	# my $prev = $self->prev;
	# while($prev->size) {
		# $out = (defined($selector)? $prev->filter($selector): $prev)->add($out);
		# $prev = $prev->prev;
	# }
	# $out
# }

# # все элементы после, отвечающие селектору
# sub nextAll {
	# my ($self, $selector) = @_;
	# my $out = $self->new;
	# my $next = $self->next;
	# while($next->size) {
		# msg1 $out->as_html;
		# $out = $out->add(defined($selector)? $next->filter($selector): $next);
		# $next = $next->next;
	# }
	# $out
# }

# # все элементы после до селектора $to, отвечающие селектору $selector
# sub nextUntil {
	# my ($self, $to, $selector) = @_;
	# my $out = $self->new;
	# my $next = $self->eq(0)->next;
	# while($next->size && $next->filter($to)->size == 0) {
		# $out = $out->add(defined($selector)? $next->filter($selector): $next);
		# $next = $next->next;
	# }
	
	# $out
# }

# # все элементы перед до селектора $to, отвечающие селектору $selector
# sub prevUntil {
	# my ($self, $to, $selector) = @_;
	# my $out = $self->new;
	# my $prev = $self->eq(0)->prev;
	# while($prev->size && $prev->{trees}[0] && $prev->filter($to)->size == 0) {
		# $out = $out->add(defined($selector)? $prev->filter($selector): $prev);
		# $prev = $prev->prev;
	# }
	
	# $out
# }


1;