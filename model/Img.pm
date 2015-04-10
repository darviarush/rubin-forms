package R::Rows::Img;
# ��������� �������� � ���� (����. img) � �� ���� (������� html/images, ��-���������)

use base R::Model::Row;

use Image::Magick;
# http://www.graphicsmagick.org/perl.html


# ���������� ��� �������� �������
sub setup {
	my ($fields) = @_;
	
	# ��������� ������� � �������
	$fields->
	
	compute('body')
	
}

# ���������� path
sub path {
	my ($self) = @_;
	my $path = Utils::to_radix($self->{id}, 62);
	$path =~ s!.!$&/!;
	$self->{dir} . "/" . $path;
}

# ���������� ���� ���������� ��������
sub orig {
	my ($self) = @_;
	$self->path . $self->{name}
}

# ����������� �������
sub body {
	my ($self, $body) = @_;
	if(@_>1) {
		$self->{id} = $::app->auth->add($self->{tab})->last_id unless defined $self->{id};
		my $path = $self->path;
		Utils::mkpath($path);
		Utils::write($self->orig, $body);
	} else {
		Utils::read($self->orig);
	}
	return $self;
}

# ������� ����� ��������
sub erase_files {
	my ($self) = @_;
	my $path = $self->path;
	opendir my $dir, $path or die $!;
	while($file = readdir $dir) {
		$file = "$path$file";
		if(-f $path) { unlink $file }
		else { $count++ }
	}
	closedir $dir;
	return $count;
}

# ������� ��������
sub erase {
	my ($self) = @_;
	$self->SUPER::erase;
	Utils::rmpath($self->path) if $self->erase_files == 0;
	$self
}

# �������� ��������
sub update {
	my ($self, $body) = @_;
	$self->erase_files;
	Utils::write($self->orig, $body);
	$self
}


# �������� ������ �������� � ���������� � � ���� name
sub resize {
	my ($self, $w, $h, $name) = @_;
	my $orig = $self->orig;
	my $magick = Image::Magick->new;
	$magick->Read($orig);
	$magick->preview();
	$magick->Resize(geometry=>geometry, width=>$w, height=>$h);	# turn � ��������
	$self->erase_files;
	$magick->Write($orig);
	$self
}

# ������������ ��������
sub turn {
	my ($self, $turn) = @_;
	my $orig = $self->orig;
	my $magick = Image::Magick->new;
	$magick->Read($orig);
	$magick->Rotate(degrees => $turn);	# turn � ��������
	$self->erase_files;
	$magick->Write($orig);
	$self
}

1;