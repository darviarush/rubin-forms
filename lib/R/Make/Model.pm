package R::Make::Model;
# команды для работы с моделью

use common::sense;
use R::App;
use R::Make;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

category "МОДЕЛЬ";
# models порядок       список моделей
# show модель          печатает столбцы модели
# sync                 синхронизирует базу
# drop                 удаляет все таблицы

name "models";
args "порядок";
desc "список моделей";
spec "порядок - если 1, то выводится в порядке загрузки, а не алфавитном";
sub models {

	#$app->modelMetafieldset->load_all_models;

	my @models = @{$app->meta->{fields}};
	@models = sort {$a->{name} cmp $b->{name}} @models unless $_[0];

	use List::Util qw/max/;
	my $max = max map {length $_->{name}} @models;
	$max += 2;

	$app->log->info( ":empty", ($_->{pk}? (): ":red"), $_->{name}, ":reset", " " x ($max - length $_->{name}), ($_->{remark}? $_->{remark}: ())) for @models;

}


name "show";
args "модель";
desc "печатает столбцы модели";
sub show {
	
	use List::Util qw/max/;

	#$app->modelMetafieldset->load_all_models;

	my $fieldset = $app->meta->exists($_[0]);

	my $mask = $ARGV[1];

	$app->log->error("нет модели $_[0]"), exit if !$fieldset;
	$app->log->info($fieldset->{remark}) if defined $fieldset->{remark};

	my @fields = @{$fieldset->{fieldset}};

	@fields = grep { $_->name =~ /$mask/o } @fields if $mask;

	my $max = 2;
	$max += max map {length $_->name} @fields;

	sub is ($) { ref $_ eq "R::Model::Field::".ucfirst($_[0]) }

	my %color_name = qw(R::Model::Field::Col :reset R::Model::Field::Ref :cyan R::Model::Field::Back :green R::Model::Field::M2m :magenta R::Model::Field::M2n :magenta R::Model::Field::Compute :red);
	$color_name{"R::Model::Field::Assign"} = ":bold";
	my $color_tab = ":cyan";
	my $color_col = ":red";

	my @fld = grep { !is("back") && !is("assign") } @fields;
	my @back = grep { (is("back") || is("assign")) and !$_->ref->fieldset->{for_m2m} } @fields;
	my @back_m2m = grep { (is("back") || is("assign")) and $_->ref->fieldset->{for_m2m} } @fields;

	my $show = sub {
		my ($field) = @_;
		my $cls = ref $field;
		
		my ($col, $arr, $info) = "";
		
		if($field->info =~ / /) { ($arr, $info) = ($`, $'); ($info, $col) = ($`, $') if $info =~ /\./; } else { ($arr, $info) = ($field->info, "") }
		
		$app->log->info( ":empty", $color_name{$cls}, $field->name, ":reset", (" " x  ($max - length $field->name)), ($arr? ($arr, " ", $color_tab, $info, ":reset", ($col? (".", $color_col, $col): ())): ()), (defined($field->{remark})? (":bold black", "\t", $field->{remark}): () ));
	};
	
	$show->($_) for @fld;
	$app->log->info("") if @back;
	$show->($_) for @back;
	$color_name{"R::Model::Field::Back"} = ":yellow";
	$app->log->info("") if @back_m2m;
	$show->($_) for @back_m2m;
}

name "sync";
desc "синхронизирует базу";
sub sync {
	$app->meta->sync_for_script;
}

name "drop";
args "[test]";
desc "удаляет все таблицы";
spec "дополнительный параметр test указывает, что в конфигурационном файле нужно секцию [connect] заменить на [connect::test]";
sub drop {

	die "Не могу удалить базу, так как это не тестовая машина" if !$app->ini->{site}{test};

	$app->ini->{connect} = $app->ini->{connect}{test} if @_==1 && $_[0] eq "test";
	#$app->model->{base} = "";

	$app->meta->drop if $app->tty->confirm("Удалить базу и все данные безвозвратно?");


}

name "migrate";
args "[desc]";
desc "создаёт миграцию";
spec "необязательный параметр desc позволяет добавить комментарий к миграции";
sub migrate {
	
	my ($desc) = @_;
	
	my $migrate = $app->perl->strftime("M%Y%m%d_%H%M%S", time);
	my $base = $app->meta->name;
	
	my $file = $app->file("migrate/$migrate.pm");
	
	die "Миграция " . $file->path . " уже существует" if $file->exists;
	
	my $f = $file->open(">");
	print $f "package $migrate {
	
use common::sense;
use R::App;

# краткое описание миграции
sub desc {
	\"$desc\"
}



# применяет миграцию
sub up {
	my \$oldmeta = \$app->meta->new(\"$migrate\")->migrateload;
	
}


# отменяет миграцию
sub down {
	my \$oldmeta = \$app->meta->new(\"$migrate\")->migrateload;
	
}


1;}



";
	
	$app->file("model")->find(sub {
		next if !/\.pm$/;
		my $path = $_;
		$_ = $app->file($_)->read;
		close($f), $file->rm, die "повреждён файл модели $path: нет package" if !s!package\s+${base}::([\w:]+)\s*;!package ${migrate}::$1 {!;
		s!$!}\n\n!;
		print $f $_;
		0
	});
	
	print $f "1;";
	close $f;
	
	print "миграция $migrate создана";
}


name "migup";
args "[N]";
desc "применяет новые миграции";
spec "N - сколько применить";
sub migup {
	
	my ($N) = @_;
	
	$app->meta->fieldset("_migrate")->sync;
	
	# алгоритм
	# 1. получить файлы
	# 2. удалить из них применённые
	# 3. взять N
	# 4. применить, на каждом шаге добавляя

	my $ref = $app->model->_migrate->refby("id");
	my @files;
	for my $path ($app->file("migrate")->find(qr/\.pm$/)->files) {
		push @files, $path if !exists $ref->{$path};
	}
	
	@files = sort @files;
	
	@files = @files[$#files - $N .. $#files] if $N && $N < @files;
	
	for my $file (@files) {
		$file =~ /M\d+_\d+/;
		my $migrate = $&;
	
		require $file;
		
		$migrate->up;
		
		$app->model->_migrate( $file )->saveAs($file);
		msg "миграция $file применена";
	}
	
}


name "migdown";
args "[N]";
desc "отменяет миграции";
spec "N - сколько применить";
sub migdown {
	my ($N) = @_;
	
	die "N - обязательный параметр" if !$N;
	
	$app->meta->fieldset("_migrate")->sync;
	
	my @files = $app->model->_migrate->order("-id")->limit($N)->id;
	
	for my $file (@files) {
		$file =~ /M\d+_\d+/;
		my $migrate = $&;
	
		require $file;
		
		$migrate->down;
		
		$app->model->_migrate( $file )->erase;
		msg "миграция $file отменена";
	}
}


name "migstat";
args "[N]";
desc "лог миграций";
spec "N - сколько показать";
sub migstat {
	
}


1;