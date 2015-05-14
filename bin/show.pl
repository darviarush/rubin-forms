#== МОДЕЛЬ
#= модель
#> печатает столбцы модели

use List::Util qw/max/;

$app->modelMetafieldset->load_all_models;

$fieldset = $app->modelMetafieldset->fieldset($ARGV[1]);

$fields = $fieldset->{fieldset};

$max = 2;
$max += max map {length $_->name} @$fields;

sub is ($) { ref $_ eq "R::Model::Field::".ucfirst($_[0]) }

%color_name = qw(R::Model::Field::Col :reset R::Model::Field::Ref :cyan R::Model::Field::Back :green R::Model::Field::M2m :magenta R::Model::Field::Compute :red);
$color_tab = ":cyan";
$color_col = ":red";

@fld = grep { !is "back" } @$fields;
@back = grep { is("back") and $_->ref->fieldset->{pk} } @$fields;
@back_m2m = grep { is("back") and !$_->ref->fieldset->{pk} } @$fields;

show($_) for @fld;
msg "" if @back;
show($_) for @back;
$color_name{R::Model::Field::Back} = ":yellow";
msg "" if @back_m2m;
show($_) for @back_m2m;

sub show {
	my ($field) = @_;
	my $cls = ref $field;
	
	my ($col, $arr, $info) = "";
	
	if($field->info =~ / /) { ($arr, $info) = ($`, $'); ($info, $col) = ($`, $') if $info =~ /\./; } else { ($arr, $info) = ($field->info, "") }

	msg ":empty", $color_name{$cls}, $field->name, ":reset", (" " x  ($max - length $field->name)), ($arr? ($arr, " ", $color_tab, $info, ":reset", ($col? (".", $color_col, $col): ())): ());
}
