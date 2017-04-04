package R::Sourcemap;
# отображает скомпиленные файлы

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}


# генерирует число из integer в VLQ
my $VLQ_SHIFT = 5;
my $VLQ_CONTINUATION_BIT = 1 << $VLQ_SHIFT;
my $VLQ_VALUE_MASK = $VLQ_CONTINUATION_BIT - 1;
my $BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
sub _VLQ {
	my ($value) = @_;
	
    my $answer = '';
    my $signBit = $value < 0 ? 1 : 0;
    my $valueToEncode = (abs($value) << 1) + $signBit;
	while ($valueToEncode || !$answer) {
		my $nextChunk = $valueToEncode & $VLQ_VALUE_MASK;
		$valueToEncode = $valueToEncode >> $VLQ_SHIFT;
		if ($valueToEncode) {
			$nextChunk |= $VLQ_CONTINUATION_BIT;
		}
		$answer .= _encodeBase64($nextChunk);
	}
	return $answer;
}

    
# в base64
sub _encodeBase64 {
	my ($value) = @_;
    substr($BASE64_CHARS, $value, 1) || die "Cannot Base64 encode value: " + $value;
}

# генерирует mappings для map-файла
sub mappings {
	my ($self, $push) = @_;
	
	# Номер символа в сгенерированном файле
	# Исходный файл
	# Номер строки в исходном файле
	# Номер символа в исходном файле
	# Исходное название (если есть)
	
	
	
	$push->{lineno}
	$push->{charno}
	#pack
	
	$self
}

# генерирует map-файл
sub mapfile {
	my ($self, $from_path, $to_path) = @_;
	
	
	
	return {
		version => 3,
		file => $to_path,						#	"app.min.js",
		sourceRoot => "",
		sources => [$from_path],				# ["foo.js", "bar.js"],
		names => [],							# ["src", "maps", "are", "fun"],		
		mappings => $self->{mappings},			# "AAgBC,SAAQ,CAAEA"
	}
}

1;