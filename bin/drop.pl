#== МОДЕЛЬ
#> удаляет все таблицы

$app->ini->{connect} = $app->ini->{connect}{test} if @ARGV==2 && $ARGV[1] eq "test";
#$app->model->{base} = "";

$app->modelMetafieldset->drop;