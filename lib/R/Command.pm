package R::Command;
# возвращает информацию о командах в bin

# конструктор
sub new {
	my ($cls, $app) = @_;
	bless {}, $cls;
}

# выдаёт список котегорий со списками команд
sub all {
	use File::Find;

	my %CAT;
	my $CAT;

	find({ no_chdir=>1, wanted=> sub {
		return unless $File::Find::name =~ /([^\/]+)\.pl$/;
		my $name = $1 // "";
		$_ = Utils::read($File::Find::name);
		my ($cat) = /^#== (.*?)\s*$/m;
		my ($args) = /^#= ([^\r\n]+)/m;
		my ($help) = /^#> ([^\r\n]+)/m;
		
		push @{$CAT{$cat // ""}}, {cat=>$cat, name=>$name, args=>$args, help=>$help};
	}}, ::files "bin");

	@$CAT = map { {cat=>$_, cmd=>[sort {$a->{name} cmp $a->{name}} @{$CAT{$_}}]} } keys %CAT;
	@$CAT = sort { $a->{cat} cmp $b->{cat} } @$CAT;
	
	$CAT
}

# выдаёт команду
sub by_name {
	my ($self, $name) = @_;
	my $path = ::file("bin/$name.pl");
	return unless $path;
	$_ = Utils::read($path);
	my ($cat) = /^#== (.*?)\s*$/m;
	my ($args) = /^#= ([^\r\n]+)/m;
	my $helps = [];
	push @$helps, $1 while /^#> ([^\r\n]+)/gm;
		
	{cat=>$cat, name=>$name, args=>$args, help=>$helps->[0], helps=>$helps}
}

# выполняет команду и выдаёт её STDERR и STDOUT в качестве строки
sub run {
	my ($self, $name, $args) = @_;
	`perl qq $name $args 2>&1`;
}

1;