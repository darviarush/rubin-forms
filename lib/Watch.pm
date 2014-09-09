use strict;
use warnings;

use POSIX qw(strftime);

sub stime {
	strftime("%T", localtime)
}

sub for_action (&) {
	my ($sub) = @_;
	find({no_chdir=>1, wanted=>sub { $sub->($File::Find::name, $1) if $File::Find::name=~/\baction\/(.*)\.(act|htm)$/; }}, dirs "action");
}

for_action {
	my ($path) = @_;
	$_watch{$path} = mtime($path);
};

sub _reload {
	#print STDERR `nginx -s reload`;
	my $res = `perl -c $0`;
	if($? == 0) {
		end_server();
		exec $0, @ARGV;
	} else {
		print STDERR $res;
	}
}


sub _watch_actions {
	my $msg = $_[0];
	for_action {
		my ($path, $fiename) = @_;
		return unless $_watch{$path} < mtime($path);
		msg stime()." - action $path" if $msg;
		_reload();
		#load_action($path, $filename);
		#$_watch{$path} = mtime($path);
		#kill USR1, @_lords;
	};
}

sub watch {
	_watch_actions(1);

	for my $path ("qq", "main.ini", values %INC) {
		if(not my $watch=$_watch{$path}) { $_watch{$path} = mtime($path); }
		elsif($watch < mtime($path)) {
			msg stime()." - module $path";
			_reload();
		}
	}
}

1;