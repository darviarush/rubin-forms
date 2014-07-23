use lib "../lib";

require Utils;
require Mailer;

$ini = Utils::parse_ini("../lib/main.ini");

$mailer = Mailer->new("..", $ini->{mailer});
$msg = $mailer->email("news",
{
To => "foxcool333\@gmail.com",
Subject => "Новости магазина очковых линз"
},
{
TextNews => "news",
HTMLNews => "hi!",
NoMail => "nomail"
}
);

print $msg->as_string;

$msg->send;