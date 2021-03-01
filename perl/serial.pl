#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  serial.pl
#
#        USAGE:  ./serial.pl  
#
#  DESCRIPTION:  Open serial port
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Rob Lassche (mn), rob@pd1rla.nl
#      COMPANY:  Me
#      VERSION:  1.0
#      CREATED:  01/29/2020 06:53:25 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Data::Dumper;
use IO::Select;
use IO::Handle;
use Device::SerialPort;
use File::Slurp qw( read_file);

$|=1;
my $file="1998_init.cmd";
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
my $port;

sub send2Device
{
	my $cmd= shift ;
	$port->write( $cmd."\n\r" ) ; 
}

sub initDevice
{
	my $file=shift;
	
	my @f;
	open FD, $file ;
	@f=<FD>;
	close( FD ) ;
	for( my $i=0; $i<@f; $i++ ) {
		my $l=trim( $f[$i] );
		if( $l =~/^#/ || "$l" eq "" ) {
			next;
		}
		if( $l =~ /^\!/ ) {
			# my( $count, $buffer ) = $port->read( 1040 ) ; 
			next;
		}
		my $r=send2Device( "$l" ) ;
	}
}

my $s = IO::Select->new() ;
$s->add( \*STDIN ); 
my $usbDevice='/dev/ttyUSB0' ;

$port = Device::SerialPort->new($usbDevice);
$port->baudrate(9600); # Configure this to match your device
$port->databits(8);
$port->parity("none");
$port->stopbits(1);
$s->add( $port->{HANDLE} ); 


my $timeout=120;
my @ready;
my $fh;
my $line;
my @a=();
my $rest='';
my $p;
initDevice( $file ) ;
my $buffer="";
while( 1 ) {
	@ready = $s->can_read( $timeout );
	#print "After can_read\n" ;
	my $full_entries=0;
	foreach $fh (@ready) {
			#print "foreach: " . Dumper( $fh ) . "\n";
            if($fh == \*STDIN) {
                $line=<STDIN>;
                #print "STDIN: $line\n" ;
				send2Device( $line ) ;
            }
            elsif($fh eq $port->{HANDLE} ) {
				#print "Read from GPIB\n" ;
				my( $count, $tmp_buffer ) = $port->read( 1040 ) ; 
				if( $count < 1 ) { 
					die "COUNT < 1"; 
				}
				#print "BUILD BUFFER: $buffer ------ $tmp_buffer\n";
				$buffer .= $tmp_buffer;
				@a=();
				@a = split( /\r\n/, $buffer ) ;
				$full_entries = @a; 
				#print "full_entries: $full_entries\n ";
				if( substr( $buffer, -2 ) ne "\r\n" ) {
					$full_entries -= 1 ; 
					#print "NOT END FOUND, AANTAL : ". $full_entries;
					$buffer=$a[$full_entries];
					#print "COPY LEFT OVER TO BUFFER: ####$buffer####\n";
				} else {
					#print "END FOUND AT END, AANTAL : ". $full_entries ;
					$buffer="" ;
				}
				
				#print "\nFOREACH: $full_entries:" . "\n";
				for( my $j=0; $j<$full_entries; $j++ ) {
					#if( $a[$j] =~ /\r/ ) { 
					#	die "N found";
					#}
					my $len = length( $a[$j] ) ;
					print "$a[$j]\n" ;
				}
			}
            else {
                die "Hu?\n" . Dumper( $fh ) ;
            }
        }
}
