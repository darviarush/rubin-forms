#== МОДЕЛЬ
#= порядок
#> список моделей
#> порядок - если 1, то выводится в порядке загрузки, а не алфавитном

$app->modelMetafieldset->load_all_models;

@models = @{$app->modelMetafieldset->{fields}};
@models = sort {$a->{name} cmp $b->{name}} @models unless $ARGV[1];

use List::Util qw/max/;
$max = max map {length $_->{name}} @models;
$max += 2;

msg ":empty", ($_->{pk}? (): ":red"), $_->{name}, ":reset", " " x ($max - length $_->{name}), ($_->{comment}? $_->{comment}: ()) for @models;