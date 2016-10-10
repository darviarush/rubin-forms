package R::Sprite;
# возвращает классы спрайтов

use common::sense;
use R::App;

my $singleton;

# конструктор
sub new {
	my ($cls) = @_;
	
	return $singleton if $singleton;
	
	$singleton = bless {
		classes => {}, 		# спрайты
	}, ref $cls || $cls;
	
	
	$singleton->load;
}


# загружает спрайты
sub load {
	my ($self) = @_;
	
	return $self if $self->{load};
	$self->{load} = 1;
	
	my $classes = $self->{classes};
	
	$app->file("html/sprite/*.css")->glob->then(sub {
		$_ = $_->read;
		
		while(m!^\.([\w-]+) \{!gm) {
			my $class = $1;
			my $name = $app->perl->camelcase($class);
			$classes->{$class} = 1;
			
			die "sprite: метод $name уже существует" if *$name{CODE};
			
			*$name = (sub { my ($class) = @_; sub { $class } })->($class);
		}
	});
	
	
	$self
}


# распечатывает все спрайты
# спрайт 
sub render {
	my ($self) = @_;
	$app->html->new("<h3></h3>");
}



1;