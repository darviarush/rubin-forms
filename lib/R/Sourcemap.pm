package R::Sourcemap;
# ���������� ������������ �����

use common::sense;
use R::App;

# �����������
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}


# ���������� ����� �� integer � VLQ
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

    
# � base64
sub _encodeBase64 {
	my ($value) = @_;
    substr($BASE64_CHARS, $value, 1) || die "Cannot Base64 encode value: " + $value;
}

# ���������� mappings ��� map-�����
sub mappings {
	my ($self, $push) = @_;
	
	# ����� ������� � ��������������� �����
	# �������� ����
	# ����� ������ � �������� �����
	# ����� ������� � �������� �����
	# �������� �������� (���� ����)
	
	
	
	$push->{lineno}
	$push->{charno}
	#pack
	
	$self
}

# ���������� map-����
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