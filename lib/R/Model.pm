package R::Model;
# менеджер моделей
# app->model->mymodel

use common::sense;
use R::App;

use vars '$AUTOLOAD';

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}


# возвращает мету
sub Metafieldset {
	$app->meta
}

# возвращает модель
sub AUTOLOAD {
	$AUTOLOAD =~ /([^:]+)$/;
	my $prop = $1;

	my $meta = __PACKAGE__->Metafieldset;
		
	my $fieldset = $meta->fieldset($prop);
	my $cls_row = $fieldset->{cls_row};
	my $cls_rowset = $fieldset->{cls_rowset};

	my $eval = "sub $AUTOLOAD { \@_>1? $cls_row->new(\@_[1..\$#_]): wantarray? $cls_rowset->new->_rows: $cls_rowset->new }";
	eval $eval;
	die "model autoload $AUTOLOAD: $@" if $@;
	my $sub = *{$AUTOLOAD}{CODE};
	
	goto &$sub;
}

sub DESTROY {}


1;