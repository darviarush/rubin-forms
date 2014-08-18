# ; операция:	v - view, a - add, e - edit, r - rm, m - are - modify
# ; роль:		noauth - неавторизированные, auth - авторизированные (user, self), user - другие пользователи, self - пользователь, all - все роли
# ; * - все поля


BEGIN {
use Test::More tests => 5;
use Utils;
use Msg;
use Connect;

$ini = Utils::parse_ini(undef, <<'END');

[do]

main.user = view
main.user.view = v2,v3

main.selfcol = rex_id,rex.user_id,user.id
main.self = add,edit,rm,view
main.self.view = v1,v2
main.self.add = v1,v2
main.self.edit = v1,v2

main.int = v1,v2
main.float = v3

END

require_ok "Valid";
require_ok "Auth";

}


eval { check_role "view", "main", {'v1'=>1, 'v2'=>1} };
ok $@;
$_user_id = 1;
is "main", check_role "view", "main", {'v2'=>1, 'v3'=>1};
valid_param "view", "main", {'v1'=>1, 'v2'=>1};

valid_param "view", 'main', {'v1'=>12, 'v2'=>10};
eval { valid_param "view", 'main', {'v1'=>12, 'v2'=>'xxx'} };
ok $@;


Utils::Template('
<div id=$+>
	<div id=$*names>
		#v1 $v2
	</div>
</div>

<div id=$*logo>
#name
</div>
', $form);

#warn Dumper($form);
$query = page_query($form, 'lir');
#warn Dumper($query);

