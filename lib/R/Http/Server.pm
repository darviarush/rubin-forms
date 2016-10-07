package R::Http::Server;
# http-сервер

use parent qw/R::Process::Server/;

use common::sense;
use R::App;

use Protocol::WebSocket::Handshake::Server qw//;
use Protocol::WebSocket::Frame qw//;

# конструктор
sub new {
	my $cls = shift;
	unshift @_, "port" if @_ == 1;
	
	my $self = $cls->SUPER::new(request => ref($app->httpRequest), @_);
	
	# hijack  - угон q для websoketa
	$self->on("/_ws_" => closure $self, \&hijack);
	
	# сообщение для запроса
	$self->message(request => closure $self, sub {
		my ($self, $uri, $post, $head) = @_;
	
		my $q = $app->q;
		
		# добавляем в q.param
		NEXT:
		$q->action($uri, $post, $head);
		
		$self->before;
		$self->freeman;
		$self->after;
			
		if($uri = $q->head("Location")) {
			$post = undef;
			$head = undef;
			$q->clear;
			goto NEXT;
		}
		
		my $emit = join "", @{$q->{echo}};
		$app->contact->emit("request", $emit);
	});
	
	# добавляем сообщения для форм
	$self->message(form => closure $self, sub {
		my ($self, $action, $param) = @_;
	
		# добавляем в q.param
		$app->q->action($action, $param);
		
		my $dispForm = $self->{dispatchers}{$action};
		$app->contact->emit("error", "нет диспетчера формы `$action`"), return if !$dispForm;
		$app->contact->emit("error", "запрос к диспетчеру формы, но `$action` - не форма"), return if $dispForm->{type} != 3;

		my $form = $dispForm->class->new;
		$form->{save} = 2;			# брать параметры из q.param
		$form->runInStart;
		my $emit = join "", @{$form->render};
		
		$app->contact->emit("form", $action, $emit);
	});
	
	# добавляем сообщения для поиска страниц
	$self->message(search => closure $self, sub {
		my ($self, $action, $param) = @_;
	
		# добавляем в q.param
		$app->q->action($action, $param);
		
		my $dispForm = $self->{dispatchers}{$action};
		$app->contact->emit("error", "нет диспетчера формы `$action`"), return if !$dispForm;
		$app->contact->emit("error", "запрос к диспетчеру формы, но `$action` - не форма"), return if $dispForm->{type} != 3;
	
		my $pageform = $dispForm->class->new;
		$pageform->{save} = 2;			# брать параметры из q.param
		$pageform->runInStart;
		my $emit = join "", @{$pageform->render};
		
		$app->contact->emit("search", $action, $emit);
	});
	
	# добавляем сообщения для перелистывания страниц
	$self->message(page => closure $self, sub {
		my ($self, $action, $param) = @_;
	
		# добавляем в q.param
		$app->q->action($action, $param);
		
		my $dispForm = $self->{dispatchers}{$action};
		$app->contact->emit("error", "нет диспетчера формы `$action`"), return if !$dispForm;
		$app->contact->emit("error", "запрос к диспетчеру формы, но `$action` - не форма"), return if $dispForm->{type} != 3;
	
		my $pageform = $dispForm->class->new;
		$pageform->{save} = 2;			# брать параметры из q.param
		$pageform->runInStart;
		my $emit = join "", @{$pageform->page_render};
		
		$app->contact->emit("page", $action, $emit);
	});
	
	$self
}

# # обработчик таймаута: если есть сокет, то пишет в него
# sub analarm {
	# my $self = shift;

	# #print STDERR "ALRM $$\n";
	# $app->log->alert("ALRM $$", "$app->{q}", "$app->{q}{ns}");
	# my $q = $app->{q};
	# return if !$q;
	
	# my $ns = $q->{ns};
	# return if !$ns;
	
	# $q->clear;

	# $app->connect->{transaction}=1, $app->connect->rollback if $app->connect->{transaction};
	
	# $q->status(504);
	# $q->echo("504 Gateway Timeout");
	
	# $self->response;
	# CORE::close($ns);
# }



# POST /ex?x= HTTP/1.1
# User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:38.9) Gecko/20100101 Goanna/2.0 Firefox/38.9 PaleMoon/26.0.0
# Content-Length: 27
# Content-Type: application/x-www-form-urlencoded
# Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
# Accept-Language: en-US,en;q=0.5
# Host: http_unicorn
# Referer: http://unicorn/ex?x=
# Connection: keep-alive
# Accept-Encoding: gzip, deflate
# Cache-Control: max-age=0
# x=20&@action=/ex/form

# фиктивный запрос экшена. Возвращает {}
sub action {
	my ($self, $method, $url, $data, $head, $ip) = @_;
	
	my $oldq = $app->{q};
	$app->q( my $q = $app->httpRequest->new );
	
	$q->{method} = $method;
	$q->uri($url);
	$q->{version} = "1.1";
	$q->{ns} = undef;
	$q->{paddr} = undef;
	$q->{ip} = $ip // "127.0.0.1";
	$q->{post} = $data;
	$q->{inhead} = {
		"User-Agent"=> "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:38.9) Gecko/20100101 Goanna/2.0 Firefox/38.9 PaleMoon/26.0.0",
		"Content-Length"=>1,
		"Content-Type"=> "application/x-www-form-urlencoded",
		"Accept"=> "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
		"Accept-Language"=> "en-US,en;q=0.5",
		"Host"=> "http_unicorn",
		"Referer"=> "http://unicorn/ex?x=",
		"Connection"=> "keep-alive",
		"Accept-Encoding"=> "gzip, deflate",
		%$head,
	};
	

	
	$self->setup, $self->init, $self->{ ACTION_INIT } = 1 if !$self->{ ACTION_INIT };
	$self->before; $self->freeman; $self->after;
	
	$app->q( $oldq );
	
	join "", @{$q->{echo}};
}

# action GET
sub GET {
	my $self = shift;
	my $url = shift;
	$self->action("GET", $url, {}, @_);
}

# action POST
sub POST {
	my $self = shift;
	$self->action("POST", @_);
}


# инициализация сервера
sub setup {}

# инициализация рыцаря
sub initialize {}

# инициализация гвардейца
sub init {}

#	impulse
#	  |
#	before
#	  |
#	freeman
#	  |
#	after
#	  

# вызывается перед обработкой запроса
sub before {}

# выполяняется перед выдачей
sub after {}

#	hijack - убирает q
#	ns переходит в 

# приконнектился веб-сокет
sub hijack {
	my ($self) = @_;
	
	# обработчик коннекта
	if(my $connect = $self->{messages}{connect}) {
		eval { $connect->(); };
		msg "message.connect: $@" if $@;
	}
	
	my $q = $app->{q};
	
	# создаётся сообщение
	$q->{is_message} = {
		handshake => Protocol::WebSocket::Handshake::Server->new,
		frame => Protocol::WebSocket::Frame->new,
	};

	# регистрируется в контактах
	$app->contact->connect;
	
	# передаётся заголовок в парсер
	my $head = $q->{inhead};
	my $chunk = join "", $q->{http}, map({ "$_: $head->{$_}\n" } keys %$head), "\n";
	
	my $ns = $q->{ns};
	if(ref $ns eq "Coro::Handle") {
		$ns->partial(1);
		$ns->read(my $buf, 1024*1024*256);
		$ns->partial(0);
		$chunk .= $buf;
	}
	
	$self->ws_read($chunk);
	
	$self
}

use Errno qw(EAGAIN EINTR);
use AnyEvent::Util qw(WSAEWOULDBLOCK);

# обработка события на веб-сокете
sub adventure {
	my ($self) = @_;
	
	my $q = $app->{q};
	my $ns = $q->{ns};
	
	if(ref $ns eq "Coro::Handle") { $ns = $ns->fh } else { AnyEvent::fh_unblock $ns; }

	while() {
		my $len = sysread $ns, my $chunk, 1024*256;
		
		# ns закрыт
		if(!defined($len) && $! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK) {
			my $e = $!;
			msg "no read in adventure: " .int($!)." $!";
			
			$app->contact->disconnect;
			$app->contact->init;
			
			# обработчик дисконнекта
			if(my $disconnect = $self->{messages}{disconnect}) {
				eval { $disconnect->($e); };
				msg "message.disconnect: $@" if $@;
			}
			
			return $self;
		}
		
		last if !$len;
		$self->ws_read($chunk);
	}

	$self
}

# разбирает ответ
sub ws_read {
	my ($self, $chunk) = @_;
	
	my $q = $app->{q};
	my $ns = $q->{ns};
	my $message = $q->{is_message};
	
	if (my $handshake = $message->{handshake}) {
		$handshake->parse($chunk);

		if ($handshake->is_done) {
			my $str = $handshake->to_string;
			syswrite $ns, $str;
			delete $message->{handshake};	# удаляем handshake
			return $self;
		}
	}

	my $frame = $message->{frame};
	$frame->append($chunk);

	while (my $mess = $frame->next) {
		my $args = $app->json->from($mess);
		msg("получен запрос не по протоколу: `$mess`"), $q->close, last if ref $args ne "ARRAY";
		my $name = shift @$args;
		msg("повреждён запрос websocket - не указано имя сообщения: `$mess`"), $q->close, last if !defined $name;
		my $cmd = $self->{messages}{$name};
		msg("не зарегистрировано сообщение с именем: `$name`"), next if !defined $cmd;
		
		$app->contact->init;
		eval { $cmd->(@$args) };
		msg "message.$name: $@" if $@;
		$app->contact->change;
	}
	
	$self
}

# достаёт обработчик запросов
sub freeman {
	my ($self) = @_;
	
	my $q = $app->{q};
	eval {
		$app->connect->begin;

		my $dispatch = $self->{dispatch};
		my $regexp = $self->{regexp};
		my $handler = $regexp? do {
			my $path = $q->uri->path;
			$path =~ $regexp? do { $q->{ids} = +{%+}; $^R }: $dispatch->{ $q->path };
		}:
		$dispatch->{ $q->path };
		
		if (defined $handler) {
			# если есть специальный параметр: срабатывает форма
			if(my $action = $q->param('@action')) {
				my $dispForm = $self->{dispatchers}{$action};
				die "нет диспетчера формы `$action`" if !$dispForm;
				die "запрос к диспетчеру формы, но `$action` - не форма" if $dispForm->{type} != 3;
				$q->form($dispForm->class);
			}
			# обрабатываем запрос
			$handler->();
			
			# если есть форма и ошибки на ней неотработаны
			if(exists $q->{form}) {
				my $form = $q->{form};
				if(!$form->{Concat} && $form->isErrors) {
				
					$q->prepend("<div class='noshow-form-errors'>ошибки на не выведенной форме $form->{Name}:", 
						"<ol class=error>",
							map({ "<li>" . $app->html->escape($_) } @{$form->{errors}}),
							map({ "<li>" . $app->html->escape( "$_:" . $form->{error}{$_} ) } keys %{$form->{error}}),
						'</ol>',
					"</div>");
				}
			}
			
		} else {
			$q->{status} = 404;
			if(my $not_found = $dispatch->{"/error/404"}) {
				$not_found->();
			} else {
				$q->type("text/plain");
				$q->echo("404 Not Found");
			}
		}
		
		$q->object_clear;
		$app->connect->commit;
	};
	if($@) {
		my $error = $@;
		
		msg ":red", "500-error:", ":reset", "$error";
		
		$q->clear;
		$app->connect->rollback;

		my $page;
		eval {
			$app->connect->begin;
			if(Isa($error, "R::Raise") and defined $error->{abbr}) {
			
				$q->render($page = "$error->{abbr}.html");
			}
			else {
				$q->render($page = "error/500.html", {
					error => (Isa($error, "R::Raise")? $error->message: $error),
				});
				$q->status(500);
			}
			
			$q->object_clear;
			$app->connect->commit;
		};
		if($@) {
			msg ":red", "500-error-2: ошибка в $page", ":reset", "$@";
			
			$q->clear;
			$app->connect->rollback;
			
			$q->status(500);
			$q->type("text/plain");
			$q->echo("500 Internal Server Error");
		}
	}
	
	#$q->object_clear;
	
	$self
}



# обрабатывает запрос
sub ritter {
	my ($self) = @_;
	
	my $keep_alive;
	
	my $q = $app->{q};
	
	return $self->adventure if $q->{is_message};
	
	my $ns = $q->{ns};
	
	my $HTTP = readline $ns;
	return $self unless defined $HTTP;
	
	#alarm $self->{alarm} if $self->{alarm};
	
	my $_test = $self->{test};
	
	if(my @param = $HTTP =~ m!^(\w+) (\S+) (HTTP\/\d\.\d)\r?$!) {
		$q->{method} = $param[0];
		$q->uri($param[1]);
		$q->{version} = $param[2];
		$q->{http} = $HTTP;

		# считываем заголовки
		my $head = $q->{inhead};
		/: (.*?)\r?$/ and $head->{$`} = $1 while defined($_ = readline $ns) and !/^\r?$/;
		
		$self->stat_begin($HTTP, $q) if $_test;

		# настраиваем сессионное подключение (несколько запросов на соединение, если клиент поддерживает)
		$keep_alive = ($head->{Connection} =~ /\bkeep-alive\b/i);

		$self->before;
		$self->freeman;
		$self->after;
		
		return $self if $q->{is_message};	# ns захвачен web-сокетом
		
		# если не был прочитан POST, то считываем его, если keep-alive
		my $length;
		if($keep_alive and not defined $q->{"post"} and ($length = $head->{"Content-Length"}) and not exists $head->{'REQUEST_BODY_FILE'}) {
			if($length < 1024*64) {
				$ns->sysread(my $buf, $length);
			} else {
				$keep_alive = undef;
			}
		}
	} else {
		my $http_status = $app->httpStatus;
		$q->status(400)	# bad request
		->type("text/plain")
		->echo("400 $http_status->{400}");
		$keep_alive = undef;
		$self->stat_begin($HTTP, $q) if $_test;
	}
	
	$q->head(Connection => "keep-alive") if $keep_alive;
	
	$self->response;
	
	#msg1 "keep!", $keep_alive;
	
	#goto IMPULSE if $keep_alive;
	
	$q->close if !$keep_alive;
	
	$self
}

# отправляет ответ 
sub response {
	my ($self) = @_;
	
	my $q = $app->{q};
	
	if(!$q->{noresponse}) {
	
		# добавляем к ответу лог
		$app->logEcho->response if exists $q->{logEcho};
		
		#my $js = $q->{js_pos};
		my $echo = $q->echo_pull;
		my $head = $q->{head};
		
		unless(exists $head->{"Content-Length"}) {
			my $len = 0;
			#my $JSON = $app->{json};
			
			for my $text (@$echo) {
				#$text = $JSON->encode($text) if ref $text;
				utf8::encode($text);		# затем используется ниже
				$len += length $text;
			}
			$head->{"Content-Length"} = $len;
		}
		
		my ($k, $v);
		my $cookie = $q->{cookie};
		my $status = $q->{status};
		
		my $http_status = $app->httpStatus;
		
		unshift @$echo, 
			"HTTP/1.1 ", $status, " ", $http_status->{$status}, "\n",
			map({ ($_, ": ", $head->{$_}, "\n") } keys %$head),
			map({ ("Set-Cookie: ", $_, "\n") } @$cookie),
			"\n";
		
		# если ns был захвачен сервером Aura
		$q->{ns}->syswrite( join "", @$echo );
	}
	
	$self->stat_end if $self->{test};
	
	# контракт: формы и объекты ORM должны удалиться тут окончательно
	my $FORMS = $q->{_FORMS};
	my $INPUTS = $q->{_INPUTS};
	my $ROW = $q->{_ROW};
	my $ROWSET = $q->{_ROWSET};
	
	# объекты, привязанные к q, например, q->{INPUTS} не очищаются, почему-то без этого ;)
	my $io = $self->request->new($q->{ns}, $q->{paddr});
	$io->{is_message} = $q->{is_message};	# указывает что был коннект и не надо закрывать ns
	%$q = %$io;
	
	$_ = $a = $b = undef;	# уничтожаем: вдруг к ним что-то привязано
	
	my $count = keys %$FORMS;
	my $count_inputs = keys %$INPUTS;
	my $count_row = keys %$ROW;
	my $count_rowset = keys %$ROWSET;
	
	if($count || $count_row || $count_inputs || $count_rowset) {
		my $msg = "Утечка памяти! ";
		$msg .= "Остались формы ($count): " . _helper_mem($FORMS) . ". " if $count;
		$msg .= "Остались инпуты ($count_inputs): " . _helper_mem($INPUTS) . ". " if $count_inputs;
		$msg .= "Остались записи ($count_row): " . _helper_mem($ROW) . ". " if $count_row;
		$msg .= "Остались запросы ($count_rowset): " . _helper_mem($ROWSET) . ". " if $count_rowset;
		$self->{role} eq "loop"? die($msg): 
		$app->log->error($msg);
	}
	
	$self
}

# возвращает сообщение
sub _helper_mem {
	my ($mem) = @_;
	local ($_);
	join ", ", map { sprintf "%s=HASH(0x%x)", $mem->{$_}, $mem } keys %$mem
}

# добавление контроллеров
*control = \&controllers;
sub controllers {
	my $self = shift;
	
	my $dispatch = $self->{dispatch};
	my $dispatchers = $self->{dispatchers};
	my $factory = $app->httpDispatcher;
	
	for(my $i=0; $i<@_; $i+=2) {
		my ($prefix, $module) = @_[$i, $i+1];
		$prefix =~ s!/$!!;
		my $path = $module;
		$path =~ s!::!/!g;
		require "$path.pm";
		while(my ($k, $action) = each %{"${module}::"}) {
			if($k =~ /^action/) {
				my $uri = $';
				$uri =~ s![A-Z]!"/" . lc $&!ge;
				$uri = $prefix . $uri;
				die "диспетчер $uri уже добавлен" if exists $dispatch->{$uri};
				die "$uri: uri диспетчера должно начинаться на /" if $uri !~ /^\//;
				$dispatch->{$uri} = my $sub = \&{$action};
				$dispatchers->{$uri} = $factory->new->type("controller")->uri($uri)->prefix($prefix)->controller($module)->action($k)->sub($sub);
			}
		}

	}

	$self
}


# добавление диспетчеров
*dispatch = \&on;
*dispatchers = \&on;
sub on {
	my $self = shift;
	
	my $dispatch = $self->{dispatch};
	my $dispatchers = $self->{dispatchers};
	my $factory = $app->httpDispatcher;
		
	for(my $i=0; $i<@_; $i+=2) {
		my ($uri, $sub) = @_[$i, $i+1];
		
		die "диспетчер $uri уже добавлен" if exists $dispatch->{$uri};
		die "$uri: uri диспетчера должно начинаться на /" if !ref($uri) && $uri !~ /^\//;
		
		if(Isa $sub, "R::Http::Dispatcher") {
			die "не совпадает uri `$uri` в диспетчере `" . $sub->uri . "`" if $sub->uri ne $uri;
			die "нет подпрограммы" if ref $sub->sub ne "CODE";
			$dispatchers->{ $uri } = $sub;
			$dispatch->{ $uri } = $sub = $sub->sub;
		} else {
			die "ожидается подпрограмма, а не $sub" if ref $sub ne "CODE";
			$dispatch->{ $uri } = $sub;
			$dispatchers->{ $uri } = $factory->new->type("dispatcher")->uri($uri)->sub($sub);
		}
		
		if(!ref $uri and $uri =~ /</) {
			$uri = quotemeta $uri;
			$uri =~ s!\\<(\\\*|\w+)\\:(\w+)\\>!
				$1 eq "int"? qr((?P<$2>-?\d+)):
				$1 eq "uint"? qr((?P<$2>\d+)):
				$1 eq "nat" || $1 eq "id"? qr((?P<$2>[1-9]\d*)):
				$1 eq "float"? qr((?P<$2>-?\d+(?:\.\d+)?|-?\.\d+)):
				$1 eq "var"? qr((?P<$2>[a-z_]\w*))i:
				$1 eq "word"? qr((?P<$2>[a-z_][\w-]*)):
				$1 eq "abc"? qr((?P<$2>[a-z]+)):
				$1 eq "dir"? qr((?P<$2>[^/]+?)):
				$1 eq "\\*" || $1 eq "string"? qr((?P<$2>.*?)):
				die "не распознана группа <$1:$2>";
			!ge;
			$uri = qr/^$uri$/;
			
		}
		
		if(ref $uri eq "Regexp") {
			my $regexp = $self->{regexp};
			(sub {
				my $sub = shift;
				$self->{regexp} = $regexp? qr/$uri(?{ $sub })|$regexp/: qr/$uri(?{ $sub })/;
			})->($sub);
		}
	}
	
	$self
}

# переименование диспетчеров
*replace = \&rename_dispatchers;
*rename = \&rename_dispatchers;
sub rename_dispatchers {
	my $self = shift;
	my $dispatch = $self->{dispatch};
	my $dispatchers = $self->{dispatchers};
	for(my $i=0; $i<@_; $i+=2) {
		my ($new, $uri) = @_[$i, $i+1];
		die "диспетчер $uri нельзя переименовать, т.к. $new уже добавлен" if exists $dispatch->{$new};
		die "$new: uri диспетчера должно начинаться на /" if $new !~ /^\//;
		$dispatch->{ $new } = delete $dispatch->{ $uri };
		$dispatchers->{ $new } = my $dis = delete $dispatchers->{ $uri };
		$dis->rename($new);
	}
	$self
}

# устанавливает обработчики сообщений
*messages = \&message;
sub message {
	my $self = shift;
	
	my $messages = $self->{messages} //= {};
	for(my $i=0; $i<@_; $i+=2) {
		my ($route, $sub) = @_[$i, $i+1];
		$messages->{$route} = $sub;
	}
	
	$self
}


# выводит статистику
sub stat_begin {
	my ($self, $HTTP, $q) = @_;
	
	$app->bench->time;
	
	my $head = $q->{inhead};
	my ($k, $v, @HTTP);
	
	push @HTTP, $HTTP;
	push @HTTP, "$k: $v\n" while ($k, $v) = each %$head;
	
	my @POST = $q->post;
	push @HTTP, join("&", map { "$_=" . substr scalar $q->post($_), 0, 10 } @POST) . "\n" if @POST;
	
	$app->log->info( ":empty bold black", "\n", @HTTP);
	
	$self
}

# выводит статистику
sub stat_end {
	my ($self) = @_;
	
	my $echo = $app->q->{echo};
	my @echo;
	for my $line (@$echo) {
		last if $line eq "\n";
		push @echo;
	}
	
	$app->log->info( ":empty bold black inline", join "", @echo);
	$app->log->info( ":empty bold black", $app->bench->log, "\n" );
	
	$self
}



1;
