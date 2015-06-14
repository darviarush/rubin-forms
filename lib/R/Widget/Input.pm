package R::Widget::Input;
# виджет <input>

#use common::sense;
use strict;
use warnings;
use R::App;

Utils::has(qw/id/);

# конструктор
sub new {
	my ($cls, $id, $data, %args) = @_;
	bless {id=>$id, data=>$data, %args}, $cls;
}

# возвращает имя 
sub name { $_[0]->{name} //= do { $_[0]->{id} =~ /\w+$/; $& } }

# текст для label
sub description {
	my ($self) = @_;
	$self->{label} // $self->name;
}

# эскейпит атрибут
sub escapeAttr {
	my ($self, $key, $val) = @_;
	$key = Utils::escapeHTML($key);
	$key .= '="' . Utils::escapeHTML($val) . '"' if ($val // "") ne "";
	" " . $key
}

# вернёт атрибут, только если установлено его значение
sub dualAttr {
	my ($self, $key, $val) = @_;
	defined($val)? $self->escapeAttr($key, $val): "";
}

# возвращает атрибуты
sub attr {
	my ($self) = @_;
	my $attr = $self->{attr};
	my @attr = ref $attr eq "HASH"? %$attr: @$attr;
	return "" unless @attr;
	my @ret;
	for(my $i=0; $i<@attr; $i+=2) {
		push @ret, $self->escapeAttr(@attr[$i, $i+1]);
	}
	join "", @ret;
}

# функция label
sub label {
	my ($self) = @_;
	"<label for=$id>" . Utils::escapeHTML($self->description) . "</label>"
}

# функция input
sub input {
	my ($self) = @_;
	my $name = $self->name;
	my $value = $self->dualAttr("value", $self->{data}{$self->name});
	my $type = $self->dualAttr("type", $self->{type});
	my $placeholder = $self->dualAttr("placeholder", $self->{placeholder});
	my $attr = $self->attr;
	"<input$type id=$id name=$name$placeholder$attr>"
}



# функция error
sub error {
	my ($self) = @_;
	'<div class="error"></div>'
}



# функция render
sub render {
	my ($self) = @_;
	my $format = $self->{format} // "%label%input%error";
	$format =~ s!%(?:(label)|(input)|(error)|%)!
		$1? $self->label:
		$2? $self->input:
		$3? $self->error:
		$&;
	!ge;
	$format
}


1;
