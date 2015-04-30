package R::Mailer;
# электронная почта

use strict;
use warnings;

use MIME::Base64;
use MIME::Lite;

use Utils;
use R::Action;

Utils::has(qw/action app/);

# конструктор
sub new {
	my ($cls, $app) = @_;
	my $action = R::Action->new($app);
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

	my $action = $param{action};
	if($action) {
		delete $param{action};
		
	}
	
	my $ini = $self->app->ini->{mailer};
	
	if($ini->{smtp}) {
		MIME::Lite->send('smtp', $ini->{smtp}, ($ini->{user}? (AuthUser=>$ini->{user}, AuthPass=>$ini->{pass}): ()));
	}
	
	$self->send;
	$self
}

1;