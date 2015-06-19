package Helper;

use warnings;
use strict;

use Data::Dumper;
use Utils;
use R::App;

our %_NO_ESCAPE_HTML = Utils::set(qw(raw html json dump style hidden show));

# переводит в json
sub json { $app->json->encode($_[0]) }

# выводит без эскейпа
sub raw { $_[0] }

# эскейпит
sub html { defined($_[0])? Utils::escapeHTML($_[0]): "" }

# выводит nbsp, если пусто
sub nbsp { $_[0] eq ""? "&nbsp;": $_[0] }

# bool(условие [, да [, нет]]) - если условие верно, а 
sub bool { $_[0]? ($_[1] // '+'): ($_[2] // '') }

# дампер
sub dump { "<pre>".Utils::escapeHTML(Dumper($_[0]))."</pre>" }

# $array:join(", ", ...) для массива
sub join { defined($_[0])? Utils::escapeHTML(join(($_[1] // ", "), @{$_[0]}, @_[2..$#_])): "" }

# возвращает элемент хеша или массива
sub at { ref $_[0] eq "ARRAY"? $_[0]->[ $_[1] ]: $_[0]->{ $_[1] } }

# cоздаёт хеш
# ключ:dict(значение, ключ=значение...)
sub dict {{@_}}
sub hash {{@_}}

# создаёт массив
sub array {[@_]}

# нечётный
sub odd { $_[0] % 2? ($_[1] // "odd"): $_[2] }

# чётный
sub even { $_[0] % 2 == 0? ($_[1] // "even"): $_[2] }

# или или
sub oddeven { $_[0] % 2? ($_[1] // "odd"): ($_[2] // "even") }

# логические операции
my $_FLOAT = qr/^-?\d+(?:\.\d+)?(?:E[+-]\d+)?$/i;
my $_is_float = sub { my ($x) = @_; defined($x) && !ref($x) && $x =~ $_FLOAT };

sub or { $_[0] or $_[1] }
sub and { $_[0] and $_[1] }
sub not { not $_[0] }
sub lt { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] < $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] lt $_[1] } }
sub gt { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] > $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] gt $_[1] } }
sub le { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] <= $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] le $_[1] } }
sub ge { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] >= $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] ge $_[1] } }
sub eq { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] == $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] eq $_[1] } }
sub ne { if($_is_float->($_[0]) && $_is_float->($_[1])) { $_[0] != $_[1] } elsif(defined($_[0]) && defined($_[1])) { $_[0] ne $_[1] } }


# атрибуты, классы, стили
sub visible { $_[0]? "": "display: none;" }
sub show { $_[0]? "": "display: none;" }
sub hide { $_[0]? "display: none;": "" }
sub style { $_[0]? "style=\"$_[0]\"": "" }
sub hidden { $_[0]? "style='display:none'": "" }
sub shower { $_[0]? "": "style='display:none'" }
sub img { return "/img/" unless $_[0]; "/images/" . Utils::img_path($_[0]) }

# запуск функции
sub run { my $f = shift; $f->(@_) }

# виджет ошибок формы
sub errors {
	my ($key, $data, $form_id, %args) = @_;
	my $errors = $data->{errors};
	'<ol class="error"', ($errors && @$errors? '': ' style="display:none"'), '>',
	map({ ('<li>', Utils::escapeHTML($_)) } $errors? @$errors: ()),
	'</ol>'
}

# виджет начала формы без ошибок
sub ajax_form {
	my ($key, $data, $form_id, %args) = @_;
	return '<input type="hidden" name="@action" value="', Utils::escapeHTML($key), '">',
	'<input type="hidden" name="@form" value="', $form_id, '">'
}

# виджет начала формы
sub begin_form {
	return ajax_form(@_), errors(@_);
}


# виджет
sub _wx {
	my ($method, $key, $data, $form_id, %args) = @_;
	
	my $name = $args{type};
	if(!defined $name) {
		my $model = $app->response->{bean}{$form_id};
		if($model) {
			 my $fld = $model->Field->{$key};
			 my $widget;
			 if($fld && ($widget = $fld->{widget})) {
				$name = $widget->{name};
				%args = (%args, %{$widget->{args}});
			 }
		}
	}
	
	$name //= "input";
	
	$name = "widget" . ucfirst $name;
	$new->$name($key, $data, $form_id, %args)->$method;
}
sub wx { unshift @_, "render"; goto &_wx }
sub label { unshift @_, "label"; goto &_wx}
sub input { unshift @_, "input"; goto &_wx }
sub error { unshift @_, "error"; goto &_wx }


1;