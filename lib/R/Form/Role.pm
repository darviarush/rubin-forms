package R::Form::Role;
# роль - позволяет создавать ACL - списки доступа
# роль может наследовать несколько других ролей
# sub fields нужна для создания необходимых валидируемых полей-параметров для allow
# sub allow указывает, что роль 
# fields и allow вызываются со всех классов, которые наследуются:
# fields с new, а allow с hasAllow
# в форме роль указывается в sub role и может быть только одна
#
# использование:
#
# class AimRole inherits R::Form::Role
#	sub fields then self.add("aim"=>":aim")
#	sub allow* then aim.owner:id == user:id
# end
#
# class AimAdd inherits RubinForm
#	sub allow then new AimRole.hasAllow
#	...
# end
#
# или
#
# class AimAdd inherits RubinForm
#	sub allowRole then "AimRole"
#	...
# end
#
# или
#
# class AimAdd inherits RubinForm, AimRole ...
#	...
# end


#use base R::Form::Form;

use common::sense;
use R::App;




1;