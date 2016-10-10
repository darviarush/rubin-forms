package R::Http::Robot::Archi;
# робот таскает новости с других сайтов (каждый раз с нового)
# а так же разговоры к новости, в которых рендомным образом учавствуют фиктивные пользователи

use common::sense;
use R::App;

use LWP::UserAgent;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# регистрирует в Шиве
sub register {
	my ($self) = @_;
	
	app->shiva->on("robot-archi" => "0 * * * *" => closure $self, \&grab);
	
	$self
}


# создаёт группы и пользователей, если их нет
sub sync {
	my ($self) = @_;
	
	$app->model->user(1)->aim(name => "Юмор", description => "Каждый час по новому анекдоту!\nКаж")->save if $app->model->aim->find(name => "Юмор")->exists;
	
	$self
}

# берёт из сайтов новости и фигачит их в группы
sub grab {
	my ($self) = @_;
	
	# места - путешествие по планете
	# грабим из карт гугла с коментами
	
	# улов из соцсетей
	
	# анекдоты
	my $agent = $app->httpAgent->new("http://vk.com", 15);
	
	$agent->
	
	$self
}

1;