package R::Tty;
# утилиты для работы с терминалом

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

# спрашивает пользователя через stdin
sub confirm {
	my ($self, $confirm) = @_;
	my $yes = "";
	do { print("$confirm (yes/no) "); } while ($yes = <STDIN>) !~ /^yes|no$/;
	return $yes =~ /yes/;
}

# спрашивает пользователя через stdin
sub select {
	my ($self, $data, $confirm) = @_;
	
	$data = [split /\n/, $data] if !ref $data;
	
	my $i = 0;
	for my $d (@$data) {
		$i++;
		print "$i) $d\n";
	}
	
	$confirm //= "Выберите вариант";
	
	my $yes;
	do { print("$confirm (1..$i) "); } while ($yes = int(<STDIN>)) < 1 or $yes > $i;
	return wantarray? ($yes, $data->[$yes-1]): $yes;
}

# устанавливает кодировку всем потокам ввода-вывода
sub mode {
	my ($self, $encode) = @_;
	
	binmode STDIN, $encode;
	binmode STDOUT, $encode;
	binmode STDERR, $encode;
	
	$self
}

# устанавливает кодировку raw потокам ввода-вывода
sub raw {
	my ($self) = @_;
	
	$self->mode(":raw");
	
	$self
}

1;