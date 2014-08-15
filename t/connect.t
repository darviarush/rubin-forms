use Data::Dumper;
use Test::More tests => 5;

require_ok 'Utils';
$ini = Utils::parse_ini('main.ini');

require_ok 'Connect';

use Msg;

($sql, $fields, $real_fields) = sel_join("user", "id, name",
	LEFT_JOIN("project", "id, name",
		LEFT_JOIN("msg_project", "id, msg")
	),
	INNER_JOIN("bs as lego", "id, leo", "fx=rxs", {fx=>\"rxs"})
	, {id => 1});
	

is_deeply $real_fields, ['id', 'name', ['lego', 'id', 'leo'], ['project', 'id', 'name', ['msg_project', 'id', 'msg']]];
	
is $sql, "SELECT user.id, user.name, lego.id, lego.leo, project.id, project.name, msg_project.id, msg_project.msg
FROM user
LEFT JOIN project ON project.user_id=user.id
INNER JOIN bs as lego ON lego.lego_id=user.id
LEFT JOIN msg_project ON msg_project.project_id=project.id
WHERE (user.id='1') AND (fx=rxs) AND (lego.fx=lego.rxs)";

$rows = [[]];
pack_rows($fields, $rows, ['1.user.id', 'user.name', '1.lego.id', 'lego.leo1', '1.project.id', 'project.name', '1.msg_project.id', 'msg_project.msg']);
pack_rows($fields, $rows, ['1.user.id', 'user.name', '1.lego.id', 'lego.leo1', '1.project.id', 'project.name', '2.msg_project.id', 'msg_project.msg']);
pack_rows($fields, $rows, ['1.user.id', 'user.name', '2.lego.id', 'lego.leo1', '1.project.id', 'project.name', '3.msg_project.id', 'msg_project.msg']);
pack_rows($fields, $rows, ['1.user.id', 'user.name', '4.lego.id', 'lego.leo1', '3.project.id', 'project.name', '6.msg_project.id', 'msg_project.msg']);
pack_rows($fields, $rows, ['1.user.id', 'user.name', undef, undef, '4.project.id', 'project.name', '7.msg_project.id', 'msg_project.msg']);
pack_rows($fields, $rows, ['2.user.id', 'user.name', '3.lego.id', 'lego.leo1', undef, undef, undef, undef]);
pack_rows($fields, $rows, ['2.user.id', 'user.name', '3.lego.id', 'lego.leo1', '2.project.id', 'project.name', '5.msg_project.id', 'msg_project.msg']);

is_deeply $rows,
[['1.user.id', 'user.name', 
	[['1.lego.id', 'lego.leo1'], ['2.lego.id', 'lego.leo1'], ['4.lego.id', 'lego.leo1']], 
	[['1.project.id', 'project.name', 
		[['1.msg_project.id', 'msg_project.msg'], ['2.msg_project.id', 'msg_project.msg'], ['3.msg_project.id', 'msg_project.msg']]], 
	 ['3.project.id', 'project.name', 
		[['6.msg_project.id', 'msg_project.msg' ]]], 
	 ['4.project.id', 'project.name', 
		[['7.msg_project.id', 'msg_project.msg' ]]] 
	]],
 ['2.user.id', 'user.name',
	[['3.lego.id', 'lego.leo1']],
	[['2.project.id', 'project.name', [['5.msg_project.id', 'msg_project.msg' ]] ]] ]
];




