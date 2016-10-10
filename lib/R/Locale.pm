package R::Locale;
# локализация

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

### константы
sub PERMISSION_DENIED { "нет прав" }


### функции приведения

# возвращает аббревиатуру
sub abbr {
	my ($self, $day, $x, $y, $z) = @_;
	my $day100 = $day % 100;
	my $day10 = 10<=$day100 && $day100<=20? 10: $day % 10;
	$day10==0? $z: $day10==1? $x: $day10<=4? $y: $z;
}

# для дней
sub days {
	my ($self, $days) = @_;
	$self->abbr($days, "день", "дня", "дней")
}

# для месяцев
sub months {
	my ($self, $days) = @_;
	$self->abbr($days, "месяц", "месяца", "месяцев")
}

# для лет
sub years {
	my ($self, $days) = @_;
	$self->abbr($days, "год", "года", "лет")
}

# месяц c 1-цы. 5-го мая
my @MONTH = qw/января февраля марта апреля мая июня июля августа сентября октября ноября декабря/;
sub month {
	my ($self, $month) = @_;
	$MONTH[$month-1]
}

# 3 1-х символа
sub mon {
	my ($self, $month) = @_;
	substr $MONTH[$month-1], 0, 3
}

my @MONTH_NAME = qw/январь февраль март апрель май июнь июль август сентябрь октябрь ноябрь декабрь/;
sub month_name {
	my ($self, $month) = @_;
	$MONTH_NAME[$month-1]
}


# месяц c 1-цы. 5-го мая
my @WEEK = qw/понедельник вторник среда четверг пятница суббота воскресенье/;
my @WEEK_ABBR = qw/Пн Вт Ср Чт Пт Сб Вс/;
sub weekdayabbr {
	my ($self, $day) = @_;
	@WEEK_ABBR[$day-1]
}


# часов
sub hours {
	my ($self, $abbr) = @_;
	$self->abbr($abbr, "час", "часа", "часов")
}

# минут
sub minutes {
	my ($self, $abbr) = @_;
	$self->abbr($abbr, "минута", "минуты", "минут")
}

# секунд
sub seconds {
	my ($self, $abbr) = @_;
	$self->abbr($abbr, "секунда", "секунды", "секунд")
}


### функции трансляции на иные языки

# транслятор
sub _ {
	my ($key) = @_;
	
}

# парсер проекта - выбирает в html фразы для перевода
sub parse {
	my ($self) = @_;
	$self
}


1;