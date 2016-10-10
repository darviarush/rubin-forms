package R::Model::Words::Rus;
# модель для парсинга русскоязычных фраз

use common::sense;
use R::App;


# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}


# фразу разбивает на слова для поиска
sub build {
	my ($self, $phrase) = @_;
	local ($`, $', $&, $1, $2);

	#utf8::encode($phrase);
	my $stopwords = $self->{stopwords};
	my $wordforms = $self->{wordforms};
	
	my $words = {};	# слово => количество
	while($phrase =~ /\d+|\p{Alpha}+/g) {
		my $z = lc $&;
		
		# не включаем
		next if exists $stopwords->{$z};
		# заменяем на другую
		my $wordform = $wordforms->{$z};
		$words->{ $wordform }++, next if defined $wordform;
		
		$z =~ tr/Ё/Е/;
		
		# стимминг
		if($z =~ s/^(.{4,})(ами|ями|умя|его|ого|ому|ему|ыми|ими|ешь|ишь|ете|ите|еть|ить|ать|ять|ось|ося|ете|ите)$/$1/){}
		elsif($z =~ s/^(.{4,})(ем|ом|ою|ов|ею|ой|ей|ью|ьи|ий|ый|ии|ия|ыя|ам|ям|ах|ях|яя|ая|ое|ее|ом|ем|юю|юу|ым|им|ей|ые|ие|ых|их|ся|сь|те|аю|ую|ет|ит|ем|им|ут|ют|ат|ят|ит|шь|ст)$/$1/){}
		elsif($z =~ s/^(.{4,})(а|я|о|у|ю|е|и|ы|ь)$/$1/){}
		elsif($z =~ s/^([a-z]{2,})(es|s|e|ed|ing|er)$/$1/){}
		$words->{ $z }++;
	}
	return $words;
}

# добавляет фразу в таблицу words, если их там нет и возвращает их идентификаторы
sub set {
	
}

# возвращает word_id для тех слов в фразе, которые есть в words
sub get {
	
}

1;