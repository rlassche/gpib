#!perl
#####################################################################
# Env. variables:
#   USE_LIB
#   Windows:
#       Define env.var. USE_LIB and set it to the
#       ppm package directory! That will override the Linux
#       default value.
#
#
#	CONFIG_FILE	Set a CONFIG_FILE location.
#		File contains db settings etc.
#		Check your SERVER_NAME variable (SSL variable)
#		
#
#####################################################################

use strict;
use warnings;

my $VERSION="1.1" ;
my $COMPILE_DATE="08-FEB-2020";

use Test::More tests => 117;

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
use_ok('Database', 'Loaded Database');

my $db = new Database( dsn => $config->{dsn},
				     user => $config->{user},
					 pass => $config->{password},
					 LOG4DB => 1,
					 CONFIG => $config,
					 LOG_LEVEL=>"FATAL",
					 LOG_CLASS => "testFORMS" ) ;
ok( $db, "Connect to the database.");

use_ok('SDC::GPIB', 'Loaded SDC::GPIB');

my $gpib = new SDC::GPIB( DATABASE => $db ) ;
ok($gpib->isa('SDC::GPIB'),"gpib is SDC::GPIB");

my $rv = $gpib->taGetDevice( { DESCRIPTION => '1998' } );
ok( $rv->{STATUS} eq "OK" && @{$rv->{DATA}} == 1, 
	"typeahead GetDevice ==> " . $rv->{DATA}[0]->{DESCRIPTION} ) ;

my $device_id =  $rv->{DATA}[0]->{ID};
ok( $device_id eq '1998', "testing with DEVICE_ID $device_id" ) ;

$rv = $gpib->getDeviceInfo( { DEVICE_ID => $device_id } );
ok( $rv->{STATUS} eq "OK" && 
	@{$rv->{DEVICE_FUNCTION}} > 0 && @{$rv->{GPIB_DEVICE}} == 1,
	"getDeviceInfo: DEVICE_FUNCTIONs and GPIB_DEVICEsetup" ) ;


$rv = $gpib->initDevice( { DEVICE_ID => $device_id } ) ;
ok( $rv->{STATUS} eq "ERROR" , "Prologix without /dev..." ) ;
$rv = $gpib->initDevice( { DEVICE_ID => $device_id, USB_DEVICE=> $usbDevice } ) ;
ok( $rv->{STATUS} eq "OK" && $rv->{PORT}, 
			"Init GPIB device $device_id" ) ;

my $device_fd = $rv->{DEVICE_FD} ;
ok($device_fd->isa('IO::Handle'),"device_fd is IO::Handle");

my $port = $rv->{PORT};
ok($port->isa('Device::SerialPort'),"port is Device::SerialPort");

$rv = $gpib->sdc_getFileno( { DEVICE_FD => $device_fd } ) ;
ok($rv->{FILENO}->isa('IO::Handle'),"sdc_getFileno has IO::Handle");

###############################
## SELECT                  ####
###############################
my $s = IO::Select->new() ;
$s->add( \*STDIN );
print "Add device to select\n" ;
$s->add( $port->{HANDLE} ); 


foreach my $c ( qw/SRS7 FB Q7 RGS T0/ ) {
	$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$c } ) ;
	ok( $rv->{STATUS} eq "OK", "Send $c" ) ; 
	
}

my $timeout=10;
my @ready;
my $fh;
my $line;
my @a=();
my $rest='';
my $p;
my( $count, $buffer ) ;
my $count=0;
my $max_count=100;
while( $count<$max_count ) {
	#print "Waiting.... \n" ;
	@ready = $s->can_read( $timeout );
	#print "\n" ;
	#print "After can_read\n" ;
	foreach $fh (@ready) {
			#print "foreach: " . Dumper( $fh ) . "\n";
            if($fh == \*STDIN) {
                $line=<STDIN>;
				#print "Send to $device_id: " . $line;
				$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$line } ) ;
            }
            elsif($fh eq $port->{HANDLE} ) {
				#print "Read from GPIB\n" ;
				$rv = $gpib->read( { DEVICE_FD => $device_fd } ) ;
				if( $rv->{STATUS} eq "OK" ) {
					#print Dumper ($rv ) ;
					foreach my $x (@{$rv->{DATA}}) {
						ok( $x, "$x") ;
						$count++;
					}
				}
			}
            else {
                print "Hu?\n" . Dumper( $fh ) ;
				exit;
            }
   }
}
ok( $count == $max_count, "Read $max_count values from device $device_id" ) ;

1;
