use strict;
use warnings;


use Data::Dumper;
use Msg;
use Test::More tests => 76;

use Msg;
require_ok 'Utils';
require_ok 'Helper';


my $ret = Utils::path({ s => [ { a => [ { x => 10 }, { x => 5 } ], b => 12 }, { a => [ { x => 20 } ], b => 13 } ] }, "s.a.x");
is_deeply $ret, [10, 5, 20];

is_deeply [qw/a c b/], [Utils::unique(qw/a c b c/)];


$ret = Utils::from_rows({
fields => ["id", "name", ["user", "id", ["sess", "id"], "name"]],
rows => [
	["id1", "name1", [["user.id1", [['user.sess.id1']], "user.name1"], ["user.id2", [['user.sess.id2']], "user.name2"]]]
]});

is_deeply $ret, [{"id"=>"id1","name"=>"name1","user"=>[{"id"=>"user.id1","name"=>"user.name1","sess"=>[{"id"=>"user.sess.id1"}]},{"id"=>"user.id2","name"=>"user.name2","sess"=>[{"id"=>"user.sess.id2"}]}]}];

my $data = Utils::to_rows([{id=> "id1", name=> "name1", user=> [{sess=> [{id=> 'user.sess.id1'}], id=> 'user.id1', name=> 'user.name1'}, {id=> 'user.id2', name=> 'user.name2', sess=> [{id=> 'user.sess.id2'}]}]}]);

is_deeply $data, {"fields"=>[["user","name","id",["sess","id"]],"name","id"],"rows"=>[[[["user.name1","user.id1",[["user.sess.id1"]]],["user.name2","user.id2",[["user.sess.id2"]]]],"name1","id1"]]};


my $example = << 'END';
------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="file1"; filename="eula.1028.txt"
Content-Type: text/plain

x1
------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="file2"; filename="eula.1031.txt"
Content-Type: text/plain

x2
------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="file3"; filename=""
Content-Type: application/octet-stream


------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="file4"; filename=""
Content-Type: application/octet-stream


------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="test1"

value1
------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="file5"; filename=""
Content-Type: application/octet-stream


------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="file6"; filename=""
Content-Type: application/octet-stream


------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="submit"

Upload
------WebKitFormBoundaryWdoiUAIAnqflZYdF
Content-Disposition: form-data; name="test2"

value2
------WebKitFormBoundaryWdoiUAIAnqflZYdF--
END

use IO::String;
my $io = IO::String->new;
print $io $example;
seek $io, 0, 0;

my $param = Utils::param_from_post($io, "multipart/form-data; boundary=----WebKitFormBoundaryWdoiUAIAnqflZYdF", length $example);
#msg $param;
is_deeply $param, {
  'file1' => ["x1\n"],
  'test1' => 'value1',
  'file4' => [],
  'file3' => [],
  'submit' => 'Upload',
  'file5' => [],
  'file6' => [],
  'test2' => 'value2',
  'file2' => ["x2\n"]
};


################################################# inject_ini #################################################

my $ref = "
[x]
# коммент 2
f = 1
а1 = 3

[x::y]
# коммент
z = 10
z1 = 20
x2 = 30
";

Utils::inject_ini($ref, "x::y", "z", 12);
like $ref, qr/^z = 12\nz1/m;

Utils::inject_ini($ref, "x::y", "n", 50, "z1");

like $ref, qr/^z1 = 20\nn = 50$/m;

Utils::inject_ini($ref, "x::y", "n", 60, "z1");

like $ref, qr/^z1 = 20\nn = 60$/m;

Utils::inject_ini($ref, "x::y", "r", 70, "z1", 1);

like $ref, qr/^r = 70\nz1 = 20\nn = 60$/m;
unlike $ref, qr/\br = 70\b.*\br = 70\b/ms;

Utils::delete_ini($ref, "x::y", "r");

unlike $ref, qr/^r = 70$/m;

like $ref, qr/^f = 1$/m;

Utils::delete_ini($ref, "x");

unlike $ref, qr/^f = 1$/m;


Utils::inject_ini($ref, "", "k1", 90);

like $ref, qr/^k1 = 90\n/m;



################################################# темплейты #################################################

my $fn = Utils::Template("
	<div id='\$+'>
		#val1
		#val2
	</div>
");
my $html = $fn->({val1=> 'val-1', val2=> 'val-2'}, 'id-test');

like $html, qr/val-1/;
like $html, qr/val-2/;
like $html, qr/id=id-test-val1/;
like $html, qr/id='id-test'/;

$fn = Utils::Template(<<'END', my $forms, my $form);
<div id='$+' ctype=test_class1>
	#val1
	<div id="$*ls" ctype=test_class2>
		#val1
		<p id="$*ls" ctype=test_class3>
			#val1
		</p>
		#val2
	</div>
	#val2
</div>
END
$html = $fn->({"val1"=> 'val-1', "val2"=> 'val-2', "ls"=> [{"val1"=> 'val-1-0', "val2"=> 'val-2-0', "ls"=> []}, {"val1"=> 'val-1-1', "val2"=> 'val-2-1', "ls"=> [{"val1"=> 'val-1-ls-<0>'}]}]}, 'id-test');


like $html, qr/val-1/;
like $html, qr/val-2/;
like $html, qr/id='id-test' ctype=test_class1/;
like $html, qr/val-1-0/;
like $html, qr/val-2-0/;
like $html, qr/val-1-1/;
like $html, qr/val-2-1/;
like $html, qr/val-1-ls-&lt;0&gt;/;
like $html, qr/"id-test-ls-0-ls" ctype=test_class3/;
like $html, qr/"id-test-ls-1-ls" ctype=test_class3/;
unlike $html, qr/id-test-ls-0-ls-0-val1/;
like $html, qr/id-test-ls-1-ls-0-val1/;


$fn = Utils::Template('
	<table id=$*>
		<tr id=$*tr><td>$f
			<table><tr><td>123</table>
			$x
	</table>
');
$html = $fn->([{tr=> [{f=>'f1', x=>'x1'}, {f=>'f2', x=>'x2'}]}, {tr=> [{f=>'f3', x=>'x3'}, {f=>'f4', x=>'x4'}]}], 'id_test');

like $html, qr/f1/;
like $html, qr/f2/;
like $html, qr/f3/;
like $html, qr/f4/;

like $html, qr/x1/;
like $html, qr/x2/;
like $html, qr/x3/;
like $html, qr/x4/;


$fn = Utils::Template('
	<table id=$* cinit>
		<!-- who? -->
		<tr id=$*tr cinit><td>$f
			<table><tr><td>123</table>
			$x
	</table>
');
$html = $fn->([{tr=> [{f=>'f1', x=>'x1'}, {f=>'f2', x=>'x2'}]}, {tr=> [{f=>'f3', x=>'x3'}, {f=>'f4', x=>'x4'}]}], 'id_test');

like $html, qr/f1/;
like $html, qr/f2/;
like $html, qr/f3/;
like $html, qr/f4/;

like $html, qr/x1/;
like $html, qr/x2/;
like $html, qr/x3/;
like $html, qr/x4/;

like $html, qr/<!--/;
like $html, qr/<!!-- who\? --!>/;

$fn = Utils::Template('- \$x:bool($y:bool("*", \'Да\n\'), "Нет"):raw(1) -');
$html = $fn->({x => 1}, "");
is $html, "- \\Да\n -";

$html = $fn->({x => 0}, "");
is $html, "- \\Нет -";

my $r = <<'END';
${x:bool($y:bool('\''), 10):raw}
END

$fn = Utils::Template($r);
$html = $fn->({x=>1, y=>1});
is $html, "'\n";

$html = $fn->({x=>0, y=>1});
is $html, "10\n";

$fn = Utils::Template('$xyz:raw:raw ');
$html = $fn->({xyz=>"<>"});
is $html, "<> ";

$r = <<'END';
{% if $x:lt(10) %}
	{% if $y %}1{% fi %}
{% elif $y:eq($z) %}
2
{% else %}
3
{% fi %}
END

$fn = Utils::Template($r);
$html = $fn->({x=>1, y=>1});
is $html, "\n\t1\n\n";
$html = $fn->({x=>10, y=>13, z=>13});
is $html, "\n2\n\n";
$html = $fn->({x=>10, y=>1, z=>2});
is $html, "\n3\n\n";


my $code = Utils::TemplateStr('<div id=$-frame>$@list/index</div>');
like $code, qr!, include_action\(\$data->{'frame'}, "\$id-frame", 'list/index'\),!;

$code = Utils::TemplateStr('<div id=$-layout>$&</div>', $forms, my $page);
like $code, qr/\@/;
is $page->{layout_id}, "layout";

%Utils::_STASH = (stash => '"');
$fn = Utils::Template('{% a =%}$%stash:raw{% end %} - $%a $"2":raw(2:raw) $\'2\'');
$html = $fn->();
is $html, " - &quot; 2 2";

$fn = Utils::Template('<tr tab="$abc"><div id="x1">');
$html = $fn->({abc=>1});
is $html, '<tr tab="1"><div id="x1">';


$code = Utils::TemplateStr('<div id=$+user:load(%user_id)>$s</div>', $forms, $page);
is $page->{load_forms}[0], "user";
$form = $forms->{$page->{load_forms}[0]};
is $form->{id}, "user";
is $form->{load}{stash}, "user_id";
is $form->{load}{var}, undef;
is $form->{model}, undef;

$code = Utils::TemplateStr('<div id=$+user:load>$s</div>', $forms, $page);
$form = $forms->{$page->{load_forms}[0]};
is $form->{id}, "user";
is $form->{load}{var}, undef;
is $form->{load}{stash}, undef;
is $form->{model}, undef;


$code = Utils::TemplateStr('<div id=$+user:load(var):model(useris)>$s</div>', $forms, $page);
$form = $forms->{$page->{load_forms}[0]};
is $form->{id}, "user";
is $form->{model}, "useris";
is $form->{load}{stash}, undef;
is $form->{load}{var}, "var";


