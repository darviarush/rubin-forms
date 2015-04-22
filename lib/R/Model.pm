package R::Model;
# менеджер моделей
# app->model->mymodel

use strict;
use warnings;
use vars '$AUTOLOAD';

use File::Find;

# конструктор
sub new {
	my ($cls, $app) = @_;
	bless {app=>$app, base=>'model'}, $cls;
}

# возвращает модель
sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	my $Prop = ucfirst $prop;
		
	my ($self) = @_;
	my $base = $self->{base};
	my $app = $self->{app};
	my $load = $Prop; #$load =~ s!__!/!g; #$load =~ s![A-Z]!/$&!g;
	
	my $meta = $app->modelMetafieldset;
	
	my @load = $base? main::files($base."/".$load.".pm"): ();
	die "not exists model $Prop" if not @load and not exists $meta->{fieldset}{$prop};
	
	if(!@load) {
		require R::Model::Row;
		{no strict "refs"; @{"R::Row::${Prop}::ISA"} = "R::Model::Row" };
	} else {
		my $fieldset;
		my $i = 0;
		for $load (@load) {
			if($i>0) {
				{no strict "refs";
				%{"R::Row::${Prop}::_${i}::"} = %{"R::Row::${Prop}::"};
				delete ${"R::Row::"}{"${Prop}::"};
				};
				require $load;
				{no strict "refs";
				push @{"R::Row::${Prop}::ISA"}, "R::Row::${Prop}::_${i}";
				};
			} else {
				require $load;
			}
			$fieldset = $meta->fieldset($prop);
			$self->$prop->can("setup")->($fieldset) if $i++ > 0;	# должен отработать обязательно конструктор филдсета - создать поля в классе модели
		}
	}

	my $eval = "sub $AUTOLOAD { \@_>1? R::Row::$Prop->new(\@_[1..\$#_]): R::Rowset::$Prop->new }";
	eval $eval;
	die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	my $sub;
	{no strict "refs"; $sub = *{$AUTOLOAD}{CODE}};

	goto &$sub;
}

sub DESTROY {}


1;