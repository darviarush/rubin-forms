#!/usr/bin/env perl

#> спамер - отправляет e-mail-сообщения

# use strict;
# use warnings;

use lib "../lib";
use Utils;
$ini = Utils::parse_ini("../lib/main.ini");
use Mailer;
require Connect;
$mailer = Mailer->new( '..', $ini->{mailer} );

my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = localtime(time);
$year += 1900;
$mon = 0 . $mon if ( length($mon) < 2 );
$mon++;

&send( 1,  1 );
&send( 7,  2 ) if $wday == 3;
&send( 31, 3 ) if $mday == 3;

# Загружает из БД данные о товарах.
# Аргумент: количество прошедших дней, за которые надо получать товар.
# Возвращает хеш с товарами.
sub get_products {
    my $days = shift;
    return $dbh->selectall_arrayref( <<'EOF', { Slice => {} }, $days );
SELECT product_id, name, description, price, presence, time, photos
FROM products
WHERE TO_DAYS(NOW())-TO_DAYS(time)<=?
ORDER BY time
EOF
}

# Принимает в качестве аргумента указанный в БД интервал
# рассылки сообщений. Возвращает список получателей и коды отписки.
sub get_receivers {
    my $news_interval = shift;
    return $dbh->selectall_arrayref(
        'SELECT email, code FROM emails WHERE news_interval = ?',
        { Slice => {} },
        $news_interval
    );
}

# Генерирует тело письма в формате HTML.
# В качестве аргумента принимает хеш с продукциейю
# Возвращает тело письма.
sub generate_html {
    my $products = shift;
    my $items;
    foreach (@$products) {
        $items .= <<END;
<br>
<br>
$_->{time}
<a href="http://$ini->{site}{host}/#product_id=$_->{product_id}"><h3>$_->{name}</h3></a>
<br>$_->{description}
<br>Цена: $_->{price}
END

        if ( $_->{photos} ) {
            my @photos = split /,/, $_->{photos};
            foreach (@photos) {
                $items .= <<END;
<br><img src="http://$ini->{site}{host}/$_"></img>
<br>
<br>
END
            }
        }
    }
    return $items;
}

# Генерирует текстовое тело письма из хеша продукции.
# ВОзвращает его же.
sub generate_text {
    my $products = shift;
    my $items;
    foreach (@$products) {
        $items .= <<END;

$_->{time}
$_->{name}
http://$ini->{site}{host}/#product_id=$_->{product_id}
Описание:
$_->{description}
Цена: $_->{price}

END
    }
    return $items;
}

# Отправляет сообщения списку адресатов.
# Принимает в качестве аргументов количество прошедших дней,
# за которые надо собрать товары и номер интервала.
sub send {
    my $days     = shift;
    my $interval = shift;
    my $products = get_products($days);
    return null unless @$products;
    my $receivers = get_receivers($interval);
    my $text_body = generate_text($products);
    my $html_body = generate_html($products);

    foreach (@$receivers) {
        my $msg = $mailer->email(
            'news',
            {
                To      => $_->{email},
                Subject => "Новости магазина очковых линз ($mday.$mon.$year)"
            },
            {
                TextNews => $text_body,
                HTMLNews => $html_body,
                EMail    => $_->{email},
                Code     => $_->{code}
            }
        );
        $msg->send;
        # print $msg->as_string;
    }
}
