package GPIBApp::Controller::Rest;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use JSON::XS;
use DBIx::Connector;
use Database;
use SDC::GPIB;


# This action will render a template
sub welcome {
  my $self = shift;

  my $devices = $self->DEVICESHLP->{DEVICES} ;
  $self->app->log->info('Controller::Rest.welcome' . Dumper( $devices ) ) ;
  # Render template "example/welcome.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub readFromDevice {
    my $self = shift;

    my( $rv, $debug ) ;

    my $status="OK";
    my $json = $self->req->body;
    my $h = decode_json( $json ) ;
    $self->app->log->info('Controller::Rest.readFromDevice' . $json ) ;

    my $devices = $self->DEVICESHLP->{DEVICES} ;
    my $device_fd = $devices->{$h->{DEVICE_ID}}->{DEVICE_FD} ;
    if( ! $device_fd ) {
        $status = 'ERROR' ;
        $debug = "DEVICE_ID $h->{DEVICE_ID} has not DEVICE_FD. Connection is closed! Cannot read.";
    } else {
        my $gpib = $self->SDCGPIBHLP->{SDCGPIB} ;
        $rv = $gpib->read( { DEVICE_FD => $device_fd }) ;
        $status = $rv->{STATUS};
        if( $rv->{STATUS} eq "OK" && $rv->{RETVAL} == 0) {
            $debug = "Read from device" ;
        } else {
            $debug = "gpib->read failed!" ;
        }
    }

    $self->render(json =>  {
                    STATUS=>"$status",
                    DEBUG=> $debug,
                    DEVICE_FD=> $device_fd,
                    DEVICE_ID=> $h->{DEVICE_ID},
					RETVAL => $rv->{RETVAL},
					DATA => $rv->{DATA}
    });

}




sub sendToDevice {
	my $self = shift;

    my( $rv, $debug ) ;

	my $status="OK";
	my $json = $self->req->body;
	my $h = decode_json( $json ) ;
  	$self->app->log->info('Controller::Rest.sendToDevice' . $json ) ;
	
  	my $devices = $self->DEVICESHLP->{DEVICES} ;
	my $device_fd = $devices->{$h->{DEVICE_ID}}->{DEVICE_FD} ;
	if( ! $device_fd ) {
		$status = 'ERROR' ;
		$debug = "DEVICE_ID $h->{DEVICE_ID} has not DEVICE_FD. Connection is closed";
	} else {
		my $gpib = $self->SDCGPIBHLP->{SDCGPIB} ;
		$rv = $gpib->send( { 
					DEVICE_FD => $device_fd, 
					COMMAND=>$h->{DEVICE_COMMAND} 
		}) ;
		$status = $rv->{STATUS};
		if( $rv->{STATUS} eq "OK" ) {
			$debug = "Command send to device" ;
		} else {
			$debug = "gpib->send failed!" ;
		}
	}

    $self->render(json =>  {
					STATUS=>"$status",
					DEBUG=> $debug,
					DEVICE_FD=> $device_fd,
					DEVICE_ID=> $h->{DEVICE_ID},
	});

}
sub initDevice {
	my $self = shift;
    my $rv ;

	my $debug ='';
 	my $status="ERROR";
	my $json = $self->req->body;
	my $h = decode_json( $json ) ;
  	my $devices = $self->DEVICESHLP->{DEVICES} ;
  	$self->app->log->info('Controller::Rest.initDevice' . Dumper( $h ) ) ;
  	$self->app->log->info('initDevice:devices: is now:' . Dumper( $devices ) ) ;
	my $gpib = $self->SDCGPIBHLP->{SDCGPIB} ;
	if( ! $devices->{$h->{DEVICE_ID}}->{DEVICE_FD} ) {
		$debug ="Device is NOT open.";
		$rv = $gpib->initDevice( { DEVICE_ID => '3456A' } );
  		$self->app->log->info('after initDevice' . Dumper( $rv ) ) ;
		if( $rv->{STATUS} eq "OK" ) {
			$status="OK";
			$debug ="Device is opened.";
			$devices->{$h->{DEVICE_ID}}->{DEVICE_FD} = $rv->{DEVICE_FD} ;
  			$self->app->log->info('initDevice:devices is not:' . Dumper( $devices ) ) ;
		}
		#$rv->{DEVICES}=$devices;
	} else {
		$status="OK";
		$debug ="Device is already open.";
	}
    $self->render(json =>  {
					STATUS=>"$status", 
					DEVICE_FD => $devices->{$h->{DEVICE_ID}}->{DEVICE_FD} ,
					DEBUG => $debug
				}) ;
}

# POST
sub getDeviceInfo {
	my $self = shift;
	my $json = $self->req->body;
	my $h = decode_json( $json ) ;
  	$self->app->log->info('Controller::Rest.getDeviceInfo' . Dumper( $h ) ) ;

  	$self->app->log->info('getDeviceInfo' . 
			Dumper( $h->{KEYS}[0][1]->{keyValue} ) ) ;
	my $gpib = $self->SDCGPIBHLP->{SDCGPIB} ;
	my $rv = $gpib->getDeviceInfo( { 
				DEVICE_ID => $h->{KEYS}[0][1]->{keyValue}
 	} );
  	$self->app->log->info('getDeviceInfo' . Dumper( $rv ) ) ;

    $self->render(json =>  $rv ) ;
}
# POST
sub taGetDevice {
	my $self = shift;
	my $json = $self->req->body;
	my $h = decode_json( $json ) ;

  	$self->app->log->info('Controller::Rest.taGetDevice' . Dumper( $h ) ) ;
	my $gpib = $self->SDCGPIBHLP->{SDCGPIB} ;

	my $rv = $gpib->taGetDevice( { DESCRIPTION => $h->{FORM_FIELDS}->{DEVICE_ID} } );
  	$self->app->log->info('taGetDevice' . Dumper( $rv ) ) ;

    $self->render(json =>  $rv ) ;
}

sub version {
  my $self = shift;

  my( $db, $u, $rv, $m, %response ) ;

  #my $config = $self->plugin('Config');

  $self->app->log->info('Controller::Rest.version' ) ;

  # Get the Helpers
  $db = $self->DATABASEHLP->{DATABASE} ;

  $self->render(json => {
                STATUS   => "OK",
                PERL => [ $db->version() ]
				});
}

1;
