# тестирует ModelEdit.pm

use strict;
use warnings;

use Test::More tests => 10;

use Msg;
use ModelEdit;
our $app;

my $ref = "
project.self = add,edit,view
project.selfcol = user_id
project.self.view = name, description
project.ref = user_id
";

my $ini = $app->ini;
$ini->{do} = Utils::parse_ini(undef, $ref);

$app->request->{param} = {
	method => 'save',
	action => 'perm',
	tab => 'project',
	col => 'name',
	role => 'self',
	perm => 'add'
};

my $model_edit = ModelEdit->new($app);
$model_edit->edit($ref);

like $ref, qr/project.self.add = name/;
is $ini->{do}{"project.self.add"}, "name";


$app->request->{param} = {
	method => 'erase',
	action => 'perm',
	tab => 'project',
	col => 'name',
	role => 'self',
	perm => 'view'
};

$model_edit->edit($ref);

like $ref, qr/project.self.view = description/;
is $ini->{do}{"project.self.view"}, "description";

$app->request->{param} = {
	method => 'erase',
	action => 'perm',
	tab => 'project',
	col => 'description',
	role => 'self',
	perm => 'view'
};

$model_edit->edit($ref);

unlike $ref, qr/project.self.view/;
is $ini->{do}{"project.self.view"}, undef;


$app->request->{param} = {
	method => 'erase',
	action => 'tab_perm',
	tab => 'project',
	col => undef,
	role => 'self',
	perm => 'view'
};

$model_edit->edit($ref);

like $ref, qr/project.self = add,edit/;
is $ini->{do}{"project.self"}, "add,edit";

$app->request->{param} = {
	method => 'save',
	action => 'tab_perm',
	tab => 'project',
	col => undef,
	role => 'self',
	perm => 'rm'
};

$model_edit->edit($ref);

like $ref, qr/project.self = add,edit,rm/;
is $ini->{do}{"project.self"}, "add,edit,rm";
