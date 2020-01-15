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


my @tmo_name = qw(
    TNONE T10us T30us T100us T300us T1ms  T3ms  
    T10ms T30ms T100ms T300ms T1s   T3s   T10s  
    T30s  T100s T300s T1000s
);
 
    use constant REOS               => 0x0400;
    use constant XEOS               => 0x0800;
    use constant BIN                => 0x1000;
    use constant DCL                => 0x14;
    use constant GET                => 0x08;        
    use constant GTL                => 0x01;
    use constant LAD                => 0x20;        
    use constant LLO                => 0x11;        
    use constant PPC                => 0x05;        
    use constant PPD                => 0x70;        
    use constant PPE                => 0x60;        
    use constant PPU                => 0x15;        
    use constant SDC                => 0x04;        
    use constant SPD                => 0x19;        
    use constant SPE                => 0x18;        
    use constant TAD                => 0x40;        
    use constant TCT                => 0x09;        
    use constant UNL                => 0x3f;        
    use constant UNT                => 0x5f;        
    use constant ERR                => 0x8000;
    use constant TIMO               => 0x4000;
    use constant ENDD                => 0x2000;
    use constant SRQI               => 0x1000;
    use constant RQS                => 0x0800;
    use constant SPOLL              => 0x0400;
    use constant EVENT              => 0x0200;
    use constant CMPL               => 0x0100;
    use constant LOK                => 0x0080;
    use constant REM                => 0x0040;
    use constant CIC                => 0x0020;
    use constant ATN                => 0x0010;
    use constant TACS               => 0x0008;
    use constant LACS               => 0x0004;
    use constant DTAS               => 0x0002;
    use constant DCAS               => 0x0001;
    use constant EDVR               => 0;
    use constant ECIC               => 1;
    use constant ENOL               => 2;
    use constant EADR               => 3;
    use constant EARG               => 4;
    use constant ESAC               => 5;
    use constant EABO               => 6;
    use constant ENEB               => 7;
    use constant EDMA               => 8;
    use constant EBTO               => 9;
    use constant EOIP               => 10;
    use constant ECAP               => 11;
    use constant EFSO               => 12;
    use constant EOWN               => 13;
    use constant EBUS               => 14;
    use constant ESTB               => 15;
    use constant ESRQ               => 16;
    use constant ETAB               => 20;
    use constant ELCK               => 21;
    use constant TNONE              => 0;
    use constant T10us              => 1;
    use constant T30us              => 2;
    use constant T100us             => 3;
    use constant T300us             => 4;
    use constant T1ms               => 5;
    use constant T3ms               => 6;
    use constant T10ms              => 7;
    use constant T30ms              => 8;
    use constant T100ms             => 9;
    use constant T300ms             => 10;
    use constant T1s                => 11;
    use constant T3s                => 12;
    use constant T10s               => 13;
    use constant T30s               => 14;
    use constant T100s              => 15;
    use constant T300s              => 16;
    use constant T1000s             => 17;
    use constant ValidDAV           => 0x0001;
    use constant ValidNDAC          => 0x0002;
    use constant ValidNRFD          => 0x0004;
    use constant ValidIFC           => 0x0008;
    use constant ValidREN           => 0x0010;
    use constant ValidSRQ           => 0x0020;
    use constant ValidATN           => 0x0040;
    use constant ValidEOI           => 0x0080;
    use constant BusDAV             => 0x0100;
    use constant BusNDAC            => 0x0200;
    use constant BusNRFD            => 0x0400;
    use constant BusIFC             => 0x0800;
    use constant BusREN             => 0x1000;
    use constant BusSRQ             => 0x2000;
    use constant BusATN             => 0x4000;
    use constant BusEOI             => 0x8000;
    use constant BUS_DAV            => 0x0100;
    use constant BUS_NDAC           => 0x0200;
    use constant BUS_NRFD           => 0x0400;
    use constant BUS_IFC            => 0x0800;
    use constant BUS_REN            => 0x1000;
    use constant BUS_SRQ            => 0x2000;
    use constant BUS_ATN            => 0x4000;
    use constant BUS_EOI            => 0x8000;
    use constant IbcPAD             => 0x0001;
    use constant IbcSAD             => 0x0002;
    use constant IbcTMO             => 0x0003;
    use constant IbcEOT             => 0x0004;
    use constant IbcPPC             => 0x0005;
    use constant IbcREADDR          => 0x0006;
    use constant IbcAUTOPOLL        => 0x0007;
    use constant IbcCICPROT         => 0x0008;
    use constant IbcIRQ             => 0x0009;
    use constant IbcSC              => 0x000A;
    use constant IbcSRE             => 0x000B;
    use constant IbcEOSrd           => 0x000C;
    use constant IbcEOSwrt          => 0x000D;
    use constant IbcEOScmp          => 0x000E;
    use constant IbcEOSchar         => 0x000F;
    use constant IbcPP2             => 0x0010;
    use constant IbcTIMING          => 0x0011;
    use constant IbcDMA             => 0x0012;
    use constant IbcReadAdjust      => 0x0013;
    use constant IbcWriteAdjust     => 0x0014;
    use constant IbcEventQueue      => 0x0015;
    use constant IbcSPollBit        => 0x0016;
    use constant IbcSpollBit        => 0x0016;
    use constant IbcSendLLO         => 0x0017;
    use constant IbcSPollTime       => 0x0018;
    use constant IbcPPollTime       => 0x0019;
    use constant IbcNoEndBitOnEOS   => 0x01A;
    use constant IbcEndBitIsNormal  => 0x1A;
    use constant IbcUnAddr          => 0x001B;
    use constant IbcSignalNumber    => 0x001C;
    use constant IbcHSCableLength   => 0x01F;
    use constant IbcLON             => 0x0022;
    use constant IbaPAD             => 0x0001;
    use constant IbaSAD             => 0x0002;
    use constant IbaTMO             => 0x0003;
    use constant IbaEOT             => 0x0004;
    use constant IbaPPC             => 0x0005;
    use constant IbaREADDR          => 0x0006;
    use constant IbaAUTOPOLL        => 0x0007;
    use constant IbaCICPROT         => 0x0008;
    use constant IbaIRQ             => 0x0009;
    use constant IbaSC              => 0x000A;
    use constant IbaSRE             => 0x000B;
    use constant IbaEOSrd           => 0x000C;
    use constant IbaEOSwrt          => 0x000D;
    use constant IbaEOScmp          => 0x000E;
    use constant IbaEOSchar         => 0x000F;
    use constant IbaPP2             => 0x0010;
    use constant IbaTIMING          => 0x0011;
    use constant IbaDMA             => 0x0012;
    use constant IbaReadAdjust      => 0x0013;
    use constant IbaWriteAdjust     => 0x0014;
    use constant IbaEventQueue      => 0x0015;
    use constant IbaSPollBit        => 0x0016;
    use constant IbaSendLLO         => 0x0017;
    use constant IbaSPollTime       => 0x0018;
    use constant IbaPPollTime       => 0x0019;
    use constant IbaNoEndBitOnEOS   => 0x01A;
    use constant IbaEndBitIsNormal  => 0x1A;
    use constant IbaUnAddr          => 0x001B;
    use constant IbaSignalNumber    => 0x001C;
    use constant IbaHSCableLength   => 0x01F;
    use constant IbaLON             => 0x0022;
    use constant IbaBNA             => 0x200;
    use constant IbaBaseAddr        => 0x201;
    use constant IbaDmaChannel      => 0x202;
    use constant IbaIrqLevel        => 0x203;
    use constant IbaBaud            => 0x204;
    use constant IbaParity          => 0x205;
    use constant IbaStopBits        => 0x206;
    use constant IbaDataBits        => 0x207;
    use constant IbaComPort         => 0x208;
    use constant IbaComIrqLevel     => 0x209;
    use constant IbaComPortBase     => 0x20A;
    use constant IbaSingleCycleDma  => 0x20B;
    use constant NO_SAD             => 0;
    use constant ALL_SAD            => -1;
 

has 'DATABASE'     => ( is => 'rw', isa => 'Database', lazy_build => 1 );

my $VERSION      = "1.2";
my $COMPILE_DATE = "08-JAN-2020";
sub printConfig {
    my $self = shift;
    my $params = shift;

    #my $gpib = shift;
    #
	#$gpib = LinuxGpib::ibeot( $dev, 1 );
    #my $ibsta = $gpib->ibsta;
    #my $ibcnt = $gpib->ibcnt;
    #my $iberr = $gpib->iberr;
    my $v;
 
    print "Configuration for gpib\n";
	my $result="xxxx";
    $v = LinuxGpib::ibask( $params->{DEVICE_FD}, IbaAUTOPOLL, \$result );
	if( ($v & ERR ) == ERR ) {
		print "HELAAS: ERROR\n" ;
	}
die sprintf( "0x%X", $v ) ;
#    print "    Automatic serial polling enabled.\n" if $v;
#    print "    Automatic serial polling diabled.\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaCICPROT);
#    print "    CIC protcol enabled.\n" if $v;
#    print "    CIC protcol disable.\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaDMA);
#    print "    DMA enabled.\n" if $v;
#    print "    DMA disabled.\n" if !$v;
# 
#    print "    GPIB read configuration:\n";
#    $v = LinuxGpib::ibask(GPIB->IbaEOSrd);
#    print "        Read operation terminated by EOS\n" if $v;
#    print "        EOS character ignored on read\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaEndBitIsNormal);
#    print "        END bit set by EOI, EOS, or EOI+EOS match.\n" if $v;
#    print "        END bit set by EOI or EOI+EOS match.\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaEOSchar);
#    printf"        EOS character for read is 0x%02x.\n", $v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaEOScmp);
#    print "        8-bit compare used for EOS on read.\n" if $v;
#    print "        7-bit compare used for EOS on read.\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaReadAdjust);
#    print "        Bytes swapped on read\n" if $v;
#    print "        Bytes not swapped on read\n" if !$v;
# 
# 
#    print "    GPIB write configuration:\n";
#    $v = LinuxGpib::ibask(GPIB->IbaEOSwrt);
#    print "        EOI asserted when EOS char sent during write\n" if $v;
#    print "        EOI not asserted when EOS char sent during write\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaEOT);
#    print "        EOI asserted at end of write\n" if $v;
#    print "        EOI not asserted at end of write\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaWriteAdjust);
#    print "        Bytes swapped on write\n" if $v;
#    print "        Bytes not swapped on write\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaHSCableLength);
#    printf"    HS-488 enabled , cable length is %dm.\n",$v if $v;
#    print "    HS-488 disabled\n" if !$v;
# 
##   In the manual, but not in NI's .h file...
##    $v = $gpib->ibask(GPIB->IbaIst);
##    print "    Individual status bit set\n" if $v;
##    print "    Individual status bit not set\n" if !$v;
#     
#    $v = LinuxGpib::ibask(GPIB->IbaPAD);
#    printf "    Primary address is   0x%02x.\n", $v;
#    $v = LinuxGpib::ibask(GPIB->IbaSAD);
#    printf "    Secondary address is 0x%02x.\n", $v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaPP2);
#    print "    PP2 mode, local parallel poll\n" if $v;
#    print "    PP1 mode, remote parallel poll\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaPPC);
#    printf "    Parallel poll configuration 0x%02x.\n", $v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaPPollTime);
#    printf "    Parallel poll time 0x%02x.\n", $v;
#  
##    $v = $gpib->ibask(GPIB->IbaRsv);
##    printf "    Serial poll status 0x%02x.\n", $v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaSC);
#    print "    Board is system controller\n" if $v;
#    print "    Board is not system controller\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaSendLLO);
#    print "    LLO command is sent\n" if $v;
#    print "    LLO command is not sent\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaSRE);
#    print "    REN is automatically asserted\n" if $v;
#    print "    REN is not automatically asserted\n" if !$v;
# 
#    $v = LinuxGpib::ibask(GPIB->IbaTIMING);
#    print "    T1 delay of 2us (normal)\n" if ($v == 1);
#    print "    T1 delay of 500ns (high speed)\n" if ($v == 2);
#    print "    T1 delay of 350ns (very high speed)\n" if ($v == 3);
#    printf"    T1 timing of %d.\n" if ($v<1 || $v>3);
# 
#    $v = LinuxGpib::ibask(GPIB->IbaTMO);
#    printf "    TMO is %s (0x%02x).\n", $tmo_name[$v], $v;
}

# Description:
# 	Lookup $params->{DEVICE_ID} in table GPIB_DEVICE and init the device.
# 	Device settings are stored in $self->{GPIB_DEVICE}
# 	
sub initDevice {
    my $self = shift;
    my $params = shift;

	my $dev;
	my $rv ;
	my $debug="";
	my $status = "ERROR" ;

	$rv = $self->getDeviceInfo( $params ) ;
	my $x;
	if( $rv->{STATUS} eq "OK" ) {
		$self->{GPIB_DEVICE} = $rv->{GPIB_DEVICE}[0];
		$debug .= sprintf( "EOS_MODE == 0x%X, SEND_EOI== 0x%X, TIMEOUT 0x%X, ", 
						$self->{GPIB_DEVICE}->{EOS_MODE},
						$self->{GPIB_DEVICE}->{SEND_EOI}, 
						$self->{GPIB_DEVICE}->{TIMEOUT} 
						);
		###################################################################################
		# board_index: specifies which GPIB interface board the device is connected to. 
		# pad and sad: arguments specify the GPIB address of the device to be opened 
		# 				(see ibpad() and ibsad()). 
		# timeout: for io operations is specified by timeout (see ibtmo()). 
		# If send_eoi is nonzero: then the EOI line will be asserted with the last byte sent 
		# 					during writes (see ibeot()). 
		# eos: specifies the end-of-string character and whether or not its reception should 
		# 		terminate reads (see ibeos()). 
		######################################################################################
		$dev=LinuxGpib::ibdev(
				$self->{GPIB_DEVICE}->{MINOR},
				$self->{GPIB_DEVICE}->{PAD},
				$self->{GPIB_DEVICE}->{SAD}, 
				$self->{GPIB_DEVICE}->{TIMEOUT}, 
				$self->{GPIB_DEVICE}->{SEND_EOI}, 
				$self->{GPIB_DEVICE}->{EOS_MODE} 
			) ;
			if( (LinuxGpib::ThreadIbsta() & ERR) == ERR ) {
				$debug .= "ibsta ERR ";
			} elsif( (LinuxGpib::ThreadIbsta() & CMPL) == CMPL ) {
				$debug .= "ibsta CMPL, ";
			}
			if( $dev > 0 ) {
				$status = "OK" ;
				#my $x=LinuxGpib::ibtmo( $dev, 12 );
				#if( ($x & CMPL) == CMPL ) {
				#	$status="OK";
				#	$debug .= sprintf( "ibtmo CMPL: reval=0x%X ", CMPL ) ;
				#} else {
				#	$debug .= "WHAT???? ibtmo: " . sprintf( "ibtmo reval=0x%X", $x ) ;
				#}
				# REOS: Enable termination of reads when eos character is received
				#
				#
				#$x=REOS | 0x0a;
				#$debug .= sprintf( "ibeos mask: 0x%X", $x ) ;
				#$x=LinuxGpib::ibeos( $dev, REOS | 0x0a );
				#$x=LinuxGpib::ibeos( $dev, 0x40A );
				#$x=LinuxGpib::ibeos( $dev, XEOS );
				#$x=LinuxGpib::ibeos( $dev, BIN );
				#$x=LinuxGpib::ibeos( $dev, 'E' );
				#$debug .= sprintf( ", ibeos return value: 0x%X", $x ) ;

				# #######################################################################
				# ibeot: Assert EOI with last data byte (board or device)
				# If send_eoi is non-zero:  then the EOI line will be asserted with the 
				# 							last byte sent by calls to ibwrt() and 
				# 							related functions. 
				# #######################################################################
				$x=LinuxGpib::ibeot( $dev, 1 );
				if( ( $x & CMPL ) == CMPL ) {
					$debug .= sprintf( ", ibeot == CMPL" ) ;
				} else {
					$debug .= sprintf( ", ibeot return value: 0x%X", $x ) ;
				}
				# Same as ibeot
    			#$x = LinuxGpib::ibconfig( $params->{DEVICE_FD}, IbcEOT, 1 );
				#if( ( $x & ERR ) == ERR ) {
				#	die "ibconfig: ERROR" ;
				#}
			}
	}
	return {STATUS => $status, 
			DEBUG => $debug,
			TRHREADIBSTA => sprintf( "0x%X 0%O %d", LinuxGpib::ThreadIbsta(), LinuxGpib::ThreadIbsta(), LinuxGpib::ThreadIbsta()),
			THREADIBERR => sprintf( "0x%X 0%O %d", LinuxGpib::ThreadIberr(), LinuxGpib::ThreadIberr(), LinuxGpib::ThreadIberr()),
			DEVICE_FD => $dev } ;
}
sub send {
    my $self = shift;
    my $params = shift;

	my $status = "ERROR" ;
	my $iberr="";
	my $debug="";
	my $rv=LinuxGpib::ibwrt( 
				$params->{DEVICE_FD}, 
				$params->{COMMAND},
				length( $params->{COMMAND} ) );
	if( (LinuxGpib::ThreadIbsta() & ERR) == ERR ) {
		$debug .= sprintf( "ERROR: ibsta value 0x%X 0%O %d", 
				LinuxGpib::ThreadIberr(), LinuxGpib::ThreadIberr(), LinuxGpib::ThreadIberr());
		$iberr= $self->gpib_error_string( {IBERR => 
											LinuxGpib::ThreadIberr() } )->{IBERR_DESCRIPTION} ;
		$status="ERROR";
	} elsif( (LinuxGpib::ThreadIbsta() & ENDD) == ENDD ) {
			$debug .=  sprintf( ", ibsta: END 0x%X, ", ENDD);
			if( (LinuxGpib::ThreadIbsta() & CMPL) == CMPL ) {
				$debug .=  sprintf( ", ibsta: CMPL 0x%X", CMPL);
				$status = "OK" ;
			}
	} else {
		die "send: HUH welke bits????";
	}

	return { STATUS =>"$status", 
			 THREADIBERR => sprintf( "0x%X 0%O %d", LinuxGpib::ThreadIberr(), LinuxGpib::ThreadIberr(), LinuxGpib::ThreadIberr()),
			 IBERR_DESCRIPTION => $iberr,
			 TRHREADIBSTA => sprintf( "0x%X 0%O %d", LinuxGpib::ThreadIbsta(), LinuxGpib::ThreadIbsta(), LinuxGpib::ThreadIbsta()),
			 DEBUG => $debug
	};
}

# TODO:
# if((ThreadIbsta() & ERR) == 0 || ThreadIberr() != EDVR)
#  read_count = ThreadIbcntl();


#
sub read {
    my $self = shift;
    my $params = shift;

	my $buffer ;
	my $len = 10; # SAVE
	my $status = "OK" ;
	my $iberr="";
	my $debug="";
	my $rv ;
	my $hstring;

	my $collect="";
	my $cnt;
	my $rest="";
	my @a;
	my $tot=0;
	#while( ($rv=LinuxGpib::ibrd( $params->{DEVICE_FD}, $buffer, $len )) != 0 )
	#{
	$rv=LinuxGpib::ibrd( $params->{DEVICE_FD}, $buffer, $len );
			$cnt = LinuxGpib::ThreadIbcnt();
			if( (LinuxGpib::ThreadIbsta() & ERR) == ERR ) {
				$debug .=sprintf( "ERROR on ibrd: ibsta == ERR, buffer: %s, cnt == %d, ibrd retval 0x%X", $buffer, $cnt, $rv ) ;
				print "$debug";
				exit;
				#if( $collect ne "" ) {
				#		die "VREEMD: ERROR MAAR TIJDENS HET LEZEN:  $debug, collect==>$collect<===" ;
				#}
				#last;
			}
			#print "TEST 0a: CNT=$cnt (max read len: $len):>>$buffer<<\n";
			if( defined $self->{REST} ) {
				#print "PREFIX REST >>$self->{REST}<< + BUFFER >>$buffer<< \n" ;
				#	
				my $len1 = length( $self->{REST} ) ;
				my $len2 = length( $buffer ) ;
				$tot = $len1 + $len2 ;
				#print "ADD BUFFER $len2 TO REST $len1. TOTAL = $tot\n";
				$buffer = $self->{REST} . $buffer ;
				#print "\t====>$buffer<==\n" ;
				# REST is used, so clear it
			} 
			$self->{REST} = "";

			#my $tot = length( $self->{REST} ) + $cnt;
			#print "BUFLEN: $tot\nBUFFER:>>$buffer<<\n"; 
			# Get lastbytes first
			my $last2bytes=substr( $buffer, -2 ) ;
			
			# Now split
			# 	
			if( $buffer =~ /\r\n/ ) {
				@a = split( /\r\n/, $buffer ) ;
				#print "SPLITTING buffer >>$buffer<<\n". Dumper( \@a ) ;; 
				#die "STOP" ;
			} else {
				@a =() ;
			}

			if( $last2bytes ne "\r\n" ) {
				#print "NO CRLF AT END OF THE STRING: $last2bytes\n" ; 
				# Last value is not complete yet!
				#
				#
				#		
				if( @a > 0 ) {
					#print "DO the POP: a:" . Dumper( \@a ) ;
					my $p= pop( @a ) ;
					if( defined $p ) {
						$self->{REST} = $p;
						#print "NEW REST=: $self->{REST}. NEW REST LENGTH:".
								length( $p ) . "\n"  ;
					}
				} else {
					$self->{REST} = $buffer ;
				}
			} else {
				#print "CRLF AT THE END!!! KEURIG EINDE\n" ;
			}
#print "TEST 1. AANTAL: " . @a . ", a=" .Dumper( \@a ) . "BUFFER: $buffer\n";
			#print "CNT=$cnt, rest=$rest\n". Dumper( \@a ) ; ;
#print "TEST 1. AANTAL: " . @a . ", a=" .Dumper( \@a ) ;
			
			#$hstring = unpack ("H*",$buffer);
			##$debug .= ", hstring=$hstring" ;
			#if( $hstring =~ /0a/ ) {
			#	$debug .= ", JA, 0a EINDE! COLLECT=$collect";
			#	$status = "OK" ;
			#	last;
			#} else {
			#	if( "$hstring" !~ /0d/ ) {
			#		#print "ADD $hstring\n" ;
			#		$collect .= $buffer ;
			#	} else {
			#		$debug .= ", JA HOOR, EEN 0d, NU NOG 1 LEZEN";
			#		# Wanneer len <> 1 is, dan nu wel op 1 zetten, want er komt nog maar 1 byte
			#		$len=1;
			#	}
			#}
			##print "BUFFER: **$buffer** -->". $hstring . "<--- ThreadIbcnt:" . LinuxGpib::ThreadIbcnt() . "\n";
	#}
	#print " EXIT FROM LOOP " ;
	#print "************ $collect ***********";

	#my $rv=LinuxGpib::ibrd( $params->{DEVICE_FD}, $buffer, $len ) ;
	#$debug .= sprintf( "ibrd return value 0x%X ", $rv ) ;
	#convert to hex
	#my $hstring = unpack ("H*",$buffer);
	#$debug .="hstring: $hstring <----";
	#if( ($rv & CMPL ) == CMPL ) {
	#	$debug .="ibrd is wel CMPL!!";
	#}
	#if( (LinuxGpib::ThreadIbsta() & ERR) == ERR ) {
	#	$status = "ERROR" ;
	#	$debug .= sprintf( "ibsta: ERR mask is true: 0x%X", ERR  ) ; 
	#	$iberr= $self->gpib_error_string( {IBERR => LinuxGpib::ThreadIberr() } )->{IBERR_DESCRIPTION} ;
	#} else {
	#	#$buffer =~ s/\r|\n//g;
	#	$status = "OK";
	#}
	#
	#
	if( @a == 0 ) {
		$status = "NOT COMPLETED" ;
	}
	#print "driver: STATUS: $status, AANTAL VALUES: ". @a . "\n" ;
	return { STATUS =>"$status",
			 THREADIBERR => sprintf( "0x%X 0%O %d", LinuxGpib::ThreadIberr(), LinuxGpib::ThreadIberr(), LinuxGpib::ThreadIberr()),
			 IBERR_DESCRIPTION => $iberr,
			 TRHREADIBSTA => sprintf( "0x%X 0%O %d", LinuxGpib::ThreadIbsta(), LinuxGpib::ThreadIbsta(), LinuxGpib::ThreadIbsta()),
			 DEBUG=> $debug,
			 DATA => \@a };
}

sub gpib_error_string {
    my $self = shift;
    my $params = shift;
	return { STATUS => "OK", 
			 THREADIBERR => $params->{IBERR},
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

sub sdc_getFileno {
    my $self   = shift;
    my $params = shift;

    my $v = LinuxGpib::sdc_getFileno( 16 );

	return { STATUS=>"OK", FILENO => $v } ;
}
1;
