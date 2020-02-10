#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  gpib_logger.pl
#
#        USAGE:  ./gpib_logger.pl  
#
#  DESCRIPTION:  GPIB logger
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Rob Lassche (mn), rob@pd1rla.nl
#      COMPANY:  Me
#      VERSION:  1.0
#      CREATED:  01/29/2020 06:40:10 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use lib '.';
use SDC::GPIB;
use Database;
use Config;
use Config::Auto;
use Getopt::Long;
use Data::Dumper;
use IO::Select;
use IO::Handle;

my $device_id='';
my $command_file='';
my $log_type='';
my $max_count=0;

sub usage {
	my $msg = shift;
	print "ERROR $0: $msg\n" ;
	print "Example:\n" ;
	print "\t$0 --device=1986 --command_file=1986_init.cmd --log_type=DB|csv|txt --max_count=100'\n" ;
	exit 0;
}
my $rv = GetOptions( 
			'device=s' => \$device_id, 
			'command_file=s' => \$command_file,
			'max_count=s' => \$max_count,
			'log_type=s' => \$log_type ) ;


if( $device_id eq "" ) {
	die usage( '--device device id not set' ) ;
}

if( ! -f $command_file ) {
	die usage( "--command_file: file not found!") ;
}

if( ! ( $log_type eq "DB" || $log_type eq "csv" || $log_type eq "txt" ) ) {
	die usage( "--log_type: DB, csv or txt expected" );
}
print "device: $device_id\n" ;
print "command_file $command_file\n" ;
print "log_type $log_type\n" ;

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
$rv = $gpib->taGetDevice( { DESCRIPTION => $device_id } );
die usage("Device $device_id not found!. ") if( $rv->{STATUS} ne "OK" );
$device_id =  $rv->{DATA}[0]->{ID};
my $device_fd;
my $device_info = $gpib->getDeviceInfo( { DEVICE_ID => $device_id } );
my $cmdHash = array2Hash( { ARRAY => $device_info->{DEVICE_FUNCTION}, KEY =>'COMMAND_ID' } ) ;
die usage( 'getDeviceInfo failed' ) if( $device_info->{STATUS} ne "OK" ) ;

$rv = $gpib->initDevice( { DEVICE_ID => $device_id } ) ;
if( $rv->{STATUS} ne "OK" ) {
	die usage( "ERROR: Cannot initDevice $device_id" ) ;
}

my $port = $rv->{PORT};
if( -f $command_file ) {
	print "Open $command_file\n" ;
	open( FD, "< $command_file" ) || die "Cannot open $command_file";
	while( <FD> ) {
		next if( $_ =~ /^#/ ) ;
		chop( $_);
		#print "$_\n";
		if( $cmdHash->{$_} ) {
			print $cmdHash->{$_}->{COMMAND_DESCRIPTION} . "(" . $cmdHash->{$_}->{DEVICE_CODE} . ")\n" ;
			#die Dumper( $cmdHash->{$_} ) ;
			$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$cmdHash->{$_}->{DEVICE_CODE} } ) ;
			die usage( "send to $device_fd failed. cmd=$_" ) 
												if( $rv->{STATUS} ne "OK" ) ;
		} else {
			die "Invalid command : $_\n" ;
		}
	}
	close( FD ) ;
}

my $s = IO::Select->new() ;
$s->add( \*STDIN );
$s->add( $port->{HANDLE} ); 

open( OUT, "> logger.$log_type" ) || die usage( 'Cannot write to file' ) ;
OUT->autoflush(1);
my $fh;
my @ready;
my $line;
my $timeout=10;
my $count=0;
while( $max_count == 0 || $count < $max_count ) {
	@ready = $s->can_read( $timeout );
	foreach $fh (@ready) {
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
                        print OUT "$x\n" ;
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
close( OUT ) ;

sub array2Hash {
	my $params = shift ;

	my %h=();
	my $key;
	foreach my $e (@{$params->{ARRAY}}) {
		$key= $e->{$params->{KEY}};
		$h{$key} = $e ;
	}
	return \%h ;
}

