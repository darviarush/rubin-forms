#> очищает кэши

for my $dir (dirs("c_action")) {
	`rm -fr $dir`;
}

1;