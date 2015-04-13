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
	
	#no strict "refs";
	#my $sub = *{$AUTOLOAD}{CODE} = Utils::closure(sub { my ($self, $val) = @_; ${"R::Rows::${Prop}::"}->new($val) })
	#use strict "refs";
	
	my $eval = "sub $AUTOLOAD { my (\$self, \$val) = \@_; R::Rows::$Prop->new(\$val) }";
	eval $eval;
	die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	no strict "refs";
	my $sub = *{$AUTOLOAD}{CODE};
	use strict "refs";
		
	my ($self) = @_;
	my $base = $self->{base};
	my $app = $self->{app};
	my $load = $Prop; #$load =~ s!__!/!g; #$load =~ s![A-Z]!/$&!g;
	
	my @load = main::files($base."/".$load.".pm");
	die "not exists model $Prop" unless @load;	
	
	my $meta = $app->modelMetafieldset;
	my $fieldset;
	my $i = 0;
	for $load (@load) {
		require $load;
		$fieldset = $meta->fieldset($prop);	# должен отработать обязательно конструктор филдсета - создать поля в классе модели
		$self->$prop->can("setup")->($fieldset) if $i++ > 0;
	}

	$fieldset->sync if $app->ini->{site}{test} && $app->ini->{site}{autosync};

	goto &$sub;
}

sub DESTROY {}


1;