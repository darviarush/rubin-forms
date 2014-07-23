use Data::Dumper;
use Test::More tests => 11;

use Msg;
use Auth;
use Utils;
require_ok 'ModelEdit';

$ref = "
[do]
project.self = add,edit,view
project.selfcol = user_id
project.self.view = name, description
project.ref = user_id
";

$ini = Utils::parse_ini(undef, $ref);

$param = {
	method => 'save',
	action => 'perm',
	tab => 'project',
	col => 'name',
	role => 'self',
	perm => 'add'
};

model_edit($ref);

like $ref, qr/project.self.add = name/;
is $ini->{do}{"project.self.add"}, "name";


$param = {
	method => 'erase',
	action => 'perm',
	tab => 'project',
	col => 'name',
	role => 'self',
	perm => 'view'
};

model_edit($ref);

like $ref, qr/project.self.view = description/;
is $ini->{do}{"project.self.view"}, "description";

$param = {
	method => 'erase',
	action => 'perm',
	tab => 'project',
	col => 'description',
	role => 'self',
	perm => 'view'
};

model_edit($ref);

unlike $ref, qr/project.self.view/;
is $ini->{do}{"project.self.view"}, undef;


$param = {
	method => 'erase',
	action => 'tab_perm',
	tab => 'project',
	col => undef,
	role => 'self',
	perm => 'view'
};

model_edit($ref);

like $ref, qr/project.self = add,edit/;
is $ini->{do}{"project.self"}, "add,edit";

$param = {
	method => 'save',
	action => 'tab_perm',
	tab => 'project',
	col => undef,
	role => 'self',
	perm => 'rm'
};

model_edit($ref);

like $ref, qr/project.self = rm,add,edit/;
is $ini->{do}{"project.self"}, "rm,add,edit";
