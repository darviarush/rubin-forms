#!/usr/bin/env perl
# секретарь по icq


BEGIN { push @INC, "../rubin-forms/lib" }
use common::sense;
use R::App;


#use Net::XMPP;
#use Mozilla::CA;
#use Net::XMPP::Client::GTalk;
#use Net::MRIM;

# $app->ini({
	# icq => {
		# uin => "618151707",
		# password => "",
		# server => "",
		# port => "",
	# },
# });

# my @TASK = ();	# список заданий
# my $IDX = 0;	# счётчик заданий

# my $icq = Net::ICQ->new(@{$app->ini->{icq}}{qw/uin password server port/}) or die "не подключено";
# $icq->connect();
 
# $icq->add_handler('SRV_SYS_DELIVERED_MESS', \&on_msg);



# while ($icq->connected) {
	# msg1 "connected";
	
	# sleep 0.5;
	
	# $icq->do_one_loop();
# }

# sub on_msg {
	# msg1 'param:', [@_];
	
	# # my $params = {
		# # 'type'         => 1,
		# # 'text'         => 'Hello world test',
		# # 'receiver_uin' => 618151707,  # кому будем отправлять (в АД)
	# # };

	# # $icq->send_event('CMD_SEND_MESSAGE', $params);
# }




#print  Mozilla::CA::SSL_ca_file();exit;

# use Net::XMPP::Client::GTalk    ;


# my $username = 'as.van.alv' ; # = '' ; Set GTalk username here [ WITHOUT '@gmail.com' ]. 
# my $password = 'detiMora'; # = '' ; Set GTalk password here.


# unless( defined( $username ) and defined( $password ) ) { 
	# die( "SET YOUR GTALK USERNAME AND PASSWORD ABOVE!\n" ) ;
# }

# # See options for domain below in documentation for new.
# my $ob = new Net::XMPP::Client::GTalk( 
	# USERNAME   => $username ,
	# PASSWORD   => $password         ,
	# );
# #$ob->{RAW_CONNECTION}{SERVER}{ssl_ca_path} = Mozilla::CA::SSL_ca_file();

# my $require_run = 1 ;
# my $iteration   = 1 ;
# while( $require_run ) { 

	# my $message = $ob->wait_for_message( 60 ) ;

	# unless( $message ) { 
		# print "GOT NO MESSAGE - waiting longer\n" ;
	# }

	# if( $message->{ error } ) { 
		# print "ERROR \n" ;
		# next             ;
	# } else { 
		# msg1( $message ) ;
	# }

	# if( $message->{ message } eq 'exit' ) { 
		# print "Asked to exit by " . $message->{ from } . "\n" ;
		# $message->{ message } = 'Exiting ... ' ;
		# $require_run = 0 ;
	# }

	# $ob->send_message( $message->{ from }, $message->{ message } ) ;

	# if( int( $iteration / 3 ) == ( $iteration / 3 ) ) { 
		# my @online_buddies = @{ $ob->get_online_buddies() } ;
		# msg1( \@online_buddies ) ;
	# }

	# $iteration++ ;

# }


# exit() ;

# use Net::MRIM;
 # my $mrim=Net::MRIM->new(
                        # Debug=>0,
                        # PollFrequency=>5
                        # );
 # $mrim->hello();
 
 
  # if (!$mrim->login("mishelkitty\@mail.ru", "detiOkeana12")) {
        # print "LOGIN REJECTED\n";
        # exit;
 # } else {
        # print "LOGGED IN\n";
 # }

  # my $ret=$mrim->authorize_user("darviarush\@mail.ru");
  
  # msg1 $ret;
  
   # $ret=$mrim->add_contact("darviarush\@mail.ru");
   
  # msg1 $ret; 
   
   # $ret=$mrim->send_message("darviarush\@mail.ru","hello");
   
  # msg1 $ret;
   
   # $mrim->disconnect();



# my $con = new Net::XMPP::Client();

# eval {

# my $status = $con->Connect(
  # hostname => 'xmpp.jp',
  # port=>5222,
  # connectiontype => 'tcpip',
  # tls => 1,
  # ssl_ca_path => Mozilla::CA::SSL_ca_file(),
# ) or die('ERROR: XMPP connection failed. $!');

# my @result = $con->AuthSend(
  # #hostname => 'jabber.ru',
  # username => 'mishel',
  # password => '***',
  # resource=>"perl",
# );

# msg1 \@result;
  
# die 'ERROR: XMPP authentication failed' if $result[0] ne 'ok';
# die 'ERROR: XMPP message failed' if $con->MessageSend(to => 'halfdroy@gmail.com', body => 'hi!');

# };
# print("$@\n"), $con->Disconnect() if $@;





#my $bot = Bot::Jabbot->new("./config.yaml");
#$bot->start();


# my $bot = Net::Jabber::Bot->new(
   # # server => 'jabber.ru',
   # # #conference_server => 'conference.jabber.ru',
   # # port => 5222,
   # # jid => 'mishel@jabber.ru',
   # # username => 'mishel',
   # # password => '***',
   # # alias => $name,
   # # resource => $name,
   # # safety_mode => 1,
   # # message_function => \&new_bot_message,
   # # background_function => \&background_checks,
   # # loop_sleep_time => 1,
   # # #forums_and_responses => \%forum_list,
   # # #forums_passwords => \%forum_passwords,
   
   
    # server => 'jabber.ru'
	# #, conference_server => undef
	# , port => 5222
	# , username => 'mishel'
	# , password => '***'
	# , alias => 'jabber_bot'
	# , message_callback => \&new_bot_message   # Called if new messages arrive.
	# , background_activity => \&background_checks # What the bot does outside jabber.
	# , loop_sleep_time => 20 # Minimum time before doing background function.
	# , process_timeout => 5 # Time to wait for new jabber messages before timing out
	# #, forums_and_responses => []	#\%forums_and_responses
	# , ignore_server_messages => 1 # Usually you don't care about admin messages from the server
	# , ignore_self_messages => 1 # Usually you don't want to see your own messages
	# , out_messages_per_second => 5 # Maximum messages allowed per second (server flood throttling)
	# , max_message_size => 1000 # Maximum byte size of the message before we chop it into pieces
	# , max_messages_per_hour => 1000 # Keep the bot from going out of control with noisy messages 
# );
 
# $bot->Start();



# use Net::XMPP;
# my $con=new Net::XMPP::Client();
# $con->Connect(hostname=>"jabber.ru");
# $con->AuthSend(username=>"mishel",
                        # password=>"password",
                        # resource=>"ALARM!");
# my $msg=new Net::XMPP::Message();
# $msg->SetMessage(to=>'halfdroy@gmail.com',
                 # from=>'mishel@jabber.ru',
                 # body=>"My First Jabber Message From FreeBSD");
# $con->Send($msg);
# $con->Disconnect();


#use Net::ICQ;
#use Win32::GUI();
#use Algorithm::Cron;



# CMD_NEW_USER_1
# CMD_UPDATE_LIST
# CMD_SEARCH_USER
# CMD_INFO_REQ
# CMD_MSG_TO_NEW_USER
# CMD_UPDATE_INFO
# CMD_AUTH_UPDATE
# CMD_UPDATE_EXT_INFO
# CMD_CHANGE_PW
# CMD_LOGIN_1
# CMD_ACK_MESSAGES
# CMD_VIS_LIST
# CMD_EXT_INFO_REQ
# CMD_RAND_SEARCH
# CMD_LOGIN
# CMD_QUERY_SERVERS
# CMD_SEND_MESSAGE
# CMD_CONTACT_LIST
# CMD_QUERY_ADDONS
# CMD_RAND_SET
# CMD_META_USER
# CMD_ADD_TO_LIST
# CMD_KEEP_ALIVE2
# CMD_LOGIN_2
# CMD_ACK
# CMD_KEEP_ALIVE
# CMD_STATUS_CHANGE
# CMD_REG_NEW_USER
# CMD_NEW_USER_INFO
# CMD_INVIS_LIST
# CMD_SEND_TEXT_CODE
# CMD_SEARCH_UIN




# my $icon = new Win32::GUI::Icon('mishel.ico');

# my $screen = Win32::GUI::GetDesktopWindow();

# my $mw = Win32::GUI::Window->new(
	# -name => 'Main',
	# -text => 'Mishel',
	# -left => $app->ini->{mw}{left},		#($screen->Width - $width) / 2,
	# -top => $app->ini->{mw}{top},		#($screen->Height - $height) / 2,
	# -width => $app->ini->{mw}{width},
	# -height => $app->ini->{mw}{height},
# );
# $mv->ChangeIcon($icon);

# #my $t1 = $mw->AddTimer('T1', 1000);
# #my $t2 = $mw->AddTimer('T2', 1000);


# my $label1 = $mw->AddLabel(
    # -text => $TASK[0],
    # -left => 5,
    # -top  => 5,
# );


# my $ni = $mw->AddNotifyIcon(
	# -name => "NI",
	# -icon => $icon,
	# -tip => "Hello"
# );

# $mw->Show();

# Win32::GUI::Dialog();

# sub Main_Terminate {
	# return -1;
# }

# sub Main_Minimize {
	# $mw->Disable();
	# $mw->Hide();
	# return 1;
# }

# sub NI_Click {
	# $mw->Enable();
	# $mw->Show();
	# return 1;
# }

# #   $mw->NI->Remove();


# # загружает список заданий
# sub loadtasks {
	
	# @TASK = ();
	
	# open my $f, "<", "mishel.txt" or die $!;
	
	# while(<$f>) {
		
		# next if !/\S/;
		
		# s/^\s*(.*)\s*$/$1/;
	
		# print "$.: $_\n";
		# push @TASK, $_;
		
		# #= Algorithm::Cron->new(crontab => , base => "local");
	# }
	
	# close $f;
# }


# # 
# sub T1_Timer {
	# print "T1\n";
	# loadtasks();
	
	# $IDX = 0 if $IDX >= @TASK;
	
	# $label1->Text($TASK[$IDX]);
	# $label1->Tip($TASK[$IDX++]);
	
	# NI_Click();
# }

# # перечитывает настройки
# sub T2_Timer {
	# print "T2\n";
# }
