package R::Sign;
# символы фонтов в html/sign/*

use common::sense;
use R::App;

my $singleton;

# конструктор
sub new {
	my ($cls) = @_;
	
	return $singleton if $singleton;
	
	$singleton = bless {
		sign => {},		# название в camelcase => знак
		orig => {},		# название c "-" => знак
	}, ref $cls || $cls;
	
	$singleton->load
}

# формирует таблицу символов для $app->sign
# таблица формируется из css-фреймворка bootsrap или совместимого, например fontawesome
# подгружает из html/sign/* фонты
sub load {
	my ($self) = @_;
	
	return $self if $self->{load};
	$self->{load} = 1;
	
	$app->file("html/sign/*")->glob->then(sub {

		my $css = $_->sub( $_->name . ".css" );
		my $tex = $css->read;

		die "в файле " . $css->path . " нет \@font-face" if $tex !~ /\@font-face\s*\{[^\{\}]*\}/;
		
		my $face = $&;
		my $path = $_->path;
		$path =~ s!^html!!;
		$face =~ s!url\('[^']*/!url('$path/!g;
		$face =~ s!url\("[^"]*/!url("$path/!g;
		
		$app->css->insertln($face);
		
		my @sign;
		
		while($tex =~ /(\.[\w-]+:before(?:\s*,\s*\.[\w-]+:before)*)\s*\{\s*content:\s*["']\\([^"']+)["']/sg) {
			my $y = $2;
			my @sign = map { m/^\.(.*):before$/; $1 } split /\s*,\s*/, $1;
			$y = chr hex $y;
			for my $nik (@sign) {
				$self->register($nik => $y);
			}
		}

	});
	
	$self
}

# регистрирует в классе R::Sign символ
sub register {
	my ($self, $nik, $sign) = @_;
	
	my $name = $nik;
	$name =~ s/-(\w)/uc $1/ge;
	#$name = "s$name" if $name =~ /^\d/;
	
	die "символ `$nik` уже зарегистрирован" if *$name{CODE};
	
	$self->{sign}{$name} = $sign;
	$self->{orig}{$nik} = $sign;
	
	*$name = (sub { my ($x)=@_; sub { $x } })->($sign);
	
	$self
}

1;