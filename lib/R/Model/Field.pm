package R::Model::Field;
# управляет полями в базе

# конструктор
sub new {
	my ($cls, $app, $name, $type) = @_;
	bless {cls=>$cls, app=>$app, name=>$name, type=>$type, tab=>'' }, $cls;
}

# возвращает 


1;