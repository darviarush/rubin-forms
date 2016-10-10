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
# @author  
# @site    
# @email   
# @license BSD
#
'
}


1;