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

my $file="1998_init.cmd";
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
my $port;
my %RACAL_DANA = (
	"SRS" => { DESCRIPTION=> "SRS command",
		   ARGS => { "7",  "8" },
	},
	"F" =>   { DESCRIPTION=> "FREQuency command Channel B",
		   ARGS => { "A",  "B" },
		 },
	"Q" =>   { DESCRIPTION=> "Q command Channel B",
		   ARGS => { "A",  "B" },
		 }
);

sub send2Device
{
	my $cmd= shift ;
	my @keys = keys %RACAL_DANA;
	print "TEST: $cmd\n";
	$port->write( $cmd."\n\r" ) ; 
	my $p ;
	return $p ;
	while( @keys ) {
		my $k=pop( @keys) ;
		print "k=$k, cmd=$cmd\n";
		if( $cmd =~ /$k/ ) {
		  my $arg = $';
		  print "FOUND: k=$k: arg=$arg\n";
		  $port->write( $cmd."\n\r" ) ; 
		  return $RACAL_DANA{$k};
		}
	}
	print "$cmd not implemented" if( ! defined $p ) ;
	return $p;
}

sub initDevice
{
	my $file=shift;
	print "initDevice: $file\n";
	
	my @f;
	open FD, $file ;
	@f=<FD>;
	close( FD ) ;
	for( my $i=0; $i<@f; $i++ ) {
		my $l=trim( $f[$i] );
		print "# $l\n";
		if( $l =~/^#/ || "$l" eq "" ) {
			print "NEXT ($l)\n";
			next;
		}
		#print "SEND SEND--> $l****\n";
		my $r=send2Device( "$l" ) ;
	}
}
#die "BYE";
#die Dumper( \@f ) ;
#exit;
my $r;
#$r=send2Device( "SRS7" ) ;
#$r=send2Device( "FA" ) ;
#die Dumper( $r ) ;

my $s = IO::Select->new() ;
$s->add( \*STDIN ); 
my $usbDevice='/dev/ttyUSB0' ;

$port = Device::SerialPort->new($usbDevice);
$port->baudrate(9600); # Configure this to match your device
$port->databits(8);
$port->parity("none");
$port->stopbits(1);
$s->add( $port->{HANDLE} ); 
print "Add " . Dumper( $port->{HANDLE} ) ;

#my $command="SRS7";
#$port->write( $command."\n\r" ) ; 
#send2Device( $command ) ;

#$command="FB";
#$port->write( $command."\n\r" ) ; 
#$command="Q7";
#$port->write( $command."\n\r" ) ; 
#send2Device( $command ) ;

#$command="RGS";
#$port->write( $command."\n\r" ) ; 

print "FILE=$file\n";
initDevice( $file ) ;

my $timeout=20;
my @ready;
my $fh;
my $line;
my @a=();
my $rest='';
my $p;
while( 1 ) {
	#print "Waiting.... " ;
	@ready = $s->can_read( $timeout );
	print "\n" ;
	#print "After can_read\n" ;
	foreach $fh (@ready) {
			#print "foreach: " . Dumper( $fh ) . "\n";
            if($fh == \*STDIN) {
                $line=<STDIN>;
                #print "STDIN: $line\n" ;
				$port->write( $line."\n\r" ) ; 
            }
            elsif($fh eq $port->{HANDLE} ) {
				#print "Read from GPIB\n" ;
				my( $count, $buffer ) = $port->read( 1040 ) ; 
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
						print "$x\n" ;
					}
					#print Dumper( \@a ) ;
				}
			}
            else {
                print "Hu?\n" . Dumper( $fh ) ;
exit;
            }
        }
}
