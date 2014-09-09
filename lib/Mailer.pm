package Mailer;

use strict;
use warnings;

use Data::Dumper;
use Utils;

# конструктор
sub new {
	my ($class, $home, $main_ini) = @_;
	bless {HOME=>$home || "lib", INI=>$main_ini || $main::ini->{'mailer'}, PARAM=>{ host=>$main::ini->{'site'}{'host'} }}, $class;
}

# отправляет письмо
sub send_email {
	my ($self, $name, $init) = @_;
	my $ini = $self->{INI};
	while(my($key, $val) = each %$ini) {
		$init->{$key} = $val unless exists $init->{$key};
	}

	my $msg = email(@_);

	if($self->{INI}->{test}) {
		print STDERR $msg->as_string."\n";
	} else {
		$msg->send;
	}
}


# формирует из шаблона письмо
sub email {
	my ($self, $name, $init, $param1) = @_;

	my $HOME = $self->{HOME};
	my $path = "$HOME/templates/$name";
	my $param = {%{$self->{PARAM}}, %$param1};
	
	# для вставки в шаблон переменных
	my $data_from_file = sub {
		my ($keys) = @_;
		return unless exists $keys->{Data};
		my $filename = "$path/$keys->{Data}";
		open my($f), $filename or die "Не открыть $filename. $!";
		read $f, my($data), -s $f;
		close $f;
		$data =~ s/\$(\w+)/$param->{$1}/ge;
		$keys->{Data} = $data;
	};

	my $ini = Utils::parse_ini("$path/mail.ini");
	my ($key, $val);
	$ini->{init}->{$key} = $val while ($key, $val) = each %$init;
	while(($key, $val) = each %{$ini->{init}}) {
		$ini->{init}{$key} = $val if $val =~ s/\$(\w+)/$param->{$1}/ge;
	}

	print STDERR Dumper($param), Dumper($ini->{init});
	
	# кодируем тему
	require MIME::Base64;
	my $subj = MIME::Base64::encode($ini->{init}->{Subject}, "");
	$subj = "=?utf-8?B?".$subj."?=";
	$ini->{init}->{Subject} = $subj;

	&$data_from_file($ini->{init});

	require MIME::Lite;
	my $msg = MIME::Lite->new(%{$ini->{init}});

	my $attach = $ini->{attach} || {};

	for my $key (sort {$a<=>$b} keys %$attach) {
		my $keys = $attach->{$key};
		&$data_from_file($keys);
		$msg->attach(%$keys);
	}

	return $msg;

}

1;