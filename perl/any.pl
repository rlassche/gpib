#!/usr/bin/perl 

use strict;
use warnings;

use AnyEvent::WebSocket::Client 0.12;
use AnyEvent::Socket;
use Data::Dumper;

my $wsEndpoint ;
my $stdinHandle; 

my $usbDevice='/dev/ttyUSB0' ;

###################################################################
# Start a TCP SOCKET SERVER
###################################################################

# a simple tcp server
my %clients;
my %connections;
my $host='hp-probook';
tcp_server undef, 8888, sub {
	my ($fh, $host, $port) = @_;
 
	print "Client connects to this server\n" ;
	syswrite $fh, "The internet is full, $host:$port. Go away!\015\012";
	$clients{$fh} = $fh;

	my $handle;
    $handle = AnyEvent::Handle->new(
                fh => $fh,
                poll => 'r',
                on_read => sub {
                    my ($self) = @_;
                    print "Received: " . $self->rbuf . "\n";
   					$wsEndpoint->send( 'TELNET data->WS: '.  $self->rbuf ) ;
  					foreach my $s (keys %clients) {
						print "TELNET data->TELNET Client: $self->rbuf\n" ;
						# Send the TELNET data to TELNET clients
						syswrite $clients{$s}, "TELNET->TELNET: " .$self->rbuf .
								"\015\012";
  					}
					$self->rbuf = '';
                },
                on_eof => sub {
                                  my ($hdl) = @_;
                                  $hdl->destroy();
                },
               );
               $connections{$handle} = $handle; # keep it alive.
},
sub {
	my ($fh, $thishost, $thisport) = @_;
 	print "tcp_server: sub...\n" ;
	AE::log info => "Bound to $thishost, port $thisport.";
};
 
##########################################################
#	READ FROM STDIN
##########################################################
$stdinHandle = AnyEvent->io (
			fh => \*STDIN, 
			poll => 'r', 
			cb => sub {
   				chomp (my $input = <STDIN>);
				print "read: $input\n";
				$wsEndpoint->send( $input ) ;
	  			foreach my $s (keys %clients) {
					print "Websocket data->TELNET Client: $input\n" ;
					# Send the STDIN data to TELNET
					syswrite $clients{$s}, "STDIN->TELNET: $input\015\012";
				}
			}
);
###################################################################
#   CONNECT TO WEBSOCKET SERVER
###################################################################
my $client = AnyEvent::WebSocket::Client->new( ssl_no_verify => 1 );
 
$client->connect("wss://hp-probook:3001/echo")->cb(sub {
 
  print "Connect\n" ;
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
  print "Send message\n" ;
  $connection->send('a message');
   

 # recieve message from the websocket...
  $connection->on(each_message => sub {
    # $connection is the same connection object
    # $message isa AnyEvent::WebSocket::Message
    my($connection, $message) = @_;
    print "each_message: " . Dumper( $message );
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
AnyEvent->condvar->recv;

