#== ����� �������
#= ����� ��� ��_���
#> �������� �����
#> ����� - ����� ������ � ������� ������������ ������
#> ��� - ���������� ���������
#> ��_��� - ����� ��� ������


($, $from, $to) = @ARGV;

for my $name (split /\n/, `find . -name '*.htm'`) {
	open f, $name or next;
	print "$name\n";
	
	read f, $_, -s f;
	close f;
	open f, ">", $name or die $!;
	
	s{$from}{$to}o;
	
	print f $_;
	close f;
}