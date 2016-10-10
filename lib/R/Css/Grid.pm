package R::Css::Grid;
# методы для создания сетки

use common::sense;
use R::App;
use R::Css;

has qw/prefix names/;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		prefix => [qw/s w m g/],
		names => {small=> "s", phone => "w", tablet => "m", descktop => "g"},
		the => {}, 		# name => the. Массив классов в адаптиве
	}, ref $cls || $cls;
}

# регистрирует классы grid в css
sub register {
	my ($self) = @_;
	
	my $names = $self->{names};
	while(my ($name, $suffix) = each %$names) {
	
		my $fix = $suffix eq 'w'? '': "-$suffix";
	
		$self->_register("$suffix*_*", $name, sub { $app->css->size($_) });
		$self->_register("offset$fix*_*", $name, sub { $app->css->move($_) });
		$self->_register("push$fix*_*", $name, sub { $app->css->locate($_) });
		$self->_register("pull$fix*_*", $name, sub { $app->css->locateoff($_) });
		
		$self->_register("lines$fix*", $name, sub { $app->css->size(undef, $_ eq "auto"? $_: ($app->cssConst->lineHeight * 1/$_) . "em") });
		
		$self->_register("$suffix*_*em", $name, sub { $app->css->size($_ . "em") });
		$self->_register("offset$fix*_*em", $name, sub { $app->css->move($_ . "em") });
		$self->_register("push$fix*_*em", $name, sub { $app->css->locate($_ . "em") });
		$self->_register("pull$fix*_*em", $name, sub { $app->css->locateoff($_ . "em") });
		
		$self->_register("$suffix*_*px", $name, sub { $app->css->size($_ . "px") });
		$self->_register("offset$fix*_*px", $name, sub { $app->css->move($_ . "px") });
		$self->_register("push$fix*_*px", $name, sub { $app->css->locate($_ . "px") });
		$self->_register("pull$fix*_*px", $name, sub { $app->css->locateoff($_ . "px") });

	}

	$self
}

# хелпер для регистрации одной маски
sub _register {
	my ($self, $mask, $name, $sub) = @_;
	
	$app->css->register($mask, closure $self, $name, $sub, \&_reg);	
	$app->css->register($mask, closure $self, $name, $sub, \&_reg) if $mask =~ s/_\*//;

}

# обработчик класса
sub _reg {
	my ($self, $name, $sub, $class, $i, $j) = @_;
	
	local $_;
	
	$app->css->gosub($name);
	
	if(my $the = $self->{the}{$name}) {
		$the->{the} .= ", .$class";
	}
	else {
		$app->css->the(".$class")->like(".float")->block;
		$self->{the}{$name} = $app->css->the;
	}
	
	$app->css->the(".$class");
	
	if(!defined $j) {
		$_ = $i==0? "auto": 1 / $i;
	} else {
		$_ = $i / $j;
	}
	
	$sub->();
	
	$app->css->end;
}


# адаптивные окна
sub adaptive {
	my ($self) = @_;

	# my $phone = em 768 / $fontSize;
	# my $tablet = em 992 / $fontSize;
	# my $descktop = em 1200 / $fontSize;

	my $phone = px 768;
	my $tablet = px 992;
	my $descktop = px 1200;
	my $unit = "px";

	$app->css->the(".float")->
		set(
			float => "left",
			clear => "none",
			position => "relative",
			($app->ini->{"design"}{"grid"}? (outline => "dotted 1px red"): ()),
		);


	# grid(12, "s");
	# linegrid(12, "s");

	# $app->css->prince("small")->
		# the(".s-hide")->hide->
		# the(".w-show")->hide->
		# the(".m-show")->hide->
		# the(".g-show")->hide->
	# end->

	$app->css->
	prince("small-only")->media("all and (max-width: " . ($phone - 1e-14 ) . "$unit)")->end->
	prince("phone-only")->media("all and (min-width: $phone) and (max-width: ". ($tablet-1e-14) ."$unit)")->end->
	prince("tablet-only")->media("all and (min-width: $tablet) and (max-width: ". ($descktop-1e-14) ."$unit)")->end->
	prince("descktop-only")->media("all and (min-width: $descktop)")->end->

	prince("small-to-phone")->media("all and (max-width: " . ($tablet - 1e-14 ) . "$unit)")->end->
	prince("small-to-tablet")->media("all and (max-width: " . ($descktop - 1e-14 ) . "$unit)")->end->
	prince("small-to-descktop")->end->
	prince("phone-to-tablet")->media("all and (min-width: $phone) and (max-width: " . ($descktop - 1e-14 ) . "$unit)")->end->
	prince("phone-to-descktop")->media("all and (min-width: $phone)")->end->
	prince("tablet-to-descktop")->media("all and (min-width: $tablet)")->end;
	
	
	$self->supergrid("small", 0);
	$self->supergrid("phone", $phone);
	$self->supergrid("tablet", $tablet);
	$self->supergrid("descktop", $descktop);

	$self
}

sub supergrid {
	my ($self, $name, $size) = @_;

	my $prefix = $self->{names}{$name};
	my $css = $app->css;
	
	my ($unit) = $size =~ /([a-z]+)$/;
	
	$css->prince($name);
	$css->media("all and (min-width: $size)") if $size;
	$css->
		the(".in1")->size($size * 0.95 . $unit)->
		the(".in2")->size($size * 0.9 . $unit)->
		the(".in3")->size($size * 0.85 . $unit)->
		the(".pass")->size(undef, $size * 0.1 . $unit)->
		
		the(".$prefix-hide")->hide;
		
		$css->the(".$_-show")->hide for grep { $_ ne $prefix } @{$self->{prefix}};
		
		#grid(12, $prefix);
		#linegrid(12, $prefix);
	$css->end;
	
	$self
}


# строит сетку
sub grid {
	my ($self, $rem, $suffix) = @_;
	my $fix = $suffix eq 'w'? '': "-$suffix";

	my @names;
	
	for my $j (1..$rem) {
		for my $i (1..$j) {
		
			#next if $i == $j;
		
			my $k = $i / $j;
			my $t = $i . "_" . $j;
			
			if($i == 1) {
			
				push @names, "." . $suffix . $j;
				push @names, ".offset" . $fix . $j;
				push @names, ".push" . $fix . $j;
				push @names, ".pull" . $fix . $j;
			
				$app->css->
				
				the(".$suffix$j, .${suffix}1_$j")->size($k)->
				
				the(".offset$fix$j, .offset${fix}1_$j")->move($k)->

				the(".push$fix$j, .push${fix}1_$j")->locate($k)->
				
				the(".pull$fix$j, .pull${fix}1_$j")->locateoff($k);

			} else {
			
				$app->css->
				
				the(".$suffix${i}_$j")->size($k)->
				
				the(".offset$fix${i}_$j")->move($k)->

				the(".push$fix${i}_$j")->locate($k)->
				
				the(".pull$fix${i}_$j")->locateoff($k);

			}

			push @names, "." . $suffix . $t;
			push @names, ".offset" . $fix . $t;
			push @names, ".push" . $fix . $t;
			push @names, ".pull" . $fix . $t;
		}
	}

	$app->css->the(join ", ", @names)->like(".float")->block;
	
	$self
}


# строит сетку высоты
sub linegrid {
	my ($self, $rem, $suffix) = @_;
	
	$suffix = $suffix eq "w"? "": "-$suffix";
	
	for(my $i=1; $i<=$rem; $i++) {
		$app->css->the(".lines$suffix$i")->size(undef, $app->cssConst->lineHeight * $i . "em");
	}
	
	$self
}





1;