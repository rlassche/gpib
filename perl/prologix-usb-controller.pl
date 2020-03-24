#!/usr/bin/perl 

use strict;
use warnings;
use lib '.';

use constant CRLF => "\n\r";
use IO::Select;
use Try::Tiny;
use Data::Dumper;
use IO::Socket::INET;
use IO::Async::Loop;
use IO::Async::Listener;
use Net::Async::WebSocket::Client;
use SDC::GPIB;
use Log::Log4perl;
use Database;
use Config;
use Config::Auto;

my( $sel, $fh, $some_handle, $timeout, $line, @ready, @handles);
my $usbDevice='/dev/ttyUSB0' ;

my( $config, $config_file) ;
$config_file = "/usr/lib/cgi-bin/gpib.cfg" ;
$config = Config::Auto::parse( $config_file ) ;

my %clients;
my $device_name = '1998';
my $jsonizer = JSON::XS->new() ;
Log::Log4perl::init('log4perl.conf');
my $logger = Log::Log4perl->get_logger();

# Server listen port
my $telnetListenPort = 7777;

# Start this process in the foreground or background
my $runningInForeground=0;

# Current process id (PID)
my $pid=$$;
if( $runningInForeground == 0 ) {
	# Fork this process and continue in the background
	$pid = fork() ;
	if( $pid != 0 ) {
		$logger->info( "PID: $pid" ) ;
		print "prologix-usb-controller.pl is running as process $pid \n" ;
		print "Listen on port $telnetListenPort\n" ;
		exit 0 ;
	}
} else {
	print "prologix-usb-controller.pl is running as process $pid \n" ;
	print "Listen on port $telnetListenPort\n" ;
}

# Open the Mysql database
my $db = new Database( dsn => $config->{dsn},
				     user => $config->{user},
					 pass => $config->{password},
					 LOG4DB => 1,
					 CONFIG => $config,
					 LOG_LEVEL=>"FATAL",
					 LOG_CLASS => "testFORMS" ) ;

# Create the GPIB object (for Prologix or GPIB)
my $gpib = new SDC::GPIB( DATABASE => $db ) ;

# Get the device info (like: Racal 1998)
my $rv = $gpib->taGetDevice( { DESCRIPTION => $device_name } );
die Dumper( $rv ) if( $rv->{STATUS} ne "OK" ) ;

my $device_description = $rv->{DATA}->[0]->{DESCRIPTION} ;
my $device_id =  $rv->{DATA}[0]->{ID};

# Initialise the prologix controller
$rv = $gpib->initDevice( { DEVICE_ID => $device_id, USB_DEVICE=> $usbDevice } ) ;
if( $rv->{STATUS} ne "OK" ) {
	die "Cannot initDevice $device_id, $usbDevice" . Dumper( $rv ) ;
}
my $serialPort = $rv->{PORT} ;


my $device_fd = $rv->{DEVICE_FD} ;
$logger->info( "Device description=$device_description, device_id=$device_id, device_fd=$device_fd" ) ;

my $loop = IO::Async::Loop->new;


# connects to a WebSocket server to establish a WebSocket connection 
# for passing frames.
#
my $wsClient = Net::Async::WebSocket::Client->new(
   on_text_frame => sub {
      my ( $self, $frame ) = @_;
      #print "on_text_frame: $frame\n" ;
	  
	  my $h = $jsonizer->decode( $frame ) ;
	  if( $h->{message} =~ /prologix-usb:/ ) {
		 #print "h: " . Dumper( $h ) ;
		 #print "h->{message}: " . Dumper( $h->{message} ) ;
	  	 my $h3 = $jsonizer->decode( $h->{message} ) ;
		 my @args=split( ':', $h3->{message} );
		 $serialPort->write( $args[1]."\n\r" ) ; 
		 #die 'h3: ' . Dumper( $h3->{message} ) ;
	  }
	  #print "MESSAGE: $h->{message} \n" ;
   },
);

$loop->add( $wsClient );

if( $runningInForeground == 1 ) {
$loop->add( IO::Async::Stream->new_for_stdin(
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;
 
      while( $$buffref =~ s/^(.*)\n// ) {
         print "You typed a line $1\n" ;
		 $wsClient->send_text_frame( "STDIN: $1" ) ;
		 $serialPort->write( $1."\n\r" ) ; 
		 my $count=0;
		 foreach my $s (keys %clients) {
			print "SEND TO TELNET CLIENT: $count++\n" ;
			$clients{$s}->write( $1 ) ;
		 }
      }
 
      return 0;
   },
) );
}
# Welcome message for a telnet-connection client
my $welcome = "prologix-usb-controller.pl - V1.0\n";
$logger->info( $welcome ) ;

#############################################################
#
# Connect to the WEBSOCKET and identiry your self
#
#############################################################
my $WSHOST='localhost';
my $WSPORT=3000;

# Start the GPIB morbo server!
$wsClient->connect(
   url => "ws://$WSHOST:$WSPORT/echo",
)->then( sub {
    #print "Connect to ws://$WSHOST:$WSPORT/echo\n" ;
    $wsClient->send_text_frame( "Hello, world from $0!\n" );
})->get;
 
$loop->add( IO::Async::Stream->new(
   handle  => $serialPort->{HANDLE},
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;
 
      while( $$buffref =~ s/^(.*)\n// ) {
		 # In forground mode: echo value to stdout
         print "$1\n" if( $runningInForeground == 1 ) ;
		 # Send value to the websocket connection
		 $wsClient->send_text_frame( $1 ) ;

		 # Send the value to all telnet clients
		 foreach my $s (keys %clients) {
			# Send to telnet clients
			$clients{$s}->write( $1."\n\r" ) ;
		 }
      }
 
      return 0;
   },
) );

############################
#
# Wait for incomming data:
# 	data from Prologix or GPIB bus
# 	data from telnet client (with commands for Prologix or GPIB devices)
#
############################
#$sel = IO::Select->new();

# Wait for data from the Prologix/GPIB controller
#$sel->add( $device_fd );
#$sel->add( \*STDIN ); 


# creating a listening socket
#my $socket = new IO::Socket::INET (
#    LocalHost => '0.0.0.0',
#    LocalPort => $port,
#    Proto => 'tcp',
#    Listen => 5,
#    Reuse => 1
#);
#$logger->info( "Listen port $port " ) ;
#$loop->add( IO::Async::Stream->new(
#   handle  => $socket,
#   on_read => sub {
#      my ( $self, $buffref, $eof ) = @_;
# 
#      while( $$buffref =~ s/^(.*)\n// ) {
#         print "IO::Async::Stream: from telnetSocket $1\n";
#		 #	exit;
#		 #$wsClient->send_text_frame( "SOCKET2 $1" ) ;
#      }
# 
#      return 0;
#   },
#) );

#$loop->listen(
#	service => "7777",
#	socktype => "stream",
#	on_stream => sub {
#      	my ( undef, $stream ) = @_;
#        $stream->configure(
#         	on_read => sub {
#			}
#		);
#		print "ON_STREAM";
#		return 0;
#	}
#)->get;

my $listener = IO::Async::Listener->new(
   on_stream => sub {
      my ( undef, $stream ) = @_;
 
	  # Register this telent client ;
	  $clients{$stream} = $stream ;

	  # Send welcome message to telnet client
	  $stream->write( "$welcome" ) ;
      print "TELNET CLIENT CONNECTION \n" if( $runningInForeground == 1 ) ;

      $stream->configure(
         on_read => sub {
            my ( $self, $buffref, $eof ) = @_;
			
			# Echo the received data to the telnet client
            $self->write( $$buffref );

			# Send to serialPort  
		 	$serialPort->write( $$buffref."\n\r" ) ; 

			# Send to the websocket
		 	$wsClient->send_text_frame( "TELNET SOCKET: $$buffref" ) ;

            print "TELNET SOCKET: $$buffref" if( $runningInForeground == 1 ) ;
            $$buffref = "";
            return 0;
         },
      );
 
      $loop->add( $stream );
   },
);
 
$loop->add( $listener );

$listener->listen(
   addr => {
      family   => "inet",
      socktype => "stream",
      port     => $telnetListenPort,
      ip       => 'localhost',
   },
)->get;

$loop->run;


$logger->info( "Exit" ) ;
