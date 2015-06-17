package R::Widget::Input;
# виджет <input>

#use common::sense;
use strict;
use warnings;
use R::App;

Utils::has(qw/name data form_id/);

# конструктор
sub new {
	my ($cls, $key, $data, $id, %args) = @_;
	bless {name=>$key, form_id=>$id, data=>$data, %args}, $cls;
}

# возвращает id
sub id {
	my $self = shift;
	$self->{id} //= $self->id . "-"	. $self->name;
}

# значение
sub value {
	my ($self) = @_;
	$self->{data}{$self->name};
}

# значение в html
sub valueHtml {
	my ($self) = @_;
	my $val = $self->{data}{$self->name};
	$val? Utils::escapeHTML($val): $val
}

# значение ошибки
sub errorValue {
	my ($self) = @_;
	$self->{data}{$self->name . "_error"};
}

# значение ошибки в html
sub errorValueHtml {
	my ($self) = @_;
	my $val = $self->{data}{$self->name . "_error"};
	$val? Utils::escapeHTML($val): $val
}

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
	'<label for="' . $self->id . '">' . Utils::escapeHTML($self->description) . '</label>'
}

# функция input
sub input {
	my ($self) = @_;
	my $name = $self->name;
	my $value = $self->dualAttr("value", $self->value);
	my $type = $self->dualAttr("type", $self->{type});
	my $placeholder = $self->dualAttr("placeholder", $self->{placeholder});
	my $attr = $self->attr;
	my $id = $self->id;
	"<input$type id=$id name=$name$placeholder$attr>"
}



# функция error
sub error {
	my ($self) = @_;
	my $val = $self->errorValue // "";
	'<div class="error"' . ($val ne ""? "": " style='display:none'") . '>' . Utils::escapeHTML($val) . '</div>'
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
