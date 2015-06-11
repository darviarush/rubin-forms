package R::Validator;
# класс для валидации

#use common::sense;
use strict;
use warnings;
use R::App;

# конструктор
sub new {
	my (\$cls) = \@_;
	bless {}, \$cls;
}


# проверка
sub noval ($) {
	my @v = caller(0), die "validator#$v[3]: значение не предусмотрено" if defined $val;
}

# проверка
sub requireval ($) {
	my @v = caller(0), die "validator#$v[3]: предусмотрено значение" if not defined $val;
}

# проверка
sub norealize () {
	my @v = caller(0), die "validator#$v[3]: ещё не реализовано" if not defined $val;
}

# функция require
sub require {
	my ($self, $key, $val, $remark) = @_;
	noval $val;
	$val = $app->request->param($key);
	$app->response->addError($key, $remark // "введите значение") if not defined $val or $val eq "";
	$val
}


# функция max
sub max {
	my ($self, $key, $val, $remark) = @_;
	requireval $val;
	my $sense = $self->require($key);
	$app->response->addError($key, $remark // "значение больше $val") if $sense>$val;
	$sense
}



# функция min
sub min {
	my ($self, $key, $val, $remark) = @_;
	requireval $val;
	my $sense = $self->require($key);
	$app->response->addError($key, $remark // "значение меньше $val") if $sense<$val;
	$sense
}



# функция max_length
sub max_length {
	my ($self, $key, $val, $remark) = @_;
	requireval $val;
	my $sense =  $app->request->param($key) // "";
	$app->response->addError($key, $remark // "длина больше $val") if length($sense) > $val;
	$sense
}



# функция min_length
sub min_length {
	my ($self, $key, $val, $remark) = @_;
	requireval $val;
	my $sense = $app->request->param($key) // "";
	$app->response->addError($key, $remark // "длина меньше $val") if length($sense) < $val;
	$sense
}



# функция default
sub default {
	my ($self, $key, $val, $remark) = @_;
	requireval $val;
	my $sense = $app->request->param($key) // $val;
	$sense
}



# функция date
sub date {
	my ($self, $key, $val, $remark) = @_;
	norealize;
	
	noval $val;
	$self->pattern('');
}



# функция time
sub time {
	my ($self, $key, $val, $remark) = @_;
	norealize;
}



# функция datetime
sub datetime {
	my ($self, $key, $val, $remark) = @_;
	norealize;
}



# функция int
sub int {
	my ($self, $key, $val, $remark) = @_;
	noval $val;
	int $self->require($key);
}



# функция number
sub number {
	my ($self, $key, $val, $remark) = @_;
	noval $val;
	0 + $self->require($key);
}

# decimal=2 округляет до указанной цифры после запятой
sub decimal {
	my ($self, $key, $val, $remark) = @_;
	norealize;
}

# функция pattern
sub pattern {
	my ($self, $key, $val, $remark) = @_;
	requireval;
	my $sense = $app->request->param($key) // "";
	$app->response->addError($key, $remark // "не соответствует регулярному выражению /$val/") if $sense =~ $val;
	$sense
}


# функция email
sub email {
	my ($self, $key, $val, $remark) = @_;
	noval $val;
	$self->pattern($key, '@', $remark // "введите корректный e-mail адрес");
}


# функция tel
sub tel {
	my ($self, $key, $val, $remark) = @_;
	noval $val;
	$self->pattern($key, '^+7\d+$', $remark // "введите корректный номер телефона");
}



# функция emailtel
sub emailtel {
	my ($self, $key, $val, $remark) = @_;
	norealize;
	
	noval $val;
	
}


1;
