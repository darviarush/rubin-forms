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
	
	my $eval = "sub $AUTOLOAD { \@_>1? R::Row::$Prop->new(\@_[1..\$#_]): R::Rowset::$Prop->new }";
	eval $eval;
	die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	my $sub;
	{no strict "refs"; $sub = *{$AUTOLOAD}{CODE}};
	
	if(!@load) {
		require R::Model::Row;
		{no strict "refs"; @{"R::Row::${Prop}::ISA"} = "R::Model::Row" };
	} else {
	
		my $i = 0;
		for $load (@load) {
			if($i>0) {
				{no strict "refs";
					*{"R::Row::$Prop\__$i\::"} = *{"R::Row::$Prop\::"};
					undef ${"R::Row::"}{"$Prop\::"};
					push @{"R::Row::$Prop\::ISA"}, "R::Row::$Prop\__$i";
				};
				require $load;
			
				# должен отработать обязательно конструктор филдсета - создать поля в классе модели
				my $fieldset = $meta->fieldset($prop);
				my $setup;
				{no strict "refs";
				$setup = *{"R::Row::$Prop\::setup"}{CODE};
				};
				$setup->($fieldset);
			} else {
				require $load;
				$meta->fieldset($prop);
			}
			$i++;
		}
	}

	goto &$sub;
}

sub DESTROY {}


1;