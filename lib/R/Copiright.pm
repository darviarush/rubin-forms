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
# @author  Yaroslav O. Kosmina
# @site    
# @email   
# @license BSD
#
'
}


1;