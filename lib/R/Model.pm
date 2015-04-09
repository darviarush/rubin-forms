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

# загружает все модели
sub load {

	find({
		no_chdir => 1,
		wanted => sub {
			my $path = $File::Find::name;
			if($path =~ /.pm$/) {
				require $path;
			}
		}
	}, main::files($self->{base}));
}

# инсталлирует базу
sub install {
	my ($self) = @_;
	
	my $models = $self->{models};
	
	for my $model (@$models) {
		$model->setup;
		$model->fields->postsetup;
	}
	
	for my $model (@$models) {
		$model->setup;
		$model->fields->postsetup;
	}
}

# возвращает запрос
sub query {
	my ($self, $model, @args) = @_;
	$self->models
}

# возвращает модель
sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;
	
	eval "sub $AUTOLOAD { my (\$self, \$val) = \@_; if(\@_ == 1) { \$self->{'$prop'} } else { \$self->{'$prop'} = \$val; \$self }}";
	die "$AUTOLOAD: ".($@ // $!) if $@ // $!;
	no strict "refs";
	my $sub = *{$AUTOLOAD}{CODE};
	use strict "refs";
	
	if(@_ == 1) {
		my ($self) = @_;
		my $base = $self->{base};
		my $app = $self->{app};
		my $new = $prop; $new =~ s![A-Z]!::$&!g; $new = $base."::".ucfirst $new;
		my $load = $prop; $load =~ s![A-Z]!/$&!g;
		$load = $base."/".ucfirst($load).".pm";
		require $load;
		$self->{$prop} = $new->new($app);
	}
		
	goto &$sub;
}

sub DESTROY {}


1;