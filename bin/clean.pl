#> очищает кэши

for my $dir (dirs("action_c")) {
	`rm -fr $dir`;
}

1;