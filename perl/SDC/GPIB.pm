#!perl
#######################################################################
#
# TODO: timeout:
# printf( "enter the desired timeout:\n"
#        "\t(0) none\n"
#        "\t(1) 10 microsec\n"
#        "\t(2) 30 microsec\n"
#        "\t(3) 100 microsec\n"
#        "\t(4) 300 microsec\n"
#        "\t(5) 1 millisec\n"
#        "\t(6) 3 millisec\n"
#        "\t(7) 10 millisec\n"
#        "\t(8) 30 millisec\n"
#        "\t(9) 100 millisec\n"
#        "\t(10) 300 millisec\n"
#        "\t(11) 1 sec\n"
#        "\t(12) 3 sec\n"
#        "\t(13) 10 sec\n"
#        "\t(14) 30 sec\n"
#        "\t(15) 100 sec\n"
#        "\t(16) 300 sec\n"
#        "\t(17) 1000 sec\n"
#        );
#        if( ibtmo( ud, timeout ) & ERR )
#######################################################################
package SDC::GPIB;
use Moose;
use LinuxGpib;

use Try::Tiny;
#use Crypt::JWT qw(decode_jwt encode_jwt);
use Config;
#use Digest::MD5 qw( md5 md5_base64 );
use Data::Dumper;
#use Hash::Merge qw/ merge /;
use JSON;
use JSON::XS;
use File::Slurp;
use MIME::Base64 qw( encode_base64 );

has 'DATABASE'     => ( is => 'rw', isa => 'Database', lazy_build => 1 );

my $VERSION      = "1.2";
my $COMPILE_DATE = "08-JAN-2020";

# Binary: 1000000000000000
# Hex   : 0x8000
# Decial: 32768
my $ERR = 32768;

# Description:
# 	Lookup $params->{DEVICE_ID} in table GPIB_DEVICE and init the device.
# 	Device settings are stored in $self->{GPIB_DEVICE}
# 	
sub initDevice {
    my $self = shift;
    my $params = shift;

	my $dev;
	my $rv ;

	$rv = $self->getDeviceInfo( $params ) ;
	if( $rv->{STATUS} eq "OK" ) {
		$self->{GPIB_DEVICE} = $rv->{GPIB_DEVICE}[0];
		$dev=LinuxGpib::ibdev(
				$self->{GPIB_DEVICE}->{MINOR},
				$self->{GPIB_DEVICE}->{PAD},
				$self->{GPIB_DEVICE}->{SAD}, 
				$self->{GPIB_DEVICE}->{TIMEOUT}, 
				$self->{GPIB_DEVICE}->{SEND_EOI}, 
				$self->{GPIB_DEVICE}->{EOS_MODE} 
			) ;
	}
	return {STATUS => $rv->{STATUS}, 
			TRHREADIBSTA => LinuxGpib::ThreadIbsta(),
			IBERR => LinuxGpib::ThreadIberr(),
			DEVICE_FD => $dev } ;
}
sub send {
    my $self = shift;
    my $params = shift;

	my $status = "ERROR" ;
	my $rv=LinuxGpib::ibwrt( 
				$params->{DEVICE_FD}, 
				$params->{COMMAND},
				length( $params->{COMMAND} ) );
	#printf( "rv=%d mask: %d\n", $rv, $rv & $ERR );
    # ERR binary:  1000000000000000
    $status = "OK" if( $rv & $ERR) == 0 ;

	return { STATUS =>"$status", 
			 IBERR => LinuxGpib::ThreadIberr(),
			 TRHREADIBSTA => LinuxGpib::ThreadIbsta(),
			 RETVAL => $rv & $ERR };
}

# TODO:
# if((ThreadIbsta() & ERR) == 0 || ThreadIberr() != EDVR)
#  read_count = ThreadIbcntl();


#
sub read {
    my $self = shift;
    my $params = shift;

	my $buffer ;
	my $len = 1024;
	my $status = "ERROR" ;

	my $rv=LinuxGpib::ibrd( $params->{DEVICE_FD}, $buffer, $len ) ;
    if( ($rv & $ERR) == 0 ) {
		$buffer =~ s/\r|\n//g;
		$status = "OK";
	} 
	return { STATUS =>"$status", RETVAL => $rv & $ERR,
			 IBERR => LinuxGpib::ThreadIberr(),
			 TRHREADIBSTA => LinuxGpib::ThreadIbsta(),
			 DATA => $buffer };
}

sub gpib_error_string {
    my $self = shift;
    my $params = shift;
	return { STATUS => "OK", 
			 IBERR => $params->{IBERR},
			 IBERR_DESCRIPTION => 
					LinuxGpib::gpib_error_string( $params->{IBERR} ) 
		   }
}

sub version {
    my $self = shift;
    return {
        PACKAGE      => 'SDC::GPIB',
        VERSION      => $VERSION,
        COMPILE_DATE => $COMPILE_DATE
    };
}


sub documentation {
    my $self   = shift;
    my $params = shift;

	my @VALUES;
	my $sql = "SELECT * FROM DEVICE_DOCUMENTATION WHERE DEVICE_ID = ?";
	push( @VALUES, $params->{DEVICE_ID} ) ;
    my $rv = $self->{DATABASE}->executeSelect( { SQL => $sql, VALUES=>\@VALUES } ) ;

	return $rv ;
}
#################################################################
# Description:
# 	typeahead get device
#################################################################
sub taGetDevice {
    my $self   = shift;
    my $params = shift;

    my @VALUES;
	my $sql = "SELECT DEVICE_ID ID, DESCRIPTION FROM GPIB_DEVICE WHERE DESCRIPTION LIKE ?";
    push( @VALUES, '%'.$params->{DESCRIPTION}.'%' ) ;
    my $rv = $self->{DATABASE}->executeSelect( { SQL => $sql, VALUES=>\@VALUES } ) ;

    return $rv;

}

######################################################################
# Description:
# 	Get $params->{DEVICE_ID} from table GPIB_DEVICE.
# 	Return the DEVICE setup (address etc.) 
# 	and an array with all supported functions.
######################################################################
sub getDeviceInfo {
    my $self   = shift;
    my $params = shift;

    my @VALUES;
	my %retval ;

	$retval{STATUS} = "OK";
	my $sql = "SELECT * FROM GPIB_DEVICE WHERE DEVICE_ID = ?";
    push( @VALUES, $params->{DEVICE_ID} ) ;
    my $rv = $self->{DATABASE}->executeSelect( { SQL => $sql, VALUES=>\@VALUES } ) ;
	$retval{GPIB_DEVICE} = $rv->{DATA} if( $rv->{STATUS} eq "OK" ) ;

	$sql = "SELECT * FROM DEVICE_FUNCTION WHERE DEVICE_ID = ?";
    $rv = $self->{DATABASE}->executeSelect( { SQL => $sql, VALUES=>\@VALUES } ) ;
	$retval{DEVICE_FUNCTION} = $rv->{DATA} if( $rv->{STATUS} eq "OK" ) ;
	
	return \%retval ;
}

1;
