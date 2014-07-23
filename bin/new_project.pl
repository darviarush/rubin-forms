#= name
#> создаёт директории и файлы нового проекта

$name = $ARGV[1];
$min = $ARGV[2];

die "use: qq new_project <name>" unless defined $name;

mkdir $name;
Utils::write("$name/qq", "#!perl\nrequire '../rubin/qq'\n");
chmod 0700, "$name/qq";
Utils::write("$name/.gitignore", "/main.ini/\n/js/*.js\n/*.js\n");
Utils::write("$name/install.sql", "");
Utils::cp("rubin/main.sample.ini", "$name/main.ini");
mkdir "$name/action";
mkdir "$name/t";
unless(defined $min) {
	mkdir "$name/lib";
	mkdir "$name/templates";
	mkdir "$name/coffee";
	mkdir "$name/js";
	mkdir "$name/css";
	mkdir "$name/img";
	mkdir "$name/html";
	mkdir "$name/error";
}
Utils::write("$name".(defined($min)? '': '/coffee')."/comp.cmd", "coffee ../".(defined($min)? '': '../')."rubin/bin/comp.coffee");