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
use Getopt::Long;

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
my $telnetHost = '192.168.123.148';

# Start this process in the foreground or background
my $runningInForeground=0;

my $WSHOST='localhost';
my $WSPORT=3000;
#my $wsEndpoint = "ws://$WSHOST:$WSPORT/echo";
my $wsEndpoint ;

sub usage {
	print "USAGE:\n" ;
	print "$0 [--foreground] [--ws='ws-end-point']\n" ;
	print "\t[--ip=a-ip-adress] [--port=listen-port-number]\n" ;
	print "\t[--usb=/dev/ttyUSBx]\n";
	print "\nExample:\n";
	print "$0 --foreground \\\n\t\t--ws='wss://www.mijn-hobbies.nl:3001/echo' \\\n" ;
	print "\t\t--ip=192.168.123.148 --port=3001 \\\n" ;
	print "\t\t--usb=/dev/ttyUSB3\n" ;
	exit;
}

GetOptions( 'ws=s' => \$wsEndpoint, 
			'foreground' => \$runningInForeground,
			'ip=s' => \$telnetHost,
			'port=s' => \$telnetListenPort
) or die usage() ;

print "wsEndpoint:          $wsEndpoint\n" ;
print "runningInForeground: $runningInForeground\n" ;
print "ip:                  $telnetHost\n" ;
print "port:                $telnetListenPort\n" ;
print "usb:                 $usbDevice\n" ;

# Current process id (PID)
my $pid=$$;
if( $runningInForeground == 0 ) {
	# Fork this process and continue in the background
	$pid = fork() ;
	if( $pid != 0 ) {
		$logger->info( "PID: $pid" ) ;
		print "prologix-usb-controller.pl is running as process $pid \n" ;
		print "Listen on port $telnetHost:$telnetListenPort\n" ;
		exit 0 ;
	}
} else {
	print "prologix-usb-controller.pl is running as process $pid\n" ;
	print "Listen on port $telnetHost:$telnetListenPort\n" ;
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
<<<<<<< HEAD
	  #
	  # Distribute WS data to:
	  # 	STDOUT
	  # 	Telnet clients
	  # 	Prologix-usb if message contains a command
	  #
      print "Websocket data->STDOUT: $frame\n" if( $runningInForeground ) ;
	  foreach my $s (keys %clients) {
			print "Websocket data->TELNET Client: $frame\n" ;
			$clients{$s}->write( $frame ."\n\r> " ) ;
	  }
=======
>>>>>>> develop
	  
	  my $h = $jsonizer->decode( $frame ) ;
	  if( $h->{message} =~ /prologix-usb:/ ) {
		 #print "h: " . Dumper( $h ) ;
		 #print "h->{message}: " . Dumper( $h->{message} ) ;
	  	 my $h3 = $jsonizer->decode( $h->{message} ) ;
		 my @args=split( ':', $h3->{message} );
		 print "From ws->USB: $args[1] \n" ;
		 $serialPort->write( $args[1]."\n\r" ) ; 
		 #die 'h3: ' . Dumper( $h3->{message} ) ;
	  } else {
      	 print "From ws->STDOUT: $frame\n" ;
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
		 try {
			print "Send to ws\n" ;
			# Send data to websocket
		 	$wsClient->send_text_frame( "STDIN: $1" ) if( defined $wsEndpoint );
		 } catch {
			print "ERROR: Cannot send to websocket\n" ;
		 };
		 # Send data to Prologix-usb
		 $rv = $serialPort->write( $1."\n\r" ) ; 
		 my $count=0;
		 foreach my $s (keys %clients) {
			print "STDIN->TELNET Client: $1\n" ;
			$clients{$s}->write( $1 ."\n\r> " ) ;
		 }
      }
 
      return 0;
   },
) );
}
# Welcome message for a telnet-connection client
my $welcome = "prologix-usb-controller.pl - V1.0";
$logger->info( $welcome ) ;

#############################################################
#
# Connect to the WEBSOCKET and identiry your self
#
#############################################################

try {
# Start the GPIB morbo server!
$wsClient->connect(
   url => $wsEndpoint,
)->then( sub {
    $wsClient->send_text_frame( "Hello, world from $0!\n" );
})->get;
} catch {
	if( ! defined $wsEndpoint ) {
		print "WARNING: Websocket endpoint not defined\n"; 
	} else {
		print "ERROR: Cannot connect to websocket: $wsEndpoint\n$!\n" ;
		exit;
	}
}
 
$loop->add( IO::Async::Stream->new(
   handle  => $serialPort->{HANDLE},
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;
 
      while( $$buffref =~ s/^(.*)\n// ) {
		 # In forground mode: echo value to stdout
         print "$1\n" if( $runningInForeground == 1 ) ;
		 # Send value to the websocket connection
		 try {
		 	$wsClient->send_text_frame( $1 ) if defined $wsEndpoint;
		 } catch {
			print "ERROR: Cannot write to websocket\n" ;
		 };

		 # Send the value to all telnet clients
		 foreach my $s (keys %clients) {
			# Send to telnet clients
			print "Send to telnet client\n" ;
			$clients{$s}->write( $1."\n> " ) ;
		 }
      }
 
      return 0;
   },
) );

my $listener = IO::Async::Listener->new(
   on_stream => sub {
      my ( undef, $stream ) = @_;
 
	  # Register this telent client ;
	  $clients{$stream} = $stream ;

	  # Send welcome message to telnet client
	  $stream->write( "$welcome\n> " ) ;
      print "TELNET CLIENT CONNECTION \n" if( $runningInForeground == 1 ) ;

      $stream->configure(
         on_read => sub {
            my ( $self, $buffref, $eof ) = @_;
			
			# Echo the received data to the telnet client
            $self->write( $$buffref );

			# Send to serialPort  
		 	$serialPort->write( $$buffref."\n\r" ) ; 

			# Send to the websocket
			try {
		 	$wsClient->send_text_frame( "TELNET data->websocket: $$buffref" ) 
													if( defined $wsEndpoint );
			} catch {
				print "Cannot send to WEBSOCKET\n" ;
		 	};
		 	foreach my $s (keys %clients) {
				if( "$s" eq "$stream" ) {
					#print "YES, DIT IS AFZENDER\n" ;
					$clients{$s}->write( "> " ) ;
					next;
				}
				#print "TELNET data->TELNET CLIENT: $$buffref\n" ;
				$clients{$s}->write( $$buffref . "> ") ;
		 	}

            print "TELNET data->STDOUT $$buffref" if( $runningInForeground == 1 ) ;
            $$buffref = "";
            return 0;
         },
      );
 
      $loop->add( $stream );
   },
);
 
$loop->add( $listener );

try {
$listener->listen(
   addr => {
      family   => "inet",
      socktype => "stream",
      port     => $telnetListenPort,
      ip       => $telnetHost
   },
)->get;
} catch {
	print "ERROR: Cannot create listen socket $telnetHost:$telnetListenPort\n";
	exit 1;
	
};

$loop->run;


$logger->info( "Exit" ) ;
