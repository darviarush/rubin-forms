package R::Copiright;
# тут находятся копирайты

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# для вставки в начало файлов
sub file {
	my ($self) = @_;
	
	'
#                               
# @author  Iaroslav O. Kosmina
# @site    darviarush@narod.ru
# @email   darviarush@mail.ru
# @license BSD-2 (aka MIT)
#
'
}


1;