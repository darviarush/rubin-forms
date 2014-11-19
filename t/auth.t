# ; операция:	v - view, a - add, e - edit, r - rm, m - are - modify
# ; роль:		noauth - неавторизированные, auth - авторизированные (user, self), user - другие пользователи, self - пользователь, all - все роли
# ; * - все поля


use strict;
use warnings;

use Test::More tests => 3;
use Msg;

my $ini = Utils::parse_ini(undef, <<'END');

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
our $app;

$app->ini($ini);
$app->auth;
eval { $app->auth->check_role("view", "main", {'v1'=>1, 'v2'=>1}) };
ok $@;
$app->session->user_id(1);
is "R::Auth", ref $app->auth->check_role("view", "main", {'v2'=>1, 'v3'=>1});
$app->auth->valid_param("", "view", "main", {'v1'=>1, 'v2'=>1});

$app->auth->valid_param("", "view", 'main', {'v1'=>12, 'v2'=>10});
eval { $app->auth->valid_param("", "view", 'main', {'v1'=>12, 'v2'=>'xxx'}) };
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
', my $forms, my $formlist);

#warn Dumper($form);
#$query = form_query($formlist->[0]);
#warn Dumper($query);

