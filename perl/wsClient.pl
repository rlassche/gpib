#!/usr/bin/perl 
use strict;
use warnings;


my $WSHOST="localhost";
my $WSPORT=3000;

my $count=0;
use IO::Async::Loop;
use Device::SerialPort;
use IO::Async::Function;
use Net::Async::WebSocket::Client;
use Data::Dumper;
use IO::Socket::INET;
use IO::Select;
use IO::Async::Socket;
 
my $usbDevice='/dev/ttyUSB0' ;
my $serialPort = Device::SerialPort->new($usbDevice);

# connects to a WebSocket server to establish a WebSocket connection 
# for passing frames.
#
my $wsClient = Net::Async::WebSocket::Client->new(
   on_text_frame => sub {
      my ( $self, $frame ) = @_;
      print "on_text_frame: $frame\n" ;
	  #exit;
   },
);

sub mysub {
	my $wsClient = shift ;
	$count++;
   	$wsClient->send_text_frame( "$count : Hello, world from $0 from mysub!\n" );
}
 
my $loop = IO::Async::Loop->new;

# dummy sub
sub doSomething { 
    my ( $delay ) = @_;
	#$wsClient->send_text_frame( "doSomething...."."\n\r" ) ;
    print "start waiting $delay second(s)\n";
    sleep $delay;
    print "done sleeping $delay second(s)\n"; 
    return $delay;
}
$loop->add( $wsClient );


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


#my $socket = IO::Async::Socket->new(
#   on_recv => sub {
#      my ( $self, $dgram, $addr ) = @_;
# 
#      print "Received reply: $dgram\n",
#      $loop->stop;
#   },
#   on_recv_error => sub {
#      my ( $self, $errno ) = @_;
#      die "Cannot recv - $errno\n";
#   },
#);


my $port=8001;
my $server='localhost';
my $telnetSocket;
# create the socket, connect to the port
socket($telnetSocket,PF_INET,SOCK_STREAM,(getprotobyname('tcp'))[2])
   or die "Can't create a socket $!\n";
connect( $telnetSocket, pack_sockaddr_in($port, inet_aton($server)))
   or die "Can't connect to port $port! \n . $!";
$telnetSocket->autoflush;
$loop->add( IO::Async::Stream->new(
   handle  => $telnetSocket,
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;
 
      while( $$buffref =~ s/^(.*)\n// ) {
         print "read from telnetSocket $1\n";
		 #$wsClient->send_text_frame( "SOCKET2 $1" ) ;
      }
 
      return 0;
   },
) );

$loop->add( IO::Async::Stream->new(
   handle  => $serialPort->{HANDLE},
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;
 
      while( $$buffref =~ s/^(.*)\n// ) {
         print "read from socket $1\n";
		 $wsClient->send_text_frame( $1 ) ;
      }
 
      return 0;
   },
) );



#$loop->add( $socket );

sub functionTest()
{
	my $function = IO::Async::Function->new( code => 
		sub { return doSomething($_[0], $wsClient ) } 
	);
	$loop->add( $function );
	# trigger asynchronous processing
	my @array = qw/5 2 4 0/;
	my @futures = map { $function->call( args => [ $_ ] ) } @array;
}
 
#############################################################
#
# Connect to the WEBSOCKET and identiry your self
#
#############################################################
$wsClient->connect(
   url => "ws://$WSHOST:$WSPORT/echo",
)->then( sub {
   print "Connect to ws://$WSHOST:$WSPORT/echo\n" ;
    $wsClient->send_text_frame( "Hello, world from $0!\n" );
})->get;
 
#$wsClient->send_text_frame( "VOOR DE WHILE" ) ;
#$wsClient->send_text_frame( "Zie je zit ook?" ) ;
#$wsClient->send_text_frame( "EN DIT????" ) ;
$loop->run;
