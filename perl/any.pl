#!/usr/bin/perl 

use strict;
use warnings;
use lib '.';

use AnyEvent::WebSocket::Client 0.12;
use AnyEvent::Socket;
use Data::Dumper;
use Config;
use Config::Auto;
use JSON::XS;
use Log::Log4perl;
use Database;
use SDC::GPIB;

my $wsEndpoint ;
my $stdinHandle; 
my $welcome = "prologix-usb-controller.pl - V1.0";

my $usbDevice='/dev/ttyUSB3' ;
my( $config, $config_file) ;
$config_file = "/usr/lib/cgi-bin/gpib.cfg" ;
$config = Config::Auto::parse( $config_file ) ;

# Server listen port
my $telnetListenPort = 8888;
my $telnetHost = '192.168.123.148';

my $device_name = '1998';
my $jsonizer = JSON::XS->new() ;
Log::Log4perl::init('log4perl.conf');
my $logger = Log::Log4perl->get_logger();

# Start this process in the foreground or background
my $runningInForeground=0;

# Current process id (PID)
my $pid=$$;
if( $runningInForeground == 0 ) {
	# Fork this process and continue in the background
	$pid = fork() ;
	if( $pid != 0 ) {
		$logger->info( "PID: $pid" ) ;
		print "any.pl is running as process $pid \n" ;
		#print "Listen on port $telnetHost:$telnetListenPort\n" ;
		exit 0 ;
	}
} else {
	print "any.pl is running as process $pid\n" ;
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

# a simple tcp server
my %clients;
my %connections;
my $host='hp-probook';

###################################################################
#   CONNECT TO WEBSOCKET SERVER
###################################################################
my $client = AnyEvent::WebSocket::Client->new( ssl_no_verify => 1 );
 
$client->connect("wss://hp-probook:3001/echo")->cb(sub {
 
  #print "Connect\n" ;
  # make $connection an our variable rather than
  # my so that it will stick around.  Once the
  # connection falls out of scope any callbacks
  # tied to it will be destroyed.
  our $connection = eval { shift->recv };
  if($@) {
    # handle error...
    print "Error: Cannot connect to WEBSOCKET server\n" ;
    warn $@;
    return;
  }
  $wsEndpoint = $connection ; 
  # send a message through the websocket...
  #print "Send message\n" ;
  $connection->send( $welcome);
   

 # recieve message from the websocket...
  $connection->on(each_message => sub {
    # $connection is the same connection object
    # $message isa AnyEvent::WebSocket::Message
    my($connection, $message) = @_;
    #print "WEBSOCKET data " . Dumper( $message );

  	foreach my $s (keys %clients) {
		#print "WEbSOCKET data->TELNET Client: $message->{body}\n" ;
		# Send the TELNET data to TELNET clients
		syswrite $clients{$s}, "WEBSOCKET->TELNET: " .$message->{body} .
					"\015\012";
  	}
  });
   
  # handle a closed connection...
  $connection->on(finish => sub {
    # $connection is the same connection object
    my($connection) = @_;
    print "Connection finish: " . Dumper( $connection ) ;
  });
 
  # close the connection (either inside or
  # outside another callback)
  #print "Closing connection" ;
  #$connection->close;
 
});
##########################################################
#	READ FROM PROLOGIX-USB DEVICE
##########################################################
my $rest='';
my $p;
my @a=();
my $serialHandler = AnyEvent->io (
			fh => $serialPort->{HANDLE}, 
			poll => 'r', 
			cb => sub {
				my( $count, $buffer ) = $serialPort->read( 1040 ) ; 
				$buffer = $rest . $buffer;
				if( $buffer =~ /\r\n/ ) {
					@a = split( /\r\n/, $buffer ) ;
					$rest='';
					#print "CRLF found in buffer. SPLIT ". Dumper( \@a ) ;; 
				} else {
					@a =() ;
				}
				my $last2bytes=substr( $buffer, -2 ) ;
				if( $last2bytes ne "\r\n" ) {
					#print "NO CRLF at end of string!\n" ;
					if( @a > 0 ) {
                    	#print "DO the POP:\n" ;
                    	$p= pop( @a ) ;
						
                    	if( defined $p ) {
                        	#print "NEW REST=: $p. NEW REST LENGTH:".
                            #    length( $p ) . "\n"  ;
                        	$rest = $p;
                    	}
                	} else {
                    	$rest = $buffer ;
						#print "Added buffer to rest: $rest\n" ;
                	}
				}
				if( @a > 0 ) {
					foreach my $x (@a) {
						#print "$x\n" ;
						#print "read from Prologix: $x\n";
						$wsEndpoint->send( $x ) ;
					}
					#print Dumper( \@a ) ;
				}
   				
				# ONLY MULTIPLEX WEBSOCKET DATA TO TELNET
				# IF STDIN IS TYPED, THEN IT WILL BE SEND TO THE WEBSOCKET
				# AND THROUGH THAT, THE TELNET CLIENT WILL RECEIVE THE 
				# STDIN DATA!!!
				# #######################################################
	  			#foreach my $s (keys %clients) {
				#	print "Websocket data->TELNET Client: $input\n" ;
				#	# Send the STDIN data to TELNET
				#	syswrite $clients{$s}, "STDIN->TELNET: $input\015\012";
				#}
			}
);

###################################################################
# Start a TCP SOCKET SERVER
###################################################################

tcp_server undef, $telnetListenPort, sub {
	my ($fh, $host, $port) = @_;
 
	#print "Client connects to this server. Register in CLIENTS\n" ;
	#print "fh=".Dumper( $fh ) . "\n" ;
	syswrite $fh, "The internet is full, $host:$port. Go away!\015\012";
	$clients{$fh} = $fh;

	my $handle;
    $handle = AnyEvent::Handle->new(
                fh => $fh,
                poll => 'r',
				on_error => sub {
					die "DIT IS ON_ERROR, YES!!\n" ;
				},
                on_read => sub {
                    my ($self) = @_;
                    #print "Received: " . $self->rbuf . "\n";
					if( ! defined $self->rbuf ) {
						die "YES Undefined " ;
					}
   					$wsEndpoint->send( 'TELNET data->WS: '.  $self->rbuf ) ;
					$serialPort->write( $self->rbuf."\n\r" ) ; 
  					#foreach my $s (keys %clients) {
					#	print "TELNET data->TELNET Client: $self->rbuf\n" ;
					#	# Send the TELNET data to TELNET clients
					#	syswrite $clients{$s}, "TELNET->TELNET: " .$self->rbuf .
					#			"\015\012";
  					#}
					$self->rbuf = '';
                },
                on_eof => sub {
                    my ($hdl) = @_;
					print  "TELNET CLIENT IS LOGGED OFF!!!!\n";
					print "hdl:" . "$hdl\n";
					print "hdl:" . Dumper( $hdl ) ;
					if( $clients{$hdl->{fh}} eq "$hdl->{fh}" ) {
						print "JA, DELETE CLIENT OOK VAN CLIENTS!!!\n";
					}
                    $hdl->destroy();
                },
               );
               $connections{$handle} = $handle; # keep it alive.
},
sub {
	# Display telnet-server information 
	my ($fh, $thishost, $thisport) = @_;
	print "Bound to $thishost, port $thisport.";
};
 
if( $runningInForeground == 1 ) {
##########################################################
#	READ FROM STDIN
##########################################################
$stdinHandle = AnyEvent->io (
			fh => \*STDIN, 
			poll => 'r', 
			cb => sub {
   				chomp (my $input = <STDIN>);
				#print "STDIN: $input\n";
				$wsEndpoint->send( $input ) ;
				$serialPort->write( $input."\n\r" ) ; 

				# ONLY MULTIPLEX WEBSOCKET DATA TO TELNET
				# IF STDIN IS TYPED, THEN IT WILL BE SEND TO THE WEBSOCKET
				# AND THROUGH THAT, THE TELNET CLIENT WILL RECEIVE THE 
				# STDIN DATA!!!
				# #######################################################
	  			#foreach my $s (keys %clients) {
				#	print "Websocket data->TELNET Client: $input\n" ;
				#	# Send the STDIN data to TELNET
				#	syswrite $clients{$s}, "STDIN->TELNET: $input\015\012";
				#}
			}
);
};

AnyEvent->condvar->recv;

