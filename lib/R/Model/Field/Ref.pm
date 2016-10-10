package R::Model::Field::Ref;
# поле таблицы базы данных - ссылка

use base R::Model::Field::Col;

use common::sense;
use R::App;


require R::Model::Index;
require R::Model::Indexref;
require R::Model::Field::Back;

has qw/refset/;
has_const(qw/ref back fk/);


# конструктор
sub new {
	my ($cls, $fieldset, $name, $to_model) = @_;
		
	$to_model ||= $name;
	#die "Нет модели $to_model" unless $self->fieldset->meta->exists($to_model);

	$fieldset->{annonce_img} = $name if $to_model eq "img" and not defined $fieldset->{annonce_img};
	
	my $self = $cls->SUPER::new($fieldset, $name, '');
	
	my $to_fieldset = $fieldset->meta->fieldset($to_model);
	my $fk = $to_fieldset->{pk};
	
	# например:
	#	book.author_id -> author.id
	# тогда:
	#	book.author_id =>
	#		ref => author.id
	#		back => author.books { ref => book.author_id }
	
	%$self = (
		%$self,
		col=>$self->{col} . '_id',
		type=>$fk->{type},
		null=>1,
		ref=>$fk,
		back=>undef,
	);
	
	$self
}

# выдаёт краткую информацию о себе
sub info {
	my ($self) = @_;
	"-> " . $self->ref->model . ($self->ref->name ne "id"? "." . $self->ref->name: "");
}

# устанавливает комментарий
sub remark {
	my ($self, $remark, $remark_bk) = @_;
	$self->{remark} = $remark;
	$self->back->{remark} = $remark_bk // "bk: $remark";
	$self
}

# возвращает или устанавливает инпут
sub input {
	my $self = shift;
	if(@_==1) { $self->SUPER::input(@_) }
	else { $self->{input} //= $self->ref->fieldset->{input} }
}

# создаёт foreign key на указанный филд
sub fk_to {
	my ($self, $fk, $fk_name) = @_;
	
	$fk_name ||= "fk_" . $self->tab . "__" . $self->col . "__to__" . $fk->tab . "__" . $fk->col;
	
	$self->{fk} = $self->fieldset->{indexref}{$fk_name} = R::Model::Indexref->new($fk_name, $self, $fk);
	
	$self
}

# возвращает столбец в таблице, на к-ю ссылается
sub refTo {
	my ($self) = @_;
	$self->{ref}
}

# # для rowset->as
# sub cloneto {
	# my ($self, $fieldset) = @_;
	# $self = $self->SUPER::cloneto($fieldset);
	# my $back = $self->{back};
	# $self->{back} = bless {%$back, ref=>$self}, ref $back;
	# $self
# }

# свойство row
sub row {
	my ($self, $bean, $val) = @_;
		
	if(@_>2) {
		$val = {@_[2..$#_]} if @_>3;
		
		if(!ref $val) {
			$self->SUPER::row($bean, $val);
		} else {
			#my $id;
			#$val->{id} = $id if !$val->{id} && $bean->id && defined($id = $self->SUPER::row($bean));
			my $id;
			if(ref $val eq "HASH") {
				$id = $self->{ref}->bean($val)->id;
			}
			elsif(Isa $val, $self->{ref}{fieldset}{cls_row}) {
				$id = $val->id;
			}
			else {
				die "set_ref($val) не HASH и не " . $self->{ref}{fieldset}{cls_row};
			}
			$bean->{save}{$self->{name}} = $id;
			$bean
		}
	}
	else {
		my $id = $self->SUPER::row($bean);
		#my $new = $self->{ref}->bean($id);
		my $new = $self->{ref}{fieldset}{cls_row}->new($id);
		$new->{rel} = $bean;
		$new->{ref} = $self->{name};
		$new
	}
}

# свойство
#	book -> author (books => books)
sub rowset {
	my ($self, $bean) = @_;
	$self->{ref}->bean->find($self->{back}{name} => $bean)
}


1;