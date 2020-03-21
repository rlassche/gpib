#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  serial2.pl
#
#        USAGE:  ./serial2.pl  
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

use lib '.';
use Data::Dumper;
use IO::Select;
use IO::Handle;
use Device::SerialPort;
use SDC::GPIB;
use Database;
use Config;
use Config::Auto;

my $usbDevice='/dev/ttyUSB0' ;

my( $config, $config_file) ;
$config_file = "/usr/lib/cgi-bin/gpib.cfg" ;
$config = Config::Auto::parse( $config_file ) ;
my $db = new Database( dsn => $config->{dsn},
				     user => $config->{user},
					 pass => $config->{password},
					 LOG4DB => 1,
					 CONFIG => $config,
					 LOG_LEVEL=>"FATAL",
					 LOG_CLASS => "testFORMS" ) ;

my $gpib = new SDC::GPIB( DATABASE => $db ) ;

my $rv = $gpib->taGetDevice( { DESCRIPTION => '1998' } );
my $device_id =  $rv->{DATA}[0]->{ID};

$rv = $gpib->getDeviceInfo( { DEVICE_ID => $device_id } );
$rv = $gpib->initDevice( { DEVICE_ID => $device_id } ) ;
my $device_fd = $rv->{DEVICE_FD} ;
my $port = $rv->{PORT};

###############################
## SELECT                  ####
###############################
my $s = IO::Select->new() ;
$s->add( \*STDIN );
$s->add( $port->{HANDLE} ); 

my $command="SRS7";
$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$command } ) ;
print "Send to device: $command\n" ;
$command="FB";
$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$command } ) ;
print "Send to device: $command\n" ;
$command="Q7";
$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$command } ) ;
print "Send to device: $command\n" ;
$command="RGS";
$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$command } ) ;
print "Send to device: $command\n" ;

my $timeout=10;
my @ready;
my $fh;
my $line;
my @a=();
my $rest='';
my $p;
my( $count, $buffer ) ;
while( 1 ) {
	print "Waiting....\n" ;
	@ready = $s->can_read( $timeout );
	#print "\n" ;
	print "After can_read\n" ;
	foreach $fh (@ready) {
			#print "foreach: " . Dumper( $fh ) . "\n";
            if($fh == \*STDIN) {
                $line=<STDIN>;
				$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$line } ) ;
            }
            elsif($fh eq $port->{HANDLE} ) {
				#print "Read from GPIB\n" ;
				$rv = $gpib->read( { DEVICE_FD => $device_fd } ) ;
				if( $rv->{STATUS} eq "OK" ) {
					#print Dumper ($rv ) ;
					foreach my $x (@{$rv->{DATA}}) {
						print "$x\n" ;
					}
				}
			}
            else {
                print "Hu?\n" . Dumper( $fh ) ;
				exit;
            }
   }
}
