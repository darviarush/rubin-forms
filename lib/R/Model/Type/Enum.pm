package R::Model::Type::Enum;
# перечисление - отражает число в строку

use common::sense;
use R::App;

# тип столбца
sub typeCol {
	my $field = shift;
	
	$field->input("select");
	
	die "enum: установлен и доп-параметр и аргументы" if $field->{dop_param} && @_;
	
	my $enum = $field->{dop_param} // [@_];
	
	my $i=0;
	$field->{dop_param} = $enum = {map { $i++ => $_ } @$enum} if ref $enum eq "ARRAY";
	
	$field->{enum_param} = { map { my $v=$enum->{$_}; (ref($v)? int($v): $v) => $_ } keys %$enum };
	
	use List::Util qw/max/;

	$field->fieldset->meta->getUIntType(max keys %$enum)
}

# чекеры вызываются так же и в rowset->find
# чекер
sub onCheck {
	my ($check, $enum) = @_;
	
	my $field = $check->stash("field");
	
	#msg1 $field->{name}, $enum;
	
	if(ref $enum) {
		my $key = int $enum;
		$check->error("enum toCol: нет значения `$enum`") if !exists $field->{enum_param}{$key};
		$check->val( $field->{enum_param}{$key} );
	}
	elsif(Num $enum) {
		$check->error("enum toCol: нет значения `$enum`") if !exists $field->{dop_param}{$enum};
	}
	elsif($enum eq "") { $check->val(undef) }	# null
	else {
		die "enum toCol: нет значения `$enum`" if !exists $field->{enum_param}{$enum};
		$check->val( $field->{enum_param}{$enum} );
	}

}

# из базы
sub fromCol {
	my ($field, $key) = @_;
	
	return undef if !defined $key;	# null
	
	die "enum fromCol: нет значения `$key`" if !exists $field->{dop_param}{$key};
	
	$field->{dop_param}{$key}
}

# # в базу
# sub toCol {
	# my ($field, $enum) = @_;
	
	# if(ref $enum) {
		# my $key = int $enum;
		# die "enum toCol: нет значения `$enum`" if !exists $field->{enum_param}{$key};
		# $field->{enum_param}{$key}
	# }
	# elsif(Num $enum) {
		# die "enum toCol: нет значения `$enum`" if !exists $field->{dop_param}{$enum};
		# $enum
	# }
	# elsif($enum eq "") { undef; }	# null
	# else {
		# die "enum toCol: нет значения `$enum`" if !exists $field->{enum_param}{$enum};
		# $field->{enum_param}{$enum}
	# }
# }

1;