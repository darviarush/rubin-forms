package R::Mail;
# почтальён

use common::sense;
use R::App;

use MIME::Base64;
use MIME::Lite;

has qw/mail param/;

# конструктор письма
sub new {
	my ($cls, %param) = @_;
	
	if(!ref $cls) {
		
		my $ini = $app->ini->{mail};
	
		if($ini->{smtp}) {
			my $smtp = $ini->{smtp};
			#delete $ini->{smtp};
			MIME::Lite->send('smtp', $smtp->{smtp}, 
				($smtp->{user}? (AuthUser=>$smtp->{user}, AuthPass=>$smtp->{pass}): ()),
				($smtp->{timeout}? (Timeout=>$smtp->{timeout}): ()),
				($smtp->{port}? (Port => $smtp->{port}): ())
			);
		}
		
		if($ini->{sendmail}) {
			MIME::Lite->send('sendmail', $ini->{sendmail});
			#delete $ini->{sendmail};
		}
		
	}

	bless {
		param => {
			%param,
		},
	}, ref $cls || $cls;
}

# тема
sub subject {
	my ($self, $val) = @_;
	$self->{param}{Subject} = $val;
	$self
}

# от кого
sub from {
	my ($self, $val) = @_;
	$self->{param}{From} = $val;
	$self
}

# кому
sub to {
	my ($self, $val) = @_;
	$self->{param}{To} = $val;
	$self
}


# подключает файл
sub attach {
	my $self = shift;
	my $file = shift;
	
	my $type = $app->httpMime->{ $app->file($file)->ext };
	
	$type .= "; codepage=utf-8" if $type =~ m!^text/!;
	
	push @{$self->{attach}}, {File => $file, Type => $type, @_};
	$self
}

# рендерит и подключает файл
sub real_render {
	my ($self, $path, $data) = splice @_, 0, 3;
	
	my $file = $app->view->renderis($path, $data);
	my $type = $app->httpMime->{ $app->file($path)->ext };
	
	push @{$self->{attach}}, {Data => $file, Type => $type, @_};
	
	$self
}

# реальный рендер
sub render {
	my $self = shift;
	my $path = shift;
	$self->real_render("mail/$path", @_);
}

# декодирует все ключи
sub no_utf8(@) {
	utf8::encode($_) for @_;
	@_
}

# формирует письмо
sub form_mail {
	my ($self) = @_;
	
	my $param = $self->{param};
	my $attach = $self->{attach};
	
	my $subject = $param->{Subject} // "(Без темы)";
	utf8::encode($subject);
	$subject = MIME::Base64::encode($subject, "");
	$subject = "=?UTF-8?B?$subject?=";
	$param->{"Subject"} = $subject;
	$param->{"From"} //= "noreply\@" . $app->ini->{site}{host};
	$param->{"To"} //= "darviarush\@mail.ru";
	$param->{"Type"} //= "multipart/mixed";

	my $mail = $self->{mail} = MIME::Lite->new(no_utf8(%$param));
	
	for my $attach (@{$self->{attach}}) {
		$mail->attach(no_utf8(%$attach));
	}

	$self
}

# отправляет
sub send {
	my ($self) = @_;
	
	$self->form_mail;
	
	if( app->ini->{site}{test} ) {
		msg ":red", "письмо:", ":reset", $self->stringify;
	}
	else {
		#open my f, "| /usr/sbin/sendmail -t" or die "Нет sendmail";
		#print f msg.as_string;
		#close f;
		$self->mail->send
	}
	
	
	$self
}

# возвращает текст письма
sub stringify {
	my ($self) = @_;
	
	$self->form_mail;
	
	my $stringify = $self->mail->as_string;
	utf8::decode($stringify);
	$stringify
}


1;