use strict;
use lib '.';
use threads;
use IO::Socket::INET;
use IO::Socket;
use IO::Select;
use Data::Dumper;
use Database;
use TransProcessor;
use SDC::GPIB;
use Config;
use Config::Auto;

=encoding utf8

=head1 Proxy Server Snoeks

=head2 DEFINITIES

=over 12

=item C<Server>

De Proxy Server accepteert connecties van clients zoals barcode readers.

Berichten worden gelezen en in een eigen database gezet.

De records in de database kunnen door een ander proces worden gelezen en verwerk. Deze proxy server richt zich dan uitsluitend op het zo efficient afhandelen
van alle client berichten.

=Listen poort=

De default listen port is 3126. 


=back

=head2 AFHANKELIJKHEDEN

=head3 package TransProcessor

Deze package haalt berichten uit de ingelezen data.

=head3 package Database

De berichten worden weggeschreve naar een C<sqlite> database.

=cut

$|++;

my $VERSION="1.1 2-NOV-2014";
my %clients;
my $rv;
my $port = 3126;


sub deamon {
	my $config_file = "/usr/lib/cgi-bin/gpib.cfg";
	my $config = Config::Auto::parse($config_file);
	my $db = new Database(
		dsn => $config->{dsn},
		user => $config->{user},
		pass => $config->{password},
		LOG4DB => 1,
		CONFIG => $config,
		LOG_LEVEL=>"FATAL",
		LOG_CLASS => "testFORMS"
	);
	my $gpib = new SDC::GPIB( DATABASE => $db );
	my $device_id='1998';
	my $rv = $gpib->getDeviceInfo( { DEVICE_ID => $device_id } );
	print Dumper($rv);
	my $rv = $gpib->initDevice( { DEVICE_ID => $device_id } );
	print "initDevice: " . Dumper($rv);
	my $device_fd = $rv->{DEVICE_FD};
	$rv = $gpib->sdc_getFileno( { DEVICE_FD => $device_fd } );
	my $fileno = $rv->{FILENO};
	print "FILENO=$fileno\n";

	my $listener = IO::Socket::INET->new(
		LocalPort => $port,
		Listen => 5,
		Proto => "tcp",
		Reuse => 1
	) || die "Cannot create socket\n";

	my $client_num = 0;
	my ( $fh, $sql );
	my $sel = new IO::Select($listener);
	my $tp = TransProcessor->new;

	my $db = new Database(
		dsn => 'dbi:SQLite:dbname=TransServer.db',
		user => 'SYSADM',
		pass => 'SYSADM'
	);

	#$rv=$db->query("SELECT * FROM sysparams ");
	#if( $rv->{STATUS} !~ /OK/ ) {
	#	die "ERROR: Check sqlite3 database TransServer.db";
	#}
	#$rv=$db->execute();
	#$rv=$db->single();

	#print "Proxy Server database version: " . $rv->{DATA}->{version} . "\n";
	print "Listen on $port : client_num=$client_num\n";
	print "starChar: " . $tp->startChar() . "\n";
	print "endChar: " . $tp->endChar() . "\n";

	my $count=0;
	my $data;
	my %DEVICES;

	# Store the CMDs into the sqlite3 database
	$sql = "INSERT INTO dataRecords( port, data ) VALUES ( ?, ? )";
	$sel->add($fileno);
	$DEVICES{$fileno} = $device_id;

	print "Waiting...\n#######################################\n";
	my $count=0;
	my $valueCount=0;
	while( my @ready = $sel->can_read ) {
		print "someone is ready\n";
		$count++;
		if( $count > 1000 ) {
			$count++ ;
			last;
		}
		foreach $fh (@ready) {
			print "$fh is ready\n" ;
			if( $fh == $listener ) {
				print "LISTENER is READY\n" ;
				my $client = $listener->accept;
				$sel->add($client);
				print "Listener Connects client: peeraddr=".$client->peerport ."\n";
				my %newCLIENT = (
					DATA => "",
					CLIENT_ID => $client->peerport,
					ROLE => ""
				);
				$clients{$client->peerport}=\%newCLIENT;
				print $client "Snoeks telnet server $VERSION\n";
			} 
			if( defined $DEVICES{$fh} ) {
					print "GPIB IS READY ($fh)\n" ;
					$rv = $gpib->read( { DEVICE_FD => $device_fd } );
					if( $rv->{STATUS} eq "OK" ) {
						#print "DAEMON COMPLETE MESSAGE: AANTAL:" .
						#		@{$rv->{DATA}}."\n";
						for( my $j=0; $j< @{$rv->{DATA}}; $j++) {
								printf( "---------- %15s %4d VALUE: %s\n",
										$device_id, $valueCount++, $rv->{DATA}->[$j] ) ;
						}
					} else { 
						#print "main: STATUS= " . $rv->{STATUS}."\n";
					}
				} 
				if( ! defined $DEVICES{$fh} ) {
					my($remote_address) = $fh->recv( $data, 1024 );

					#print "remote_address: $remote_address\n"  ;
					#print "data       : " . $data . "\n"  ;
					#print "data length: " . length $data . "\n"  ;
					if( !$data ) {
						print "CLOSE CLIENT_ID **" . $fh->peerport . "**\n" .Dumper($fh);
						delete $clients{$fh->peerport};
						$sel->remove($fh);
						$fh->close;

						next;
					}

					# For test purpose: strip CR/LF in telnet
					$data =~ s/\r\n$//;
					print "data 2      : " . $data . "\n";
					$rv = $gpib->send( { DEVICE_FD => $device_fd, COMMAND=>$data } ) ;
					print Dumper( $rv ) ;

					# Concat the data portion
					$clients{$fh->peerport()}->{DATA} .= $data;
					do {
						$rv = $tp->extractCommand($clients{$fh->peerport()}->{DATA} );
						if( $rv->{STATUS} =~/OK/ ) {
							$clients{$fh->peerport()}->{DATA} =
							  $rv->{REST};
							my $cmd=$rv->{CMD};
							print "CMD=$cmd\n";
							if( $rv->{PRE_CHAR_CMD} ne $tp->startChar()) {
								print "\tSKIPPED SOME BYTES\n";
								print "\tPRE_CHAR_CMD:".$rv->{PRE_CHAR_CMD} . "\n";
							}
							$rv=$db->query("$sql");
							$rv=$db->bind( [$fh->peerport(), $cmd] );
							$rv=$db->execute();
							$rv=$db->commitTransaction();
						}
					} while( $rv->{STATUS} =~ /OK/ );
					if( $data =~/end/ ) {
						print "Bye to peerport=".$fh->peerport() . "\n";

						$sel->remove($fh);
						delete $clients{$fh->peerport};
					} elsif( $data =~ /^ALL:/ ) {
						foreach my $p (keys %clients) {
							$data =~ s/^ALL://;
							$clients{$p}->send("Msg from: ". $data);
						}
					}
					#print "simulate working 20 sec...";
					#sleep(20);
				}
		}
		#print "\nCLIENTS STATUS: ". Dumper( \%clients );
		print "Waiting...";
	}
}
deamon();
exit;
my($pid) = fork();
if ( $pid != 0 ) {

	#parent process
	print "parent\n";
} else {
	print "child running as $$\n";
	deamon();
}
