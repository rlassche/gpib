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
use lib '.';
use LWP::UserAgent;
use Config;
use Config::Auto;
use SDC::GPIB;
use Redis::Client;
use Redis::Client::Hash;
use IO::Select;


use Data::Dumper;
use Test::More tests => 10;
use Env qw( WEB_URL CONFIG_FILE )  ;
use YAML::XS;
use JSON;
use JSON::Parse 'parse_json';
use Sys::Hostname::FQDN qw( fqdn );
use Database;

# This is a helper to slurp up files, I could have just used File::Slurp
#sub slurp($) {
#    my $filename = shift;
#
#    # Slurp up the contents of the given filename
#    open my $slurpy, '<', $filename or die "Cannot open $filename: $!";
#    return do { local $/; <$slurpy> };
#}

my $VERSION="1.2" ;
my $COMPILE_DATE="08-JAN-2020";

my( $config, $config_file) ;
$config_file = "/usr/lib/cgi-bin/gpib.cfg" ;

$config_file = $CONFIG_FILE if( $CONFIG_FILE );
$config = Config::Auto::parse( $config_file ) ;
ok( $config, "Using CONFIG_FILE : $config_file" ) ;
my $db = new Database( dsn => $config->{dsn},
				     user => $config->{user},
					 pass => $config->{password},
					 LOG4DB => 1,
					 CONFIG => $config,
					 LOG_LEVEL=>"FATAL",
					 LOG_CLASS => "testFORMS" ) ;
ok( $db, "Connect to the database.");

my $gpib = new SDC::GPIB( DATABASE => $db ) ;

my $rv = $gpib->taGetDevice( { DESCRIPTION => 'hp' } );
ok( $rv->{STATUS} eq "OK" && @{$rv->{DATA}} == 1, 
	"typeahead GetDevice ==>hp: " . $rv->{DATA}[0]->{DESCRIPTION} ) ;
my $device_id =  $rv->{DATA}[0]->{ID};
ok( $device_id eq '3456A', "Continue testing with DEVICE_ID $device_id" ) ;

my $rv = $gpib->getDeviceInfo( { DEVICE_ID => $device_id } );
ok( $rv->{STATUS} eq "OK" && 
	@{$rv->{DEVICE_FUNCTION}} > 0 && @{$rv->{GPIB_DEVICE}} == 1,
	"getDeviceInfo: DEVICE_FUNCTIONs and GPIB_DEVICEsetup" ) ;

$rv = $gpib->initDevice( { DEVICE_ID => $device_id } ) ;
ok( $rv->{STATUS} eq "OK" && $rv->{IBERR} == 0 && $rv->{DEVICE_FD}, 
			"Init GPIB device $rv->{CONFIG}->{DEVICE_ID} - ".
			$rv->{CONFIG}->{DESCRIPTION}. 
			", DEVICE_FD=" . $rv->{DEVICE_FD} );
my $device_fd = $rv->{DEVICE_FD} ;
my $command="F1R1M0T4";
$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$command } ) ;
ok( $rv->{STATUS} eq "OK" && $rv->{IBERR} == 0, 
	"Send command: $command, IBERR==$rv->{IBERR}" ) ;

#my $timeout=10;
#my $s = IO::Select->new() ;
#print "FD:  $device_fd\n" ;
#$s->add( $device_fd ); 
#my @ready = $s->can_read( $timeout ) ;
#die Dumper( \@ready ) ;
#exit;
$rv = $gpib->read( { DEVICE_FD => $device_fd } ) ;
ok( $rv->{STATUS} eq "OK" && $rv->{IBERR} == 0,
	 "Read command: $rv->{DATA}, IBERR=$rv->{IBERR}" ) ;
$command="ENTER;A";
$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$command } ) ;
ok( $rv->{STATUS} eq "OK" && $rv->{IBERR} == 0 , 
	"Send command: $command, IBERR=$rv->{IBERR}" ) ;
$rv = $gpib->read( { DEVICE_FD => $device_fd } ) ;
ok( $rv->{STATUS} eq "OK" && $rv->{IBERR} == 0, 
	"Read command: $rv->{DATA}, $rv->{IBERR}" ) ;
#die Dumper( $rv ) ;
$rv = $gpib->gpib_error_string( { IBERR => 14 } ) ;
ok( $rv->{STATUS} eq "OK" && $rv->{IBERR_DESCRIPTION} =~/EBUS/, 
		"IBERR 14 text string -> $rv->{IBERR_DESCRIPTION}"  );

$rv = $gpib->documentation( { DEVICE_ID => $device_id } ) ;
ok( $rv->{STATUS} eq "OK" && defined $rv->{DATA}, "documentation for $device_id" ); 
1;
