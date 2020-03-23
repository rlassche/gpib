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

my $device_name = '1998';
my $jsonizer = JSON::XS->new() ;
Log::Log4perl::init('log4perl.conf');
my $logger = Log::Log4perl->get_logger();

my $runningInForeground=1;

if( $runningInForeground == 0 ) {
my $pid = fork() ;
if( $pid != 0 ) {
	$logger->info( "PID: $pid" ) ;
	print "server.pl is running as process $pid \n" ;
	print "Listen on port 7777\n" ;
	exit 0 ;
}
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
         print "You typed a line $1\n";
		 $wsClient->send_text_frame( "STDIN: $1" ) ;
		 $serialPort->write( $1."\n\r" ) ; 
      }
 
      return 0;
   },
) );
}
# Welcome message for a telnet-connection client
my $welcome = "server.pl - V1.0\n";
$logger->info( $welcome ) ;

#############################################################
#
# Connect to the WEBSOCKET and identiry your self
#
#############################################################
my $WSHOST='localhost';
my $WSPORT=3000;

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
         print "$1\n" if( $runningInForeground == 1 ) ;
		 $wsClient->send_text_frame( $1 ) ;
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

# Server listen port
my $port = 7777;

# creating a listening socket
my $socket = new IO::Socket::INET (
    LocalHost => '0.0.0.0',
    LocalPort => $port,
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
);
$logger->info( "Listen port $port " ) ;
$loop->add( IO::Async::Stream->new(
   handle  => $socket,
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;
 
      while( $$buffref =~ s/^(.*)\n// ) {
         print "read from telnetSocket $1\n";
			exit;
		 #$wsClient->send_text_frame( "SOCKET2 $1" ) ;
      }
 
      return 0;
   },
) );

#$loop->listen(
#	service => "echo",
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

#my $listener = IO::Async::Listener->new(
#   on_stream => sub {
#      my ( undef, $stream ) = @_;
# 
#      $stream->configure(
#         on_read => sub {
#            my ( $self, $buffref, $eof ) = @_;
#			print "Listener: on_read: $$buffref\n" ;
#			# Echo the received data
#            $self->write( $$buffref );
#            $$buffref = "";
#            return 0;
#         },
#         on_accept => sub {
#            my ( $self, $buffref, $eof ) = @_;
#            return 0;
#		 },
#      );
# 
#      $loop->add( $stream );
#   },
#);
 
#die Dumper( $listener ) ;
#$loop->add( $listener );

#$listener->listen(
#   addr => {
#      family   => "inet",
#      socktype => "stream",
#      port     => 7777,
#      ip       => 'localhost',
#   },
#);
#
#$listener->listen(
#   addr => { family => "inet", socktype => "stream", ip=> 'localhost', port=>8001 },
#)->on_done( sub {
#   my ( $listener ) = @_;
#   my $socket = $listener->read_handle;
# 
#   print "Now listening on port ", $socket->sockport;
#});

# Wait for connections from telnet clients
#$sel->add( $socket );

$loop->run;

# Register all socket connections from the netwerk 
#my %clients;

# Now, wait for available data.....
#while(@ready = $sel->can_read) {
#		# Data arrived. Check WHO is sending data (telnet client, Prologix/GPIB bus...
#        foreach $fh (@ready) {
#            if($fh == $socket) {
#				$logger->info( "Incomming client connection on socket." ) ;
#				#print "CONNECTION FROM NETWORK \n";
#				# Accept the incomming connection
#				my $client_socket = $socket->accept();
#
#				# Listen for data comming from this network socket
#				$sel->add( $client_socket );
#
#				# Register this new network client socket
#				$clients{$client_socket} = $client_socket;
#
#				# Send a welcome message to the socket-client
#				$client_socket->send( "IO::Socket:$welcome" ) ;
#				$logger->info( "Client accepted." ) ;
#			} elsif( defined $clients{$fh} ) {
#				# Data received from network socket (or EOF)
#                $line=<$fh>;
#				if( defined $line ) {
#					$logger->info( "Data from client: $line" ) ;
#
#					# Echo back the received command to the telnet client
#					$fh->send( "IO::Socket:$line" ) ;
#					# The telnet client data is a Prologix/GPIB command.
#					# Send the data to the device
#					$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$line} ) ;
#				} else {
#					$logger->info( "Client left session" ) ;
#					# EOF client-socket, remove from registration
#					# Remove handle from select
#					$sel->remove( $fh ) ;
#					# Remove client from the registration
#					delete $clients{$fh} ;
#				}
#			} elsif( $fh == $device_fd ) {
#				$logger->info( "Data from Prologix/GPIB:  $device_description" ) ;
#				$rv = $gpib->read( { DEVICE_FD => $device_fd } ) ;
#				if( $rv->{STATUS} eq "OK" ) {
#					foreach my $x (@{$rv->{DATA}}) {
#						$logger->info( "value: $x" ) ;
#						if( $runningInForeground == 1 ) { 
#							print "$x\n";
#						}
#						# Send one value to EACH telnet client
#						foreach my $c (keys %clients ) {
#							$logger->info( "Send to client: $x" ) ;
#							$clients{$c}->send( $x . CRLF ) ;
#						}
#					}
#				}
#			} elsif($fh == \*STDIN) {
#				# NOTE: STDIN is not monitored because this is a background process!
#				# Data received from STDIN (=keyboard)
#                $line=<STDIN>;
#				$logger->info( "Data from STDIN: $line" ) ;
#
##				# Echo back the received data
#                print "STDIN: $line" ;
#            }
#            else {
#				$logger->info( "ERROR: Huh?: " ) ;
#                die "Huh? ERROR: \n" . Dumper( $fh) ;
#            }
#        }
#}
$logger->info( "Exit" ) ;
