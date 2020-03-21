#!/usr/bin/perl 

use strict;
use warnings;
use lib '.';

use constant CRLF => "\n\r";
use IO::Select;
use Data::Dumper;
use IO::Socket::INET;
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

Log::Log4perl::init('log4perl.conf');
my $logger = Log::Log4perl->get_logger();

my $pid = fork() ;
if( $pid != 0 ) {
	$logger->info( "PID: $pid" ) ;
	print "server.pl is running as process $pid \n" ;
	print "Listen on port 7777\n" ;
	exit 0 ;
}

my $device_name = '1998';

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

my $device_fd = $rv->{DEVICE_FD} ;
$logger->info( "Device description=$device_description, device_id=$device_id, device_fd=$device_fd" ) ;


# Welcome message for a telnet-connection client
my $welcome = "server.pl - V1.0\n";
$logger->info( $welcome ) ;

############################
#
# Wait for incomming data:
# 	data from Prologix or GPIB bus
# 	data from telnet client (with commands for Prologix or GPIB devices)
#
############################
$sel = IO::Select->new();

# Wait for data from the Prologix/GPIB controller
$sel->add( $device_fd );

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

# Wait for connections from telnet clients
$sel->add( $socket );

# Register all socket connections from the netwerk 
my %clients;

# Now, wait for available data.....
while(@ready = $sel->can_read) {
		# Data arrived. Check WHO is sending data (telnet client, Prologix/GPIB bus...
        foreach $fh (@ready) {
            if($fh == $socket) {
				$logger->info( "Incomming client connection on socket." ) ;
				#print "CONNECTION FROM NETWORK \n";
				# Accept the incomming connection
				my $client_socket = $socket->accept();

				# Listen for data comming from this network socket
				$sel->add( $client_socket );

				# Register this new network client socket
				$clients{$client_socket} = $client_socket;

				# Send a welcome message to the socket-client
				$client_socket->send( "IO::Socket:$welcome" ) ;
				$logger->info( "Client accepted." ) ;
			} elsif( defined $clients{$fh} ) {
				# Data received from network socket (or EOF)
                $line=<$fh>;
				if( defined $line ) {
					$logger->info( "Data from client: $line" ) ;

					# Echo back the received command to the telnet client
					$fh->send( "IO::Socket:$line" ) ;
					# The telnet client data is a Prologix/GPIB command.
					# Send the data to the device
					$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$line} ) ;
				} else {
					$logger->info( "Client left session" ) ;
					# EOF client-socket, remove from registration
					# Remove handle from select
					$sel->remove( $fh ) ;
					# Remove client from the registration
					delete $clients{$fh} ;
				}
			} elsif( $fh == $device_fd ) {
				$logger->info( "Data from Prologix/GPIB:  $device_description" ) ;
				$rv = $gpib->read( { DEVICE_FD => $device_fd } ) ;
				if( $rv->{STATUS} eq "OK" ) {
					foreach my $x (@{$rv->{DATA}}) {
						$logger->info( "value: $x" ) ;
						# Send one value to EACH telnet client
						foreach my $c (keys %clients ) {
							$logger->info( "Send to client: $x" ) ;
							$clients{$c}->send( $x . CRLF ) ;
						}
					}
				}
			} elsif($fh == \*STDIN) {
				# NOTE: STDIN is not monitored because this is a background process!
				# Data received from STDIN (=keyboard)
                $line=<STDIN>;
				$logger->info( "Data from STDIN: $line" ) ;

				# Echo back the received data
                print "STDIN: $line" ;
            }
            else {
				$logger->info( "ERROR: Huh?: " ) ;
                die "Huh? ERROR: \n" . Dumper( $fh) ;
            }
        }
}
$logger->info( "Exit" ) ;
