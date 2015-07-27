package R::Miu;
# Система тестирования, документирования и публикаций в интернете

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
	}, ref $cls || $cls;
}


# разбирает 
sub run {
	my ($self, $opt) = @_;
	
	if(!$opt{test} && !$opt{article} &&!$opt{public}) {
		$opt{test} = 1;
		$opt{article} = 1;
		$opt{public} = 1;
	}
	
	$self->{opt} = $opt;
	
	if($opt->{test}) {
		$app->file->find()->then({
			$app->patternTest->new;
		});
	}
	
	if($opt->{article}) {
		$app->patternArticle->new;
	}
	
	if($opt->{public}) {
		$app->patternPublic->new;
	}
	
	$self
}


1;
