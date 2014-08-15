#> комитит в репозитории git

chdir "..";

@dirs = split /\n/, `ls`;
for(@dirs) {
	chdir $_;
	print "\n-> $_\n";
	print `git add .`;
	print `git commit -am save`;
	print `git push`;
	chdir "..";
}
