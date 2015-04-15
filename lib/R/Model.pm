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
	bless {app=>$app, base=>'model', models=>[]}, $cls;
}

# возвращает модель
sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	my $Prop = ucfirst $prop;
	
	my $eval = "sub $AUTOLOAD { \@_>1? R::Rows::$Prop->new(\@_[1..\$#_]): R::Rowset::$Prop->new }";
	eval $eval;
	die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	no strict "refs";
	my $sub = *{$AUTOLOAD}{CODE};
	use strict "refs";
		
	my ($self) = @_;
	my $base = $self->{base};
	my $app = $self->{app};
	my $load = $Prop; #$load =~ s!__!/!g; #$load =~ s![A-Z]!/$&!g;
	
	my $meta = $app->modelMetafieldset;
	
	my @load = main::files($base."/".$load.".pm");
	die "not exists model $Prop" if not @load and not exists $meta->{fieldset}{$prop};
	
	if(!@load) {
		require R::Model::Row;
		no strict "refs";
		@{"R::Rows::${Prop}::ISA"} = "R::Model::Row";
		use strict "refs";
	} else {
		my $fieldset;
		my $i = 0;
		for $load (@load) {
			if($i>0) {
				no strict "refs";
				%{"R::Rows::${Prop}::_${i}::"} = %{"R::Rows::${Prop}::"};
				delete ${"R::Rows::"}{"${Prop}::"};
				use strict "refs";
				require $load;
				no strict "refs";
				push @{"R::Rows::${Prop}::ISA"}, "R::Rows::${Prop}::_${i}";
				use strict "refs";
			} else {
				require $load;
			}
			$fieldset = $meta->fieldset($prop);
			$self->$prop->can("setup")->($fieldset) if $i++ > 0;	# должен отработать обязательно конструктор филдсета - создать поля в классе модели
		}
	}

	#$fieldset->sync if $app->ini->{site}{test} && $app->ini->{site}{autosync};

	goto &$sub;
}

sub DESTROY {}


1;