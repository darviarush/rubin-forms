# тестирует R::Connect

use strict;
use warnings;



use Data::Dumper;
use Test::More tests => 3;
use Msg;

our $app;

my ($sql, $fields, $real_fields) = $app->connect->sel_join("user", "id, name",
	["LEFT", "project", "id, name",
		["LEFT", "msg_project", "id, msg"]
	],
	["INNER", "bs as lego", "id, leo", "fx=rxs", {fx=>\"rxs"}]
	, {id => 1});
	
is_deeply $real_fields, ['id', 'name', ['lego', 'id', 'leo'], ['project', 'id', 'name', ['msg_project', 'id', 'msg']]];
	
is $sql, "SELECT user.id, user.name, lego.id, lego.leo, project.id, project.name, msg_project.id, msg_project.msg
FROM user
LEFT JOIN project ON project.user_id=user.id
INNER JOIN bs as lego ON lego.lego_id=user.id
LEFT JOIN msg_project ON msg_project.project_id=project.id
WHERE (user.id='1') AND (fx=rxs) AND (lego.fx=lego.rxs)";

no warnings 'numeric';

my $rows = [[]];
$app->connect->pack_rows($fields, $rows, [0+'1.user.id', 'user.name', 0+'1.lego.id', 'lego.leo1', 0+'1.project.id', 'project.name', 0+'1.msg_project.id', 'msg_project.msg']);
$app->connect->pack_rows($fields, $rows, [0+'1.user.id', 'user.name', 0+'1.lego.id', 'lego.leo1', 0+'1.project.id', 'project.name', 0+'2.msg_project.id', 'msg_project.msg']);
$app->connect->pack_rows($fields, $rows, [0+'1.user.id', 'user.name', 0+'2.lego.id', 'lego.leo1', 0+'1.project.id', 'project.name', 0+'3.msg_project.id', 'msg_project.msg']);
$app->connect->pack_rows($fields, $rows, [0+'1.user.id', 'user.name', 0+'4.lego.id', 'lego.leo1', 0+'3.project.id', 'project.name', 0+'6.msg_project.id', 'msg_project.msg']);
$app->connect->pack_rows($fields, $rows, [0+'1.user.id', 'user.name', undef, undef, 0+'4.project.id', 'project.name', 0+'7.msg_project.id', 'msg_project.msg']);
$app->connect->pack_rows($fields, $rows, [0+'2.user.id', 'user.name', 0+'3.lego.id', 'lego.leo1', undef, undef, undef, undef]);
$app->connect->pack_rows($fields, $rows, [0+'2.user.id', 'user.name', 0+'3.lego.id', 'lego.leo1', 0+'2.project.id', 'project.name', 0+'5.msg_project.id', 'msg_project.msg']);

is_deeply $rows,
[[0+'1.user.id', 'user.name', 
	[[0+'1.lego.id', 'lego.leo1'], [0+'2.lego.id', 'lego.leo1'], [0+'4.lego.id', 'lego.leo1']], 
	[[0+'1.project.id', 'project.name', 
		[[0+'1.msg_project.id', 'msg_project.msg'], [0+'2.msg_project.id', 'msg_project.msg'], [0+'3.msg_project.id', 'msg_project.msg']]], 
	 [0+'3.project.id', 'project.name', 
		[[0+'6.msg_project.id', 'msg_project.msg' ]]], 
	 [0+'4.project.id', 'project.name', 
		[[0+'7.msg_project.id', 'msg_project.msg' ]]] 
	]],
 [0+'2.user.id', 'user.name',
	[[0+'3.lego.id', 'lego.leo1']],
	[[0+'2.project.id', 'project.name', [[0+'5.msg_project.id', 'msg_project.msg' ]] ]] ]
];



