#== МОДЕЛЬ
#> удаляет все таблицы

$app->model->{base} = "";

$app->modelMetafieldset->sync;