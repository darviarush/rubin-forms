# Главный класс приложения R::App

## Инициализация

```perl


use common::sense;
use lib "lib";
use R::App qw/$app msg msg1 in out body invariant RETURN/;

$app->man->conf;



```

## Контрактное программирование

`R::App` по умолчанию добавляет методы для контрактного программирования.
Это `in`, `out`, `body` и `invariant`.

* `in` - предусловия
* `out` - постусловия
* `body` - тело подпрограммы
* `invariant` - условия состояния класса, проверяющиеся при вызове каждого метода после предусловий и после завершения метода до постусловий
* `RETURN` - используется в `out`. Возвращает то что вернуло тело функции

Во всех блоках, в том числе и в инварианте `wantarray` будет соответствовать вызову функции. 

```perl

package LeonKiller {
	
	use R::App;
	
	invariant {
		my ($self) = @_;
		assert $self->{tired} < 3, "киллер надорвётся на 3-м";
	};
	
	# убивает человека
	sub kill {
		in {
			my ($self, $person, $pay) = @_;
			assert $pay < 1000, "сумма не должна быть подозрительно высокой";
			assert !$person->{security}, "убивать только субъектов без охраны";
		};
		out {
			assert RETURN < 100, "у киллера слишком много денег! Его же убъют, если он скажет об этом!";
		};
		body {
			my ($self, $person, $pay) = @_;
			
			# лишаем персону жизни
			delete $person->{life};
			
			# устаём от заказа
			$self->{tired}++;
			
			# кладём оплату в кошелёк
			$self->{wallet} += $pay;
			
			# сообщаем сколько у нас в кошельке
			return $self->{wallet};
		};
	}

	# создаёт полного сил киллера (tired - усталость) с 30 монетами в кошельке
	sub new { bless { tired=>0, wallet=>30 }, shift }
}

```

В приведённом примере `kill` будет заменена на функцию-обёртку, при `$app->ini->{site}{test} == 1` и на блок `body` в боевом приложении.

```perl

package Person {
	# подключаем контракты
	use R::App;
	# создаёт персону
	sub new { bless { life => 1 }, shift }
	# нанимает охранника
	sub employ {
		in {
			my ($self, $security) = @_;
			assert $security, "секъюрити должен быть обязательно указан";
		};
		out {
			my ($self, $security) = @_;
			assert $self->{security}, "секъюрити нанят";
		};
		body {
			my ($self, $security) = @_;
			$self->{security} = $security;
		};
	}
	# проверяет, что персона жива
	sub is_life { !!shift->{life} }
}

```

В примере экземпляр класса `LeonKiller` принимает заказ посредством метода `kill` на убийство.

```perl

# вот наш киллер
our $killer = LeonKiller->new;

our $top_manager = Person->new;
our $cash = $killer->kill($top_manager, 20);

$cash;									# 50
$top_manager->is_life;					# 

```

Киллер легко убивает топ-менеджера, так как он без охраны. Но с охраняемым челом такой номер не пройдёт.

```perl

our $security = Person->new;
our $top_manager = Person->new;

$top_manager->employ($security);

$killer->kill($top_manager, 1500);		#@ ~ сумма не должна быть подозрительно высокой

$killer->kill($top_manager, 50);		#@ ~ убивать только субъектов без охраны

$top_manager->is_life;					# 1
$killer->{wallet};						# 50

our $top_manager = Person->new;

$killer->kill($top_manager, 50);		#@ ~ у киллера слишком много денег!
$top_manager->is_life;					#
$killer->{wallet};						# 100

```

Как видно изменения произведённые `body` - остались.

А вот тут сработает инвариант после `body`, ведь киллер устал убивая предыдущих топ-менеджеров.

```perl

our $top_manager = Person->new;

$killer->{wallet} = 10;
$killer->{tired};						# 2

$killer->kill($top_manager, 50);		#@ ~ киллер надорвётся на 3-м

