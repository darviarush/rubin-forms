package R::Html;
# всё что связано с html

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, $cls;
}


# декодирует из html
sub from {
	my ($self, $html) = @_;
	todo;
}


# кодирует в html
sub to {
	my ($self, $val) = @_;
	$val =~ s!(&)|(<)|(>)|(")|(')! $1? '&amp;': $2? '&lt;': $3? '&gt;': $4? '&quot;': '&#39;' !ge;
	$val
}



1;
