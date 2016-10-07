package R::Ini;
# парсит ini-файл

use common::sense;
use R::App;

my $main_ini;

# конструктор
sub new {
	my ($cls, $path) = @_;
	return $main_ini if defined $main_ini;
	if(!defined $path) {
		$path = ($app->project_name // "main") . ".ini";
		$path = "etc/$path" if !-e $path;
	};
	$main_ini = -e $path? parse_ini($path): {};
	$main_ini = bless $main_ini, ref $cls || $cls;
	#$main_ini->{path} = $path;
	$main_ini
}


sub parse {my ($self, $path) = @_; bless parse_ini($path), ref $self}
sub parse_str {my ($self, $text) = @_; bless parse_ini(undef, $text), ref $self}
sub dump {goto &dump_ini}
sub print {goto &print_ini}
#sub inject {}
#sub delete {}

# разбирает ini-файл и возвращает хэш
sub parse_ini {
	my ($path, $text) = @_;
	my $f;
	if(defined $path) {
		return {} unless -e $path;
		open $f, "<:utf8", $path or die "not open ini file `$path`. $!\n";
	} else {
		require IO::String;
		$f = IO::String->new($text);
	}
	local ($_, $1, $2, $3, $4, $', $`);

	my $result = {};
	my $entry = $result;

	my $canon = sub {
		return unless ref $entry eq "ARRAY";
		my $arr = $entry;
		$entry = $entry->[$#$entry];
		push @$arr, ($entry = {}) unless ref $entry eq "HASH";
	};

	my $can = sub {
		my ($key, $val) = @_;
		my $v = $entry->{$key};
		if(ref $v eq "ARRAY") { push @$v, $val } else { $entry->{$key} = [$v, $val] }
	};

	while(<$f>) {
		# удаляем начальные и конечные пробельные символы
		s/^\s*(.*?)\s*$/$1/;

		# пропускаем пустые строки и комментарии
		next if $_ eq "" or /^[;#]/;

		# строка с "="
		/^(.*?)\s*=\s*/ && do {
			my ($key, $val) = ($1, $');
			$val = undef if $val eq "";
			$entry->{$key} = $val, next unless exists $entry->{$key};
			&$can($key, $val);
			next;
		};

		# новая глава
		/^\[(.*?)\]$/ && do {
			$entry = $result;
			my @x = split '::', $1;
			my $key = pop @x;
			$entry = $entry->{$_} // ($entry->{$_} = {}), &$canon for @x;
			if(exists $entry->{$key}) { my $val = {}; &$can($key, $val); $entry = $val; }
			else { $entry = ($entry->{$key} = {}); }
		};
		next;

		# ошибка в ini
		close $f;
		die "$.. Error parsing ini-file `$path`\n";
	}

	close $f;

	return $result;
}

# сериализирует данные в ini
sub dump_ini {
	my ($ini, $order) = @_;
	return "" unless keys %$ini;
	my @tree = ([], $ini);
	my @dump = ();
	my $tek = '';
	while(@tree) {
		my ($path, $tree) = splice @tree, -2;
		my $arr = ref $tree eq "HASH"? [$tree]: $tree;
		for $tree (@$arr) {
			push @dump, "\n[".join("::", @$path)."]\n" if @$path;
			while(my($key, $val) = each %$tree) {
				push(@dump, "$key = $val\n"), next unless ref $val;
				push @tree, ([@$path, $key]), $val;
			}
		}
	}

	return join "", @dump;
}

# печатает ini в файл
sub print_ini {
	my ($path, $ini) = @_;
	open my($f), ">", $path or die "not create ini-file `$path`. $!\n";
	print $f dump_ini($ini);
	close $f;
}

# вставляет или заменяет в ini-тексте значение
sub inject_ini {
	my ($ini, $section, $key, $val, $ins_key, $before) = @_;
	local ($_, $&, $`, $', $1);
	my $re = $section eq ""? qr'\A'm: "^\\[$section\\]\\s*\$";
	my $to = qr/^\[[^\n]*?\]|\Z/m;
	$val = '""' if $val eq "" and defined $val;
	$val =~ s/^\s*(.*?)\s*$/$1/;
	$val = "$key = $val\n";
	my $flag;
	$_[0] =~ s/$/\n\n[$section]\n$val/, return unless $_[0] =~ s/$re.*?$to/ $_=$&; $flag=1 unless s!^\s*$key\s*=.*\n?!$val!m; $_ /mse;
	return unless $flag;
	if($ins_key) {
		$flag = 0;
		$_[0] =~ s/$re.*?$to/ $_=$&; $flag = 1 unless s!^\s*$ins_key\s*=.*(?:\n|\z)! $before? "$val$&": "$&$val" !me; $_ /mse;
		return unless $flag;
	}
	$_[0] =~ s/$re/$&$val/m if $before;
	$_[0] =~ s/($re.*?\n?)(\s*$to)/$1$val$2/ms unless $before;
}

# удляляет из ini-текста ключ. Если key не указан, то - секцию
sub delete_ini {
	my ($ini, $section, $key) = @_;
	local ($_, $&, $`, $', $1);
	my $to = qr/^\[[^\n]*?\]|\Z/m;
	if(defined $key) {
		my $re = $section eq ""? qr'\A'm: "^\\[$section\\]\\s*\$";
		$_[0] =~ s/$re.*?$to/ $_=$&; s!^\s*$key\s*=.*\n?!!m; $_ /mse;
	} else {
		$_[0] =~ s/^\[$section\].*?($to)/$1/ms;
	}
}


1;
