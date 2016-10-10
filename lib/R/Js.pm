package R::Js;
# менеджер управления скриптами фронт-энда

use common::sense;
use R::App;

# конструктор
sub new {
	my ($cls) = @_;
	bless {
		inc => {},
	}, ref $cls || $cls;
}

# добавляет код js
sub append {
	my $self = shift;
	
	my $script = join "", @_;
	$script =~ s!^\s*<script[^<>]*>\s*(<\!--)?!!;
	$script =~ s!(-->)?\s*</script\s*>\s*$!!;
	
	push @{$self->{script}}, $script;
	$self
}

# добавляет файл
sub require {
	my ($self, $path) = @_;
	
	my $file = $app->file->from($path);
	
	return $self if $self->{inc}{$file->path};
	
	$self->append( $file->read );
	
	$self->{inc}{$file->path} = 1;
	
	$self
}

# сохраняет код в файл
sub save {
	my ($self, $path) = @_;
	
	my $f = $app->file->from($path);
	my $s = $self->stringify;
	
	$f->write($s) if !$f->exists or $s ne $f->read;
	
	$self->{saveTime} = $f->mtime;
	
	$self
}

# стрингифицирует
sub stringify {
	my ($self) = @_;
	join "\n", @{$self->{script}}
}

# очищает js
sub clear {
	my ($self) = @_;
	@{$self->{script}} = ();
	$self
}

1;