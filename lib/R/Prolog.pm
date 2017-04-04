package R::Prolog;
# содержит методы для эмуляции логического программирования в perl
# 
# my $facts = $app->prolog->vm;
# $facts->man("ivan");
# $facts->man("max");
# $facts->woman("mishel");
# $facts->woman("ira");
# $facts->para(\"A", \"B")->Is->man(\"A")->woman(\"B");
# msg1 $facts->Goal->para(\"A", \"B");

use common::sense;
use R::App;
use Scalar::Util qw/reftype/;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# сопоставление с образцом (pattern matching)
# возвращает истину, если удалось
# заменяет undef на значения из другого образца. Но только если полностью распознан.
sub match {
	my ($self, $A, $B) = @_;
	my @S = ($A, $B);
	my @R = ();
	while(@S) {
		$B = pop @S;
		$A = pop @S;
		
		if(!defined($A) && !defined($B)) {
			return "";
		}
		elsif(!defined $A) {
			#push @R, \$;
		}
		elsif(!defined $B) {
		}
		elsif(ref $A eq ref $B) {
			if(ref $A eq "") {
			}
			elsif(reftype($A) eq "ARRAY") {
			}
			elsif(reftype($A) eq "HASH") {
			}
			else {	# функция, скаляр, регулярка и т.д.
				return "" if ;
			}
		}
		else {
			return "";
		}
	}
	return 1;
}

# унификация - вывод 
sub unificate {
	my ($self) = @_;
	$self
}

# поиск с возвратом
sub backtracking {
	my ($self) = @_;
	$self
}

1;