package R::Model::Type::Datetime;
# тип времени для колумнов
use base DateTime;

use common::sense;
use R::App;
#use DateTime::Format::Strptime;

# возвращает тип колумна в базе 
sub typeCol { "datetime" }

#require DateTime::TimeZone::Local::Win32 if $^O =~ /^(?:cygwin|MSWin32|os2)$/;
#require DateTime::TimeZone::HPUX if $^O eq "hpux";
#use DateTime::TimeZone::Local::Unix;
our $time_zone = DateTime::TimeZone->new( name => 'Europe/Moscow' );

# форматтер в
#my $parser = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );
#my $formatter = DateTime::Format::Strptime->new( pattern => '%{format}' );

# устанавливаем дефолтную локаль
DateTime->DefaultLocale( "ru_RU" );

# в представление столбца
sub toCol {
	my ($self) = @_;
	$self->strftime("%F %T")
}

# конструктор - возвращает новый объект
sub fromCol {
	my ($field, $val) = @_;
	#require "DateTime/Format/MySQL.pm";
	#my $dt = DateTime::Format::MySQL->parse_datetime($val); #$parser->parse_datetime($val);
	return if !defined $val;
	my @dt = split /\D/, $val;
	$field->{class}->SUPER::new(
		year       => $dt[0],
		month      => $dt[1],
		day        => $dt[2],
		hour       => $dt[3],
		minute     => $dt[4],
		second     => $dt[5],
		time_zone  => $time_zone,
		formatter => "R::Model::Type::Datetime::Format",
	);
}

# # 
# sub now {
	# my ($self) = @_;
	# $self
# }

package R::Model::Type::Datetime::Format;

use R::App;

# форматирует дату
sub format_datetime {
	my ($cls, $dt) = @_;
	
	#my $now = DateTime->now;
	#$now->set_time_zone($time_zone);
	my $diff = time - $dt->epoch;
	my $now = DateTime->now->set_time_zone($time_zone);
	
	if($diff < 0) {
	
		$diff = -$diff;
	
		if($diff < 60*60) {		# час	
			my $sub = $dt->subtract_datetime($now);
			my $min = $sub->delta_minutes;
			return sprintf "через %02i %s", $min, $app->locale->minutes($min);
		}
		if($diff < 2*60*60) {	# 2 часа
			my $sub = $dt->subtract_datetime($now);
			my $min = $sub->delta_minutes;
			return sprintf "через час %02i %s", $min, $app->locale->minutes($min);
		}
		if($diff < 24*60*60 && $dt->day == $now->day) {	# сутки
			return sprintf "сегодня в %02i:%02i", $dt->hour, $dt->minute;
		}
		if($diff < 2*24*60*60 && $dt->day-1 == $now->day) {	# 2 суток
			return sprintf "завтра в %02i:%02i", $dt->hour, $dt->minute;
		}
		if($diff < 3*24*60*60 && $dt->day-2 == $now->day) {	# 3 суток
			return sprintf "послезавтра в %02i:%02i", $dt->hour, $dt->minute;
		}
		if($diff < 7*24*60*60) {	# неделя
			return sprintf "след %s в %02i:%02i", $dt->day_abbr, $dt->hour, $dt->minute;
		}
		if($diff < 30*24*60*60) {	# месяц
			my $sub = $dt->subtract_datetime($now);
			my $days = $sub->delta_days;
			return sprintf "через %i %s в %02i:%02i", $days, $app->locale->days($days), $dt->hour, $dt->minute;
		}
		if($diff < 365*24*60*60) {	# год
			return sprintf "след %i %s в %02i:%02i", $dt->day, $app->locale->mon($dt->month), $dt->hour, $dt->minute;
		}
	
		my $sub = $dt->subtract_datetime($now);
		my $years = $sub->years;
		sprintf "через %i %s %i %s в %02i:%02i", $years, $app->locale->years($years), $dt->day, $app->locale->mon($dt->month), $dt->hour, $dt->minute;
	}
	
	if($diff < 60*60) {		# час
		my $sub = $now->subtract_datetime($dt);
		my $min = $sub->delta_minutes;
		return sprintf "%02i %s назад", $min, $app->locale->minutes($min);
	}
	if($diff < 2*60*60) {	# 2 часа
		my $sub = $now->subtract_datetime($dt);
		my $min = $sub->delta_minutes;
		return sprintf "час %02i %s назад", $min, $app->locale->minutes($min);
	}
	if($diff < 24*60*60 && $dt->day == $now->day) {	# сутки
		return sprintf "сегодня в %02i:%02i", $dt->hour, $dt->minute;
	}
	if($diff < 2*24*60*60 && $dt->day+1 == $now->day) {	# 2 суток
		return sprintf "вчера в %02i:%02i", $dt->hour, $dt->minute;
	}
	if($diff < 3*24*60*60 && $dt->day+2 == $now->day) {	# 3 суток
		return sprintf "позавчера в %02i:%02i", $dt->hour, $dt->minute;
	}
	if($diff < 7*24*60*60) {	# неделя
		return sprintf "пред %s в %02i:%02i", $dt->day_abbr, $dt->hour, $dt->minute;
	}
	if($diff < 30*24*60*60) {	# месяц
		my $sub = $now->subtract_datetime($dt);
		my $days = $sub->delta_days;
		return sprintf "%i %s назад в %02i:%02i", $days, $app->locale->days($days), $dt->hour, $dt->minute;
	}
	if($diff < 365*24*60*60) {	# год
		return sprintf "пред %i %s в %02i:%02i", $dt->day, $app->locale->mon($dt->month), $dt->hour, $dt->minute;
	}
	
	my $sub = $now->subtract_datetime($dt);
	my $years = $sub->years;
	sprintf "%i %s назад %i %s в %02i:%02i", $years, $app->locale->years($years), $dt->day, $app->locale->mon($dt->month), $dt->hour, $dt->minute;
}

1;