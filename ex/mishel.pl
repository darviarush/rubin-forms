#use common::sense;


my @TASK = ();	# список заданий
my $IDX = 0;	# счётчик заданий



#use Algorithm::Cron;
use Win32::GUI();

my $icon = new Win32::GUI::Icon('mishel.ico');

my $screen = Win32::GUI::GetDesktopWindow();

my $width = 400;
my $height = 100;

my $mw = Win32::GUI::Window->new(
	-name => 'Main',
	-text => 'Mishel',
	-left => ($screen->Width - $width) / 2,
	-top => ($screen->Height - $height) / 2,
	-width => $width,
	-height => $height,
);
$mv->ChangeIcon($icon);

my $t1 = $mw->AddTimer('T1', 1000);
#my $t2 = $mw->AddTimer('T2', 1000);

loadtasks();
my $label1 = $mw->AddLabel(
    -text => $TASK[0],
    -left => 5,
    -top  => 5,
);


my $ni = $mw->AddNotifyIcon(
	-name => "NI",
	-icon => $icon,
	-tip => "Hello"
);

$mw->Show();

Win32::GUI::Dialog();

sub Main_Terminate {
	return -1;
}

sub Main_Minimize {
	$mw->Disable();
	$mw->Hide();
	return 1;
}

sub NI_Click {
	$mw->Enable();
	$mw->Show();
	return 1;
}

#   $mw->NI->Remove();


# загружает список заданий
sub loadtasks {
	
	@TASK = ();
	
	open my $f, "<", "mishel.txt" or die $!;
	
	while(<$f>) {
		
		next if !/\S/;
		
		s/^\s*(.*)\s*$/$1/;
	
		print "$.: $_\n";
		push @TASK, $_;
		
		#= Algorithm::Cron->new(crontab => , base => "local");
	}
	
	close $f;
}


# 
sub T1_Timer {
	print "T1\n";
	loadtasks();
	
	$IDX = 0 if $IDX >= @TASK;
	
	$label1->Text($TASK[$IDX]);
	$label1->Tip($TASK[$IDX++]);
	
	NI_Click();
}

# перечитывает настройки
sub T2_Timer {
	print "T2\n";
}
