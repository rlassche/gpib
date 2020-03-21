#!/usr/bin/perl
# Filename : client.pl

use strict;
use Socket;
use IO::Socket::INET;
use IO::Select;

# initialize host and port
my $host = shift || 'localhost';
my $port = shift || 7777;
my $server = "localhost";  # Host IP running the server

my $s = IO::Select->new() ;

my $socket;
# create the socket, connect to the port
socket($socket,PF_INET,SOCK_STREAM,(getprotobyname('tcp'))[2])
   or die "Can't create a socket $!\n";
connect( $socket, pack_sockaddr_in($port, inet_aton($server)))
   or die "Can't connect to port $port! \n";
$socket->autoflush;

$s->add( \*STDIN ); 
$s->add( $socket ); 

my $timeout=20;
my @ready;
my $fh;
my $line;
while( 1 ) {
	@ready = $s->can_read( $timeout );
	foreach $fh (@ready) {
            if($fh == \*STDIN) {
                $line=<STDIN>;
                print "STDIN: $line\n" ;
				#$port->write( $line."\n\r" ) ; 
				print $socket $line ;
            } elsif( $fh == $socket ) {
				$line=<$socket>;
				print "SOCKET: $line" ;
			}
	}
}
