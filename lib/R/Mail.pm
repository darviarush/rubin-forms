package R::Mail;
# электронная почта

use strict;
use warnings;

use MIME::Base64;
use MIME::Lite;

use Utils;
use R::Action;
use R::App;

Utils::has(qw/action app/);

# конструктор
sub new {
	my ($cls, $app) = @_;
	my $action = R::Action->new($app);
	$action->{app_prop} = "mail->action";
	$action->{dir} = "mail";
	$action->{dir_c} = "watch/mail_c";
	$action->{ext_act} = qr/\.act$/;
	$action->{ext_htm} = qr/\.(?:html?|txt)$/;
	bless {
		app=>$app,
		action=>$action,
	}, $cls;
}

# отправляет письмо
sub send {
	my ($self, %param) = @_;
	my $action_ini;
	my $action_init = {};
	my $action = $param{action};
	
	if(defined $action) {
		delete $param{action};
		$action_ini = Utils::parse_ini(::file("mail/$action/mail.ini"));
		$action_init = $action_ini->{init};
	}
	
	my $ini = {%{$self->app->ini->{mail}}};
	
	if($ini->{smtp}) {
		my $smtp = $ini->{smtp};
		delete $ini->{smtp};
		MIME::Lite->send('smtp', $smtp->{smtp}, 
			($smtp->{user}? (AuthUser=>$smtp->{user}, AuthPass=>$smtp->{pass}): ()),
			($smtp->{timeout}? (Timeout=>$smtp->{timeout}): ())
		);
	}
	
	if($ini->{sendmail}) {
		MIME::Lite->send('sendmail', $ini->{sendmail});
		delete $ini->{sendmail};
	}
	
	my $subject = $ini->{Subject} // $action_init->{Subject} // $param{Subject};
	$subject = MIME::Base64::encode($subject, "");
	$subject = "=?UTF-8?B?$subject?=";
	
	my $msg = MIME::Lite->new(%$ini, %$action_init, %param, Subject=>$subject);
	
	# добавляем к письму аттачи
	if(defined $action) {
		
		# http://www.getinfo.ru/article529.html - создание писем с помощью mime::lite
		while(my ($key, $val) = each %{$action_ini->{attach}}) {
			my $Action = $val->{Action};
			if(defined $Action) {
				delete $val->{Action};
				$val->{Data} = $self->render("$action/$Action");
			}
			$msg->attach(%$val);
		}
		
	}
	
	$msg->send;
	
	$self
}

# рендерит mail-страницу
sub render {
	my ($self, $action) = @_;
	my $app = bless {}, "R::App";
	%$app = %{$self->{app}};
	my $request = R::Request->new($app);
	my $response = R::Response->new($app);
	$app->request($request);
	$app->response($response);
	$app->action($self->action);
	
	$response->render($action);
}

1;