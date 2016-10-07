package R::Http::Request;
# запрос и ответ одновременно

use common::sense;
use R::App;


use URI;
#use IO::String;
use HTTP::Date;

has qw/data method version ns now/;

# конструктор
sub new {
	my ($cls, $ns, $paddr) = @_;
	bless {
		ns => $ns,			# сокет, полученный от accept
		paddr => $paddr,	# адрес клиента
		status => 200,
		inhead => {},	# входящие заголовки
		head => {"Content-Type" => "text/html; charset=utf-8"}, # исходящие заголовоки
		echo => [],		# исходящее тело ответа
		cookie => [],	# выходные куки
		now => time,	# время создания запроса
		running => 1,	# запрос выполняется - используется в keep-alive и web-сокетах
	}, ref $cls || $cls;
}


# устанавливает пример запроса
sub simple {
	my $self = shift;
	
	$self = $self->new;
	
	$self->{method} = "GET";
	$self->uri("/");
	$self->{version} = "1.1";
	$self->{ns} = undef;
	$self->{paddr} = undef;
	$self->{ip} = "127.0.0.1";
	$self->{post} = {};
	$self->{inhead} = {
		"User-Agent"=> "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:38.9) Gecko/20100101 Goanna/2.0 Firefox/38.9 PaleMoon/26.0.0",
		"Content-Length"=>1,
		"Content-Type"=> "application/x-www-form-urlencoded",
		"Accept"=> "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
		"Accept-Language"=> "en-US,en;q=0.5",
		"Host"=> "http_unicorn",
		"Referer"=> "http://unicorn/ex?x=",
		"Connection"=> "keep-alive",
		"Accept-Encoding"=> "gzip, deflate",
	};
	
	%$self = (%$self, @_);
	
	$self->uri($self->{uri}) if !ref $self->{uri};
	
	$self
}

# устанавливает некоторые параметры (для тестов)
sub action {
	my ($self, $url, $post, $head) = @_;
	
	if(exists $self->{form}) {
		my $form = $self->{form};
		if(!$form->{Concat} && $form->isErrors) {
			msg ":red", "ошибки на не выведенной форме:", ":cian", $form->{Name}, ":bold black", $form->{errors}, $form->{error};
		}
	}
	
	%$self = %{$self->simple};
	
	$self->{method} = $post? "POST": "GET";
	$self->uri($url);
	$self->{post} = $post;
	$self->{inhead} = $head if $head;
	
	$self->form if $self->param('@action');
	
	$self
}


# обрабытывает запрос формы
sub form {
	my ($self, $class) = @_;
	
	if(!defined $class) {
		$class = $self->param('@action');
		$class =~ s!/(\w)!ucfirst $1!ge;
	}
	
	#msg1 $class;

	$self->{form} = my $form = $class->new;
	$self->{NumberForms}{$class} = 0;
	
	# устанавливаем номер формы и уменьшаем счётчик этой формы на странице (в списках может быть много одинаковых форм)
	#my $number = $form->{Number} = $self->param('@number');
	#$form->{Name} = $number? $class . $number: $class;
	

	$form->{save} = 1;	# брать параметры из q.can(lc metaform.method)	
	$form->save;		# возвращает answer
	
	$self
}

# метод пришедшего запроса - get
sub isGet {
	my ($self) = @_;
	$self->{method} eq "GET"
}

# метод пришедшего запроса - post
sub isPost {
	my ($self) = @_;
	$self->{method} eq "POST"
}

# uri запроса
sub uri {
	my $self = shift;
	if(@_) {
		my $uri = shift;
		$self->{uri} = ref $uri? $uri: URI->new($uri);
		$self
	}
	else {
		$self->{uri}
	}
}

# возвращает ip посетителя
require Socket;
sub ip {
	my ($self) = @_;
	$self->{ip} //= $self->head("X-IP") // do {
		my($port, $iaddr) = Socket::sockaddr_in($self->{paddr});
        #my $name = gethostbyaddr($iaddr, AF_INET);
        # logmsg "connection from $name [",
                # inet_ntoa($iaddr), "]
                                # at port $port";
		Socket::inet_ntoa($iaddr)
	}
}

# устанавливает статус
sub status {
	my $self = shift;
	if(@_) {
		$self->{status} = shift;
		$self
	}
	else {
		$self->{status}
	}
}

# устанавливает тип
sub type {
	my $self = shift;
	if(@_) {
		local ($_, $`, $');
		$_ = shift;
		$_ .= "; charset=utf-8" if /^text\//i && !/\bcharset=/i;
		$self->head("Content-Type", $_);
		$self
	}
	else {
		my $type = $self->{head}{"Content-Type"} // "text/html";
		$type =~ s/;.*//;
		$type
	}
}

# возвращает и устанавливает куки
sub cookie {

	if(@_>2) {	# устанавливаем куку
		my ($self, $name, $value, %param) = @_;
		
		my %param_allow = $app->perl->set(qw/expires path domain secure httponly/);
		my @noallow = grep { !exists $param_allow{$_} } keys %param;
		die "неизвестный ключ в cookie: " . join ", ", @noallow if @noallow;
		
		$self->{outcookie}{$name} = $value;
		
		my $val = join "", $name, "=", $value,
			(exists $param{expires}? ("; Expires=" , HTTP::Date::time2str($param{expires})): ()),
			(exists $param{path}? "; Path=$param{path}": ()),
			(exists $param{domain}? "; Domain=$param{domain}": ()),
			(exists $param{secure}? "; Secure": ()),
			(exists $param{httponly}? "; HttpOnly": ());
		#$self->head("Set-Cookie", $val);
		push @{$self->{cookie}}, $val;
		$self

	} else {
		my ($self, $name) = @_;
		my $cookie = $self->{incookie};
		unless(defined $cookie) {
			$self->{incookie} = $cookie = _param($self->{inhead}{Cookie}, qr/;\s*/);
		}
		@_>1? $cookie->{$name}: $cookie
	}
}

# устанавливает редирект
sub redirect {
	my ($self, $location) = @_;
	$location = $self->referer("/") if @_ == 1;
	if(defined $location) {
		$self->status(303);
		$self->head("Location" => $location);
	}
	else {
		$self->status(200);
		$self->head("Location" => undef);
	}
}

# будет ли редирект
sub isRedirect {
	my ($self) = @_;
	$self->status == 303
}

# ошибка "не найдена страница"
sub not_found {
	my ($self) = @_;
	$self->status(404);
	die $app->raise->bingo("error/404" => "тут ничего нет");
}

# показать страницу с ошибками формы
sub form_error {
	my ($self, $form) = @_;
	$self->redirect(undef) if $self->isRedirect;
	$self->echo_clear;
	$self->render("error/from_form.html", {
		return_location => $self->referer("/"),
		form => $form // $self,
	});
}

# require для js
sub js {
	my ($self, $js) = @_;
	
	if(@_ == 1) {	# устанавливаем смещение
		die "позиция для вывода библиотек js уже установлена" if defined $self->{js_pos};
		$self->echo( $self->{js_pos} = $app->viewDeferred->new(\&js_stringify) );
		""
	}
	else {
		my $inc = $self->{js_inc};
		push @{$self->{js_order}}, $inc->{$js} = $js if !exists $inc->{$js};
		$self
	}
}

# require для css
sub css {
	my ($self, $css) = @_;
	
	if(@_ == 1) {	# устанавливаем смещение
		die "позиция для вывода библиотек css уже установлена" if defined $self->{css_pos};
		$self->echo( $self->{css_pos} = $app->viewDeferred->new(\&css_stringify) );
		""
	}
	else {
		my $inc = $self->{css_inc};
		push @{$self->{css_order}}, $inc->{$css} = $css if !exists $inc->{$css};
		$self
	}
}

# выводит в позицию js скрипт на js
sub script {
	my $self = shift;
	push @{$self->{js_script}}, @_;
	$self
}

# выводит в позицию css стили
sub style {
	my $self = shift;
	push @{$self->{css_style}}, @_;
	$self
}

# выводит css
sub css_stringify {
	my ($self) = @_;
	my $ret = join "",
		map({ "<link rel=\"stylesheet\" href=\"$_\">\n" } @{$self->{css_order}}),
		map { /^\s*<style\b/? $_: "<style><!--\n$_\n--></style>\n" } @{$self->{css_style}},
		@{$app->css->{serf}}? ("<style><!--\n", $app->css->stringify, "\n--></style>\n"): ();
	
	# тут заменяется css для следующего запроса
	$app->css( $app->cssOrig->clone );
		
	delete @$self{qw/css_pos css_order css_style/};
	$ret
}

# выводит js
sub js_stringify {
	my ($self) = @_;
	my $ret = $app->ini->{design}{withoutjs}? "": join("",
		map({ "<script src=\"$_\" type=\"text/javascript\"></script>\n" } @{$self->{js_order}}),
		map { /^\s*<script\b/? $_: "<script><!--\n$_\n--></script>\n" } @{$self->{js_script}}
	);
		
	delete @$self{qw/js_pos js_order js_script/};
	
	$ret
}

# выводит всё с переводом строк и красиво раскрашенным
sub print {
	my ($self) = @_;
	todo;
	$self
}

# вперёд вывода
sub prepend {
	my $self = shift;
	unshift @{$self->{echo}}, @_;
	$self
}

# добавляет к выводу
sub echo {
	my $self = shift;
	push @{$self->{echo}}, @_;
	$self
}

# очищает буфер вывода
sub echo_clear {
	my ($self) = @_;
	
	delete @$self{qw/css_pos css_inc css_order js_pos js_inc js_order js_script css_style/};
	
	@{$self->{echo}} = ();
	$self
}

# возвращает ссылку на буфер вывода и очищает его
sub echo_pull {
	my ($self) = @_;
	
	$self->{css_pos}->stringify if defined $self->{css_pos};
	$self->{js_pos}->stringify if defined $self->{js_pos};
	
	$self->{echo}
}

# рендерит шаблон в echo
sub render {
	my ($q, $path, $data) = @_;
	$app->view->render($path, $data, $q->{echo});
	$q
}

# реферер
sub referer {
	my ($self, $default) = @_;
	my $referer = $self->{inhead}{Referer} || $default;
	my $host = quotemeta $app->ini->{site}{host};
	$referer = $default unless $referer =~ s/^https?:\/\/$host(\/|$)/\//i;
	$referer
}

# устанавливает входной заголовок
sub inhead {
	if(@_ == 1) {
		my $self = shift;
		$self->{inhead}
	}
	elsif(@_>2) {
		my ($self, $name, $val) = @_;
		$self->{inhead}{$name} = $val;
		$self
	}
	else {
		my ($self, $name) = @_;
		$self->{inhead}{$name}
	}
}

# устанавливает выходной заголовок
sub outhead {
	my ($self, $name, $val) = @_;
	if(@_>2) {
		$self->{head}{$name} = $val;
		$self
	}
	else {
		$self->{head}{$name}
	}
}

# очищает выходные заголовки
sub head_clear {
	my ($self) = @_;
	%{$self->{head}} = ();
	$self
}

# очищает привязанные объекты
sub object_clear {
	my ($self) = @_;

	undef $self->{form};
	undef $self->{user};
	undef $self->{session};
	$self
}

# очищает ошибки
sub error_clear {
	my ($self) = @_;
	
	undef $self->{error};
	undef $self->{errors};
	undef $self->{isError};
	undef $self->{info};

	$self
}

sub clear {
	my ($self) = @_;
	
	$self->error_clear->object_clear->echo_clear->head_clear->status(200)->type("text/html");
}

# устанавливает выходной заголовок, или возвращает входной
sub head {
	die "head имя, [значение]. А тут: " . scalar(@_) . " параметров" if @_ < 2 || @_ > 3;

	if(@_>2) {
		my ($self, $name, $val) = @_;
		$self->{head}{$name} = $val;
		$self
	}
	else {
		my ($self, $name) = @_;
		$self->{inhead}{$name}
	}
}

# ids, get, post и param
# $val = param(name) - возвращает первое значение или undef
# @val = param(name) - возвращает массив значений
# @names = param() - возвращает список имён параметров
# вспомогательная функция
sub _ret {
	my $hash = shift;
	
	if(@_==1) {
		my $key = shift;
		my $val = $hash->{$key};
		if(wantarray) {
			return exists $hash->{$key}? (map {my $v=$_; utf8::decode($v) if defined $v and not ref $v; $v} ref $val eq "ARRAY"? @$val: $val): ();
		}
		$val = ref $val eq "ARRAY"? $val->[0]: $val;
		utf8::decode($val) if defined $val and not ref $val;
		return $val;
	}
	else {
		keys %$hash
	}
}


# возвращает параметры URL: /path5_6_-7, тогда ids = { id: 5, id2: 6, id3: -7 }
sub ids {
	my $self = shift;
	my $ids = $self->{ids};
	unless(defined $ids) {
		my $path = $self->path;
		my $ids = $self->{ids} = {};
		my $i = 0;
		for my $id (split /[_-]/, $self->{uri_ids}) {
			$ids->{$i==0? "id": "id" . ($i+1)} = $id;
			$i++;
		}
	}
	
	_ret($ids, @_);
}

# параметры после ?
sub get {
	my $self = shift;
	my $get = $self->{get};
	unless(defined $get) {
		$self->{get} = $get = _param($self->{uri}->query);
	}
	_ret($get, @_);
}

# POST-параметры
sub post {
	my $self = shift;
	my $post = $self->{post};
	unless(defined $post) {
		my $head = $self->{inhead};
		my ($type, $len, $rbfile) = ($head->{'Content-Type'}, $head->{'Content-Length'}, $head->{'REQUEST_BODY_FILE'});
		if(defined $rbfile) {
			my $f;
			open $f, $rbfile or die "NOT OPEN REQUEST_BODY_FILE=$rbfile $!";
			$self->{post} = $post = _param_from_post($f, $type, $len);
			close $f;
		} elsif($len) {
			my @res = _param_from_post($self->{ns}, $type, $len);
			$self->{post} = $post = $res[0];
			$self->{file} = $res[1];
			#msg1 "xxx", [ keys %{$self->{file}{"photos"}} ];
		} else {
			$self->{post} = $post = {};
		}
	}
	_ret($post, @_);
}

# возвращает структуру файла принятую по POST upload
sub file {
	my $self = shift;
	my $file = $self->{file};
	if(not defined $file and not defined $self->{post}) {
		scalar $self->post(@_);
		$file = $self->{file};
	}
	
	_ret($file, @_);
}

# параметры POST, GET и из URL
sub param {
	if(@_>2) {	# устанавливаем
		die "устанавливать параметры нельзя";
	}
	else {
		my $self = shift;
		my $param = $self->{param};
		unless(defined $param) {
			if(@_) {
				my ($name) = @_;
				if(wantarray) {
					my @val = $self->ids($name);
					@val = $self->get($name) if !@val;
					#msg("\@val", \@val),
					return @val if @val;
				} else {
					my $val = $self->ids($name) // $self->get($name);
					#msg("val", $name, $val, "ids:", scalar $self->ids($name), "get:", scalar $self->get($name)),
					return $val if defined $val;
				}
			}
			
			$self->post("") unless exists $self->{post};
			$self->get("") unless exists $self->{get};
			$self->ids("") unless exists $self->{ids};
			
			$self->{param} = $param = {%{$self->{post}}, %{$self->{get}}, %{$self->{ids}}};
		}
	
		_ret($param, @_);
	}
}

# параметры GET и из URL
sub uriparam {
	if(@_>2) {	# устанавливаем
		die "устанавливать параметры нельзя";
	}
	else {
		my $self = shift;
		my $uriparam = $self->{uriparam};
		unless(defined $uriparam) {
			if(@_) {
				my ($name) = @_;
				if(wantarray) {
					my @val = $self->ids($name);
					@val = $self->get($name) if !@val;
					return @val if @val;
				} else {
					my $val = $self->ids($name) // $self->get($name);
					return $val if defined $val;
				}
			}
			
			$self->get("") unless exists $self->{get};
			$self->ids("") unless exists $self->{ids};
			
			$self->{uriparam} = $uriparam = {%{$self->{get}}, %{$self->{ids}}};
		}
	
		_ret($uriparam, @_);
	}
}


# сессия - дёргаем её 1-й раз
sub session {
	my ($self) = @_;
	$self->{"session"} //= $app->model->session($self->cookie("sess"))->touch
}

# пользователь из сессии
sub user {
	my ($self) = @_;
	$self->{"user"} //= $self->session->user
}

# добавляет ошибку, если нет сессии и возвращает undef, а если есть, то user_id
sub auth {
	my ($self) = @_;
	
	my $id = $self->user->id;
	
	$self->addErrors("Авторизируйтесь") if !$id;
	
	$id
}

# # устанавливает-возвращает экшн
# sub action {
	# my $self = shift;
	# if(@_) {
		# my $action = $self->{"action"} = shift;
		# $self->{data}{forms}{$action} = { map { $_ => scalar( $self->param($_) ) } $self->param } if !shift;
		# $self
	# }
	# else {
		# $self->{"action"}
	# }
# }

# # проверяет - есть ли ошибки
# sub isErrors {
	# my ($self) = @_;
	# my $act = $self->{data}{forms}{$self->action};
	# $act->{"error_"} && keys(%{$act->{"error_"}}) || $act->{"errors_"} && @{$act->{"errors_"}}
# }

# # добавляет ошибки в форму
# sub addErrors {
	# my ($self, $error) = @_;
	# push @{$self->{data}{forms}{$self->action}{errors_}}, $error;
	# $self
# }

# # добавляет информацию в форму
# sub addInfo {
	# my ($self, $info) = @_;
	# push @{$self->{data}{forms}{$self->action}{info_}}, $info;
	# $self
# }

# # добавляет ошибку к полю
# sub addError {
	# my ($self, $name, $error) = @_;
	# $self->{data}{forms}{$self->action}{"error_"}{$name} = $error;
	# $self
# }


# проверяет - есть ли ошибки страницы
sub isErrors {
	my ($self) = @_;
	$self->{isError}
}

# добавляет ошибку к полю
sub addError {
	my ($self, $name, $error) = @_;
	$self->{error}{$name} = $error;
	$self->{isError}{$error} = 1;
	$self
}

# добавляет ошибки на страницу
sub addErrors {
	my ($self, $error) = @_;
	push @{$self->{errors}}, $error;
	$self->{isError}{$error} = 1;
	$self
}

# добавляет информацию на страницу
sub addInfo {
	my ($self, $info) = @_;
	push @{$self->{info}}, $info;
	$self
}



# возвращает путь url без конечных id
sub path {
	my ($self) = @_;
	$self->{uri_path} //= do {
		my $path = $self->uri->path;
		$self->{uri_ids} = $path =~ s/\d+(?:[-_]\d+)*$//? $&: "";
		$path
	}
}

# возвращает путь url
sub real_path {
	my ($self) = @_;
	$self->uri->path
}

# возвращает url, заменяя в нём GET-переменные на указанные
# удаляет параметры с фейловым значением
sub url {
	my ($self, %param) = @_;
	my $uri = $self->uri->clone;
	my %ext = $uri->query_form;
	delete $ext{$_} for keys %param;
	%param = map { $_ => $param{$_} } grep { $param{$_} } keys %param;
	my @x = (%ext, %param);
	$uri->query_form(@x? @x: undef);
	$uri->as_string;
}

# возвращает параметр id
sub id {
	my ($self) = @_;
	my $id = $self->param("id");
	defined($id)? 0+$id: 0
}

# возвращает параметр id2
sub id2 {
	my ($self) = @_;
	my $id = $self->param("id2");
	defined($id)? 0+$id: 0
}


# требуется значение
sub require {
	my ($self, $name) = @_;
	my $val = $self->param($name);
	$self->addError($name, "заполните поле") if !defined $val or $val eq "";
	$val
}

# введите число
sub int {
	my ($self, $name) = @_;
	my $val = $self->param($name);
	$self->addError($name, "введите число") if !defined $val or $val !~ /^-?\d+$/;
	$val
}

# введите целое
sub uint {
	my ($self, $name) = @_;
	my $val = $self->param($name);
	$self->addError($name, "введите целое число") if !defined $val or $val !~ /^\d+$/;
	$val
}

# введите целое
sub natural {
	my ($self, $name) = @_;
	my $val = $self->param($name);
	$self->addError($name, "введите число больше одного") if !defined $val or $val !~ /^\d+$/ or $val < 1;
	$val
}

# введите вещественное
sub number {
	my ($self, $name) = @_;
	my $val = $self->param($name);
	$self->addError($name, "введите число") if !defined $val or $val !~ /^-?\d+(\.\d+)$/;
	$val
}

# введите вещественное
sub unumber {
	my ($self, $name) = @_;
	my $val = $self->param($name);
	$self->addError($name, "введите число больше нуля") if !defined $val or $val !~ /^\d+(\.\d+)$/;
	$val
}

# введите email
sub email {
	my ($self, $name) = @_;
	my $val = $self->param($name);
	$self->addError($name, "введите e-mail, например, name\@mail.ru") if !defined $val or $val !~ /@/;
	$val
}

# введите email
sub password {
	my ($self, $name) = @_;
	my $val = $self->param($name);
	$self->addError($name, "введите пароль не менее 3 символов") if !defined $val or $val !~ /^.{3,}$/;
	$val
}

# проверяет, что нет идентификатора у страницы
sub noid {
	my ($self) = @_;
	
	$self->addError("id", "у страницы не может быть id") if defined $self->ids("id");
	
	$self
}

# загружает модель
sub load {
	my ($self, $model, $name) = @_;
	$name //= "id";
	my $id = $self->natural($name);
	return undef if !$id;
	my $mod = $app->model->$model->find(id=>$id)->exists;
	$self->addError($name, "не найдена модель $model c № $id") if !$mod;
	$mod
}

# загружает и проверяет, чтобы owner был текущим пользователем
sub owner {
	my ($self, $model, $owner, $name) = @_;
	$owner //= "owner";
	my $mod = $self->load($model, $name);
	if($mod) {
		$self->addError("модель Вам не принадлежит") if $mod->$owner->id != $self->auth;
	}
	$mod
}

# просто оборачивает значение в модель не проверяя
sub model {
	my ($self, $name, $model) = @_;
	my $id = $self->param($name);
	$app->model->$model($id);
}

# загружает файл
sub upload {
	my ($self, $name) = @_;
	
	my @file = $self->post($name);
	 
	$self->addError($name, "Нет файла") if !(@file and ref $file[0] eq "HASH" and exists $file[0]->{body});
	#$self->cgi->upload($name);
	
	wantarray? @file: $file[0];
}

# закрывает сокет
sub close {
	my ($self) = @_;
	my $ns = $self->{ns};
	
	if(defined $ns) {
		$ns->close;
	}
	
	undef $self->{running};
	
	$self
}

############################ Утилиты ############################

# распаковывает данные переданные в виде параметров url
#	$sep - разделитель параметров. По умолчанию "&". Для кук установить ";\s*"
require URI::Escape;
sub _param {
	no utf8;
	my ($data, $sep) = @_;
	local ($_, $`, $');
	my $param = {};
	for ($data? split($sep // qr/&/, $data): ()) {
		tr/+/ /;
		/$/ unless /=/;
		my $key = URI::Escape::uri_unescape($`);
		my $val = $param->{$key};
		my $newval = URI::Escape::uri_unescape($');
		if(defined $val) {
			if(ref $val eq "ARRAY") { push @$val, $newval } else { $param->{$key} = [$val, $newval]}
		} else {
			$param->{$key} = $newval;
		}
	}
	return $param;
}

# распаковывает данные переданные в виде параметров url
#	$sep - разделитель параметров. По умолчанию "&". Для кук установить ";\s*"
#	k=v&e=1,2&x=3,&y={f=6&r=,&z=&m}&z={}, распознаётся как 
#		{k => "v", e=>[1,2], x => [3], y => {
#			f => 6, r => [], z => "", m => undef
#		}, z => [{}]
# ...


# считывает из потока параметры POST
sub _param_from_post {
	no utf8;
	my ($stdin, $type, $len) = @_;
	#print STDERR "param_from_post: $stdin, $type, $len\n";
	return unless $len;
	local ($_, $`, $', $1);
	if($type =~ m!^multipart/form-data;\s*boundary=!i) {
		my $boundary = qr/^--$'(--)?\r?\n/;
		my $param = {};
		my $file = {};
		my $is_val = 0;
		my $file_name;
		my @buf;
		
		my ($head, $is_head);
		my ($name, $encoding) = ("");
		
		
		
		while(<$stdin>) {
			if($_ =~ $boundary) {
				my $the_end = $1;
				@buf = "" if @buf == 0;
				$buf[$#buf] =~ s/\r?\n//;
				if($name ne "") {

					my $body = join '', @buf;
				
					my $val = $is_val? $body: $file_name;
					my $file_val = {body => $body, head=>$head};
					
					# устанавливается и для параметров
					if(exists $file->{$name}) {
						my $a = $param->{$name};
						my $p = $file->{$name};
						$param->{$name} = $a = [$a], $file->{$name} = $p = [$p] unless ref $p eq "ARRAY";
						push @$p, $file_val;
						push @$a, $val;
					}
					else {
						#print STDERR "name new: $name\n";
						$file->{$name} = $file_val;
						$param->{$name} = $val;
					}
					
				}
				last if $the_end;
				$is_head = 1;
				$head = {};
				@buf = ();
				$is_val = 0;
				$name = "";
				$file_name = "";
				#$encoding = "";
			} elsif($is_head && /^\r?$/) {
				$is_head = undef;
			} elsif($is_head) {
				$name = $1, $is_val = !/\bfilename=['"]?([^'";]+)/i, $file_name=$1 if /^Content-Disposition: .*?\bname=['"]?([^\s'";]+)/i;
				#$encoding = $1 if /Content-Transfer-Encoding: ([\w-]+)/;
				s/\r?\n//;
				/: /; $head->{$`} = $';
			} else {
				push @buf, $_;
			}
		}
		
		#require R::App;
		#R::App::msg1 $file;
		return $param, $file;
	} elsif($type =~ m!\bapplication/json\b!i) {
		read $stdin, $_, $len;
		$app->json->from($_);
	} else {
		read $stdin, $_, $len;
		_param($_);
	}
}



1;
